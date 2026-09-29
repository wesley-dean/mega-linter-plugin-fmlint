#!/usr/bin/env bash
# shellcheck shell=bash
## @file tests/validate.bash
## @brief Validates the plugin descriptor against MegaLinter's pinned schema.
## @details
## Uses the same pinned MegaLinter image as integration testing so descriptor
## validation does not depend on a separately installed v8r executable.

set -euo pipefail

readonly MEGALINTER_IMAGE="${MEGALINTER_IMAGE:-ghcr.io/oxsecurity/megalinter-ci_light:v10.1.0}"
readonly V8R_SCHEMA_URL="${V8R_SCHEMA_URL:-https://raw.githubusercontent.com/oxsecurity/megalinter/v10.1.0/megalinter/descriptors/schemas/megalinter-descriptor.jsonschema.json}"

docker run \
  --rm \
  --entrypoint v8r \
  -v "${PWD}:/tmp/lint" \
  -w /tmp/lint \
  "${MEGALINTER_IMAGE}" \
  --schema "${V8R_SCHEMA_URL}" \
  mega-linter-plugin-fmlint/fmlint.megalinter-descriptor.yml
