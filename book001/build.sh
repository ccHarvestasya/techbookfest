#!/usr/bin/env bash
set -euo pipefail

MARGIN=${MARGIN:-20mm}

pandoc book.md \
  -s \
  -f markdown+raw_tex \
  --metadata-file=metadata.yaml \
  --template=template.tex \
  --include-before-body=cover.tex \
  --include-after-body=colophon.tex \
  --toc \
  --number-sections \
  --no-highlight \
  --pdf-engine=lualatex \
  -V margin=$MARGIN \
  -o book.pdf
