################################################################################
#
# beaglemic-driver
#
################################################################################

BEAGLEMIC_DRIVER_VERSION = 345158badc8e561a63a8b6431548ac5ed5002b24
BEAGLEMIC_DRIVER_SITE = git://github.com/dinuxbg/beaglemic
BEAGLEMIC_DRIVER_LICENSE = GPL-2.0
BEAGLEMIC_DRIVER_LICENSE_FILES = COPYING
BEAGLEMIC_DRIVER_MODULE_SUBDIRS = driver


$(eval $(kernel-module))
$(eval $(generic-package))

