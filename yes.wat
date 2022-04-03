(module
  (import "wasi_unstable" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))

  (memory 1)
  (export "memory" (memory 0))

  ;; store output "y\n" to memory 0
  ;; NOTE: memory[0:16] is reserved for other use (see below)
  (data (i32.const 16) "y\n")

(func $initialize_iov
  (param $str_ptr i32) (param $str_len i32)

  ;; initialize io vector(iov) in memory[0:8]
  (i32.store (i32.const 0) (local.get $str_ptr)) ;; memory[0:4]: pointer to string
  (i32.store (i32.const 4) (local.get $str_len)) ;; memory[4:8]: length of string
)

  ;; main function name should be `_start`
  (func $main (export "_start")
    (local $errno i32)
    (local $output_ptr i32) ;; memory index of output string
    (local $output_len i32) ;; length of output string

    ;; refer "y\n" by default
    (local.set $output_ptr (i32.const 16))
    (local.set $output_len (i32.const 2))

    (call $initialize_iov (local.get $output_ptr) (local.get $output_len))

    ;; write to stdout infinitely
    (loop $next
      (local.set $errno (call $fd_write
        (i32.const 1) ;; stdout
        (i32.const 0) ;; pointer to iov
        (i32.const 1) ;; number of strings to be written
        (i32.const 8) ;; memory index to write number of bytes written (memory[8:16] is used)
      ))

      ;; go to next loop only if fd_write succeeded
      ;; NOTE: It is necessary to close pipeline!
      ;; (e.g: In command `yes | head -n $N`, `head` sends SIGPIPE to `yes` after it writes N lines
      ;;       then `yes` terminates. If `yes` ignored SIGPIPE and kept writing new lines,
      ;;       `head` would wait `yes`'s termination infinitely.
      (br_if $next (i32.eqz (local.get $errno)))
    )
  )
)
