LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = " \
    file://initial-support-for-docker-compose-secondaries.patch \
"

SRCREV = "505627bbf4e38f49693c898ebfbca98d116c6718"
