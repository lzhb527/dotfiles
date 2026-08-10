#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

msg()  { printf "${GREEN}[==>]${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}[!]${NC} %s\n" "$*"; }
err()  { printf "${RED}[x]${NC} %s\n" "$*" >&2; }

read -rp "请输入主机名: " HOSTNAME
[[ -n "$HOSTNAME" ]] || { err "主机名不能为空"; exit 1; }

read -rp "请输入用户名: " USERNAME
[[ -n "$USERNAME" ]] || { err "用户名不能为空"; exit 1; }

read -rsp "为 $USERNAME 设置密码: " USER_PASS; echo
read -rsp "再次输入密码: " USER_PASS2; echo
[[ "$USER_PASS" == "$USER_PASS2" ]] || { err "两次密码不一致"; exit 1; }

read -rsp "设置 root 密码: " ROOT_PASS; echo
read -rsp "再次输入 root 密码: " ROOT_PASS2; echo
[[ "$ROOT_PASS" == "$ROOT_PASS2" ]] || { err "两次密码不一致"; exit 1; }

set_timezone() {
    msg "设置时区为 Asia/Shanghai"
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    hwclock --systohc
}

set_locale() {
    msg "配置 locale"
    sed -i 's/^#\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    sed -i 's/^#\(zh_CN.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
}

set_keymap_and_font() {
    msg "设置控制台字体与键盘布局"
    echo "KEYMAP=us" > /etc/vconsole.conf
    echo "FONT=ter-v32b" >> /etc/vconsole.conf
}

set_hostname() {
    msg "设置主机名: $HOSTNAME"
    echo "$HOSTNAME" > /etc/hostname
    cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF
}

set_root_password() {
    msg "设置 root 密码"
    echo "root:$ROOT_PASS" | chpasswd
}

set_user_password() {
    msg "创建用户并设置密码"
    useradd -m -G wheel,audio,video,optical,storage,power -s /bin/bash "$USERNAME"
    echo "$USERNAME:$USER_PASS" | chpasswd
}

configure_sudo() {
    msg "配置 sudo（wheel 组免密）"
    sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
}

enable_services() {
    msg "启用 NetworkManager 与 systemd-resolved"
    systemctl enable NetworkManager
    systemctl enable systemd-resolved
}

install_bootloader() {
    msg "安装 systemd-boot"
    bootctl install --esp=/boot

    cat > /boot/loader/loader.conf <<EOF
default arch
timeout 3
console-mode max
editor no
EOF

    local root_uuid
    root_uuid=$(blkid -s UUID -o value "$(findmnt -n -o SOURCE /)")

    cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /amd-ucode.img
initrd  /initramfs-linux.img
options root=UUID=$root_uuid rootfstype=btrfs rootflags=subvol=@ quiet splash
EOF

    [[ -f /boot/intel-ucode.img ]] || {
        sed -i '/intel-ucode/d' /boot/loader/entries/arch.conf;
    }
    [[ -f /boot/amd-ucode.img ]] || {
        sed -i '/amd-ucode/d' /boot/loader/entries/arch.conf;
    }

    msg "systemd-boot 安装完成"
}

install_mkinitcpio_hooks() {
    msg "配置 mkinitcpio 钩子（btrfs + systemd 自动检测）"
    sed -i 's/^HOOKS=.*/HOOKS=(base systemd autodetect modconf kms keyboard sd-vconsole block filesystems btrfs fsck)/' /etc/mkinitcpio.conf
    mkinitcpio -P
}

set_pacman() {
    msg "启用 pacman 平行下载与彩色输出"
    sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
    sed -i 's/^#Color/Color/' /etc/pacman.conf
    sed -i '/^#\[multilib\]/,/^#Include/ { s/^#// }' /etc/pacman.conf
}

main() {
    set_timezone
    set_locale
    set_keymap_and_font
    set_hostname
    set_root_password
    set_user_password
    configure_sudo
    set_pacman
    enable_services
    install_mkinitcpio_hooks
    install_bootloader

    msg "=== chroot 配置完成 ==="
    warn "请回到外层脚本完成卸载与重启"
}

main "$@"
