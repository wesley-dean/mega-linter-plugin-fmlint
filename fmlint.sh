#!/bin/sh

filename="$1"
tempfile="$(mktemp)"

sed -Eze 's/((^|\n)---.*?---(\n|$)).*/\1/' < "$filename" > "$tempfile"

yamllint "$tempfile" | sed -Ee "s|${tempfile}|${filename}|g"
