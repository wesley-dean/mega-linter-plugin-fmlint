#!/usr/bin/env bash
# shellcheck shell=bash
## @file tests/validate.bash
## @brief Validates an fmlint plugin descriptor against MegaLinter's pinned schema.
## @details
## Uses the same pinned MegaLinter image as integration testing so descriptor
## validation does not depend on a separately installed v8r executable.  The
## descriptor path may be supplied as the first argument; otherwise the maintained
## development descriptor is validated.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## v8r writes its ordinary validation report to STDOUT.
## @par STDERR
## Docker and v8r diagnostics may be written to STDERR.
##
## @returns v8r's descriptor-validation output.
## @retval 0 The descriptor satisfies the pinned MegaLinter schema.
## @note Non-zero Docker or v8r exit statuses are propagated unchanged.

set -euo pipefail

readonly MEGALINTER_IMAGE="${MEGALINTER_IMAGE:-ghcr.io/oxsecurity/megalinter-ci_light:v10.1.0}"
readonly V8R_SCHEMA_URL="${V8R_SCHEMA_URL:-https://raw.githubusercontent.com/oxsecurity/megalinter/v10.1.0/megalinter/descriptors/schemas/megalinter-descriptor.jsonschema.json}"
readonly DESCRIPTOR_PATH="${1:-mega-linter-plugin-fmlint/fmlint.megalinter-descriptor.yml}"

docker run \
  --rm \
  --entrypoint v8r \
  -v "${PWD}:/tmp/lint" \
  -w /tmp/lint \
  "${MEGALINTER_IMAGE}" \
  --schema "${V8R_SCHEMA_URL}" \
  "${DESCRIPTOR_PATH}"
