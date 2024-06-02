.data
buffer: .skip 100    // Buffer to hold the input string (100 bytes)
len:    .quad 100    // Length of the buffer

.text
.global _start
//.type _start, %function  // Define _start as a function

_start:
    // Read syscall parameters
    mov x8, 63        // Syscall number for read (NR_read)
    mov x0, 0         // File descriptor 0 (stdin)
    ldr x1, =buffer   // Address of the buffer
    ldr x2, =len      // Length of the buffer (100 bytes)
    ldr x2, [x2]      // Dereference the length

    // Make the read syscall
    svc 0

    // Store the number of bytes read in x0
    mov x3, x0

    // Write syscall parameters
    mov x8, 64        // Syscall number for write (NR_write)
    mov x0, 1         // File descriptor 1 (stdout)
    ldr x1, =buffer   // Address of the buffer
    mov x2, x3        // Number of bytes to write (from x3, the return value of read)

    // Make the write syscall
    svc 0

    // Exit syscall parameters
    mov x8, 93        // Syscall number for exit (NR_exit)
    mov x0, 0         // Exit code 0
    svc 0             // Make the syscall

.bss
.align 3
