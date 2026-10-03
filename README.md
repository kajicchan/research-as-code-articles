# research-as-code-articles

[research-as-code](https://d31ms51gntaaqd.cloudfront.net/) サイトの記事本文（Markdown）を管理するリポジトリ。
（独自ドメイン設定後はそちらのURLに差し替え予定）

## 記事の書き方

1. `posts/_template.md` をコピーして `posts/<カテゴリ名>/<slug>.md` を作る（カテゴリのディレクトリが無ければ新規作成する。`<slug>` はURLになるので英数字とハイフンのみ）
2. フロントマターを埋める（`title` と `excerpt` は本文側に書くので含めない。`category` もディレクトリ名がそのままカテゴリになるので含めない）

```yaml
---
tags: ["タグ1", "タグ2"]
publishedAt: "2026-01-01"
---
```

3. 本文は次の順番で書く
   1. `# タイトル`（記事タイトル）
   2. `## 更新履歴`（作成時と編集のたびに「編集者・日時」の行を追加する表）
   3. `## 要約`（一覧カードや検索結果に表示される1〜2文）
   4. それ以降は自由記述

## ディレクトリ構成

```
posts/
  _template.md              # 新規記事のテンプレート（先頭 _ はビルド時に記事として扱わない）
  <カテゴリ名>/
    <slug>.md                # 記事本体。ディレクトリ名がカテゴリ、ファイル名がそのままURLのslugになる
    <slug>/charts/
      <name>.json             # 表・グラフのリクエスト定義（下記参照）
      <name>.svg               # pushを検知して自動生成されるSVG（手で編集しない）
```

カテゴリ名はディレクトリ名がそのまま表示名になる（例: `posts/スポーツ科学/`）。
slug はカテゴリをまたいで一意にする（同じ slug のファイルが別カテゴリに存在しないこと）。

## 表・グラフの埋め込み（useful-api連携）

数値データを表やグラフのSVGにしたい場合、[useful-api](https://github.com/kajicchan/useful-api) を使う。

1. `posts/<カテゴリ名>/<slug>/charts/<name>.json` に、呼び出すエンドポイントとリクエストボディを書く

```json
{
  "endpoint": "table",
  "body": { "title": "...", "rows": [["...", 1]] }
}
```

`endpoint` は `table` / `chart/bar` / `chart/line` のいずれか（useful-apiのパスと一致させる）。

2. mainにpushすると、GitHub Actions（`generate-charts.yml`）が `charts/` 配下の `.json` を見つけてuseful-apiを呼び出し、同名の `.svg` を生成してコミットし直す
3. 生成された `.svg` の中身をコピーして、記事のMarkdown本文に貼り付ける（自動では埋め込まれない）。埋め込むときは、1行の`<svg>...</svg>`ではなく複数行のまま貼ること（1行だと段落`<p>`に巻き込まれてレイアウトが崩れる）

この仕組みはAPIキーをGitHub Actionsのsecret（`USEFUL_API_KEY`）として登録しておく必要がある。
