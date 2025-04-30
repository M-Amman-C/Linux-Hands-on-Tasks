#!/bin/bash

# Ensure root user
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

echo "----- Starting Cleanup -----"

# ===========
# Task 1 Cleanup
# ===========

echo "Cleaning up Task 1..."

rm -rf /root/logbackup
rm -f /root/logs.tar.gz /root/logs_backup_link /root/latest_logs.tar.gz
rm -f /root/error_report.txt /root/errors.log /root/boot_logs.txt /root/sshd_logs.txt

# ===========
# Task 2 Cleanup
# ===========

echo "Cleaning up Task 2..."

# Kill the dummy "yes" process if running
pkill -f "yes > /dev/null"
if pgrep yes > /dev/null; then
    yes_id=$(pgrep yes)
    pkill yes
    echo "Killed 'yes' process with PID(s): $yes_id"
else
    echo "No 'yes' process running."
fi

# Restore tuning profile
tuned-adm profile balanced

# Disable persistent journal
sed -i 's/^Storage=persistent/#Storage=auto/' /etc/systemd/journald.conf
systemctl restart systemd-journald
rm -rf /var/log/journal

# ===========
# Task 3 Cleanup
# ===========

echo "Cleaning up Task 3..."

umount /mnt/data
sed -i '/\/mnt\/data/d' /etc/fstab
rm -rf /mnt/data

lvremove -y /dev/vg_storage/lv_data
vgremove -y vg_storage
pvremove -y /dev/sdb1

# Optionally remove partition from /dev/sdb (WARNING: irreversible)

last_partition=$(lsblk -n -o NAME /dev/sdb | tail -n 1)

if [ "$last_partition" == "└─sdb1" ]; then
    echo "Last partition is /dev/sdb1. Proceeding to delete it."

    # Delete the partition and write changes
    echo -e "d\nw" | fdisk /dev/sdb
    echo "/dev/sdb1 partition deleted successfully."
else
    echo "Last partition is not /dev/sdb1. Skipping deletion."
fi

partprobe /dev/sdb

# ===========
# Task 4 Cleanup
# ===========

echo "Cleaning up Task 4..."

# Restore firewalld to default
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

# Set GUI back (if needed)
systemctl set-default graphical.target

# ===========
# Task 5 Cleanup
# ===========

echo "Cleaning up Task 5..."

# Remove users and home
userdel -r developer1
userdel -r adminuser

# Remove groups
groupdel devops
groupdel qa
groupdel design

# Remove custom home directory if still exists
rm -rf /devhome/developer1

echo "Cleanup completed successfully!"

