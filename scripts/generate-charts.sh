#!/usr/bin/env bash
# posts/<カテゴリ>/<slug>/charts/*.json を読み、useful-api を呼び出して
# 同名の .svg を生成する。CIから呼ばれる想定。
set -euo pipefail

API_BASE="https://ycdi9tb8p9.execute-api.ap-northeast-1.amazonaws.com/prod"
API_KEY="${USEFUL_API_KEY:?USEFUL_API_KEY is not set}"

shopt -s nullglob globstar

for json_file in posts/**/charts/*.json; do
  endpoint=$(jq -r '.endpoint' "$json_file")
  svg_file="${json_file%.json}.svg"

  echo "Generating $svg_file (endpoint: $endpoint) from $json_file"

  http_status=$(jq -c '.body' "$json_file" | curl -sS -X POST "$API_BASE/$endpoint" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $API_KEY" \
    -d @- \
    -o "$svg_file" \
    -w "%{http_code}")

  if [ "$http_status" != "200" ]; then
    echo "::error file=$json_file::useful-api request failed with status $http_status"
    cat "$svg_file"
    exit 1
  fi
done
