import { cache } from "./cache";
import { api } from "./api";

export async function getStock(sku: string): Promise<number> {
  const hit = cache.get(sku);
  if (hit !== undefined) {
    return hit;
  }

  const stock = await api.fetchStock(sku);

  // TTLは5秒と短くする。在庫数は秒単位で変動し、古い値を返すと
  // 購入確定時に在庫切れの衝突が起きてユーザー体験を損なうため。
  cache.set(sku, stock, { ttl: 5_000 });

  return stock;
}
