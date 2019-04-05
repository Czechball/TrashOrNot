#!/bin/bash
CheckDisks()
{
read -n1 -r -p "Odpoj všechny testovací disky a zmáčkni [ENTER]" key
if [ "$key" = '' ]; then :; else exit; fi
printf "Skenování systémových disků...\n"
	checkbefore=$(lsblk -d -I 8 | grep disk | tr -s ' ' | cut -d ' ' -f 1 | tr -s \\n | tr -d \\n)
	read -n1 -r -p "Připoj disk pro testování a zmáčkni [ENTER]" key
	checkafter=$(lsblk -d -I 8 | grep disk | tr -s ' ' | cut -d ' ' -f 1 | tr -s \\n | tr -d \\n)
	if [ "$key" = '' ]; then
	while [[ "$checkbefore" == "$checkafter" ]]; do
	  for (( i=0; i<${#chars}; i++ )); do
	    sleep 0.3
	    checkafter=$(lsblk -d -I 8 | grep disk | tr -s ' ' | cut -d ' ' -f 1 | tr -s \\n | tr -d \\n)
	    echo -en "Skenování připojených disků... ${chars:$i:1}" "\r"
	    sleep 0.3
	  done
	done
	    checkafter=$(lsblk -d -I 8 | grep disk | tr -s ' ' | cut -d ' ' -f 1 | tr -s \\n | tr -d \\n)
		check=$(echo "$checkafter" | tr -d "$checkbefore")
		printf "Zjištěné ID testovacího disku: sd$check\n"
		diskletter="$check"
		sleep 2
	else
		echo
	    exit
	fi
}
WaitDisk()
{
	while ! ls /dev/sd$diskletter -R 0>/dev/null 1>/dev/null 2>/dev/null; do
	  for (( i=0; i<${#chars}; i++ )); do
	    sleep 0.3
	    echo -en "Čekání na připojení disku... ${chars:$i:1}" "\r"
	  done
	done
}
ReadSmart()
{
	clear
	printf "Nalezen disk /dev/sd$diskletter\nNačítání S.M.A.R.T hodnot...\n"
	prevserialnumber=$serialnumber
	status=$(sudo smartctl /dev/sd$diskletter -a -f brief)
	reallocseccount=$(echo "$status" | grep Reallocated_Sector_Ct | tr -s ' ' | cut -d " " -f $cutpos)
	startstopcount=$(echo "$status" | grep Start_Stop_Count | tr -s ' '  | cut -d " " -f $cutpos)
	pocetspusteni=$(expr $startstopcount / 2)
	poweronhours=$(echo "$status" | grep Power_On_Hours | tr -s ' '  | cut -d " " -f $cutpos)
	currentpendingcount=$(echo "$status" | grep Current_Pending_Sector | tr -s ' '  | cut -d " " -f $cutpos2)
	uncorrectablesectorcount=$(echo "$status" | grep Offline_Uncorrectable | tr -s ' '  | cut -d " " -f $cutpos2)
	modelfamily=$(echo "$status" | grep "Model Family" | tr -s ' ' | cut -d ' ' -f 3-)
	devicemodel=$(echo "$status" | grep "Device Model" | tr -s ' ' | cut -d ' ' -f 3-)
	capacity=$(echo "$status" | grep "User Capacity" | tr -s ' ' | cut -d ' ' -f 5- | tr -d ] | tr -d [)
	serialnumber=$(echo "$status" | grep "Serial Number" | tr -s ' ' | cut -d ' ' -f 3-)
	score=$(expr $reallocseccount + $currentpendingcount + $uncorrectablesectorcount)
}
CheckSmart()
{
	if [[ $score == 0 ]];
	then
		statuscolor="\e[32m"
		printf "$statuscolor --- \e[4mDisk OK\e[24m ---\e[0m\n"
	else
		statuscolor="\e[91m"
		printf "$statuscolor --- \e[4mDisk špatný\e[24m ---\e[0m\n"
	fi
	printf "Série:				$modelfamily\n"
	printf "Model:				$devicemodel\n"
	printf "Sériové číslo:			$serialnumber\n"
	printf "Velikost:			$capacity\n"
	printf "Počet přemapovaných sektorů:	$statuscolor$reallocseccount\e[0m\n"
	printf "Počet podezřelých sektorů:	$statuscolor$currentpendingcount\e[0m\n"
	printf "Počet neopravitelných sektorů:	$statuscolor$uncorrectablesectorcount\e[0m\n\n"
	printf "\e[1mPočet spuštění disku:		\e[34m$pocetspusteni	krát\e[0m\n"
	printf "\e[1mCelková doba provozu:		\e[34m$poweronhours	hodin\e[0m\n\n"
	if [[ $serialnumber = $prevserialnumber ]]
	then
		printf "\e[91mVAROVÁNÍ: Byl načten stejný disk jako předchozí.\e[0m\nZkus načíst S.M.A.R.T ještě jednou.\n"
	else
		:
	fi
}
RepeatPrompt()
{
	echo
	read -n1 -r -p "Připoj nový disk a zmáčkni [ENTER] pro pokračování" key
	if [ "$key" = '' ]; then
	    Repeat
	else
		echo
	    exit
	fi
}
Repeat()
{
	clear
	WaitDisk
	ReadSmart
	CheckSmart
	RepeatPrompt
}

chars="/-\|"
cutpos=9
cutpos2=8

clear
CheckDisks
WaitDisk
ReadSmart
CheckSmart
RepeatPrompt