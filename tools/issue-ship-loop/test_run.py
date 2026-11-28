"""Command integration tests with local GitHub/agent doubles; no network calls."""

import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest


SCRIPT = Path(__file__).with_name("run.sh")
SKILLS = SCRIPT.parents[2] / "agents" / "skills"
MOCK = r'''
import json, os, pathlib, sys, time
root = pathlib.Path(os.environ["MOCK_ROOT"])
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
with (root / "calls.jsonl").open("a") as f:
    f.write(json.dumps([name, args]) + "\n")
if name == "git":
    if args[:1] == ["-C"]:
        print((pathlib.Path(args[1]) / ".branch").read_text())
    elif args[:1] == ["rev-parse"]:
        print(root if args[1] == "--show-toplevel" else root / ".git")
    elif args[:1] == ["symbolic-ref"]:
        print("origin/main")
    elif args[:1] == ["wt"]:
        wt = root / "worktrees" / args[2]
        wt.mkdir(parents=True, exist_ok=True)
        (wt / ".branch").write_text(args[2])
        print(wt)
elif name == "gh":
    statefile = root / "issues.json"
    issues = json.loads(statefile.read_text())
    if args[:2] == ["issue", "list"]:
        if os.environ.get("MOCK_LIST_FAIL"):
            sys.exit(9)
        if os.environ.get("MOCK_LIST_WAIT"):
            (root / "listing-queue").touch()
            deadline = time.monotonic() + 15
            while not (root / "release-list").exists():
                if time.monotonic() > deadline:
                    sys.exit(91)
                time.sleep(0.02)
        label = args[args.index("--label") + 1]
        for n, labels in issues.items():
            if label in labels:
                print(n)
    elif args[:2] == ["issue", "view"]:
        print("\n".join(issues[args[2]]))
    elif args[:2] == ["issue", "edit"]:
        labels = issues[args[2]]
        for option, value in zip(args[3::2], args[4::2]):
            if option == "--remove-label" and value in labels:
                labels.remove(value)
            if option == "--add-label" and value not in labels:
                labels.append(value)
        statefile.write_text(json.dumps(issues))
    elif args[:2] == ["pr", "view"]:
        print("99 false")
elif name in ("claude", "codex"):
    (root / ("started-" + name)).write_text(str(os.getpid()))
    if os.environ.get("MOCK_AGENT_WAIT"):
        deadline = time.monotonic() + 20
        while not (root / "release-agents").exists():
            if time.monotonic() > deadline:
                sys.exit(90)
            time.sleep(0.02)
    print("mock agent result", flush=True)
    sys.exit(int(os.environ.get("MOCK_AGENT_RC", "0")))
'''


class ShiploopTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="shiploop-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / ".git").mkdir()
        binary = self.root / "bin"
        binary.mkdir()
        for name in ("git", "gh", "claude", "codex"):
            executable = binary / name
            executable.write_text(f"#!{sys.executable}\n" + MOCK)
            executable.chmod(0o755)
        (self.root / "issues.json").write_text("{}")
        self.env = {
            **os.environ,
            "PATH": f"{binary}{os.pathsep}{os.environ['PATH']}",
            "MOCK_ROOT": str(self.root),
            "SHIPLOOP_SKILLS_DIR": str(SKILLS),
        }
        self.state = self.root / ".git" / "ship-loop"

    def run_command(self, *args, **extra_env):
        return subprocess.run(
            ["bash", str(SCRIPT), *args], cwd=self.root,
            env={**self.env, **extra_env}, capture_output=True, text=True, timeout=20,
        )

    def calls(self, name=None):
        path = self.root / "calls.jsonl"
        calls = [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []
        return [args for tool, args in calls if name is None or tool == name]

    def start(self, *args):
        proc = subprocess.Popen(
            ["bash", str(SCRIPT), *args], cwd=self.root,
            env={**self.env, "MOCK_AGENT_WAIT": "1"},
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
            start_new_session=True,
        )

        def cleanup():
            if proc.poll() is None:
                os.killpg(proc.pid, signal.SIGKILL)
            proc.communicate(timeout=5)

        self.addCleanup(cleanup)
        return proc

    def wait_for_agents(self, *names):
        deadline = time.monotonic() + 10
        while not all((self.root / f"started-{name}").exists() for name in names):
            if time.monotonic() > deadline:
                self.fail(f"agents did not start: {names}")
            time.sleep(0.03)

    def test_triage_uses_skill_and_all_issues(self):
        result = self.run_command("triage")
        self.assertEqual(result.returncode, 0, result.stderr)
        invocation = self.calls("claude")[0]
        prompt = invocation[invocation.index("-p") + 1]
        self.assertIn("/issue-triage", prompt)
        self.assertIn("全オープン Issue", prompt)
        self.assertIn("ship:auto", prompt)
        self.assertFalse(self.calls("gh"))
        self.assertFalse((self.state / "locks" / "dispatch").exists())
        self.assertIn("mock agent result", next((self.state / "logs").glob("*.log")).read_text())

    def test_filtered_triage_and_codex_investigation(self):
        result = self.run_command("triage", "--from", "enhancement")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("ラベル「enhancement」", " ".join(self.calls("claude")[0]))
        result = self.run_command("investigate", "853", "--agent", "codex")
        self.assertEqual(result.returncode, 0, result.stderr)
        prompt = self.calls("codex")[0][-1]
        self.assertIn("$issue-investigate", prompt)
        self.assertIn("Issue #853", prompt)
        self.assertIn("実行キューへの追加は行わない", prompt)

    def test_failure_is_logged_and_lock_released(self):
        result = self.run_command("investigate", "853", MOCK_AGENT_RC="7")
        self.assertEqual(result.returncode, 7, result.stdout)
        self.assertFalse((self.state / "locks" / "dispatch").exists())
        self.assertEqual(len(list((self.state / "logs").glob("investigate-853-*.log"))), 1)

    def test_invalid_arguments_do_not_call_external_tools(self):
        for args in [("investigate",), ("investigate", "oops"),
                     ("triage", "--agent", "oops"), ("codex", "-n", "oops"),
                     ("investigate", "853", "--from", "bug")]:
            with self.subTest(args=args):
                self.assertNotEqual(self.run_command(*args).returncode, 0)
        self.assertFalse(self.calls())

    def test_concurrent_stages_are_excluded(self):
        proc = self.start("triage")
        self.wait_for_agents("claude")
        result = self.run_command("investigate", "853", "--agent", "codex")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.calls("codex"))
        (self.root / "release-agents").touch()
        output, _ = proc.communicate(timeout=10)
        self.assertEqual(proc.returncode, 0, output)

    def test_stop_persists_until_explicit_resume(self):
        self.assertEqual(self.run_command("stop").returncode, 0)
        self.assertTrue((self.state / "stop-requested").exists())
        self.assertEqual(self.run_command("both").returncode, 0)
        self.assertFalse(self.calls("gh"))
        self.assertFalse(self.calls("claude"))
        self.assertFalse(self.calls("codex"))
        status = self.run_command("status")
        self.assertIn("停止要求あり", status.stdout)
        self.assertEqual(self.run_command("resume").returncode, 0)
        self.assertFalse((self.state / "stop-requested").exists())
        self.assertFalse(self.calls("claude"))
        self.assertFalse(self.calls("codex"))

    def test_stop_finishes_both_current_issues_without_claiming_next(self):
        (self.root / "issues.json").write_text(json.dumps({
            "1": ["ship:auto"], "2": ["ship:auto"], "3": ["ship:auto"],
        }))
        proc = self.start("both")
        self.wait_for_agents("claude", "codex")
        self.assertEqual(self.run_command("stop").returncode, 0)
        self.assertIsNone(proc.poll(), "stop must not kill the current issues")
        (self.root / "release-agents").touch()
        output, _ = proc.communicate(timeout=10)
        self.assertEqual(proc.returncode, 0, output)
        issues = json.loads((self.root / "issues.json").read_text())
        self.assertEqual(issues["3"], ["ship:auto"])
        self.assertEqual(len(self.calls("claude")) + len(self.calls("codex")), 2)
        self.assertEqual(len([c for c in self.calls("gh") if c[:2] == ["pr", "view"]]), 2)
        self.assertTrue((self.state / "stop-requested").exists())
        self.assertFalse(list((self.state / "locks").iterdir()))
        self.run_command("resume")
        result = self.run_command("codex", "-n", "1")
        self.assertEqual(result.returncode, 0, result.stdout)
        issues = json.loads((self.root / "issues.json").read_text())
        self.assertEqual(issues["3"], ["ship:codex"])

    def test_stop_during_queue_fetch_prevents_claim(self):
        (self.root / "issues.json").write_text('{"1": ["ship:auto"]}')
        self.env["MOCK_LIST_WAIT"] = "1"
        proc = self.start("codex")
        deadline = time.monotonic() + 10
        while not (self.root / "listing-queue").exists():
            self.assertLess(time.monotonic(), deadline)
            time.sleep(0.02)
        self.assertEqual(self.run_command("stop").returncode, 0)
        (self.root / "release-list").touch()
        output, _ = proc.communicate(timeout=10)
        self.assertEqual(proc.returncode, 0, output)
        self.assertFalse(self.calls("codex"))
        self.assertEqual(json.loads((self.root / "issues.json").read_text()), {"1": ["ship:auto"]})

    def test_worker_failures_are_not_reported_as_empty_queue(self):
        result = self.run_command("both", MOCK_LIST_FAIL="1")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("キューを取得できなかった", result.stdout)
        self.assertFalse(self.calls("claude"))
        self.assertFalse(self.calls("codex"))


if __name__ == "__main__":
    unittest.main()
