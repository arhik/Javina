.text
.balign 4
_exit:
	stp	x29, x30, [sp, -16]!
	mov	x29, sp
	mov	w1, w0
	mov	w0, #60
	bl	_syscall1
	ldp	x29, x30, [sp], 16
	ret
/* end function exit */

.text
.balign 4
_print:
	stp	x29, x30, [sp, -16]!
	mov	x29, sp
	mov	x3, x1
	mov	x2, x0
	mov	w1, #1
	mov	w0, #1
	bl	_syscall3
	ldp	x29, x30, [sp], 16
	ret
/* end function print */

.data
.balign 8
_greet:
	.ascii "hello world!\n"
/* end data */

.text
.balign 4
.globl __start
__start:
	stp	x29, x30, [sp, -16]!
	mov	x29, sp
	mov	x1, #13
	adrp	x0, _greet@page
	add	x0, x0, _greet@pageoff
	bl	_print
	mov	w0, #0
	bl	_exit
	ldp	x29, x30, [sp], 16
	ret
/* end function _start */

