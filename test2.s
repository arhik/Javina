.data
.balign 8
_welcome_str:
	.ascii "Welcome to Javina: "
	.byte 0
/* end data */

.data
.balign 8
_prompt:
	.ascii "javina>"
/* end data */

.bss
.balign 8
_input_buffer:
	.fill 65536,1,0
/* end data */

