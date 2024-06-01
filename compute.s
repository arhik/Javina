.text
.balign 4
_compute:
	stp	x29, x30, [sp, -32]!
	mov	x29, sp
	str	x19, [x29, 24]
	mov	w19, w0
	bl	_eval_l
	mov	w18, w0
	mov	w0, w19
	mov	w19, w18
	bl	_eval_r
	mul	w0, w19, w0
	ldr	x19, [x29, 24]
	ldp	x29, x30, [sp], 32
	ret
/* end function compute */

