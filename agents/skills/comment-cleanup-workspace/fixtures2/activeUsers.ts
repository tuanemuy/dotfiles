type User = { id: string; name: string; active: boolean; createdAt: number };

/**
 * この関数はユーザーのリストを受け取り、それぞれのユーザーについて処理を行います。
 * まずリストをループして各ユーザーのアクティブ状態を確認し、アクティブなユーザー
 * だけを残します。次に、残ったユーザーを名前で昇順に並べ替えます。並べ替えには
 * 安定ソートを使う必要があります。なぜなら、名前が同じユーザーが複数いる場合に
 * 登録された順序を保持することが画面表示の仕様で求められているためです。
 * 最後に、並べ替えたリストを呼び出し元に返します。
 */
export function activeUsersSorted(users: User[]): User[] {
  // アクティブなユーザーだけをフィルタする
  const active = users.filter((u) => u.active);

  // 名前でソートする
  active.sort((a, b) => {
    if (a.name < b.name) return -1;
    if (a.name > b.name) return 1;
    // 名前が同じなら登録順（createdAt 昇順）を保つ
    return a.createdAt - b.createdAt;
  });

  return active;
}
