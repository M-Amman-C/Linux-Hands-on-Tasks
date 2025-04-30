#!/bin/bash

echo -e "\n\n\t\t------------------------------Task - 1------------------------------\n\n"


# Q-1
last -s -60min | grep -q root && echo -e "\n\nLogin and Switch to root user: ✅ Correct" || echo -e "\n\nLogin and Switch to root user: ❌ Wrong"

# Q-2
echo -e "\n\nCreate a directory called logbackup: "
ls /root/ | grep logbackup &>/dev/null && echo "✅ Correct" || echo "❌ Wrong"

# Q-3
echo -e "\n\nCopy all .log files from /var/log to logbackup: "


[[ $(ls -l /var/log/*.log | wc -l)==$(ls -l /root/logbackup/* | wc -l) ]] && echo "✅ Correct" || echo "❌ Wrong" 

# Q-4
echo -e "\n\nCreate a compressed archive named logs.tar.gz from the logbackup directory: "
ls /root/ | grep logs.tar.gz &>/dev/null && echo "✅ Correct" || echo "❌ Wrong"


# Q-6
echo -e "\n\nRedirect the above result into a file called error_report.txt in your home directory: "
[ -s "$HOME/error_report.txt" ] && grep -iq "error" "$HOME/error_report.txt" && echo "✅ Found" || echo " ❌ Empty or no 'error' found"

# Q-7
echo -e "\n\nAlso, redirect any errors to a separate file errors.log: "
[ -s "$HOME/errors.log" ] && echo "✅ Exists" || echo " ❌ Not found or empty"

# Q-8
echo -e "\n\nCreate A hard link to logs.tar.gz named logs_backup_link: "
[ -f "$HOME/logs_backup_link" ] && [ "$(stat --format='%i' $HOME/logs.tar.gz)" = "$(stat --format='%i' $HOME/logs_backup_link)" ] && echo "✅ Valid hard link" || echo "❌ Hard link invalid"

# Q-9
echo -e "A soft link named latest_logs.tar.gz pointing to the same archive:"
[ -L "$HOME/latest_logs.tar.gz" ] && [ "$(readlink $HOME/latest_logs.tar.gz)" = "/root/logs.tar.gz" ] && echo "✅ Valid soft link" || echo "❌ Soft link invalid"


# Q-11
echo -e "\n\nChange its permissions to rw-r-----: "
perm=$(stat -c "%A" "$HOME/logs.tar.gz")
[ "$perm" = "-rw-r-----" ] && echo "✅ Correct permissions ($perm)" || echo "❌ Incorrect permissions ($perm)"



echo -e "\n\n\t\t------------------------------Task - 2------------------------------\n\n"


HIST_FILE=/var/log/command_history.log


# Q-1
echo -e "\n\n# Q-1\nStart a dummy process (yes > /dev/null) in the background: "
grep -E "yes\s+>\s*/dev/null\s*&?" "$HIST_FILE" &>/dev/null && echo "✅ Correct" || echo "❌ Wrong"

# Q-2
echo -e "\n\n# Q-2\nCheck and lower its priority to 5 (using renice or nice): "
grep -E "renice\s+5\s+|nice\s+-n\s+5\s+" "$HIST_FILE" &>/dev/null && echo "✅ Correct" || echo "❌ Wrong"

# Q-3
echo -e "\n\n# Q-3\nView current tuning profile: "
grep -E "tuned-adm\s+active" "$HIST_FILE" &>/dev/null && echo "✅ Correct" || echo "❌ Wrong"

# Q-4
echo -e "\n\n# Q-4\nSwitch to a performance-oriented profile named “throughput-performance”: "
grep -E "tuned-adm\s+profile\s+throughput-performance" "$HIST_FILE" && echo "✅ Correct" || echo "❌ Wrong"

# Q-5
test_messageecho -e "\n\n# Q-5\nView logs from the last boot using journalctl: "
grep -E "journalctl\s+--boot|journalctl\s+-b" "$HIST_FILE" &>/dev/null && echo "✅ Correct" || echo "❌ Wrong"

# Q-6
echo -e "\n\n# Q-6\nFilter logs by service name (sshd): "
grep -E "journalctl\s+.*-u\s+sshd" "$HIST_FILE" &>/dev/null && echo "✅ Correct" || echo "❌ Wrong"

# Q-7
echo -e "\n\n# Q-7\nSave logs to a file named sshd_logs.txt: "
grep -iE "journalctl.*sshd.*.*sshd_logs\.txt.*" "$HIST_FILE" &>/dev/null && echo "✅ Correct" || echo "❌ Wrong"

# Q-8
echo -e "\n\n# Q-8\nConfigure persistent logging of journald (edit config): "
cat /etc/systemd/journald.conf | grep "Storage=persistent" &>/dev/null && echo "✅ Correct" || echo "❌ Wrong"



echo -e "\n\n\t\t------------------------------Task - 3------------------------------\n\n"


# Q-1
echo -e "\n\n# Q-1: List all available disks and partitions (Check for /dev/sdb)"
grep -E "lsblk|fdisk -l|parted -l" "$HIST_FILE" &>/dev/null && echo "✅ Correct" || echo "❌ Wrong"


# Q-2
echo -e "\n\n# Q-2: Create a new primary partition of at least 1GB on /dev/sdb"
lsblk -b /dev/sdb | awk '$4 >= 1000000000 && $1 ~ /sdb[0-9]/' | grep -q "sdb" && echo "✅ Correct" || echo "❌ Wrong"


# Q-4
echo -e "\n\n# Q-4: Create a volume group called vg_storage"
vgs | grep -q "vg_storage" && echo "✅ Correct" || echo "❌ Wrong"


# Q-5
echo -e "\n\n# Q-5: Create a 512MB logical volume called lv_data in vg_storage"
lvs --units m --nosuffix | awk '$1 == "lv_data" && $2 == "vg_storage" && $4 >= 500 && $4 <= 600' | grep -q "lv_data" && echo "✅ Correct" || echo "❌ Wrong"


# Q-6
echo -e "\n\n# Q-6: Format the logical volume with ext4"
blkid -o value -s TYPE /dev/vg_storage/lv_data 2>/dev/null | grep -q "ext4" && echo "✅ Correct" || echo "❌ Wrong"


# Q-7
echo -e "\n\n# Q-7: Create a mount point /mnt/data"
[ -d "/mnt/data" ] && echo "✅ Correct" || echo "❌ Wrong"


# Q-8
echo -e "\n\n# Q-8: Mount it permanently (Check /etc/fstab for /mnt/data)"
grep -q "/mnt/data" /etc/fstab && echo "✅ Correct" || echo "❌ Wrong"



echo -e "\n\n\t\t------------------------------Task - 4------------------------------\n\n"



# Q-1
echo -e "\n\n# Q-1: Ensure firewalld is running"
systemctl is-active firewalld &>/dev/null && echo "✅ Correct" || echo "❌ Wrong"

# Q-2
echo -e "\n\n# Q-2: Add a rule to allow only SSH (port 22)"
firewall-cmd --list-all | grep -q 'ssh' && echo "✅ Correct" || echo "❌ Wrong"

# Q-3
echo -e "\n\n# Q-3: Block HTTP traffic explicitly (port 80)"
firewall-cmd --list-all | grep -q 'http' && echo "❌ Wrong (HTTP still allowed)" || echo "✅ Correct (HTTP blocked)"

# Q-4
echo -e "\n\n# Q-4: Verify that only SSH is allowed and HTTP is blocked"

firewall-cmd --list-services | grep -qw 'ssh' && SSH_OK=1 || SSH_OK=0
firewall-cmd --list-services | grep -qw 'http' && HTTP_OK=0 || HTTP_OK=1

[[ $SSH_OK -eq 1 && $HTTP_OK -eq 1 ]] && echo "✅ Correct" || echo "❌ Wrong"


# Q-5
echo -e "\n\n# Q-5: Change the default system target to no GUI (multi-user.target)"
systemctl get-default | grep -q 'multi-user.target' && echo "✅ Correct" || echo "❌ Wrong"



echo -e "\n\n\t\t------------------------------Task - 5------------------------------\n\n"

sudo dnf install sshpass -y &>/dev/null

check_user(){
	username=$1
	
	if id $username &> /dev/null; then
		echo "✅ User exists"
	else
		echo "❌ Wrong"
	fi
}

check_home(){
	username=$1
	expected_home=$2
	actual_home=$(getent passwd $username | cut -d: -f6)
	[[ -d "$actual_home" ]] && {
		[[ "$expected_home" == "$actual_home" ]] && echo "✅ User home correct" || echo "❌ User home incorrect"
	} || echo "❌ Home directory does not exist"
}

check_shell(){
	username=$1
	expected_shell=$2
	actual_shell=$(getent passwd $username | cut -d: -f7)
	[[ "$expected_shell" == "$actual_shell" ]] && echo "✅ User shell correct" || echo "❌ User shell incorrect"
}


check_comment(){
	username=$1
	expected_comment=$2
	actual_comment=$(getent passwd $username | cut -d: -f5)
	[[ "$expected_comment" == "$actual_comment" ]] && echo "✅ User comment correct" || echo "❌ User comment incorrect"
}

check_chage_policy() {
        username="$1"
        max_days="$2"
        min_days="$3"
	warn_days="$4"


        actual_max=$(chage -l "$username" | grep "Maximum" | awk -F: '{print $2}' | xargs)
        actual_min=$(chage -l "$username" | grep "Minimum" | awk -F: '{print $2}' | xargs)
        actual_warn=$(chage -l "$username" | grep "warning" | awk -F: '{print $2}' | xargs)



        [[ "$actual_max" == "$max_days" ]] && echo "✅ $username has correct max days: $max_days" || echo "❌ $username has incorrect max days: $actual_max"
        [[ "$actual_min" == "$min_days" ]] && echo "✅ $username has correct min days: $min_days" || echo "❌ $username has incorrect min days: $actual_min"
        [[ "$actual_warn" == "$warn_days" ]] && echo "✅ $username has correct warn days: $warn_days" || echo "❌ $username has incorrect warn days: $actual_warn"

}

check_group() {
	username=$1
	id -nG "$username" | grep -qw "$group" && echo "$username is in group $group" || echo "$username is not in group $group"
}

#Q-1

echo -e "\n\n# Q-1: Create user developer1"
check_user "developer1"

echo -e "\n\t\tHome directory at /devhome/developer1: "
check_home "developer1" "/devhome/developer1"

echo -e "\n\t\tDefault shell /bin/bash:"
check_shell "developer1" "/bin/bash"

echo -e "\n\t\tCustom comment \"Frontend Developer\""
check_comment "developer1" "Frontend Developer"

echo -e "\n\t\tSet a password for developer1 as \"creator\""

result=$( sshpass -p "creator" ssh -o StrictHostKeyChecking=no developer1@localhost exit)
    if [[ "$result" =~ "Permission denied" ]]; then
        echo "❌ Wrong"  # Password incorrect
    else
        echo "✅ Correct"  # Password correct
    fi

#Q-2

echo -e "\n\nSet password aging policy"
check_chage_policy developer1  90 1 7

#Q-3

echo -e "\n\nCreate three groups: devops,qa and design: "
grep -q 'devops' /etc/group && grep -q 'qa' /etc/group && grep -q 'design' /etc/group && \
echo "✅ Correct (Groups devops, qa, and design created)" || echo "❌ Wrong (One or more groups are missing)"


#Q-4

echo -e "\n\n# Q-5: Add developer1 to devops and qa groups: "
grep -Eq "usermod.*(-aG.*(devops,qa|qa,devops).*(developer1)|developer1.*-aG.*(devops,qa|qa,devops))" "$HIST_FILE" || \
( grep -Eiq "usermod.*(-aG.*devops.*developer1|developer1.*-aG.*devops)" "$HIST_FILE" && \
  grep -Eiq "usermod.*(-aG.*qa.*developer1|developer1.*-aG.*qa)" "$HIST_FILE" ) && \
echo "✅ Correct" || echo "❌ Wrong"

#Q-5

echo -e "\n\nRemove developer1 from qa:"
id -nG "developer1" | grep -qw "qa" && echo "❌ Wrong" || echo "✅ Correct"


#Q-6

echo -e "\n\nAdd a new user adminuser set password as admin: "
check_user "adminuser"

#Q-7
echo -e "\n\nMake sure that adminuser can run commands like the root user does"
sudo -lU adminuser | grep -q 'ALL' 2>/dev/null && echo "✅ Correct (adminuser can run commands like root)" || echo "❌ Wrong (adminuser cannot run commands like root)"


