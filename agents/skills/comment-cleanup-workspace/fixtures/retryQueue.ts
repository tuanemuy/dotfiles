// retryQueue.ts
// このファイルはジョブのリトライキューを実装している。
// 作成者: nakamura / 最終更新: 2024-06-20

type Job = { id: string; attempts: number; runAt: number };

export class RetryQueue {
  private jobs: Job[] = [];

  // ジョブを追加する
  add(job: Job) {
    this.jobs.push(job);
    // 配列ではなくヒープを使うべきか検討したが、同時実行ジョブは常に数十件程度で
    // 線形探索でも十分速く、ヒープの複雑さに見合わないため配列のまま。
    this.jobs.sort((a, b) => a.runAt - b.runAt);
  }

  // 次に実行すべきジョブを取り出す
  poll(now: number): Job | undefined {
    const next = this.jobs[0];
    if (!next || next.runAt > now) {
      // まだ実行時刻になっていない
      return undefined;
    }
    return this.jobs.shift();
  }

  // バックオフを計算する
  backoff(attempts: number): number {
    // 指数バックオフ。ただし上限を5分でクランプする。
    // 上限なしだと一度失敗が続いたジョブが事実上永久に再実行されなくなり、
    // 復旧後の処理が大幅に遅延するため。
    const base = 1000 * 2 ** attempts;
    return Math.min(base, 5 * 60 * 1000);
  }

  // size を返す
  size(): number {
    // jobs の長さを返す
    return this.jobs.length;
  }
}
