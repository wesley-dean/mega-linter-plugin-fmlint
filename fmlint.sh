#!/bin/sh

filename="$1"

if [ ! -f "$filename" ] ; then
  yamllint "$@"
  exit $?
fi

shift

tempfile="$(mktemp)"

sed -Eze 's/((^|\n)---.*?---(\n|$)).*/\1/' < "$filename" > "$tempfile"

yamllint "$@" "$tempfile" | sed -Ee "s|${tempfile}|${filename}|g"
