# wasm-yes
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)
[![Test](https://github.com/Syuparn/wasm-yes/actions/workflows/test.yml/badge.svg)](https://github.com/Syuparn/wasm-yes/actions/workflows/test.yml)
[![WAPM](https://img.shields.io/badge/WAPM-0.2.1-blueviolet)](https://wapm.io/Syuparn/yes)

yes command implemented in WebAssembly and WASI

# Install

This command is distributed from [WAPM](https://wapm.io/).

```bash
$ wapm install Syuparn/yes
$ wapm run yes | head -n 3
y
y
y
```

You can also compile wasm manually from `wat` file.

```bash
$ wasm2wat yes.wat
$ wasmer yes.wasm
y
y
y
...
```

# Usage

Same as the GNU `yes` command.

```bash
# write `y` infinitely
$ wapm run yes
y
y
y
y
y
...

# write argument instead
$ wapm run yes no!
no!
no!
no!
no!
no!
...
```

# About source code

In order to reduce binary size, `yes.wat` is written by hand.

# For developers

You can test generated wasm by [bats](https://github.com/bats-core/bats-core).

```bash
# install wat2wasm and bats
$ npm install

# build wasm
$ npx wat2wasm yes.wat

# run test (requires wasmer)
$ npx bats test/yes.bats
 ✓ yes without argument writes 'y'
 ✓ yes always writes 'y'

2 tests, 0 failures
```
