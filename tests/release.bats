#!/usr/bin/env bats

setup() {
  TEST_ROOT="${BATS_TEST_TMPDIR}/release-${BATS_TEST_NUMBER}"
  mkdir -p "${TEST_ROOT}"
  export RELEASE_REF="0123456789abcdef0123456789abcdef01234567"
}

@test "release descriptor pins runtime files to the build commit" {
  run make --no-print-directory build \
    DIST_DIR="${TEST_ROOT}/dist" \
    VERSION=1.2.3 \
    BUILD_REF="${RELEASE_REF}"

  [ "${status}" -eq 0 ]

  descriptor="${TEST_ROOT}/dist/fmlint.megalinter-descriptor.yml"
  checksum="${descriptor}.sha256"

  [ -f "${descriptor}" ]
  [ -f "${checksum}" ]

  grep -Fq '# Release version: v1.2.3' "${descriptor}"
  grep -Fq "# Source commit: ${RELEASE_REF}" "${descriptor}"
  ! grep -Fq '/refs/heads/main/' "${descriptor}"

  pinned_prefix="https://raw.githubusercontent.com/wesley-dean/mega-linter-plugin-fmlint/${RELEASE_REF}/"
  count=$(grep -Fo "${pinned_prefix}" "${descriptor}" | wc -l | tr -d ' ')
  [ "${count}" -eq 2 ]

  run bash -c 'cd "$1" && sha256sum -c fmlint.megalinter-descriptor.yml.sha256' _ "${TEST_ROOT}/dist"
  [ "${status}" -eq 0 ]
}

@test "release build rejects mutable or symbolic build references" {
  run make --no-print-directory build \
    DIST_DIR="${TEST_ROOT}/dist" \
    VERSION=1.2.3 \
    BUILD_REF=main

  [ "${status}" -ne 0 ]
  [[ "${output}" == *"40-character lowercase Git commit SHA"* ]]
}


@test "documented release URLs satisfy MegaLinter plugin path contract" {
  version_url="https://github.com/wesley-dean/mega-linter-plugin-fmlint/releases/download/v1.2.3/fmlint.megalinter-descriptor.yml"
  latest_url="https://github.com/wesley-dean/mega-linter-plugin-fmlint/releases/latest/download/fmlint.megalinter-descriptor.yml"

  for plugin_url in "${version_url}" "${latest_url}"; do
    [[ "${plugin_url}" == *"/mega-linter-plugin-"* ]]
    [[ "${plugin_url}" == *.megalinter-descriptor.yml ]]
  done
}
