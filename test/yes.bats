#!/usr/bin/env bats

@test "yes without argument writes 'y'" {
  result="$(wasmer yes.wasm | head -n 1)"
  [ "$result" = "y" ]
}

@test "yes always writes 'y'" {
  lineno=0
  for result in $(wasmer yes.wasm | head -n 10); do
    echo "line $((lineno++)):"
    [ "$result" = "y" ]
  done
}
