################################################################################
#
# beaglemic-firmware
#
################################################################################

BEAGLEMIC_FIRMWARE_VERSION = c4eaf1b61648d6547a83e3ee77747919230ed80e
BEAGLEMIC_FIRMWARE_SITE = git://github.com/dinuxbg/beaglemic
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

