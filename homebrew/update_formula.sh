#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./update_formula.sh <version> <owner> <arm64_sha256> <x64_sha256>
#
# Example:
# ./update_formula.sh 0.1.0 my-org abcdef... 123456...

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <version> <owner> <arm64_sha256> <x64_sha256>"
  exit 1
fi

VERSION="$1"
OWNER="$2"
ARM64_SHA="$3"
X64_SHA="$4"

FORMULA_FILE="$(cd "$(dirname "$0")" && pwd)/Formula/bm-cli.rb"

if [[ ! -f "$FORMULA_FILE" ]]; then
  echo "Formula not found: $FORMULA_FILE"
  exit 1
fi

sed -i.bak -E "s/version \"[^\"]+\"/version \"${VERSION}\"/" "$FORMULA_FILE"
sed -i.bak -E "s|homepage \"https://github.com/[^\"]+/bm-cli\"|homepage \"https://github.com/${OWNER}/bm-cli\"|" "$FORMULA_FILE"
sed -i.bak -E "s|https://github.com/[^\"]+/bm-cli/releases/download/v#\\{version\\}/bm-cli-darwin-arm64.tar.gz|https://github.com/${OWNER}/bm-cli/releases/download/v#{version}/bm-cli-darwin-arm64.tar.gz|" "$FORMULA_FILE"
sed -i.bak -E "s|https://github.com/[^\"]+/bm-cli/releases/download/v#\\{version\\}/bm-cli-darwin-x64.tar.gz|https://github.com/${OWNER}/bm-cli/releases/download/v#{version}/bm-cli-darwin-x64.tar.gz|" "$FORMULA_FILE"
sed -i.bak -E "0,/sha256 \".*\"/s//sha256 \"${ARM64_SHA}\"/" "$FORMULA_FILE"
sed -i.bak -E "0,/sha256 \".*\"/{//b}; /sha256 \".*\"/s//sha256 \"${X64_SHA}\"/" "$FORMULA_FILE"

rm -f "${FORMULA_FILE}.bak"
echo "Updated ${FORMULA_FILE}"
