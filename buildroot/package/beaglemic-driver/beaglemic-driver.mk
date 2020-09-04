################################################################################
#
# beaglemic-driver
#
################################################################################

BEAGLEMIC_DRIVER_VERSION = 8f9b664010dccc8700b58501971b6b3963fd7897
BEAGLEMIC_DRIVER_SITE = git://github.com/dinuxbg/beaglemic
BEAGLEMIC_DRIVER_LICENSE = GPL-2.0
BEAGLEMIC_DRIVER_LICENSE_FILES = COPYING
BEAGLEMIC_DRIVER_MODULE_SUBDIRS = driver


$(eval $(kernel-module))
$(eval $(generic-package))

