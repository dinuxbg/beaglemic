/* SPDX-License-Identifier: BSD-2-Clause
 *
 * common.h - Common constant definitions
 *
 * Copyright (c) 2018-2020 Dimitar Dimitrov <dimitar@dinux.eu>
 */

#ifndef __COMMON_H__
#define __COMMON_H__

#define SCRATCH_BANK_0	10
#define SCRATCH_BANK_1	11
#define SCRATCH_BANK_2	12
#define PEER_PRU_BANK	14

#define REG_PRU0_MODE		r29.b0
#define INTC_COMPOSITE_SYS_BASE	16
#define PRU0_TO_PRU1_INTR	(21 - INTC_COMPOSITE_SYS_BASE)
#define R31_INTR_STROBE		(1u << 5)

#define R30_CLK_PIN		14


#define CMD_START	0x01
#define CMD_STOP	0x02

#endif	/* __COMMON_H__ */
