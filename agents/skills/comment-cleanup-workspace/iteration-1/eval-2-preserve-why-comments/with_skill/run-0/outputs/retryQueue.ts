type Job = { id: string; attempts: number; runAt: number };

export class RetryQueue {
  private jobs: Job[] = [];

  add(job: Job) {
    this.jobs.push(job);
    // 配列ではなくヒープを使うべきか検討したが、同時実行ジョブは常に数十件程度で
    // 線形探索でも十分速く、ヒープの複雑さに見合わないため配列のまま。
    this.jobs.sort((a, b) => a.runAt - b.runAt);
  }

  poll(now: number): Job | undefined {
    const next = this.jobs[0];
    if (!next || next.runAt > now) {
      return undefined;
    }
    return this.jobs.shift();
  }

  backoff(attempts: number): number {
    // 上限なしだと一度失敗が続いたジョブが事実上永久に再実行されなくなり、
    // 復旧後の処理が大幅に遅延するため、5分でクランプする。
    const base = 1000 * 2 ** attempts;
    return Math.min(base, 5 * 60 * 1000);
  }

  size(): number {
    return this.jobs.length;
  }
}
