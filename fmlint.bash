#!/usr/bin/env bash

# shellcheck disable=SC2124
filename="${@: -1}"

echo "in $0 STDOUT"
echo "in $0 STDERR" >&2

if [ -f "$filename" ]; then
  # This ugliness is to remove the last argument from the list of arguments
  set -- "${@:1:$(($#-1))}"

  sed -Eze 's/((^|\n)---.*?---(\n|$)).*/\1/' < "$filename" \
  | yamllint "$@" -
else
  yamllint "$@"
fi

