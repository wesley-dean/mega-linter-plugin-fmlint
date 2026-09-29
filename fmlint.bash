#!/usr/bin/env bash
# shellcheck shell=bash
## @file fmlint.bash
## @brief Lints YAML frontmatter from one Markdown file.
## @details
## MegaLinter invokes this adapter once per selected Markdown file.  The adapter
## requires YAML frontmatter to begin on the first line with an exact `---`
## delimiter, copies only the frontmatter body into a temporary YAML document,
## invokes yamllint with the caller-provided arguments, rewrites temporary-file
## diagnostics back to the original Markdown path, and propagates yamllint's exit
## status.  Markdown content after the closing delimiter is never passed to
## yamllint.  Files without an opening frontmatter delimiter are ignored.

set -u -o pipefail

readonly FMLINT_EX_USAGE=64
readonly FMLINT_EX_DATAERR=65
readonly FMLINT_EX_NOINPUT=66
readonly FMLINT_EX_SOFTWARE=70

## @fn fmlint_extract_frontmatter()
## @brief Extracts YAML frontmatter from one Markdown file.
## @details
## Reads the supplied Markdown file and writes a YAML document containing the
## opening `---` delimiter and every following line up to, but not including,
## the first exact closing `---` delimiter.  A trailing carriage return is
## ignored only while recognizing delimiter lines so CRLF Markdown is accepted.
## Files that do not begin with frontmatter are reported through the exit status
## without producing output.  An opening delimiter without a closing delimiter
## is treated as malformed frontmatter.
##
## @param filename Markdown file to inspect.
## @param destination File that will receive extracted YAML frontmatter.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## A diagnostic is written for unreadable input or unterminated frontmatter.
##
## @returns Nothing is written to STDOUT.
## @retval 0 Frontmatter was extracted successfully.
## @retval 1 The file does not begin with YAML frontmatter.
## @retval 65 The opening delimiter has no matching closing delimiter.
## @retval 66 The input file cannot be read.
## @retval 70 The destination file cannot be prepared.
##
## @par Examples
## @code
## if fmlint_extract_frontmatter README.md /tmp/frontmatter.yml; then
##   yamllint /tmp/frontmatter.yml
## fi
## @endcode
fmlint_extract_frontmatter() {
  local filename=$1
  local destination=$2
  local first_line=''
  local line=''
  local normalized=''
  local found_closing=false
  local input_fd

  if [[ ! -r ${filename} ]]; then
    printf 'fmlint: cannot read %s\n' "${filename}" >&2
    return "${FMLINT_EX_NOINPUT}"
  fi

  if ! exec {input_fd}< "${filename}"; then
    printf 'fmlint: cannot open %s\n' "${filename}" >&2
    return "${FMLINT_EX_NOINPUT}"
  fi

  if ! IFS= read -r first_line <&"${input_fd}"; then
    first_line=''
  fi
  normalized=${first_line%$'\r'}

  if [[ ${normalized} != '---' ]]; then
    exec {input_fd}<&-
    return 1
  fi

  if ! : > "${destination}"; then
    exec {input_fd}<&-
    printf 'fmlint: cannot prepare temporary frontmatter\n' >&2
    return "${FMLINT_EX_SOFTWARE}"
  fi
  printf '%s\n' '---' > "${destination}"

  while IFS= read -r line <&"${input_fd}" || [[ -n ${line} ]]; do
    normalized=${line%$'\r'}
    if [[ ${normalized} == '---' ]]; then
      found_closing=true
      break
    fi
    printf '%s\n' "${line}" >> "${destination}"
  done
  exec {input_fd}<&-

  if [[ ${found_closing} != true ]]; then
    printf '%s\n' "${filename}" >&2
    printf '%s\n' \
      '  1:1       error    unterminated YAML frontmatter  (frontmatter)' >&2
    return "${FMLINT_EX_DATAERR}"
  fi

  return 0
}

## @fn fmlint_run_yamllint()
## @brief Runs yamllint against extracted frontmatter and remaps diagnostics.
## @details
## Invokes yamllint with the caller-provided arguments followed by the temporary
## YAML file.  Captured output is replayed after replacing a leading temporary
## path with the original Markdown path, preserving useful MegaLinter
## diagnostics while keeping the temporary representation private.
##
## @param filename Original Markdown path used for diagnostic attribution.
## @param frontmatter Temporary YAML file containing extracted frontmatter.
## @param output_file Temporary file used to capture yamllint output.
## @param ... Arguments to pass to yamllint before the temporary YAML path.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## yamllint output with temporary paths rewritten to the original Markdown path.
## @par STDERR
## Nothing is written directly to STDERR; yamllint STDERR is captured and replayed
## through STDOUT with its ordinary output because MegaLinter consumes one log.
##
## @returns Zero or more newline-delimited yamllint diagnostic lines.
## @retval 0 yamllint accepted the extracted frontmatter.
## @note Non-zero yamllint exit statuses are propagated unchanged.
##
## @par Examples
## @code
## fmlint_run_yamllint post.md /tmp/frontmatter.yml /tmp/output --format standard
## @endcode
fmlint_run_yamllint() {
  local filename=$1
  local frontmatter=$2
  local output_file=$3
  shift 3
  local status=0
  local line=''

  yamllint "$@" "${frontmatter}" > "${output_file}" 2>&1
  status=$?

  while IFS= read -r line || [[ -n ${line} ]]; do
    if [[ ${line} == "${frontmatter}"* ]]; then
      printf '%s%s\n' "${filename}" "${line#"${frontmatter}"}"
    else
      printf '%s\n' "${line}"
    fi
  done < "${output_file}"

  return "${status}"
}

if (($# < 1)); then
  printf '%s\n' 'Usage: fmlint [yamllint arguments ...] MARKDOWN_FILE' >&2
  exit "${FMLINT_EX_USAGE}"
fi

filename=${!#}
yamllint_args=("${@:1:$#-1}")

fmlint_tmp_dir=$(mktemp -d) || {
  printf '%s\n' 'fmlint: unable to create temporary directory' >&2
  exit "${FMLINT_EX_SOFTWARE}"
}
trap 'rm -rf -- "${fmlint_tmp_dir}"' EXIT

frontmatter_file="${fmlint_tmp_dir}/frontmatter.yml"
yamllint_output="${fmlint_tmp_dir}/yamllint.out"

fmlint_extract_frontmatter "${filename}" "${frontmatter_file}"
extract_status=$?
case ${extract_status} in
  0)
    ;;
  1)
    exit 0
    ;;
  *)
    exit "${extract_status}"
    ;;
esac

fmlint_run_yamllint \
  "${filename}" \
  "${frontmatter_file}" \
  "${yamllint_output}" \
  "${yamllint_args[@]}"
exit $?
