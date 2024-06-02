.data
buffer: .skip 100  // Buffer to hold the input string
len:    .quad 100  // Length of the buffer

.text
.global _start

_main:
    // Read syscall parameters
    mov x8, 63            // Syscall number for read (NR_read)
    mov x0, 0             // File descriptor 0 (stdin)
    ldr x1, =buffer       // Address of the buffer
    ldr x2, =len          // Length of the buffer (100 bytes)
    ldr x2, [x2]          // Dereference the length

    // Make the syscall
    svc 0

    // Exit syscall parameters
    mov x8, 93            // Syscall number for exit (NR_exit)
    mov x0, 0             // Exit code 0
    svc 0                 // Make the syscall

.bss
.align 3
