---
tags: ["Rust", "AWS", "API", "自己開発"]
publishedAt: "2026-10-03"
---

# 数値データをSVGの表・グラフに変換するAPIを作った

## 更新履歴

| 編集者 | 日時 |
|---|---|
| 運営者 | 2026-10-03 |

## 要約

筋トレとランニングの記録を記事として投稿したいと思ったのがきっかけで、JSON/YAMLの数値データをSVGの表やグラフに変換するAPI「useful-api」を作りました。AWS Lambda(Rust)+ API Gateway + AWS CDKで構成しています。

## きっかけ

このサイトは「記事をコーディングして投稿する」という思想のもと、記事本文をMarkdownで書き、ビルドと配信もコードで管理しています。

自分は普段から筋トレとランニングをしていて、その目標や日々のトレーニング内容を記事として投稿したいと考えていました。ただ、重量の推移やランニングの距離・ペースといった数値データは、文章や表だけで伝えるより、グラフにした方が分かりやすくなります。

このサイトは完全に静的なサイトで、記事はビルド時にMarkdownからHTMLに変換されるだけです。フロントエンドにグラフ描画ライブラリを持たせることもできますが、それよりも「データを渡せばSVGが返ってくるAPI」を用意して、生成したSVGをそのままMarkdownに貼り付けられるようにした方が、このサイトの作り方(記事もインフラもコードで管理する)に合っていると考えました。

## 作ったもの: useful-api

JSON/YAMLで数値データを渡すと、SVGの表やグラフに変換して返すAPIです。

| エンドポイント | 内容 |
|---|---|
| `POST /table` | 数値データをSVGの表に変換 |
| `POST /chart/bar` | 数値データをSVGの棒グラフに変換 |
| `POST /chart/line` | 数値データをSVGの折れ線グラフに変換 |

## 技術構成

| レイヤー | 技術 | 役割 |
|---|---|---|
| 実行環境 | AWS Lambda(Rust, arm64) | 機能(エンドポイント)ごとに1関数 |
| API | API Gateway(REST API) | API Key + Usage Planで認証・レート制限 |
| グラフ描画 | plotters | 棒グラフ・折れ線グラフの描画 |
| インフラ管理 | AWS CDK(TypeScript) | Lambda用スタックとAPI Gateway用スタックに分離 |
| CI | GitHub Actions | fmt / clippy / test / CDKの型チェック・synthを自動実行 |

Lambda関数の中は「core(業務ロジック、HTTP非依存)→ adapter(HTTPとcoreをつなぐ)→ app(エントリーポイント)」という3層に分けていて、coreはLambdaの型を一切知らないため、実際のリクエストを飛ばさずにユニットテストだけでロジックを検証できるようにしています。

## 実際に生成したSVG

実際にデプロイ済みのAPIを呼び出して生成したSVGです(このページにそのまま埋め込んでいます)。

表(`POST /table`)。送ったリクエストはこちら。

```json
{
  "title": "種目別 重量(例)",
  "headers": ["種目", "重量(kg)"],
  "rows": [
    ["スクワット", 100],
    ["ベンチプレス", 70],
    ["デッドリフト", 120]
  ],
  "width": 500,
  "height": 260
}
```

返ってきたSVGをそのまま埋め込むとこうなります。

<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 260" width="500" height="260" font-family="sans-serif" font-size="14"><rect x="0" y="0" width="500" height="260" fill="#ffffff"/><text x="250" y="20.666666666666668" text-anchor="middle" font-weight="bold" fill="#111111">種目別 重量(例)</text><rect x="0" y="32" width="500" height="28" fill="#f0f0f0"/><text x="6" y="50.666666666666664" font-weight="bold" fill="#111111">種目</text><text x="256" y="50.666666666666664" font-weight="bold" fill="#111111">重量(kg)</text><text x="6" y="98.00000000000001" text-anchor="start" fill="#111111">スクワット</text><text x="494" y="98.00000000000001" text-anchor="end" fill="#111111">100</text><text x="6" y="164.66666666666666" text-anchor="start" fill="#111111">ベンチプレス</text><text x="494" y="164.66666666666666" text-anchor="end" fill="#111111">70</text><text x="6" y="231.33333333333334" text-anchor="start" fill="#111111">デッドリフト</text><text x="494" y="231.33333333333334" text-anchor="end" fill="#111111">120</text><rect x="0" y="32" width="500" height="228" fill="none" stroke="#333333"/><line x1="0" y1="60" x2="500" y2="60" stroke="#cccccc"/><line x1="0" y1="126.66666666666667" x2="500" y2="126.66666666666667" stroke="#cccccc"/><line x1="0" y1="193.33333333333334" x2="500" y2="193.33333333333334" stroke="#cccccc"/><line x1="0" y1="260" x2="500" y2="260" stroke="#cccccc"/><line x1="0" y1="32" x2="500" y2="32" stroke="#333333"/><line x1="0" y1="32" x2="0" y2="260" stroke="#cccccc"/><line x1="250" y1="32" x2="250" y2="260" stroke="#cccccc"/><line x1="500" y1="32" x2="500" y2="260" stroke="#cccccc"/></svg>

折れ線グラフ(`POST /chart/line`)。送ったリクエストはこちら。

```json
{
  "title": "週間走行距離(例)",
  "xLabel": "週",
  "yLabel": "距離(km)",
  "data": [
    { "label": "1週目", "value": 10 },
    { "label": "2週目", "value": 15 },
    { "label": "3週目", "value": 12 },
    { "label": "4週目", "value": 20 }
  ],
  "width": 500,
  "height": 260
}
```

返ってきたSVGをそのまま埋め込むとこうなります。

<svg width="500" height="260" viewBox="0 0 500 260" xmlns="http://www.w3.org/2000/svg">
<rect x="0" y="0" width="500" height="260" opacity="1" fill="#FFFFFF" stroke="none"/>
<text x="250" y="15" dy="0.76em" text-anchor="middle" font-family="sans-serif" font-size="16.129032258064516" opacity="1" fill="#000000">
週間走行距離(例)
</text>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="194" x2="489" y2="194"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="191" x2="489" y2="191"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="187" x2="489" y2="187"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="184" x2="489" y2="184"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="180" x2="489" y2="180"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="177" x2="489" y2="177"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="173" x2="489" y2="173"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="169" x2="489" y2="169"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="166" x2="489" y2="166"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="162" x2="489" y2="162"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="159" x2="489" y2="159"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="155" x2="489" y2="155"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="151" x2="489" y2="151"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="148" x2="489" y2="148"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="144" x2="489" y2="144"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="141" x2="489" y2="141"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="137" x2="489" y2="137"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="133" x2="489" y2="133"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="130" x2="489" y2="130"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="126" x2="489" y2="126"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="123" x2="489" y2="123"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="119" x2="489" y2="119"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="115" x2="489" y2="115"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="112" x2="489" y2="112"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="108" x2="489" y2="108"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="105" x2="489" y2="105"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="101" x2="489" y2="101"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="98" x2="489" y2="98"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="94" x2="489" y2="94"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="90" x2="489" y2="90"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="87" x2="489" y2="87"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="83" x2="489" y2="83"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="80" x2="489" y2="80"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="76" x2="489" y2="76"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="72" x2="489" y2="72"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="69" x2="489" y2="69"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="65" x2="489" y2="65"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="62" x2="489" y2="62"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="58" x2="489" y2="58"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="54" x2="489" y2="54"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="51" x2="489" y2="51"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="47" x2="489" y2="47"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="44" x2="489" y2="44"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="40" x2="489" y2="40"/>
<line opacity="0.1" stroke="#000000" stroke-width="1" x1="65" y1="36" x2="489" y2="36"/>
<text x="10" y="115" dy="0.76em" text-anchor="middle" font-family="sans-serif" font-size="10.483870967741936" opacity="1" fill="#000000" font-weight="bold" transform="rotate(270, 10, 115)">
距離(km)
</text>
<line opacity="0.2" stroke="#000000" stroke-width="1" x1="65" y1="194" x2="489" y2="194"/>
<line opacity="0.2" stroke="#000000" stroke-width="1" x1="65" y1="159" x2="489" y2="159"/>
<line opacity="0.2" stroke="#000000" stroke-width="1" x1="65" y1="123" x2="489" y2="123"/>
<line opacity="0.2" stroke="#000000" stroke-width="1" x1="65" y1="87" x2="489" y2="87"/>
<line opacity="0.2" stroke="#000000" stroke-width="1" x1="65" y1="51" x2="489" y2="51"/>
<polyline fill="none" opacity="1" stroke="#000000" stroke-width="1" points="64,36 64,194 "/>
<text x="55" y="194" dy="0.5ex" text-anchor="end" font-family="sans-serif" font-size="9.67741935483871" opacity="1" fill="#000000">
0.0
</text>
<polyline fill="none" opacity="1" stroke="#000000" stroke-width="1" points="59,194 64,194 "/>
<text x="55" y="159" dy="0.5ex" text-anchor="end" font-family="sans-serif" font-size="9.67741935483871" opacity="1" fill="#000000">
5.0
</text>
<polyline fill="none" opacity="1" stroke="#000000" stroke-width="1" points="59,159 64,159 "/>
<text x="55" y="123" dy="0.5ex" text-anchor="end" font-family="sans-serif" font-size="9.67741935483871" opacity="1" fill="#000000">
10.0
</text>
<polyline fill="none" opacity="1" stroke="#000000" stroke-width="1" points="59,123 64,123 "/>
<text x="55" y="87" dy="0.5ex" text-anchor="end" font-family="sans-serif" font-size="9.67741935483871" opacity="1" fill="#000000">
15.0
</text>
<polyline fill="none" opacity="1" stroke="#000000" stroke-width="1" points="59,87 64,87 "/>
<text x="55" y="51" dy="0.5ex" text-anchor="end" font-family="sans-serif" font-size="9.67741935483871" opacity="1" fill="#000000">
20.0
</text>
<polyline fill="none" opacity="1" stroke="#000000" stroke-width="1" points="59,51 64,51 "/>
<polyline fill="none" opacity="1" stroke="#000000" stroke-width="1" points="65,195 490,195 "/>
<polyline fill="none" opacity="1" stroke="#000000" stroke-width="1" points="118,195 118,200 "/>
<text x="118" y="202" dy="0.76em" text-anchor="middle" font-family="sans-serif" font-size="9.67741935483871" opacity="1" fill="#000000">
1週目
</text>
<polyline fill="none" opacity="1" stroke="#000000" stroke-width="1" points="224,195 224,200 "/>
<text x="224" y="202" dy="0.76em" text-anchor="middle" font-family="sans-serif" font-size="9.67741935483871" opacity="1" fill="#000000">
2週目
</text>
<polyline fill="none" opacity="1" stroke="#000000" stroke-width="1" points="330,195 330,200 "/>
<text x="330" y="202" dy="0.76em" text-anchor="middle" font-family="sans-serif" font-size="9.67741935483871" opacity="1" fill="#000000">
3週目
</text>
<polyline fill="none" opacity="1" stroke="#000000" stroke-width="1" points="436,195 436,200 "/>
<text x="436" y="202" dy="0.76em" text-anchor="middle" font-family="sans-serif" font-size="9.67741935483871" opacity="1" fill="#000000">
4週目
</text>
<text x="277" y="219" dy="0.76em" text-anchor="middle" font-family="sans-serif" font-size="10.483870967741936" opacity="1" fill="#000000" font-weight="bold">
週
</text>
<polyline fill="none" opacity="1" stroke="#0000FF" stroke-width="1" points="118,123 224,87 330,108 436,51 "/>
<circle cx="118" cy="123" r="3" opacity="1" fill="#0000FF" stroke="none" stroke-width="1"/>
<circle cx="224" cy="87" r="3" opacity="1" fill="#0000FF" stroke="none" stroke-width="1"/>
<circle cx="330" cy="108" r="3" opacity="1" fill="#0000FF" stroke="none" stroke-width="1"/>
<circle cx="436" cy="51" r="3" opacity="1" fill="#0000FF" stroke="none" stroke-width="1"/>
</svg>

どちらも数値は例として適当に入れたものですが、実際にAPIへリクエストを送って返ってきたSVGをそのまま貼り付けています。

## 試してみる

このAPIは公開していて、以下のエンドポイントとAPIキーでそのまま試せます。

```
POST https://ycdi9tb8p9.execute-api.ap-northeast-1.amazonaws.com/prod/table
POST https://ycdi9tb8p9.execute-api.ap-northeast-1.amazonaws.com/prod/chart/bar
POST https://ycdi9tb8p9.execute-api.ap-northeast-1.amazonaws.com/prod/chart/line
```

```bash
curl -X POST "https://ycdi9tb8p9.execute-api.ap-northeast-1.amazonaws.com/prod/chart/line" \
  -H "Content-Type: application/json" \
  -H "x-api-key: 606636d2-245d-43d2-888a-1b1f4b75a69d" \
  -d '{
    "title": "週間走行距離(例)",
    "xLabel": "週",
    "yLabel": "距離(km)",
    "data": [
      { "label": "1週目", "value": 10 },
      { "label": "2週目", "value": 15 }
    ]
  }'
```

レート制限(5リクエスト/秒、バースト10)をかけているので、負荷をかけるような使い方はご遠慮ください。

## これから

次は、このAPIを使って実際の筋トレ・ランニングの記録を記事にしていく予定です。重量の推移やランニングのペースを、手作業でグラフを作ることなく、数値データを渡すだけで記事に埋め込めるようになりました。
