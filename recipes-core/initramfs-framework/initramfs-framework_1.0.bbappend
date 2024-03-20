FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "\
    file://plymouth \
    file://ostree \
    file://kmod \
    file://0001-Mount-run-with-tmpfs.patch \
    file://0002-only-scan-for-block-devices.patch \
"

SRC_URI:append:cfs-support = "\
    file://composefs \
    file://80-composefs.conf \
"

PACKAGES:append = " \
    initramfs-module-plymouth \
    initramfs-module-ostree \
    initramfs-module-kmod \
"

PACKAGES:append:cfs-support = "\
    initramfs-module-composefs \
"

SUMMARY:initramfs-module-plymouth = "initramfs support for plymouth"
RDEPENDS:initramfs-module-plymouth = "${PN}-base plymouth ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'systemd-udev-rules', '', d)}"
FILES:initramfs-module-plymouth = "/init.d/02-plymouth"

SUMMARY:initramfs-module-ostree = "initramfs support for ostree based filesystems"
RDEPENDS:initramfs-module-ostree = "${PN}-base ostree-switchroot"
FILES:initramfs-module-ostree = "/init.d/95-ostree"

SUMMARY:initramfs-module-composefs = "initramfs support for booting composefs images"
RDEPENDS:initramfs-module-composefs = "${PN}-base kernel-module-erofs kernel-module-overlay"
FILES:initramfs-module-composefs = "\
    /init.d/94-composefs \
    ${nonarch_libdir}/ostree/prepare-root.conf \
"
FILES:initramfs-module-composefs:append:cfs-signed = "\
    ${sysconfdir}/ostree/initramfs-root-binding.key \
"

SUMMARY:initramfs-module-kmod = "initramfs support for loading kernel modules"
RDEPENDS:initramfs-module-kmod = "${PN}-base"
FILES:initramfs-module-kmod = "\
    /init.d/01-kmod \
    /etc/modules-load.d/* \
"

SUMMARY:initramfs-module-firmware = "initramfs support for HDMI firmware"
RDEPENDS:initramfs-module-firmware = "${PN}-base firmware-imx-hdmi"
FILES:initramfs-module-firmware = "\
    /usr/lib/firmware/* \
"

do_install:append() {
    install -m 0755 ${WORKDIR}/plymouth ${D}/init.d/02-plymouth
    install -m 0755 ${WORKDIR}/ostree ${D}/init.d/95-ostree
    install -m 0755 ${WORKDIR}/kmod ${D}/init.d/01-kmod
}

require recipes-extended/ostree/ostree-prepare-root.inc

do_install:append:cfs-support() {
    # Bundled into initramfs-module-kmod package:
    install -d ${D}/etc/modules-load.d/
    install -m 0755 ${WORKDIR}/80-composefs.conf ${D}/etc/modules-load.d/80-composefs.conf

    # Bundled into initramfs-module-composefs package:
    install -m 0755 ${WORKDIR}/composefs ${D}/init.d/94-composefs
    install -d ${D}${nonarch_libdir}/ostree/
    install -m 0644 /dev/null ${D}${nonarch_libdir}/ostree/prepare-root.conf
    write_prepare_root_config ${D}${nonarch_libdir}/ostree/prepare-root.conf
}

require recipes-extended/ostree/gen-cfs-keys.inc

generate_cfs_keys[lockfiles] += "${DEPLOY_DIR_IMAGE}/cfskeys.lock"
generate_cfs_keys() {
    gen_cfs_keys
}

CFS_INSTALL_PREFUNCS_COND ?= " generate_cfs_keys"
CFS_INSTALL_PREFUNCS ?= \
    "${@d.getVar('CFS_INSTALL_PREFUNCS_COND') if 'cfs-signed' in d.getVar('OVERRIDES') else ''}"
CFS_INSTALL_DEPENDS_COND ?= "\
    coreutils-native:do_populate_sysroot \
    openssl-native:do_populate_sysroot \
"
CFS_INSTALL_DEPENDS ?= \
    "${@d.getVar('CFS_INSTALL_DEPENDS_COND') if 'cfs-signed' in d.getVar('OVERRIDES') else ''}"

CFS_INSTALL_FILE_CHECKSUMS ?= "${@cfs_get_key_file_checksums(d)}"

do_install[prefuncs] += "${CFS_INSTALL_PREFUNCS}"
do_install[depends] += "${CFS_INSTALL_DEPENDS}"
do_install[file-checksums] += "${CFS_INSTALL_FILE_CHECKSUMS}"

do_install:append:cfs-signed() {
    # Bundled into initramfs-module-composefs package:
    install -d ${D}${sysconfdir}/ostree/
    install -m 0644 ${CFS_SIGN_KEYDIR}/${CFS_SIGN_KEYNAME}.pub \
    	            ${D}${sysconfdir}/ostree/initramfs-root-binding.key
}

# Adding modules so plymouth can show the splash screen during boot
SRC_URI:append:mx8-nxp-bsp = " file://50-imx8-graphics.conf"
RDEPENDS:initramfs-module-kmod:append:mx8-nxp-bsp = " \
    kernel-module-display-connector \
    kernel-module-lontium-lt8912b \
    kernel-module-sec-dsim \
    kernel-module-sec-mipi-dsim-imx \
    kernel-module-ti-sn65dsi83 \
"

do_install:append:mx8-nxp-bsp() {
    install -d ${D}/etc/modules-load.d/
    install -m 0755 ${WORKDIR}/50-imx8-graphics.conf ${D}/etc/modules-load.d/50-imx8-graphics.conf
}

SRC_URI:append:verdin-am62 = " file://50-am62-graphics.conf"
RDEPENDS:initramfs-module-kmod:append:verdin-am62 = " \
    kernel-module-pwm-tiehrpwm \
    kernel-module-fb-sys-fops \
    kernel-module-sysimgblt \
    kernel-module-sysfillrect \
    kernel-module-syscopyarea \
    kernel-module-drm-kms-helper \
    kernel-module-drm-dma-helper \
    kernel-module-tidss \
    kernel-module-display-connector \
    kernel-module-tc358768 \
    kernel-module-ti-sn65dsi83 \
    kernel-module-lontium-lt8912b \
"
do_install:append:verdin-am62() {
    install -d ${D}/etc/modules-load.d/
    install -m 0755 ${WORKDIR}/50-am62-graphics.conf ${D}/etc/modules-load.d/50-am62-graphics.conf
}
