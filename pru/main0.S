/* SPDX-License-Identifier: BSD-2-Clause
 *
 * main0.S - PDM acquisition frontend.
 *
 * Copyright (c) 2018-2020 Dimitar Dimitrov <dimitar@dinux.eu>
 */


#include "common.h"

#define MIC_SLEEP_TIMEOUT_MS	10
#define PRU_CYCLE_NS		((1000 * 1000 * 1000) / (200 * 1000 * 1000))

	.extern _start_16ch
	.extern _start_8ch

	.text
	.section .init0, "x"
	.global	_start
_start:
	/*
	 * Appears that INMP621 cannot handle PDM clock frequency changes
	 * on the fly. Occasionally the microphone enters a state with
	 * substantially increased audio noise in its output when
	 * changing between 16 and 8 channel audio. Remember that the
	 * different modes also have different PDM clock frequencies.
	 *
	 * Solution found via trial and error is to reset the microphone
	 * by going through its SLEEP state.
	 *
	 * INMP621 has typical timeout of 30us for entering SLEEP mode,
	 * and SPM0423HD4H - 10ms.
	 */
	clr	r30, r30, R30_CLK_PIN

	ldi32	r0, (MIC_SLEEP_TIMEOUT_MS * 1000 * 1000) / (PRU_CYCLE_NS * 2)
wait_mic_sleep:
	sub	r0, r0, 1
	qbne	wait_mic_sleep, r0, 0

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
