#!/bin/sh

# SPDX-License-Identifier: BSD-2-Clause

RPROC0=/sys/class/remoteproc/remoteproc2
RPROC1=/sys/class/remoteproc/remoteproc3

echo stop > $RPROC0/state
echo stop > $RPROC1/state

# PinMux must be setup from DeviceTree, so go ahead
# directly to remoteproc initialization.

cp out/pru-core0.elf /lib/firmware/
cp out/pru-core1.elf /lib/firmware/
echo pru-core0.elf > $RPROC0/firmware
echo pru-core1.elf > $RPROC1/firmware

echo start > $RPROC0/state
echo start > $RPROC1/state
