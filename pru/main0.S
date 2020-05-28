/* main0.S - PDM acquisition frontend.
 *
 * Copyright (c) 2018-2020 Dimitar Dimitrov <dimitar@dinux.eu>
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */


#include "common.h"

	.extern _start_16ch
	.extern _start_8ch

	.text
	.section .init0, "x"
	.global	_start
_start:
	/* Ensure filters start initialized. */
	zero	r0, 29 * 4
	xout    SCRATCH_BANK_0, r0, 29 * 4
	xout    SCRATCH_BANK_1, r0, 29 * 4
	xout    SCRATCH_BANK_2, r0, 28 * 4 /* Careful with REG_PRU0_MODE! */


	/* Poll for acquisition poll. */
	xin	SCRATCH_BANK_2, REG_PRU0_MODE, 1
	qbeq	jump_to_8ch, REG_PRU0_MODE, 8
	qbeq	jump_to_16ch, REG_PRU0_MODE, 16
	jmp	_start


jump_to_8ch:
	jmp _start_8ch

jump_to_16ch:
	jmp _start_16ch

	/* Dummy data, required by remoteproc loader */
	.data
	.section .resource_table,"aw",@progbits
my_resource_table:
	.word	1, 0, 0, 0	/* struct resource_table base */
	.word	0		/* uint32_t offset[1] */
