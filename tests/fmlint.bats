#!/usr/bin/env bats

setup() {
  TEST_ROOT="${BATS_TEST_TMPDIR}/case-${BATS_TEST_NUMBER}"
  mkdir -p "${TEST_ROOT}/bin"
  export FMLINT_UNDER_TEST="${BATS_TEST_DIRNAME}/../fmlint.bash"
  export FMLINT_TEST_ARGS_LOG="${TEST_ROOT}/args.log"
  export FMLINT_TEST_CONTENT_LOG="${TEST_ROOT}/frontmatter.yml"
  export FMLINT_FAKE_STATUS=0
  export PATH="${TEST_ROOT}/bin:${PATH}"

  cat >"${TEST_ROOT}/bin/yamllint" <<'FAKE'
#!/usr/bin/env bash
set -u

last=${!#}
printf '%s\n' "$#" "$@" >"${FMLINT_TEST_ARGS_LOG}"
cp -- "${last}" "${FMLINT_TEST_CONTENT_LOG}"
printf '%s\n' "${last}"
printf '%s\n' '  2:3       warning  fake warning  (fake)'
exit "${FMLINT_FAKE_STATUS:-0}"
FAKE
  chmod +x "${TEST_ROOT}/bin/yamllint"
}

@test "only YAML frontmatter reaches yamllint" {
  markdown="${TEST_ROOT}/hostile-body.md"
  cat >"${markdown}" <<'EOF'
---
title: Valid frontmatter
---
# Markdown body

- this
- is
- not: intended as YAML input

```bash
echo "the Markdown body must be ignored"
```
EOF

  run "${FMLINT_UNDER_TEST}" --format standard "${markdown}"

  [ "${status}" -eq 0 ]
  expected=$'---\ntitle: Valid frontmatter'
  actual=$(cat "${FMLINT_TEST_CONTENT_LOG}")
  [ "${actual}" = "${expected}" ]
}

@test "yamllint arguments remain distinct argv elements" {
  markdown="${TEST_ROOT}/file with spaces.md"
  cat >"${markdown}" <<'EOF'
---
title: Argument preservation
---
Body
EOF

  run "${FMLINT_UNDER_TEST}" \
    --format standard \
    --config-file "config with spaces.yml" \
    "${markdown}"

  [ "${status}" -eq 0 ]
  mapfile -t argv <"${FMLINT_TEST_ARGS_LOG}"
  [ "${argv[0]}" -eq 5 ]
  [ "${argv[1]}" = "--format" ]
  [ "${argv[2]}" = "standard" ]
  [ "${argv[3]}" = "--config-file" ]
  [ "${argv[4]}" = "config with spaces.yml" ]
}

@test "yamllint diagnostics are attributed to the Markdown file" {
  markdown="${TEST_ROOT}/diagnostics.md"
  cat >"${markdown}" <<'EOF'
---
title: Diagnostics
---
Body
EOF

  run "${FMLINT_UNDER_TEST}" "${markdown}"

  [ "${status}" -eq 0 ]
  [ "${lines[0]}" = "${markdown}" ]
  [[ "${output}" != *"/frontmatter.yml"* ]]
}

@test "yamllint exit status is propagated unchanged" {
  markdown="${TEST_ROOT}/status.md"
  cat >"${markdown}" <<'EOF'
---
title: Status
---
Body
EOF
  export FMLINT_FAKE_STATUS=7

  run "${FMLINT_UNDER_TEST}" "${markdown}"

  [ "${status}" -eq 7 ]
}

@test "Markdown without frontmatter is ignored without invoking yamllint" {
  markdown="${TEST_ROOT}/plain.md"
  printf '%s\n' '# Ordinary Markdown' >"${markdown}"

  run "${FMLINT_UNDER_TEST}" "${markdown}"

  [ "${status}" -eq 0 ]
  [ ! -e "${FMLINT_TEST_ARGS_LOG}" ]
}

@test "unterminated frontmatter is a distinct data error" {
  markdown="${TEST_ROOT}/unterminated.md"
  cat >"${markdown}" <<'EOF'
---
title: Unterminated
EOF

  run "${FMLINT_UNDER_TEST}" "${markdown}"

  [ "${status}" -eq 65 ]
  [[ "${output}" == *"unterminated YAML frontmatter"* ]]
  [ ! -e "${FMLINT_TEST_ARGS_LOG}" ]
}

@test "CRLF frontmatter delimiters are recognized" {
  markdown="${TEST_ROOT}/crlf.md"
  printf '%s\r\n' \
    '---' \
    'title: CRLF' \
    '---' \
    '# Markdown' >"${markdown}"

  run "${FMLINT_UNDER_TEST}" "${markdown}"

  [ "${status}" -eq 0 ]
  [ -e "${FMLINT_TEST_CONTENT_LOG}" ]
}
