#!/usr/bin/env bash

# shellcheck disable=SC2124
filename="${@: -1}"

if [ ! -f "$filename" ] ; then
  yamllint "$@"
  exit $?
fi

# This ugliness is to remove the last argument from the list of arguments
set -- "${@:1:$(($#-1))}"

tempfile="$(mktemp)"
sed -Eze 's/((^|\n)---.*?---(\n|$)).*/\1/' < "$filename" > "$tempfile"

yamllint "$@" "$tempfile" | sed -Ee "s|${tempfile}|${filename}|g"

rm -f "$tempfile"
