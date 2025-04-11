#!/usr/bin/env bash

set -euo pipefail

docker run \
  --rm \
  -it \
  -v "$(pwd):/tmp/lint" \
  -w "/tmp/lint" \
  -e VALIDATE_ALL_CODEBASE=true \
  -e REPORT_OUTPUT_FOLDER=none \
  -e DISABLE_ERRORS=true \
  -e PRINT_ALPACA=false \
  -e PLUGINS="[\"file://mega-linter-plugin-fmlint/fmlint.megalinter-descriptor.yml\"]" \
  -e ENABLE_LINTERS="[\"MARKDOWN_FMLINT\"]" \
  -e MEGALINTER_FILES_TO_LINT="[\"test/good.md\",\"test/bad.md\"]" \
  docker.io/oxsecurity/megalinter-ci_light:latest
