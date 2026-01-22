#!/usr/bin/env bash
set -euo pipefail

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
  -V papersize=b5 \
  -V geometry:margin=20mm \
  -o book.pdf
