type User = { id: string; name: string; active: boolean; createdAt: number };

/**
 * アクティブなユーザーだけを名前の昇順で返す。
 * 名前が同じ場合は登録順を保持する（画面表示の仕様で安定ソートが求められるため）。
 */
export function activeUsersSorted(users: User[]): User[] {
  const active = users.filter((u) => u.active);

  active.sort((a, b) => {
    if (a.name < b.name) return -1;
    if (a.name > b.name) return 1;
    // 名前が同じなら登録順（createdAt 昇順）を保つ
    return a.createdAt - b.createdAt;
  });

  return active;
}
