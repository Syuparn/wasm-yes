# wasm-yes
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

yes command implemented in WebAssembly and WASI

# Usage

Same as the GNU `yes` command.

```bash
# run command by wasmer (or whatever wasm runtime you like)
$ wasmer yes.wasm
y
y
y
y
y
...
```

# About source code

In order to reduce binary size, `yes.wat` is written by hand.
