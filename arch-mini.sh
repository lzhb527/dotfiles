#!/bin/bash
# /dev/sda1 为 EFI 分区、/dev/sda2 为 SWAP 交换分区、/dev/sda3 为真正的系统根分区。pacstrap 阶段 Btrfs 必须的文件系统管理工具 btrfs-progs
fdisk -l
mkfs.fat -F 32 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mkfs.btrfs -f /dev/sda3

mount /dev/sda3 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
umount /mnt

export BTRFS_OPTS="rw,noatime,compress=zstd,ssd,space_cache=v2"
mount -o ${BTRFS_OPTS},subvol=@ /dev/sda3 /mnt
mkdir -p /mnt/{home,var/log,var/cache,boot}
mount -o ${BTRFS_OPTS},subvol=@home /dev/sda3 /mnt/home
mount -o ${BTRFS_OPTS},subvol=@log /dev/sda3 /mnt/var/log
mount -o ${BTRFS_OPTS},subvol=@cache /dev/sda3 /mnt/var/cache

mount /dev/sda1 /mnt/boot

lsblk
# 💡 Parallels M1 虚拟机的 AArch64 环境下包签名可能报错，需在安装前关闭
# 运行：nano /etc/pacman.conf
# 找到 SigLevel = Required DatabaseOptional 并在其前面加 # 注释掉
# 并在其下方添加一行：SigLevel = Never

pacstrap /mnt base base-devel linux btrfs-progs grub efibootmgr bash-completion neovim terminus-font git networkmanager

genfstab -U /mnt >>/mnt/etc/fstab
arch-chroot /mnt

# 第二阶段：已进入 chroot 新系统环境后执行
ln -sf /usr/share/zoneinfo/America/Detroit /etc/localtime
hwclock --systohc

# 运行：nvim /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" >/etc/locale.conf
echo "your_hostname" >/etc/hostname

# 💡 chroot 切换进新系统后，新系统内部也需要关闭一次签名，否则重启后 pacman 无法使用
# 运行：nvim /etc/pacman.conf
# 再次将 SigLevel = Required DatabaseOptional 注释掉
# 并添加一行：SigLevel = Never

mkinitcpio -P

# 设定 root 超级管理员密码
passwd

# btrfs
# 1. 安装引导程序
bootctl install
# 2. 生成加载配置
tee /boot/loader/loader.conf <<EOF
default   arch.conf
timeout   5
console-mode max
EOF
# 3. 生成启动条目（自动注入 PARTUUID 与 Btrfs 优化挂载参数）
tee /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /Image
initrd  /initramfs-linux.img
options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/sda3) rootflags=subvol=@,rw,noatime,compress=zstd,ssd,space_cache=v2 rw video=1440x900@60
EOF

# 创建普通用户并设置密码（请将 username 替换为您想要的用户名）
useradd -m -G wheel username
passwd username
# %wheel ALL=(ALL:ALL) ALL

# 退出 chroot 环境
exit

# 重启虚拟机（重启前记得在 Parallels 中弹出或断开 Archboot ISO 镜像）
reboot
