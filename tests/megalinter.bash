#!/usr/bin/env bash
# shellcheck shell=bash
## @file tests/megalinter.bash
## @brief Exercises fmlint through a real MegaLinter plugin load.
## @details
## Runs the descriptor named by `FMLINT_DESCRIPTOR`, defaulting to the maintained
## development descriptor, and verifies both successful and failing frontmatter
## cases.  Release validation points this script at the generated descriptor so
## the exact distributed bytes and their commit-pinned runtime dependencies are
## exercised before publication.
##
## The integration test intentionally keeps MegaLinter errors enabled so a broken
## plugin cannot appear green merely because the repository configuration
## suppresses linter failures.

set -euo pipefail

readonly MEGALINTER_IMAGE="${MEGALINTER_IMAGE:-ghcr.io/oxsecurity/megalinter-ci_light:v10.1.0}"
readonly FMLINT_DESCRIPTOR="${FMLINT_DESCRIPTOR:-mega-linter-plugin-fmlint/fmlint.megalinter-descriptor.yml}"

## @fn run_megalinter()
## @brief Runs the selected plugin descriptor against a selected fixture set.
## @details
## Mounts the repository as MegaLinter input, loads the selected plugin
## descriptor, and leaves linter errors enabled so the process status reflects
## real plugin behavior.
##
## @param files_json JSON array accepted by MEGALINTER_FILES_TO_LINT.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## MegaLinter writes its ordinary console report to STDOUT.
## @par STDERR
## MegaLinter and Docker diagnostics may be written to STDERR.
##
## @returns MegaLinter's console report.
## @retval 0 MegaLinter accepted every selected fixture.
## @note Non-zero Docker or MegaLinter exit statuses are propagated unchanged.
##
## @par Examples
## @code
## run_megalinter '["tests/fixtures/good.md"]'
## @endcode
run_megalinter() {
  local files_json=$1
  local plugin_uri="file://${FMLINT_DESCRIPTOR}"

  docker run \
    --rm \
    -v "${PWD}:/tmp/lint" \
    -w /tmp/lint \
    -e VALIDATE_ALL_CODEBASE=true \
    -e DISABLE_ERRORS=false \
    -e PRINT_ALPACA=false \
    -e SARIF_REPORTER=false \
    -e REPORT_OUTPUT_FOLDER=/tmp/megalinter-reports \
    -e "PLUGINS=[\"\${plugin_uri}\"]" \
    -e ENABLE_LINTERS='["MARKDOWN_FMLINT"]' \
    -e "MEGALINTER_FILES_TO_LINT=${files_json}" \
    "${MEGALINTER_IMAGE}"
}

if ! run_megalinter '["tests/fixtures/good.md","tests/fixtures/markdown-body-is-not-yaml.md"]'; then
  printf '%s\n' 'Expected valid frontmatter fixtures to pass MegaLinter.' >&2
  exit 1
fi

if run_megalinter '["tests/fixtures/bad-frontmatter.md"]'; then
  printf '%s\n' 'Expected invalid YAML frontmatter to fail MegaLinter.' >&2
  exit 1
fi

if run_megalinter '["tests/fixtures/unterminated.md"]'; then
  printf '%s\n' 'Expected unterminated frontmatter to fail MegaLinter.' >&2
  exit 1
fi
