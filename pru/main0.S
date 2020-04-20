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

/*
 * Native bank:
 *   r0, r1, r2, ..., r7			Integrator 0
 *   r8, r9, r10, ..., r15			Integrator 1
 *   r16, r17, r18, ..., r23			Integrator 2
 *   r24, r25, r26, ..., r29			Global registers
 *
 * Bank 0:
 *   r0, r2, r4, ..., r14			Comb 0, delay 1
 *   r1, r3, r5, ..., r15			Comb 0, delay 2
 *   r16, r17, r18, ..., r23			Rate change latch (Comb 0 input)
 *
 * Bank 1:
 *   r0, r2, r4, ..., r14			Comb 1, delay 1
 *   r1, r*3, r5, ..., r15			Comb 1, delay 2
 *   r16, r17, r18, ..., r23			PCM output accumulator
 *
 * Bank 2:
 *   r0, r2, r4, ..., r14			Comb 2, delay 1
 *   r1, r3, r5, ..., r15			Comb 2, delay 2
 *   r16, r17, r18, ..., r23			output: pcm
 *   r24					output: frame counter
 *
 * Warning: XCHG instruction is not supported on AM335x. See:
 *   http://e2e.ti.com/support/processors/f/791/t/340589?Am335x-PRU-scratchpad-XCHG-problem-
 *
 *
 * Notes:
 *  - The parallel 8-bit input data is strobed. The cycles for COMB
 *    processing are not enough to fit the data setup time of the MIC
 *    output.
 *  - PCM output is buffered to allow PRU1 consumer more time to fetch data.
 *
 * This firmware implements 3-stage CIC filter to achieve 24-bit output
 * sample accuracy:
 *       I -> I -> I -> R -> C -> C -> C
 * Per [1]:
 *       B_OUT = N * log2(R * M) + B_IN
 * For this firmware:
 *       B_IN = 1
 *       M = 2
 *       R = 128
 *       N = 3
 * Which yelds B_OUT=25 bits
 *
 * [1] http://home.mit.bme.hu/~kollar/papers/cic.pdf
 */

#include "common.h"

#define RPDATA	r29.b1		/* Parallel 8-bit input strobe. */
#define RJMPSUB r29.w2		/* Subroutine - the next stage. */
#define CTMP1	r28		/* Comb Temporary Value 1. */
#define CTMP2	r27		/* Comb Temporary Value 1. */
#define CTMP3	r26		/* Comb Temporary Value 1. */
#define CW	r25		/* Comb/Stage Working Global Register. */

#define RFRCNT	r24		/* Frame counter. Conveniently placed
				   immediately after PCM output regs. */

#define INTC_COMPOSITE_SYS_BASE	16
#define PRU0_TO_PRU1_INTR	(21 - INTC_COMPOSITE_SYS_BASE)
#define R31_INTR_STROBE		(1u << 5)

#define R30_CLK_PIN		14

.altmacro

/* Total: 5 cycles */
.macro	handle_dbit y1, y2, y3, bin, rin
	qbbc	.+8, \rin, \bin
	add	\y1, \y1, 1
	qbbs	.+8, \rin, \bin
	sub	\y1, \y1, 1
	add	\y2, \y2, \y1
	add	\y3, \y3, \y2
.endm


/* Rate changer (Integrator 2 output latch): 12 cycles
 *
 * Record Integrator 2 output to Bank 1. This is our
 * rate reducer.
 */
.macro	latch_integrator_2_out
latch_integrator_2_out:
	xout	SCRATCH_BANK_0, r16, 8 * 4

	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

	ldi	RJMPSUB, %pmem(comb_input0)
	jmp	subroutine_return
.endm

/* Comb input: 12 cycles.
 *
 * Record the Comb0 input into CW.
 */
.macro	__comb_ch_inp_subroutine	MICN, INR
comb_input\MICN:
	/* Save the integrator working registers. */
	mov	CTMP1, r\INR

	/* 8 cycles to fill in input for COMB0 */
	xin	SCRATCH_BANK_0, r\INR, 4
	mov	CW, r\INR

	nop
	nop
	nop
	nop
	nop
	nop

	/* Restore integrator working registers. */
	mov	r\INR, CTMP1
	ldi	RJMPSUB, %pmem(comb0_mic\MICN)
	jmp	subroutine_return
.endm

/* Comb stage: 12 cycles.
 *
 * Record the output into CW. This implies that the next
 * subroutine _must_ be the next comb stage for the same
 * MIC channel, or pcm output stage.
 */
.macro	__comb_ch_subroutine	COMBN, SCRATCH_BANK, MICN, Z1, Z2
comb\COMBN\()_mic\MICN:
	/* Save the integrator working registers. */
	mov	CTMP1, r\Z1
	mov	CTMP2, r\Z2

	/* 6 cycles to perform actual comb.
	 * Z1 and Z2 must be consecutive! */
	xin	\SCRATCH_BANK, r\Z1, 8
	sub	CTMP3, CW, r\Z2
	mov	r\Z2, r\Z1
	mov	r\Z1, CW
	mov	CW, CTMP3
	xout	\SCRATCH_BANK, r\Z1, 8

	/* Restore integrator working registers. */
	mov	r\Z1, CTMP1
	mov	r\Z2, CTMP2
	ldi	RJMPSUB, %pmem(comb\COMBN\()_mic\MICN\()_next_stage)
	jmp	subroutine_return

	/* Rely on placing subsequent subroutines adjacent in IMEM. */
comb\COMBN\()_mic\MICN\()_next_stage:
.endm

/* Comb output: 12 cycles.
 *
 * Record the Comb2 output into CW.
 */
.macro	__comb_ch_out_subroutine	MICN, OUTR
comb_output\MICN:
	/* Save the integrator working registers. */
	mov	CTMP1, r\OUTR

	/* 8 cycles to store output from COMB2 */
	mov	r\OUTR, CW
	xout	SCRATCH_BANK_1, r\OUTR, 4

	/*
	 * Clear CW so that next stage can work with
	 * initialized variable.
	 */
	ldi	CW, 0

	nop
	nop
	nop
	nop
	nop

	/* Restore integrator working registers. */
	mov	r\OUTR, CTMP1
	ldi	RJMPSUB, %pmem(comb_output\MICN\()_next_stage)
	jmp	subroutine_return

comb_output\MICN\()_next_stage:
.endm


.macro	comb_subroutines	MICN
	__comb_ch_inp_subroutine MICN, %(16 + MICN)
	__comb_ch_subroutine 0, SCRATCH_BANK_0, MICN, %(2 * MICN), %(2 * MICN + 1)
	__comb_ch_subroutine 1, SCRATCH_BANK_1, MICN, %(2 * MICN), %(2 * MICN + 1)
	__comb_ch_subroutine 2, SCRATCH_BANK_2, MICN, %(2 * MICN), %(2 * MICN + 1)
	__comb_ch_out_subroutine MICN, %(16 + MICN)
.endm

/* Idle stage: 12 cycles.
 *
 * Assumes that CW is cleared by previous stage, so that we can use
 * it as a counter of the NSTAGES number of idle subroutines we must
 * execute.
 */
.macro	idle_subroutine		NSTAGES
idle_subroutine:
	nop
	nop
	nop
	nop
	nop
	nop
	nop

	add	CW, CW, 1
	qbeq	finish_idle, CW, \NSTAGES

	/* Need to idle more. */
	nop
	ldi	RJMPSUB, %pmem(idle_subroutine)
	jmp	subroutine_return

	/* This was the last idle subroutine. Move on to next stage. */
finish_idle:
	ldi	CW, 0
	ldi	RJMPSUB, %pmem(idle_subroutine_end)
	jmp	subroutine_return
idle_subroutine_end:
.endm

/* PCM output latch: 12 cycles
 *
 * Move from PCB output latch to PCM output bank.
 *
 * WARNING: Z1, Z2 and Z3 must be consecutive registers!
 */
.macro	__pcm_output_latch_stage	N, Z1, Z2, Z3
__pcm_output_latch_stage\N:
	/* Save the integrator working registers. */
	mov	CTMP1, r\Z1
	mov	CTMP2, r\Z2
	mov	CTMP3, r\Z3

	xin	SCRATCH_BANK_1, r\Z1, 3 * 4
	xout	SCRATCH_BANK_2, r\Z1, 3 * 4

	nop
	nop

	/* Restore integrator working registers. */
	mov	r\Z1, CTMP1
	mov	r\Z2, CTMP2
	mov	r\Z3, CTMP3

	ldi	RJMPSUB, %pmem(__pcm_output_latch_stage\N\()_next_stage)
	jmp	subroutine_return

__pcm_output_latch_stage\N\()_next_stage:
.endm

.macro	pcm_output_latch
	__pcm_output_latch_stage 0, 16, 17, 18
	__pcm_output_latch_stage 1, 19, 20, 21
	/* Careful, we may repeat r21, but should not override r24! */
	__pcm_output_latch_stage 2, 21, 22, 23
.endm

	.text
	.section .init0, "x"
	.global	_start
_start:
	ldi	RJMPSUB, %pmem(subroutine_dispatch_table_start)
	ldi	RPDATA, 0
	ldi	RFRCNT, 0
	jmp	main_loop

	.text
	.section .text

	/* We have 29 cycles per clock level, so 58 cycle period.
	 * This yields F_mclk = 200MHz / 58 = 3.448 MHz
	 */
main_loop:
	mov	RPDATA, r31			/* 1 - part of CLK 1 cycle! */

	/* ---------- CLK 0->1 --------------------------------------*/
	set	r30, r30, R30_CLK_PIN		/* 1 */

	jmp	RJMPSUB				/* 1 jmp, 12 subroutine cycles*/
subroutine_return:

	handle_dbit r0, r8, r16, 0, RPDATA	/* 5 */
	handle_dbit r1, r9, r17, 1, RPDATA	/* 5 */
	handle_dbit r2, r10, r18, 2, RPDATA	/* 5 */

	/* ---------- CLK 1->0 --------------------------------------*/
	clr	r30, r30, R30_CLK_PIN		/* 1 */

	handle_dbit r3, r11, r19, 3, RPDATA	/* 5 */
	handle_dbit r4, r12, r20, 4, RPDATA	/* 5 */

	nop					/* 1 */

	handle_dbit r5, r13, r21, 5, RPDATA     /* 5 */
	handle_dbit r6, r14, r22, 6, RPDATA	/* 5 */
	handle_dbit r7, r15, r23, 7, RPDATA	/* 5 */

	/* We could coalesce the "return jump" from RJMPSUB
	 * with the main loop back edge.  This would free
	 * one instruction cycle. The only way I could do
	 * it, though, is by splitting a handle_dbit,
	 * which complicates code.
	 *
	 * With handle_dbit splitting we can increase the
	 * allowed cycles for RJMPSUB to 14. Since we don't
	 * need that much for now, let's stick with simpler
	 * code at expense of efficiency.
	 */
	jmp main_loop


/*
 * Dispatch table with short subroutines, which are executed during
 * the few spare cycles we have between handling PDM bit data.
 * We use them to run the comb filters.
 *
 *  Subroutines are as follows:
 *    1. Rate reducer (latch_integrator_3_out).
 *    2. For each channel CH, do a sequence of 3 comb filters:
 *      2.1. Move from BANK0_R${16+CH)} to CW
 *      2.2. Comb0
 *      2.3. Comb1
 *      2.4. Comb2
 *      2.5. Move CW to BANK1 PCM output accumulator
 *    3. Idle subroutines to achieve 128 rate reduce.
 *    4. For each channel CH, move from BANK1 PCM Accumulator to
 *       BANK2 PCM Output.
 *    5. Ping peer.
 */
subroutine_dispatch_table_start:
	latch_integrator_2_out

	/*
	 * 8 microphones, with 5 stages each. Total: 40 subroutines.
	 */
	.set i,0
	.rept 8
	   comb_subroutines	%i
	   .set i,i+1
	.endr

	/* idle (nop) stages
	 *
	 * WARNING: Put it here to allow maximum time between peer
	 * signalling and PCM OUT writing, to avoid peer reading
	 * missing data.
	 *
	 * WARNING: Relying on last COMB filter stage to clear CW.
	 */
	idle_subroutine	(128 - 1 - 5 * 8 - 3 - 1)

	/* 3 subroutines. */
	pcm_output_latch

	/* Stage to send results to peer PRU (12 cycles). */
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	/* Increment frame counter. */
	add	RFRCNT, RFRCNT, 1
	/* Write it to peer. */
	xout    SCRATCH_BANK_2, RFRCNT, 4

	/* Ping peer. */
	ldi	r31, R31_INTR_STROBE | PRU0_TO_PRU1_INTR
	ldi	RJMPSUB, %pmem(subroutine_dispatch_table_start)
	jmp	subroutine_return


	/* Dummy data, required by remoteproc loader */
	.data
	.section .resource_table,"aw",@progbits
my_resource_table:
	.word	1, 0, 0, 0	/* struct resource_table base */
	.word	0		/* uint32_t offset[1] */
