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

![種目別 重量(例)](https://raw.githubusercontent.com/kajicchan/research-as-code-articles/main/posts/%E9%96%8B%E7%99%BA/svg-table-chart-api/charts/table-example.svg)

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

![週間走行距離(例)](https://raw.githubusercontent.com/kajicchan/research-as-code-articles/main/posts/%E9%96%8B%E7%99%BA/svg-table-chart-api/charts/line-example.svg)

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
