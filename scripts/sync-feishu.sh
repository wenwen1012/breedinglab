#!/usr/bin/env bash
set -Eeuo pipefail

: "${FEISHU_APP_ID:?Missing FEISHU_APP_ID secret}"
: "${FEISHU_APP_SECRET:?Missing FEISHU_APP_SECRET secret}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# The sync manifest is deliberately limited to one document for this MVP.
readarray -t DOC_FIELDS < <(python3 - <<'PY'
import yaml
with open("sync/docs.yaml", "r", encoding="utf-8") as f:
    config = yaml.safe_load(f) or {}
docs = config.get("docs", [])
if len(docs) != 1:
    raise SystemExit(f"MVP expects exactly one document; found {len(docs)}")
doc = docs[0]
url = str(doc["feishu_url"]).strip()
target = str(doc["target"]).strip()
weight = int(doc.get("weight", 10))
if not url.startswith("https://") or ".feishu.cn/" not in url:
    raise SystemExit("feishu_url must be an HTTPS Feishu URL")
if not target.startswith("content/docs/") or ".." in target.split("/"):
    raise SystemExit("target must stay inside content/docs/")
print(url)
print(target)
print(weight)
PY
)

DOC_URL="${DOC_FIELDS[0]}"
TARGET="${DOC_FIELDS[1]}"
WEIGHT="${DOC_FIELDS[2]}"
TARGET_DIR="$(dirname "$TARGET")"
mkdir -p "$TARGET_DIR"

# feishu2md stores credentials in its normal config file. Use a temporary HOME
# so credentials exist only for this GitHub Actions job.
export HOME="${RUNNER_TEMP:-/tmp}/feishu2md-home"
mkdir -p "$HOME"
feishu2md config --appId "$FEISHU_APP_ID" --appSecret "$FEISHU_APP_SECRET"

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "Downloading the configured Feishu document..."
feishu2md dl --output "$TMP_DIR" "$DOC_URL"

MD_FILE="$(find "$TMP_DIR" -type f -name '*.md' -print -quit)"
if [[ -z "${MD_FILE:-}" ]]; then
  echo "::error::feishu2md completed but no Markdown file was produced."
  exit 1
fi

# Copy all downloaded resources alongside the Markdown so relative image/file
# links emitted by feishu2md remain available.
cp -a "$TMP_DIR/." "$TARGET_DIR/"
DOWNLOADED_NAME="$(basename "$MD_FILE")"
DOWNLOADED_TARGET="$TARGET_DIR/$DOWNLOADED_NAME"
if [[ ! -f "$DOWNLOADED_TARGET" ]]; then
  echo "::error::Downloaded Markdown file was not found after copying."
  exit 1
fi

python3 - "$DOWNLOADED_TARGET" "$TARGET" "$WEIGHT" <<'PY'
import json
import re
import sys
from pathlib import Path

source = Path(sys.argv[1])
target = Path(sys.argv[2])
weight = int(sys.argv[3])
body = source.read_text(encoding="utf-8")

match = re.search(r"(?m)^#\s+(.+?)\s*$", body)
title = match.group(1).strip() if match else "BreedingLab｜多源育种数据处理与智能组配"
if match:
    body = body[:match.start()] + body[match.end():]
body = body.lstrip("\n")

front_matter = (
    "---\n"
    f"title: {json.dumps(title, ensure_ascii=False)}\n"
    f"weight: {weight}\n"
    "language: zh\n"
    "---\n\n"
)
target.write_text(front_matter + body, encoding="utf-8")
if source != target:
    source.unlink()
print(f"Generated {target}")
PY

echo "Feishu document sync finished."
