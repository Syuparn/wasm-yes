(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))

  (memory 1)
  (export "memory" (memory 0))

  ;; store output "y\n" to memory 0
  ;; NOTE: memory[0:8] is reserved for iov (see below)
  (data (i32.const 8) "y\n")

  ;; main function name should be `_start`
  (func $main (export "_start")
    ;; initialize io vector(iov) in memory[0:8]
    (i32.store (i32.const 0) (i32.const 8)) ;; pointer to "y\n"
    (i32.store (i32.const 4) (i32.const 2)) ;; length of "y\n"

    ;; write to stdout infinitely
    (loop $next
      (drop (call $fd_write ;; ignore return value (number of bytes written)
        (i32.const 1) ;; stdout
        (i32.const 0) ;; pointer to iov
        (i32.const 1) ;; number of strings to be written
        (i32.const 12) ;; memory index to write number of bytes written
      ))
      (br $next) ;; go to next loop
    )
  )
)
