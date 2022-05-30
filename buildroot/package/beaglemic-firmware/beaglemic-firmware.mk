################################################################################
#
# beaglemic-firmware
#
################################################################################

BEAGLEMIC_FIRMWARE_VERSION = 64c8d7751f0ffcb4d7d9fc0dd7cb8854f67be743
BEAGLEMIC_FIRMWARE_SOURCE = $(BEAGLEMIC_DRIVER_VERSION).tar.gz
BEAGLEMIC_FIRMWARE_SITE = https://github.com/dinuxbg/beaglemic/archive
BEAGLEMIC_FIRMWARE_LICENSE = TCL
BEAGLEMIC_FIRMWARE_LICENSE_FILES = COPYING

define BEAGLEMIC_FIRMWARE_BUILD_CMDS
	CROSS_COMPILE=pru- $(MAKE) -C $(@D)/pru
endef

define BEAGLEMIC_FIRMWARE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -t $(TARGET_DIR)/lib/firmware -m 0644 $(@D)/pru/out/*.elf
	$(INSTALL) -m 0755 \
		-D $(BR2_EXTERNAL_BEAGLEMIC_PATH)/package/beaglemic-firmware/beaglemicd \
		$(TARGET_DIR)/usr/bin/beaglemicd
endef

define AM33X_CM3_INSTALL_INIT_SYSV
	$(INSTALL) -m 0755 \
		-D $(BR2_EXTERNAL_BEAGLEMIC_PATH)/package/beaglemic-firmware/S99-beaglemic-init \
		$(TARGET_DIR)/etc/init.d/S99-beaglemic-init
endef

$(eval $(generic-package))

