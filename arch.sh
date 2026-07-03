#!/bin/bash
# Filename：archlinux.sh
# /dev/sda1 为 EFI 分区、/dev/sda2 为 SWAP 交换分区、/dev/sda3 为真正的系统根分区。同时在 pacstrap 阶段自动补上了 Btrfs 必须的文件系统管理工具 btrfs-progs

# 第一阶段：在 Live ISO 环境中执行 (Ctrl+C 退出 Basic Setup 后)
#

# ==============================================================================
# 1. 准备磁盘分区与格式化
# ==============================================================================
# 检查当前的磁盘结构，确保目标磁盘为 /dev/sda
fdisk -l

# 格式化 EFI 启动分区
mkfs.fat -F 32 /dev/sda1

# 激活交换分区 (SWAP)
mkswap /dev/sda2
swapon /dev/sda2

# 格式化系统根分区为 Btrfs
mkfs.btrfs -f /dev/sda3

# ==============================================================================
# 2. 创建 Btrfs 子卷并正确挂载
# ==============================================================================
# 临时挂载 Btrfs 根目录以创建子卷
mount /dev/sda3 /mnt

# 创建标准子卷（@ 代表根目录，其他子卷用于快照时排除日志、缓存等）
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache

# 创建完成后卸载临时挂载
umount /mnt

# 设置统一的 Btrfs 挂载参数（启用 zstd 压缩、SSD 优化）
export BTRFS_OPTS="rw,noatime,compress=zstd,ssd,space_cache=v2"

# 挂载核心根目录子卷 @ 到 /mnt
mount -o ${BTRFS_OPTS},subvol=@ /dev/sda3 /mnt

# 创建新系统内部所需的挂载点目录
mkdir -p /mnt/{home,var/log,var/cache,boot}

# 将其余子卷挂载到对应的目录下
mount -o ${BTRFS_OPTS},subvol=@home /dev/sda3 /mnt/home
mount -o ${BTRFS_OPTS},subvol=@log /dev/sda3 /mnt/var/log
mount -o ${BTRFS_OPTS},subvol=@cache /dev/sda3 /mnt/var/cache

# 最后挂载 EFI 启动分区
mount /dev/sda1 /mnt/boot

# 验证所有挂载点是否完全正确
lsblk

# ==============================================================================
# 3. 配置 Live 环境的包签名并开始安装核心系统
# ==============================================================================
# 💡 Parallels M1 虚拟机的 AArch64 环境下包签名可能报错，需在安装前关闭
# 请手动编辑 Live 环境的配置文件：
# 运行：nano /etc/pacman.conf
# 找到 SigLevel = Required DatabaseOptional 并在其前面加 # 注释掉
# 并在其下方添加一行：SigLevel = Never
# 修改完成后保存退出 (Ctrl+O, Enter, Ctrl+X)

# 使用 pacstrap 安装初始包（在此处加入了 btrfs-progs 管理工具和 terminus-font）
pacstrap /mnt base base-devel linux btrfs-progs grub efibootmgr bash-completion neovim terminus-font git networkmanager

systemctl enable NetworkManager

# ==============================================================================
# 4. 生成配置并进入 chroot 新系统环境
# ==============================================================================
# 生成文件系统表并写入新系统
genfstab -U /mnt >>/mnt/etc/fstab

# 正式进入新安装的系统环境中
arch-chroot /mnt

# 第二阶段：已进入 chroot 新系统环境后执行

# ==============================================================================
# 5. 基础本地化与时间设置
# ==============================================================================
# 设置系统时区（此处以 America/Detroit 为例，可自行更改）
ln -sf /usr/share/zoneinfo/America/Detroit /etc/localtime
hwclock --systohc

# 配置语言环境
# 请手动编辑语言配置文件：
# 运行：nvim /etc/locale.gen
# 找到并取消注释这行（删掉前面的 #）： #en_US.UTF-8 UTF-8
# 保存退出后运行以下命令生成语言：
locale-gen

# 设置默认系统语言变量
echo "LANG=en_US.UTF-8" >/etc/locale.conf

# 设置您的计算机名（请将 your_hostname 替换为您喜欢的名字）
echo "your_hostname" >/etc/hostname

# ==============================================================================
# 6. 在新系统中二次关闭包签名
# ==============================================================================
# 💡 chroot 切换进新系统后，新系统内部也需要关闭一次签名，否则重启后 pacman 无法使用
# 运行：nvim /etc/pacman.conf
# 再次将 SigLevel = Required DatabaseOptional 注释掉
# 并添加一行：SigLevel = Never

# ==============================================================================
# 7. 内核、引导器与用户配置
# ==============================================================================
# 重新构建 Initramfs 镜像（可安全忽略过程中出现的 warnings 警告）
mkinitcpio -P

# 设定 root 超级管理员密码
passwd

# 安装并配置 GRUB 引导程序
grub-install --target=arm64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# systemd-boot
# bootctl install
#
# sudo mkdir -p /boot/loader/entries && sudo tee /boot/loader/loader.conf << EOF
# default   arch.conf
# timeout   5
# console-mode max
# EOF
#
# sudo tee /boot/loader/entries/arch.conf << EOF
# title   Arch Linux
# linux   /vmlinuz-linux
# initrd  /intel-ucode.img
# initrd  /initramfs-linux.img
# options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/sda3) rw
# EOF

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
linux   /vmlinuz-linux
initrd  /amd-ucode.img
initrd  /initramfs-linux.img
options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/sda3) rootflags=subvol=@,rw,noatime,compress=zstd,ssd,space_cache=v2 rw
EOF

# 创建普通用户并设置密码（请将 username 替换为您想要的用户名）
useradd -m -G wheel username
passwd username

# 为该普通用户赋予 sudo 权限
# 运行命令：EDITOR=nvim visudo
# 找到并取消注释以下这行（去掉最前面的 # 号）：
# %wheel ALL=(ALL:ALL) ALL
# 保存并退出

# ==============================================================================
# 8. 自动化网络配置 (systemd-networkd)
# ==============================================================================
# 获取虚拟网卡接口名称（原作者的名称为 enp0s5，请根据实际输出确认）
ip link

# 创建网络配置文件（此处以网卡名 enp0s5 为例，若您的不同请修改命令中的文件名）
# 请运行：nvim /etc/systemd/network/20-wired.network
# 在文件中写入以下 4 行内容后保存退出：
# [Match]
# Name=enp0s5
# [Network]
# DHCP=yes

# 链接域名解析器并启用网络服务开机自启
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
systemctl enable systemd-networkd systemd-resolved

# ==============================================================================
# 9. 结束安装并重启
# ==============================================================================
# 退出 chroot 环境
exit

# 重启虚拟机（重启前记得在 Parallels 中弹出或断开 Archboot ISO 镜像）
reboot

# 第三阶段：重启并登录到全新系统后执行

# 测试网络是否成功联网
ping -c 4 archlinux.org

# 完整同步并更新系统至最新状态
sudo pacman -Syyu

# ==============================================================================
# 10. 安装 AUR 助手 (yay)
# ==============================================================================
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
rm -rf yay

# ==============================================================================
# 11. 安装 Parallels Tools 增强工具
# ==============================================================================
# 💡 执行前，请先在 Mac 顶部的 Parallels 菜单中点击「操作 (Actions)」->「安装 Parallels Tools」
sudo pacman -S linux-headers dkms
sudo mount --mkdir /dev/cdrom /mnt/cdrom
sudo /mnt/cdrom/install
