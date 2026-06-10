/**
 * ソート済み配列から target を二分探索する。
 * 配列は呼び出し側で昇順ソート済みであることが前提（この関数は検証しない）。
 * 等しい要素が複数ある場合、どのインデックスが返るかは規定しない。
 * @returns 見つかればインデックス、なければ -1
 */
export function bsearch(arr: number[], target: number): number {
  let lo = 0;
  let hi = arr.length - 1;

  while (lo <= hi) {
    // (lo + hi) / 2 だと lo+hi が境界付近でオーバーフローしうるため、この式で中点を取る
    const mid = lo + ((hi - lo) >> 1);

    if (arr[mid] === target) return mid;
    if (arr[mid] < target) {
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }

  return -1;
}
