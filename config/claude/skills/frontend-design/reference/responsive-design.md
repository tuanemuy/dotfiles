# レスポンシブデザイン

## モバイルファースト：正しく書く

モバイル用のベーススタイルから始め、`min-width`クエリで複雑さを重ねる。デスクトップファースト（`max-width`）はモバイルが不要なスタイルを最初にロードすることを意味します。

## ブレークポイント：コンテンツ駆動

デバイスサイズを追いかけない—コンテンツがどこで崩れるかを教えてくれます。狭い状態から始め、デザインが崩れるまで引き伸ばし、そこにブレークポイントを追加。3つのブレークポイントで通常は十分（640、768、1024px）。ブレークポイントなしの流動的な値には`clamp()`を使用。

## 画面サイズだけでなく入力方法を検出する

**画面サイズは入力方法を教えてくれません。** タッチスクリーン付きのラップトップ、キーボード付きのタブレット—ポインターとホバーのクエリを使用：

```css
/* 精密ポインター（マウス、トラックパッド） */
@media (pointer: fine) {
  .button { padding: 8px 16px; }
}

/* 粗いポインター（タッチ、スタイラス） */
@media (pointer: coarse) {
  .button { padding: 12px 20px; }  /* より大きなタッチターゲット */
}

/* デバイスがホバーをサポート */
@media (hover: hover) {
  .card:hover { transform: translateY(-2px); }
}

/* デバイスがホバーをサポートしない（タッチ） */
@media (hover: none) {
  .card { /* ホバー状態なし - 代わりにactiveを使用 */ }
}
```

**重要**: 機能をホバーに依存しない。タッチユーザーはホバーできません。

## セーフエリア：ノッチに対応する

モダンなスマートフォンにはノッチ、丸角、ホームインジケーターがあります。`env()`を使用：

```css
body {
  padding-top: env(safe-area-inset-top);
  padding-bottom: env(safe-area-inset-bottom);
  padding-left: env(safe-area-inset-left);
  padding-right: env(safe-area-inset-right);
}

/* フォールバック付き */
.footer {
  padding-bottom: max(1rem, env(safe-area-inset-bottom));
}
```

metaタグで**viewport-fitを有効化**：
```html
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
```

## レスポンシブ画像：正しく実装する

### 幅記述子付きsrcset

```html
<img
  src="hero-800.jpg"
  srcset="
    hero-400.jpg 400w,
    hero-800.jpg 800w,
    hero-1200.jpg 1200w
  "
  sizes="(max-width: 768px) 100vw, 50vw"
  alt="ヒーロー画像"
>
```

**仕組み**：
- `srcset`は利用可能な画像を実際の幅（`w`記述子）でリスト
- `sizes`は画像がどの幅で表示されるかをブラウザに伝える
- ブラウザがビューポート幅とデバイスピクセル比に基づいて最適なファイルを選択

### アートディレクション用のPicture要素

異なるクロップ/コンポジション（解像度だけでなく）が必要な場合：

```html
<picture>
  <source media="(min-width: 768px)" srcset="wide.jpg">
  <source media="(max-width: 767px)" srcset="tall.jpg">
  <img src="fallback.jpg" alt="...">
</picture>
```

## レイアウト適応パターン

**ナビゲーション**: 3段階—モバイルでハンバーガー＋ドロワー、タブレットで水平コンパクト、デスクトップでラベル付きフル。**テーブル**: `display: block`と`data-label`属性を使用してモバイルでカードに変換。**段階的開示**: モバイルで折りたためるコンテンツに`<details>/<summary>`を使用。

## テスト：DevToolsだけを信用しない

DevToolsのデバイスエミュレーションはレイアウトには有用ですが、以下を見逃す：

- 実際のタッチインタラクション
- 実際のCPU/メモリ制約
- ネットワーク遅延パターン
- フォントレンダリングの違い
- ブラウザクローム/キーボードの表示

**少なくとも以下でテスト**: 1台の実際のiPhone、1台の実際のAndroid、関連する場合はタブレット。安いAndroidスマートフォンはシミュレーターでは見えないパフォーマンス問題を明らかにします。

---

**避けるべきこと**: デスクトップファーストデザイン。機能検出ではなくデバイス検出。モバイル/デスクトップ別のコードベース。タブレットと横向きの無視。すべてのモバイルデバイスが高性能と仮定すること。

---
