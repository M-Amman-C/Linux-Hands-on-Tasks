#!/bin/bash

# ======================
# Task 1: Log Management
# ======================

echo "" > /root/command_history.log
echo "----- Task 1 -----"

# Create backup directory
mkdir -p /root/logbackup

# Copy .log files, redirect errors to errors.log
cp /var/log/*.log /root/logbackup 2> /root/errors.log

# Only create archive if directory is not empty
if [ "$(ls -A /root/logbackup)" ]; then
    tar -czf /root/logs.tar.gz -C /root logbackup
else
    echo "No .log files found to archive." >> /root/errors.log
fi

# Check if /var/log/syslog exists before grepping
if [ -f /var/log/syslog ]; then
    grep -i "error" /var/log/syslog > /root/error_report.txt 2>> /root/errors.log
else
    echo "Error: /var/log/syslog not found." >> /root/errors.log
    echo "No syslog file found to search errors." > /root/error_report.txt
fi

# Create links only if archive was created
if [ -f /root/logs.tar.gz ]; then
    ln /root/logs.tar.gz /root/logs_backup_link
    ln -s /root/logs.tar.gz /root/latest_logs.tar.gz

    # List permissions and change them
    ls -l /root/logs.tar.gz
    chmod 640 /root/logs.tar.gz
else
    echo "logs.tar.gz not found, skipping linking and chmod." >> /root/errors.log
fi

# ========================
# Task 2: System Tuning
# ========================

echo "----- Task 2 -----"

# Start a dummy process
yes > /dev/null &
DUMMY_PID=$!
renice 5 -p $DUMMY_PID

# View and switch tuning profile
tuned-adm active
tuned-adm profile throughput-performance

# Use journalctl
journalctl -b > /root/boot_logs.txt
journalctl -u sshd > /root/sshd_logs.txt

# Enable persistent logging
mkdir -p /var/log/journal
sed -i 's/^#Storage=.*/Storage=persistent/' /etc/systemd/journald.conf
systemctl restart systemd-journald

# ================================
# Task 3: Disk and LVM Management
# ================================

echo "----- Task 3 -----"

lsblk

# Create partition (automated using fdisk)
echo -e "g\nw" | fdisk /dev/sdb
echo -e "o\nn\np\n1\n\n+1G\nw" | fdisk /dev/sdb
partprobe /dev/sdb

# Create physical volume, volume group and logical volume
pvcreate /dev/sdb1
vgcreate vg_storage /dev/sdb1
lvcreate -L 512M -n lv_data vg_storage
wipefs -a /dev/vg_storage/lv_data
mkfs.ext4 -F /dev/vg_storage/lv_data

mkdir -p /mnt/data

# Add to fstab for permanent mount
echo "/dev/vg_storage/lv_data /mnt/data ext4 defaults 0 0" >> /etc/fstab
mount -a

# ====================
# Task 4: Firewall
# ====================

echo "----- Task 4 -----"

systemctl start firewalld
systemctl enable firewalld

firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --remove-service=http
firewall-cmd --reload
firewall-cmd --list-all

# Set system to non-GUI (multi-user.target)
systemctl set-default multi-user.target

# ====================
# Task 5: User Management
# ====================

echo "----- Task 5 -----"

# Create user developer1
useradd -m -d /devhome/developer1 -s /bin/bash -c "Frontend Developer" developer1
echo "developer1:creator" | chpasswd

# Set password aging policy
chage -m 1 -M 90 -W 7 developer1

# Create groups
groupadd devops
groupadd qa
groupadd design

usermod -aG devops,qa developer1
gpasswd -d developer1 qa

# Add adminuser with sudo access
useradd adminuser
echo "adminuser:admin" | chpasswd
usermod -aG wheel adminuser

echo "Script completed successfully!"

cat /root/linuxlab/solution.sh > /var/log/command_history.log
