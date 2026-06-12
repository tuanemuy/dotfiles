type User = { id: string; name: string; active: boolean; createdAt: number };

/**
 * アクティブなユーザーだけを名前の昇順で返す。
 * 名前が同じ場合は登録順（createdAt 昇順）を保つ。画面表示の仕様で
 * 同名ユーザーの登録順維持が求められているため。
 */
export function activeUsersSorted(users: User[]): User[] {
  const active = users.filter((u) => u.active);

  active.sort((a, b) => {
    if (a.name < b.name) return -1;
    if (a.name > b.name) return 1;
    return a.createdAt - b.createdAt;
  });

  return active;
}
