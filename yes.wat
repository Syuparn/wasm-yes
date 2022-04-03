(module
  (import "wasi_unstable" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))

  (memory 1)
  (export "memory" (memory 0))

  ;; store output "y\n" to memory 0
  ;; NOTE: memory[0:16] is reserved for other use (see below)
  (data (i32.const 16) "y\n")

  ;; main function name should be `_start`
  (func $main (export "_start")
    (local $errno i32)

    ;; initialize io vector(iov) in memory[0:8]
    (i32.store (i32.const 0) (i32.const 16)) ;; pointer to "y\n"
    (i32.store (i32.const 4) (i32.const 2)) ;; length of "y\n"
    ;; memory[8:16] is used for number of bytes written by fd_write

    ;; write to stdout infinitely
    (loop $next
      (local.set $errno (call $fd_write
        (i32.const 1) ;; stdout
        (i32.const 0) ;; pointer to iov
        (i32.const 1) ;; number of strings to be written
        (i32.const 8) ;; memory index to write number of bytes written
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
