#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Script needs root. Re-running with sudo..."
  exec sudo "$0" "$@"
fi



# Functions
results="{\"maximum_marks\": 200, \"obtained_maximum_marks\": 0, \"tasks\": []}"

if ! command -v jq &> /dev/null; then
    echo "jq not found, installing..."
    sudo apt install -y jq
fi

if ! command -v sshpass &> /dev/null; then
    echo "sshpass not found, installing..."
    sudo apt install -y sshpass
fi


#---------------------------------------------------------------------Tests-------------------------------------------------------------

#-------------------------------------------------Task 1---------------------------------------------

test1_obtained_marks=0
failed_properties=()

# Q-1: Check if root has logged in within the last 60 minutes
if last -s -60min | grep -q root; then
    test1_obtained_marks=$((test1_obtained_marks + 5))
else
    failed_properties+=("Question 1")
fi

# Q-2: Check if directory logbackup exists in /root
if ls /root/ | grep -q logbackup; then
    test1_obtained_marks=$((test1_obtained_marks + 5))
else
    failed_properties+=("Question 2")
fi

# Q-3: Check if .log files copied to logbackup match in number
log_files_count=$(ls /var/log/*.log 2>/dev/null | wc -l)
backup_files_count=$(ls /root/logbackup/* 2>/dev/null | wc -l)

if [ "$log_files_count" -eq "$backup_files_count" ]; then
    test1_obtained_marks=$((test1_obtained_marks + 5))
else
    failed_properties+=("Question 3")
fi

# Q-4: Check if logs.tar.gz archive is created in /root
if [ -f /root/logs.tar.gz ]; then
    test1_obtained_marks=$((test1_obtained_marks + 5))
else
    failed_properties+=("Question 4")
fi

# Q-6: Check if error_report.txt in HOME exists and contains 'error'
if [ -s "$HOME/error_report.txt" ] && grep -iq "error" "$HOME/error_report.txt"; then
    test1_obtained_marks=$((test1_obtained_marks + 5))
else
    failed_properties+=("Question 6")
fi

# Q-7: Check if errors.log exists and is non-empty
if [ -s "$HOME/errors.log" ]; then
    test1_obtained_marks=$((test1_obtained_marks + 5))
else
    failed_properties+=("Question 7")
fi

# Q-8: Check if valid hard link to logs.tar.gz exists
if [ -f "$HOME/logs_backup_link" ] && \
   [ "$(stat --format='%i' /root/logs.tar.gz 2>/dev/null)" = "$(stat --format='%i' $HOME/logs_backup_link 2>/dev/null)" ]; then
    test1_obtained_marks=$((test1_obtained_marks + 5))
else
    failed_properties+=("Question 9")
fi

# Q-9: Check if valid soft link exists to logs.tar.gz
if [ -L "$HOME/latest_logs.tar.gz" ] && \
   [ "$(readlink $HOME/latest_logs.tar.gz)" = "/root/logs.tar.gz" ]; then
    test1_obtained_marks=$((test1_obtained_marks + 5))
else
    failed_properties+=("Question 9")
fi

# Final Test Status
if [ "$test1_obtained_marks" -eq 40 ]; then
    test1_status="pass"
    test1_message="All tasks completed correctly."
else
    test1_status="fail"
    test1_message="Tasks failed: ${failed_properties[*]}"
fi

results=$(echo "$results" | jq ".tasks += [{\"no\": 1, \"name\": \"Task 1\", \"obtained_marks\": $test1_obtained_marks, \"maximum_marks\": 40, \"message\": \"$test1_message\"}]")
results=$(echo "$results" | jq ".obtained_maximum_marks += $test1_obtained_marks")


#-------------------------------------------------Task 2---------------------------------------------

HIST_FILE=/var/log/command_history.log

test2_obtained_marks=0
test2_failed_properties=()

# Q-1: Start a dummy process (yes > /dev/null) in the background
if grep -E "yes\s+>\s*/dev/null\s*&?" "$HIST_FILE" &>/dev/null; then
    test2_obtained_marks=$((test2_obtained_marks + 5))
else
    test2_failed_properties+=("Question 1")
fi

# Q-2: Check and lower its priority to 5
if grep -E "renice\s+5\s+|nice\s+-n\s+5\s+" "$HIST_FILE" &>/dev/null; then
    test2_obtained_marks=$((test2_obtained_marks + 5))
else
    test2_failed_properties+=("Question 2")
fi

# Q-3: View current tuning profile
if grep -E "tuned-adm\s+active" "$HIST_FILE" &>/dev/null; then
    test2_obtained_marks=$((test2_obtained_marks + 5))
else
    test2_failed_properties+=("Question 3")
fi

# Q-4: Switch to “throughput-performance” profile
if grep -E "tuned-adm\s+profile\s+throughput-performance" "$HIST_FILE" &>/dev/null; then
    test2_obtained_marks=$((test2_obtained_marks + 5))
else
    test2_failed_properties+=("Question 4")
fi

# Q-5: View logs from the last boot using journalctl
if grep -E "journalctl\s+--boot|journalctl\s+-b" "$HIST_FILE" &>/dev/null; then
    test2_obtained_marks=$((test2_obtained_marks + 5))
else
    test2_failed_properties+=("Question 5")
fi

# Q-6: Filter logs by service name (sshd)
if grep -E "journalctl\s+.*-u\s+sshd" "$HIST_FILE" &>/dev/null; then
    test2_obtained_marks=$((test2_obtained_marks + 5))
else
    test2_failed_properties+=("Question 6")
fi

# Q-7: Save logs to a file named sshd_logs.txt
if grep -iE "journalctl.*sshd.*.*sshd_logs\.txt.*" "$HIST_FILE" &>/dev/null; then
    test2_obtained_marks=$((test2_obtained_marks + 5))
else
    test2_failed_properties+=("Question 7")
fi

# Q-8: Configure persistent logging
if grep -q "Storage=persistent" /etc/systemd/journald.conf; then
    test2_obtained_marks=$((test2_obtained_marks + 5))
else
    test2_failed_properties+=("Question 8")
fi

# Final Test Status
if [ "$test2_obtained_marks" -eq 40 ]; then
    test2_status="pass"
    test2_message="All journaling and tuning tasks completed correctly."
else
    test2_status="fail"
    test2_message="Tasks failed: ${test2_failed_properties[*]}"
fi


results=$(echo "$results" | jq ".tasks += [{\"no\": 2, \"name\": \"Task 2\", \"obtained_marks\": $test2_obtained_marks, \"maximum_marks\": 40, \"message\": \"$test2_message\"}]")
results=$(echo "$results" | jq ".obtained_maximum_marks += $test2_obtained_marks")



#-------------------------------------------------Task 3---------------------------------------------


test3_obtained_marks=0
test3_failed_properties=()

# Q-1: List all available disks and partitions (Check for /dev/sdb)
if grep -E "lsblk|fdisk\s+-l|parted\s+-l" "$HIST_FILE" &>/dev/null; then
    test3_obtained_marks=$((test3_obtained_marks + 5))
else
    test3_failed_properties+=("Question 1")
fi

sdb1_exist=0

# Q-2: Create a new primary partition of at least 1GB on /dev/sdb
if lsblk -b /dev/sdb | awk '$4 >= 1000000000 && $1 ~ /sdb[0-9]/' | grep -q "sdb"; then
    test3_obtained_marks=$((test3_obtained_marks + 5))
    sdb1_exist=1
else
    test3_failed_properties+=("Question 2")
fi

if [ "$sdb1_exist" -eq 1 ]; then
	# Q-4: Create a volume group called vg_storage
	if vgs | grep -q "vg_storage"; then
		test3_obtained_marks=$((test3_obtained_marks + 5))
	else
		test3_failed_properties+=("Question 4")
	fi

	# Q-5: Create a 512MB logical volume called lv_data in vg_storage
	if lvs --units m --nosuffix | awk '$1 == "lv_data" && $2 == "vg_storage" && $4 >= 500 && $4 <= 600' | grep -q "lv_data"; then
		test3_obtained_marks=$((test3_obtained_marks + 5))
	else
		test3_failed_properties+=("Question 5")
	fi
	
	# Q-6: Format the logical volume with ext4
	if blkid -o value -s TYPE /dev/vg_storage/lv_data 2>/dev/null | grep -q "ext4"; then
		test3_obtained_marks=$((test3_obtained_marks + 5))
	else
		test3_failed_properties+=("Question 6")
	fi
else
	test3_failed_properties+=("Question 4 Question 5 Question 6")
fi


# Q-7: Create a mount point /mnt/data
if [ -d "/mnt/data" ]; then
    test3_obtained_marks=$((test3_obtained_marks + 5))
else
    test3_failed_properties+=("Question 7")
fi

# Q-8: Mount it permanently (Check /etc/fstab for /mnt/data)
if grep -q "/mnt/data" /etc/fstab; then
    test3_obtained_marks=$((test3_obtained_marks + 5))
else
    test3_failed_properties+=("Question 8")
fi

# Final Test Status
if [ "$test3_obtained_marks" -eq 35 ]; then
    test3_status="pass"
    test3_message="All partitioning and LVM tasks completed correctly."
else
    test3_status="fail"
    test3_message="Tasks failed: ${test3_failed_properties[*]}"
fi


# Append to results JSON
results=$(echo "$results" | jq ".tasks += [{\"no\": 3, \"name\": \"Task 3\", \"obtained_marks\": $test3_obtained_marks, \"maximum_marks\": 35, \"message\": \"$test3_message\"}]")
results=$(echo "$results" | jq ".obtained_maximum_marks += $test3_obtained_marks")


#-------------------------------------------------Task 4---------------------------------------------


test4_obtained_marks=0
test4_failed_properties=()

# Q-1: Ensure firewalld is running
if systemctl is-active firewalld &>/dev/null; then
    test4_obtained_marks=$((test4_obtained_marks + 5))
else
    test4_failed_properties+=("Question 1")
fi

# Q-2: Add a rule to allow only SSH (port 22)
if firewall-cmd --list-all | grep -q 'ssh'; then
    test4_obtained_marks=$((test4_obtained_marks + 5))
else
    test4_failed_properties+=("Question 2")
fi

# Q-3: Block HTTP traffic explicitly (port 80)
if firewall-cmd --list-all | grep -q 'http'; then
    test4_failed_properties+=("Question 3")
else
    test4_obtained_marks=$((test4_obtained_marks + 5))
fi

# Q-4: Verify that only SSH is allowed and HTTP is blocked
firewall-cmd --list-services | grep -qw 'ssh' && SSH_OK=1 || SSH_OK=0
firewall-cmd --list-services | grep -qw 'http' && HTTP_OK=0 || HTTP_OK=1

if [[ $SSH_OK -eq 1 && $HTTP_OK -eq 1 ]]; then
    test4_obtained_marks=$((test4_obtained_marks + 10))
else
    test4_failed_properties+=("Question 4")
fi

# Q-5: Change the default system target to no GUI (multi-user.target)
if systemctl get-default | grep -q 'multi-user.target'; then
    test4_obtained_marks=$((test4_obtained_marks + 5))
else
    test4_failed_properties+=("Question 5")
fi

# Final Test Status
if [ "$test4_obtained_marks" -eq 30 ]; then
    test4_status="pass"
    test4_message="All firewalld and system target configurations are correct."
else
    test4_status="fail"
    test4_message="Tasks failed: ${test4_failed_properties[*]}"
fi

# Append to results JSON
results=$(echo "$results" | jq ".tasks += [{\"no\": 4, \"name\": \"Task 4\", \"obtained_marks\": $test4_obtained_marks, \"maximum_marks\": 30, \"message\": \"$test4_message\"}]")
results=$(echo "$results" | jq ".obtained_maximum_marks += $test4_obtained_marks")

#-------------------------------------------------Task 5---------------------------------------------


test5_obtained_marks=0
test5_failed_properties=()

# Check developer1 user (5 marks)
if id developer1 &>/dev/null; then
    test5_obtained_marks=$((test5_obtained_marks + 5))
else
    test5_failed_properties+=("Question 1")
fi



# Check home directory (5 marks)
actual_home=$(getent passwd developer1 | cut -d: -f6)
if [[ -d "$actual_home" && "$actual_home" == "/devhome/developer1" ]]; then
    test5_obtained_marks=$((test5_obtained_marks + 5))
else
    test5_failed_properties+=("Question 1.1")
fi

# Check shell (5 marks)
actual_shell=$(getent passwd developer1 | cut -d: -f7)
if [[ "$actual_shell" == "/bin/bash" ]]; then
    test5_obtained_marks=$((test5_obtained_marks + 5))
else
    test5_failed_properties+=("Question 1.2")
fi

# Check comment (5 marks)
actual_comment=$(sudo getent passwd developer1 | cut -d: -f5)
if [[ "$actual_comment" == "Frontend Developer" ]]; then
    test5_obtained_marks=$((test5_obtained_marks + 5))
else
    test5_failed_properties+=("Question 1.3")
fi

# Check password for developer1 (5 marks)
if id developer1 &>/dev/null; then
	result=$(sshpass -p "creator" ssh -o StrictHostKeyChecking=no developer1@localhost exit)
	if [[ "$result" =~ "Permission denied" ]]; then
		test5_failed_properties+=("Question 2")
	else
		test5_obtained_marks=$((test5_obtained_marks + 5))
	fi
else
	test5_failed_properties+=("Question 2")
fi




#Check Password Policy
if id developer1 &>/dev/null; then
	actual_max=$(sudo chage -l developer1 | grep "Maximum" | awk -F: '{print $2}' | xargs)
	actual_min=$(sudo chage -l  developer1 | grep "Minimum" | awk -F: '{print $2}' | xargs)
	actual_warn=$(sudo chage -l  developer1 | grep "warning" | awk -F: '{print $2}' | xargs)
	if [[ $actual_max == 90 && $actual_min == 1 && $actual_warn == 7 ]]; then
    		test5_obtained_marks=$((test5_obtained_marks + 5))
	else
    		test5_failed_properties+=("Question 3")
	fi
else
	test5_failed_properties+=("Question 3")
fi



# Check groups created (5 marks)

if grep -q 'devops' /etc/group && grep -q 'qa' /etc/group && grep -q 'design' /etc/group; then
	test5_obtained_marks=$((test5_obtained_marks + 5))
else
	test5_failed_properties+=("Question 4")
fi



# Check if developer1 added to devops and qa (5 marks)
if grep -Eq "usermod.*(-aG.*(devops,qa|qa,devops).*(developer1)|developer1.*-aG.*(devops,qa|qa,devops))" "$HIST_FILE" || \
   ( grep -Eiq "usermod.*(-aG.*devops.*developer1|developer1.*-aG.*devops)" "$HIST_FILE" && \
     grep -Eiq "usermod.*(-aG.*qa.*developer1|developer1.*-aG.*qa)" "$HIST_FILE" ); then
    test5_obtained_marks=$((test5_obtained_marks + 5))
else
    test5_failed_properties+=("Question 5")
fi

# Check if developer1 removed from qa (5 marks)
if id developer1 &>/dev/null; then
	if id -nG developer1 | grep -qw "qa"; then
		test5_failed_properties+=("Question 6")
	else
		test5_obtained_marks=$((test5_obtained_marks + 5))
	fi
else
	test5_failed_properties+=("Question 6")
fi

# Check adminuser created and password set(5 marks)


if id adminuser &>/dev/null; then
    result=$(sshpass -p "creator" ssh -o StrictHostKeyChecking=no developer1@localhost exit)
    if [[ "$result" =~ "Permission denied" ]]; then
	    test5_failed_properties+=("Question 7")
    else
	    test5_obtained_marks=$((test5_obtained_marks + 5))
    fi
else
    test5_failed_properties+=("Question 7")
fi

# Check if adminuser has sudo privileges (8 marks)
if id adminuser &>/dev/null; then
	if sudo -lU adminuser | grep -q 'ALL' 2>/dev/null; then
		test5_obtained_marks=$((test5_obtained_marks + 5))
	else
		test5_failed_properties+=("Question 8")
	fi
else
        test5_failed_properties+=("Question 8")
fi


# Final Task Status
if [ "$test5_obtained_marks" -eq 55 ]; then
    test5_status="pass"
    test5_message="All user and group configuration tasks are correctly implemented."
else
    test5_status="fail"
    test5_message="Issues found: ${test5_failed_properties[*]}"
fi

# Append to results JSON
results=$(echo "$results" | jq ".tasks += [{\"no\": 5, \"name\": \"Task 5\", \"obtained_marks\": $test5_obtained_marks, \"maximum_marks\": 55, \"message\": \"$test5_message\"}]")
results=$(echo "$results" | jq ".obtained_maximum_marks += $test5_obtained_marks")

echo "$results" | jq



