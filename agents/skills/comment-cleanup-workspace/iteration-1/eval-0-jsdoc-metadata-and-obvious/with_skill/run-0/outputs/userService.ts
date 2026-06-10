import { db } from "./db";
import { hash } from "./crypto";

/**
 * ユーザーを作成する。
 * @param input ユーザー入力
 * @param input.email メールアドレス
 * @param input.password パスワード（平文）
 * @returns 作成されたユーザーのID
 */
export async function createUser(input: { email: string; password: string }) {
  const existing = await db.users.findByEmail(input.email);
  if (existing) {
    throw new Error("email already exists");
  }

  const passwordHash = await hash(input.password);

  const user = await db.users.insert({
    email: input.email,
    passwordHash,
  });

  return user.id;
}

export async function deactivateAll(ids: string[]) {
  for (let i = 0; i < ids.length; i++) {
    await db.users.update(ids[i], { active: false });
  }
}
