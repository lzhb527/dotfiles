#!/usr/bin/env bash
# Phase 2: runs inside chroot
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

msg() { printf "${GREEN}[==>]${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}[!]${NC} %s\n" "$*"; }
err() { printf "${RED}[x]${NC} %s\n" "$*" >&2; }

read -rp "Enter hostname: " HOSTNAME
[[ -n "$HOSTNAME" ]] || {
    err "Hostname cannot be empty"
    exit 1
}

read -rp "Enter username: " USERNAME
[[ -n "$USERNAME" ]] || {
    err "Username cannot be empty"
    exit 1
}

disable_sig_check() {
    sed -i 's/^\(SigLevel.*Required.*DatabaseOptional\)/#\1\nSigLevel = Never/' /etc/pacman.conf
}

set_timezone() {
    msg "Set timezone -> America/Detroit"
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    hwclock --systohc
}

set_locale() {
    msg "Generate locale and write /etc/locale.conf"
    sed -i -e 's/^#\(en_US.UTF-8 UTF-8\)/\1/' \
        -e 's/^#\(zh_CN.UTF-8 UTF-8\)/\1/' \
        -e 's/^#\(zh_TW.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" >/etc/locale.conf
}

set_hostname() {
    msg "Set hostname -> $HOSTNAME"
    echo "$HOSTNAME" >/etc/hostname
    cat >/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF
}

setup_zram() {
    msg "Install and configure zram"
    pacman -S --noconfirm zram-generator

    cat >/etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
swap-priority = 100
EOF

    echo "vm.swappiness = 100" >/etc/sysctl.d/99-zram.conf
}

mkinitcpio_build() {
    msg "Rebuild initramfs"
    mkinitcpio -P
}

setup_bootloader() {
    msg "Install systemd-boot"
    bootctl install

    tee /boot/loader/loader.conf >/dev/null <<EOF
default   arch.conf
timeout   15
console-mode max
EOF

    local partuuid
    partuuid=$(blkid -s PARTUUID -o value /dev/sda3)

    tee /boot/loader/entries/arch.conf >/dev/null <<EOF
title   Arch Linux
linux   /Image
initrd  /initramfs-linux.img
options root=PARTUUID=$partuuid rootflags=subvol=@,rw,noatime,compress=zstd:3,ssd,discard=async,autodefrag,space_cache=v2 video=1440x900@60
EOF
}

set_root_pass() {
    msg "Set root password"
    while true; do
        read -rsp "root password: " p1
        echo
        read -rsp "Confirm: " p2
        echo
        [[ "$p1" == "$p2" && -n "$p1" ]] || {
            err "Mismatch or empty"
            continue
        }
        echo "root:$p1" | chpasswd
        break
    done
}

create_user() {
    msg "Create user $USERNAME"
    useradd -m -G wheel "$USERNAME"
    while true; do
        read -rsp "$USERNAME password: " p1
        echo
        read -rsp "Confirm: " p2
        echo
        [[ "$p1" == "$p2" && -n "$p1" ]] || {
            err "Mismatch or empty"
            continue
        }
        echo "$USERNAME:$p1" | chpasswd
        break
    done

    msg "Enable sudo for wheel group"
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
}

enable_services() {
    msg "Enable NetworkManager"
    systemctl enable NetworkManager
}

main() {
    disable_sig_check
    set_timezone
    set_locale
    set_hostname
    setup_zram
    mkinitcpio_build
    setup_bootloader
    set_root_pass
    create_user
    enable_services

    msg "=== chroot configuration complete ==="
    warn "Return to outer script: exit && umount -R /mnt && reboot"
}

main "$@"
