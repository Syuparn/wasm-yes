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

  [ "$lineno" -eq 10 ]
}

@test "if argument is passed, yes writes it instead" {
  result="$(wasmer yes.wasm foo | head -n 1)"
  [ "$result" = "foo" ]
}

@test "yes always writes first argument" {
  lineno=0
  for result in $(wasmer yes.wasm foo | head -n 10); do
    echo "line $((lineno++)):"
    [ "$result" = "foo" ]
  done

  [ "$lineno" -eq 10 ]
}

@test "yes ignores second argument" {
  result="$(wasmer yes.wasm foo bar | head -n 1)"
  [ "$result" = "foo" ]
}

@test "yes ignores second and subsequent arguments" {
  result="$(wasmer yes.wasm foo bar baz hoge fuga piyo | head -n 1)"
  [ "$result" = "foo" ]
}

@test "yes can handle multibyte argument" {
  lineno=0
  for result in $(wasmer yes.wasm はい | head -n 10); do
    echo "line $((lineno++)):"
    [ "$result" = "はい" ]
  done

  [ "$lineno" -eq 10 ]
}
