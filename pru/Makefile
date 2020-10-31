# SPDX-License-Identifier: BSD-2-Clause
#
# Copyright (c) 2018-2020, Dimitar Dimitrov
#   All rights reserved.
#
# Very simple makefile to cross-compile for PRU


# Common flags
CROSS_COMPILE ?= pru-
CFLAGS += -g -Os
CFLAGS += -Wall -Wextra

# Define this to squeeze code size by removing atexit, exit, constructors
# and destructors from CRT.
CFLAGS += -minrt

# Headers needed by the TI rpmsg library.
CFLAGS += -I./include -I./include/am335x

# Per-PRU core flags. The -mmcu option will select the correct linker
# script and will predefine mcu-specific macros.
CFLAGS0 += -mmcu=am335x.pru0 -nostdlib -nodefaultlibs -nostartfiles
CFLAGS1 += -mmcu=am335x.pru1

# List of source files to compile for each PRU core.
SRC0 := main0.S pru0-16ch.S pru0-8ch.S
SRC1 := main1.c pru_rpmsg.c pru_virtqueue.c

# GCC's -MMD does not yield the needed C dependencies when compiling all
# C source files at once. So manually list headers here.
HEADERS := $(wildcard *.h)

# Where to output compiled objects
OUT := out

# Final ELF image file names
ELF0 := $(OUT)/pru-core0.elf
ELF1 := $(OUT)/pru-core1.elf

# ============================ DO NOT TOUCH BELOW ============================
all: $(ELF0) $(ELF1)
	@echo Success: $^

%.s : %.elf
	$(CROSS_COMPILE)objdump -S -d $< > $@

# Binary images for IMEM and DMEM memories. Might be useful
# for firmware loaders that cannot handle ELF.
%.imem.bin : %.elf
	$(CROSS_COMPILE)objcopy -O binary  --only-section=.text* $< $@

%.dmem.bin : %.elf
	$(CROSS_COMPILE)objcopy -O binary              \
	  --only-section=.data*                        \
	  --only-section=.bss*                         \
	  --set-section-flags .bss=alloc,load,contents \
	  $< $@

$(OUT):
	mkdir $(OUT)

$(ELF0): $(SRC0) $(HEADERS) | $(OUT)
	$(CROSS_COMPILE)gcc $(CFLAGS) $(CFLAGS0) $(SRC0) $(LDFLAGS) -o $@

$(ELF1): $(SRC1) $(HEADERS) | $(OUT)
	$(CROSS_COMPILE)gcc $(CFLAGS) $(CFLAGS1) $(SRC1) $(LDFLAGS) -o $@

clean:
	$(RM) -fr $(ELF0) $(ELF1) $(OUT)

cscope:
	cscope -bRk

.PHONY: all clean cscope
