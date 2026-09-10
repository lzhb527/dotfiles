#!/usr/bin/env bash
# Arch Linux installer — Btrfs + systemd-boot + zram
# Assumes: /dev/sda1 = EFI, /dev/sda2 = SWAP, /dev/sda3 = Btrfs root
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

msg() { printf "${GREEN}[==>]${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}[!]${NC} %s\n" "$*"; }
err() { printf "${RED}[x]${NC} %s\n" "$*" >&2; }

require_root() { [[ $EUID -eq 0 ]] || {
    err "Please run as root"
    exit 1
}; }

confirm() {
    local p="${1:-Continue?}"
    read -rp "$p [y/N]: " a
    [[ "$a" =~ ^[Yy]$ ]]
}

disk_check() {
    for d in /dev/sda1 /dev/sda2 /dev/sda3; do
        [[ -b "$d" ]] || {
            err "Missing block device $d"
            exit 1
        }
    done
}

disable_sig_check() {
    msg "Disable pacman signature check (Parallels AArch64 compatibility)"
    sed -i 's/^\(SigLevel.*Required.*DatabaseOptional\)/#\1\nSigLevel = Never/' /etc/pacman.conf
}

disable_sig_check_new() {
    msg "Disable signature check in the new system"
    sed -i 's/^\(SigLevel.*Required.*DatabaseOptional\)/#\1\nSigLevel = Never/' /etc/pacman.conf
}

phase1_prepare_disk() {
    msg "List disk partitions"
    fdisk -l

    confirm "Format /dev/sda1,2,3. Continue?" || {
        err "Cancelled"
        exit 1
    }

    msg "Format partitions"
    mkfs.fat -F 32 /dev/sda1
    mkswap /dev/sda2
    swapon /dev/sda2
    mkfs.btrfs -f /dev/sda3
}

phase2_create_subvol() {
    msg "Create Btrfs subvolumes"
    mount /dev/sda3 /mnt
    for s in @ @home @log @cache; do
        btrfs subvolume create "/mnt/$s"
    done
    umount /mnt
}

phase3_mount() {
    msg "Mount subvolumes and EFI"
    local BTRFS_OPTS="rw,noatime,compress=zstd:3,ssd,space_cache=v2,autodefrag,discard=async"
    mount -o "${BTRFS_OPTS},subvol=@" /dev/sda3 /mnt
    mkdir -p /mnt/{home,var/log,var/cache,boot}
    mount -o "${BTRFS_OPTS},subvol=@home" /dev/sda3 /mnt/home
    mount -o "${BTRFS_OPTS},subvol=@log" /dev/sda3 /mnt/var/log
    mount -o "${BTRFS_OPTS},subvol=@cache" /dev/sda3 /mnt/var/cache
    mount /dev/sda1 /mnt/boot

    lsblk
}

phase4_pacstrap() {
    msg "pacstrap: install base packages"
    pacstrap /mnt \
        base base-devel linux btrfs-progs \
        bash-completion nano sudo vim \
        neovim terminus-font git networkmanager

    msg "Generate fstab"
    genfstab -U /mnt >>/mnt/etc/fstab
}

phase5_copy_scripts() {
    local dir
    dir="$(dirname "$0")"
    cp "$dir/chroot2.sh" /mnt/chroot2.sh
    chmod +x /mnt/chroot2.sh
}

phase6_chroot() {
    msg "Enter chroot and run phase 2"
    arch-chroot /mnt /bin/bash /chroot2.sh
    rm -f /mnt/chroot2.sh
}

main() {
    require_root
    disk_check

    warn "This script will erase all data on /dev/sda1,2,3"
    confirm "Start installation?" || exit 1

    disable_sig_check
    phase1_prepare_disk
    phase2_create_subvol
    phase3_mount
    phase4_pacstrap
    phase5_copy_scripts
    phase6_chroot

    msg "=== Installation complete ==="
    warn "Run: umount -R /mnt && reboot (eject the install ISO before reboot)"
}

main "$@"
