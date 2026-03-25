---
name: optimize
description: 読み込み速度、レンダリング、アニメーション、画像、バンドルサイズにわたってインターフェースパフォーマンスを改善。体験をより速く、よりスムーズにします。
user-invokable: true
args:
  - name: target
    description: 最適化する機能やエリア（任意）
    required: false
---

パフォーマンスの問題を特定・修正し、より速く、よりスムーズなユーザー体験を作り出します。

## パフォーマンス問題の評価

現在のパフォーマンスを理解し、問題を特定する：

1. **現状を測定する**：
   - **Core Web Vitals**: LCP、FID/INP、CLSスコア
   - **読み込み時間**: インタラクティブになるまでの時間、最初のコンテンツ描画
   - **バンドルサイズ**: JavaScript、CSS、画像サイズ
   - **ランタイムパフォーマンス**: フレームレート、メモリ使用量、CPU使用量
   - **ネットワーク**: リクエスト数、ペイロードサイズ、ウォーターフォール

2. **ボトルネックを特定する**：
   - 何が遅いか？（初期読み込み？インタラクション？アニメーション？）
   - 原因は何か？（大きな画像？重いJavaScript？レイアウトスラッシング？）
   - どれくらい悪いか？（知覚可能？煩わしい？ブロッキング？）
   - 誰が影響を受けるか？（全ユーザー？モバイルのみ？低速接続？）

**重要**: 前後で測定してください。早すぎる最適化は時間の無駄です。本当に重要なことを最適化してください。

## 最適化戦略

体系的な改善計画を作成する：

### 読み込みパフォーマンス

**画像の最適化**：
- モダンフォーマット（WebP、AVIF）を使用
- 適切なサイジング（300px表示に3000pxの画像をロードしない）
- フォールド下画像の遅延読み込み
- レスポンシブ画像（`srcset`、`picture`要素）
- 画像圧縮（80-85%品質は通常知覚されない）
- 高速配信のためCDNを使用

```html
<img
  src="hero.webp"
  srcset="hero-400.webp 400w, hero-800.webp 800w, hero-1200.webp 1200w"
  sizes="(max-width: 400px) 400px, (max-width: 800px) 800px, 1200px"
  loading="lazy"
  alt="ヒーロー画像"
/>
```

**JavaScriptバンドルの削減**：
- コードスプリッティング（ルートベース、コンポーネントベース）
- ツリーシェイキング（未使用コードの削除）
- 未使用の依存関係を削除
- 重要でないコードの遅延読み込み
- 大きなコンポーネントにダイナミックインポートを使用

```javascript
// 重いコンポーネントの遅延読み込み
const HeavyChart = lazy(() => import('./HeavyChart'));
```

**CSSの最適化**：
- 未使用CSSの削除
- クリティカルCSSのインライン化、残りは非同期
- CSSファイルの最小化
- 独立した領域にCSS containmentを使用

**フォントの最適化**：
- `font-display: swap`または`optional`を使用
- フォントのサブセット化（必要な文字のみ）
- クリティカルフォントのプリロード
- 適切な場合はシステムフォントを使用
- ロードするフォントウェイトを制限

```css
@font-face {
  font-family: 'CustomFont';
  src: url('/fonts/custom.woff2') format('woff2');
  font-display: swap; /* すぐにフォールバックを表示 */
  unicode-range: U+0020-007F; /* 基本ラテンのみ */
}
```

**読み込み戦略の最適化**：
- クリティカルリソースを最初に（非クリティカルはasync/defer）
- クリティカルアセットのプリロード
- 次のページのプリフェッチ
- オフライン/キャッシング用のService Worker
- 多重化のためのHTTP/2またはHTTP/3

### レンダリングパフォーマンス

**レイアウトスラッシングの回避**：
```javascript
// ❌ 悪い例: 読み書きの交互（リフローを引き起こす）
elements.forEach(el => {
  const height = el.offsetHeight; // 読み取り（レイアウトを強制）
  el.style.height = height * 2; // 書き込み
});

// ✅ 良い例: 読み取りをまとめ、書き込みをまとめる
const heights = elements.map(el => el.offsetHeight); // すべての読み取り
elements.forEach((el, i) => {
  el.style.height = heights[i] * 2; // すべての書き込み
});
```

**レンダリングの最適化**：
- 独立した領域にCSS `contain`プロパティを使用
- DOMの深さを最小化（フラットな方が速い）
- DOMサイズを削減（要素を少なく）
- 長いリストに`content-visibility: auto`を使用
- 非常に長いリストに仮想スクロール（react-window、react-virtualized）

**ペイントとコンポジットの削減**：
- アニメーションには`transform`と`opacity`を使用（GPU加速）
- レイアウトプロパティ（width、height、top、left）のアニメーションを避ける
- 既知の高コスト操作に`will-change`を控えめに使用
- ペイント領域を最小化（小さい方が速い）

### アニメーションパフォーマンス

**GPU加速**：
```css
/* ✅ GPU加速（高速） */
.animated {
  transform: translateX(100px);
  opacity: 0.5;
}

/* ❌ CPUバウンド（低速） */
.animated {
  left: 100px;
  width: 300px;
}
```

**スムーズな60fps**：
- フレームあたり16ms目標（60fps）
- JSアニメーションに`requestAnimationFrame`を使用
- スクロールハンドラーのデバウンス/スロットル
- 可能な場合はCSSアニメーションを使用
- アニメーション中に長時間実行されるJavaScriptを避ける

**Intersection Observer**：
```javascript
// 要素がビューポートに入ったことを効率的に検出
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      // 要素が表示された、遅延読み込みまたはアニメーション
    }
  });
});
```

### React/フレームワーク最適化

**React固有**：
- 高コストなコンポーネントに`memo()`を使用
- 高コストな計算に`useMemo()`と`useCallback()`
- 長いリストの仮想化
- ルートのコードスプリット
- レンダー内でのインライン関数生成を避ける
- React DevTools Profilerを使用

**フレームワーク非依存**：
- 再レンダリングを最小化
- 高コストな操作のデバウンス
- 計算値のメモ化
- ルートとコンポーネントの遅延読み込み

### ネットワーク最適化

**リクエストの削減**：
- 小さなファイルの結合
- アイコンにSVGスプライトを使用
- 小さなクリティカルアセットのインライン化
- 未使用のサードパーティスクリプトの削除

**APIの最適化**：
- ページネーションの使用（すべてをロードしない）
- 必要なフィールドのみリクエストするGraphQL
- レスポンス圧縮（gzip、brotli）
- HTTPキャッシュヘッダー
- 静的アセットのCDN

**低速接続向けの最適化**：
- 接続に基づくアダプティブローディング（navigator.connection）
- 楽観的UIの更新
- リクエストの優先順位付け
- プログレッシブエンハンスメント

## Core Web Vitalsの最適化

### Largest Contentful Paint（LCP < 2.5s）
- ヒーロー画像の最適化
- クリティカルCSSのインライン化
- キーリソースのプリロード
- CDNの使用
- サーバーサイドレンダリング

### First Input Delay（FID < 100ms）/ INP（< 200ms）
- 長いタスクの分割
- 非クリティカルなJavaScriptの遅延
- 重い計算にWeb Workerを使用
- JavaScript実行時間の削減

### Cumulative Layout Shift（CLS < 0.1）
- 画像と動画にディメンションを設定
- 既存コンテンツの上にコンテンツを挿入しない
- CSS `aspect-ratio`プロパティの使用
- 広告/埋め込みのスペースを予約
- レイアウトシフトを引き起こすアニメーションを避ける

```css
/* 画像のスペースを予約 */
.image-container {
  aspect-ratio: 16 / 9;
}
```

## パフォーマンスモニタリング

**使用するツール**：
- Chrome DevTools（Lighthouse、パフォーマンスパネル）
- WebPageTest
- Core Web Vitals（Chrome UXレポート）
- バンドルアナライザー（webpack-bundle-analyzer）
- パフォーマンスモニタリング（Sentry、DataDog、New Relic）

**主要メトリクス**：
- LCP、FID/INP、CLS（Core Web Vitals）
- Time to Interactive（TTI）
- First Contentful Paint（FCP）
- Total Blocking Time（TBT）
- バンドルサイズ
- リクエスト数

**重要**: 実際のデバイスで実際のネットワーク条件で測定してください。高速接続のデスクトップChromeは代表的ではありません。

**絶対にしてはいけないこと**：
- 測定せずに最適化する（早すぎる最適化）
- パフォーマンスのためにアクセシビリティを犠牲にする
- 最適化中に機能を壊す
- どこでも`will-change`を使用する（新しいレイヤーを作成し、メモリを使用する）
- フォールド上のコンテンツを遅延読み込みする
- 主要な問題を無視してマイクロ最適化を行う（最大のボトルネックを最初に最適化する）
- モバイルパフォーマンスを忘れる（しばしばより遅いデバイス、より遅い接続）

## 改善の検証

最適化が効果があったことをテストする：

- **前後のメトリクス**: Lighthouseスコアを比較
- **リアルユーザーモニタリング**: 実際のユーザーでの改善を追跡
- **異なるデバイス**: フラッグシップiPhoneだけでなく、ローエンドAndroidでテスト
- **低速接続**: 3Gにスロットルし、体験をテスト
- **リグレッションなし**: 機能が引き続き動作することを確認
- **ユーザーの知覚**: *速く感じる*か？

覚えておいてください：パフォーマンスは機能です。速い体験はよりレスポンシブに、より洗練されて、よりプロフェッショナルに感じます。体系的に最適化し、容赦なく測定し、ユーザーが知覚するパフォーマンスを優先してください。
