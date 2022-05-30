################################################################################
#
# beaglemic-driver
#
################################################################################

BEAGLEMIC_DRIVER_VERSION = 64c8d7751f0ffcb4d7d9fc0dd7cb8854f67be743
BEAGLEMIC_DRIVER_SOURCE = $(BEAGLEMIC_DRIVER_VERSION).tar.gz
BEAGLEMIC_DRIVER_SITE = https://github.com/dinuxbg/beaglemic/archive
BEAGLEMIC_DRIVER_LICENSE = GPL-2.0
BEAGLEMIC_DRIVER_LICENSE_FILES = COPYING
BEAGLEMIC_DRIVER_MODULE_SUBDIRS = driver


$(eval $(kernel-module))
$(eval $(generic-package))

