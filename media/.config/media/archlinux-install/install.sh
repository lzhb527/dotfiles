#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

msg()  { printf "${GREEN}[==>]${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}[!]${NC} %s\n" "$*"; }
err()  { printf "${RED}[x]${NC} %s\n" "$*" >&2; }

require_root() {
    [[ $EUID -eq 0 ]] || { err "请以 root 身份运行此脚本"; exit 1; }
}

confirm() {
    local prompt="$1"
    read -rp "$prompt [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

check_uefi() {
    [[ -d /sys/firmware/efi/efivars ]] || {
        err "未检测到 UEFI，此脚本仅支持 UEFI 启动"; exit 1;
    }
    msg "已检测到 UEFI 模式"
}

select_disk() {
    lsblk -d -n -o NAME,SIZE,MODEL | grep -v "loop\|rom" || true
    echo
    read -rp "请输入目标磁盘（例如 /dev/sda 或 /dev/nvme0n1）: " DISK
    [[ -b "$DISK" ]] || { err "磁盘 $DISK 不存在"; exit 1; }

    if confirm "确认将抹除 $DISK 上的所有数据？"; then
        :
    else
        err "已取消"; exit 1
    fi
}

partition_disk() {
    msg "对 $DISK 进行分区（EFI 512M + 剩余 Btrfs）"
    sgdisk --zap-all "$DISK"
    sgdisk -n 1:0:+512M -t 1:EF00 -c 1:"EFI System" "$DISK"
    sgdisk -n 2:0:0      -t 2:8300 -c 2:"Linux filesystem" "$DISK"

    if [[ "$DISK" =~ "nvme" ]]; then
        PART_EFI="${DISK}p1"; PART_ROOT="${DISK}p2"
    else
        PART_EFI="${DISK}1";  PART_ROOT="${DISK}2"
    fi

    sleep 2
    partprobe "$DISK" || true
    [[ -b "$PART_EFI" && -b "$PART_ROOT" ]] || { err "分区失败"; exit 1; }
}

format_partitions() {
    msg "格式化 EFI 分区为 FAT32"
    mkfs.fat -F32 "$PART_EFI"

    msg "格式化根分区为 Btrfs"
    mkfs.btrfs -f -L "ArchLinux" "$PART_ROOT"
}

create_subvolumes() {
    msg "挂载 Btrfs 顶层子卷以创建子卷"
    mount "$PART_ROOT" /mnt

    for sub in @ @home @cache @log; do
        btrfs subvolume create "/mnt/$sub"
    done

    umount /mnt
}

mount_subvolumes() {
    msg "挂载子卷（启用压缩、autodefrag、discard）"
    local opts="compress=zstd:3,noatime,ssd,space_cache=v2,autodefrag,discard=async"

    mount -o "subvol=@,$opts"      "$PART_ROOT" /mnt
    mkdir -p /mnt/{home,boot,var/cache,var/log}
    mount "$PART_EFI" /mnt/boot

    mount -o "subvol=@home,$opts"  "$PART_ROOT" /mnt/home
    mount -o "subvol=@cache,$opts" "$PART_ROOT" /mnt/var/cache
    mount -o "subvol=@log,$opts"   "$PART_ROOT" /mnt/var/log

    msg "挂载结果："
    findmnt -R /mnt || true
}

install_base() {
    msg "安装基础系统与常用工具"
    pacstrap -K /mnt \
        base linux linux-firmware linux-headers \
        btrfs-progs efibootmgr \
        networkmanager vim nano sudo \
        base-devel git wget curl \
        intel-ucode amd-ucode \
        terminus-font
}

generate_fstab() {
    msg "生成 fstab"
    genfstab -U /mnt >> /mnt/etc/fstab
    msg "fstab 已生成"
}

copy_chroot_script() {
    msg "复制 chroot 配置脚本到新系统"
    cp "$(dirname "$0")/chroot.sh" /mnt/chroot.sh
    chmod +x /mnt/chroot.sh
}

run_chroot() {
    msg "进入 chroot 执行系统配置"
    arch-chroot /mnt /bin/bash /chroot.sh
    rm -f /mnt/chroot.sh
}

main() {
    require_root
    check_uefi

    msg "=== Arch Linux Btrfs 安装脚本 ==="
    warn "此脚本将完全擦除所选磁盘上的所有数据"
    confirm "是否继续？" || { err "已取消"; exit 1; }

    select_disk
    partition_disk
    format_partitions
    create_subvolumes
    mount_subvolumes
    install_base
    generate_fstab
    copy_chroot_script
    run_chroot

    msg "=== 安装完成 ==="
    warn "请执行：umount -R /mnt && reboot"
}

main "$@"
