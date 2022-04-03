(module
  (import "wasi_unstable" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (import "wasi_unstable" "args_sizes_get" (func $args_sizes_get (param i32 i32) (result i32)))
  (import "wasi_unstable" "args_get" (func $args_get (param i32 i32) (result i32)))

  (memory 1)
  ;; memory usage
  ;;
  ;; memory[0:8]  : iov
  ;; memory[8:16] : write number of bytes written by write_fd
  ;; memory[16:18]: string "y\n"
  ;; memory[20:24]: number of command-line args
  ;; memory[24:28]: size of command-line args string data
  ;; memory[28:]: command-line args
  (export "memory" (memory 0))

  ;; store output "y\n" to memory[16:18]
  (data (i32.const 16) "y\n")

  (func $initialize_iov
    (param $str_ptr i32) (param $str_len i32)

    ;; initialize io vector(iov) in memory[0:8]
    (i32.store (i32.const 0) (local.get $str_ptr)) ;; memory[0:4]: pointer to string
    (i32.store (i32.const 4) (local.get $str_len)) ;; memory[4:8]: length of string
  )

  (func $has_command_line_args
    (result i32)
    (drop (call $args_sizes_get
      (i32.const 20) ;; memory[20:24]: pointer to store number of args
      (i32.const 24) ;; memory[20:28]: pointer to store size of args string data
    ))
    ;; NOTE: ignore args[0] because it is command name "yes.wasm" itself
    (i32.gt_u (i32.load (i32.const 20)) (i32.const 1)) ;; return len(args) > 1
  )

  (func $get_first_command_arg
    (param $n_args i32) (param $args_data_ptr i32) (result i32) ;; return pointer of args[1]

    ;; read and store arg string data
    (drop (call $args_get ;; drop returned errno
      ;; pointer to store arg string data pointers
      ;; store args[0] pointer to memory[$args_data_ptr:$args_data_ptr+4],
      ;; store args[1] pointer to memory[$args_data_ptr+4:$args_data_ptr+8],...
      (local.get $args_data_ptr)
      ;; pointer to store the whole arg string data
      ;; NOTE: define pointer not to overlap args pointers above
      (i32.add (local.get $args_data_ptr) (i32.mul (local.get $n_args) (i32.const 4)))
    ))

    ;; return pointer of args[1]
    ;; NOTE: ignore args[0] because it is command name "yes.wasm" itself
    (i32.load (i32.add (local.get $args_data_ptr) (i32.const 4)))
  )

  (func $append_breakline
    (param $str_ptr i32)

    (local $i i32)
    (local.set $i (local.get $str_ptr))
    (loop $next
      (if (i32.eqz (i32.load8_u (local.get $i))) ;; if memory[i] == '\0'
        (then
          ;; overwrite "\n" to memory[i]
          (i32.store8 (local.get $i) (i32.const 10))
          ;; overwrite "\0" to memory[i+1]
          (i32.store8 (i32.add (local.get $i) (i32.const 1)) (i32.const 0))
          (return)
        )
        (else nop)
      )
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $next)
    )
  )

  (func $len_str
    (param $str_ptr i32) (result i32)
    (local $n i32)
    (local.set $n (i32.const 0))

    (loop $next
      (if (i32.eqz (i32.load8_u (i32.add (local.get $str_ptr) (local.get $n)))) ;; if memory[str_ptr+n] == '\0'
        (then
          (return (local.get $n))
        )
        (else nop)
      )
      (local.set $n (i32.add (local.get $n) (i32.const 1)))
      (br $next)
    )
    (unreachable)
  )

  ;; main function name should be `_start`
  (func $main (export "_start")
    (local $errno i32)
    (local $output_ptr i32) ;; memory index of output string
    (local $output_len i32) ;; length of output string

    ;; refer "y\n" by default
    (local.set $output_ptr (i32.const 16))
    (local.set $output_len (i32.const 2))

    ;; if command-line argument is passed, print it instead
    (if (call $has_command_line_args)
      (then
        ;; store arg string data and refer first arg
        (local.set $output_ptr
          (call $get_first_command_arg
            (i32.load (i32.const 20)) ;; number of args
            (i32.const 28) ;; pointer to store args data
          )
        )
        ;; append "\n" to the first arg
        (call $append_breakline (local.get $output_ptr))
        ;; refer first arg length
        (local.set $output_len (call $len_str (local.get $output_ptr)))
      )
      (else nop)
    )

    ;; create io vector for strings to be written
    (call $initialize_iov (local.get $output_ptr) (local.get $output_len))
    ;; write to stdout infinitely
    (loop $next
      (local.set $errno
        (call $fd_write
          (i32.const 1) ;; stdout
          (i32.const 0) ;; memory[0:8]: pointer to iov
          (i32.const 1) ;; number of strings to be written
          (i32.const 8) ;; memory[8:16]: memory index to write number of bytes written
        )
      )

      ;; go to next loop only if fd_write succeeded
      ;; NOTE: It is necessary to close pipeline!
      ;; (e.g: In command `yes | head -n $N`, `head` sends SIGPIPE to `yes` after it writes N lines
      ;;       then `yes` terminates. If `yes` ignored SIGPIPE and kept writing new lines,
      ;;       `head` would wait `yes`'s termination infinitely.
      (br_if $next (i32.eqz (local.get $errno)))
    )
  )
)
