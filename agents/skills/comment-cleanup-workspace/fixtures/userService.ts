import { db } from "./db";
import { hash } from "./crypto";

/**
 * ユーザーを作成する。
 * 2024/02/10 tanaka が作成。
 * 2024/03/01 sato がメール重複チェックを追加（バグ #1234 対応）。
 * 最初はパスワードを平文で保存していたが、後でハッシュ化に変更した。
 * @param input ユーザー入力
 * @param input.email メールアドレス
 * @param input.password パスワード（平文）
 * @returns 作成されたユーザーのID
 */
export async function createUser(input: { email: string; password: string }) {
  // メールアドレスで既存ユーザーを検索する
  const existing = await db.users.findByEmail(input.email);
  if (existing) {
    // 既に存在する場合はエラーを投げる
    throw new Error("email already exists");
  }

  // パスワードをハッシュ化する
  // bcrypt から argon2 に変えた（2024/04, レビュー指摘）
  const passwordHash = await hash(input.password);

  // ユーザーをDBに挿入する
  const user = await db.users.insert({
    email: input.email,
    passwordHash,
  });

  // const oldId = user.legacyId; // 旧IDは使わなくなったのでコメントアウト
  // return oldId;

  return user.id;
}

// i をループで回してユーザーを1件ずつ処理する
export async function deactivateAll(ids: string[]) {
  for (let i = 0; i < ids.length; i++) {
    // i 番目のユーザーを無効化
    await db.users.update(ids[i], { active: false });
  }
}
