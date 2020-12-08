#!/bin/bash
CheckDisks()
{
read -n1 -r -p "Odpoj všechny testovací disky a zmáčkni [ENTER]" key
if [ "$key" = '' ]; then :; else exit; fi
echo "Skenování systémových disků..."
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
		echo "Zjištěné ID testovacího disku: sd$check"
		diskletter="$check"
		if ! udevadm info --query=all --name=sd"$diskletter" | grep ata
		then
			printf "\e[31mCHYBA:\e[0m Připojené zařízení není hard disk.\n"
			error
		fi
		sleep 2
	else
		echo
	    error
	fi
}
WaitDisk()
{
	while ! ls /dev/sd"$diskletter" -R 0>/dev/null 1>/dev/null 2>/dev/null; do
	  for (( i=0; i<${#chars}; i++ )); do
	    sleep 0.3
	    echo -en "Čekání na připojení disku... ${chars:$i:1}" "\r"
	  done
	done
}
ReadSmart()
{
	clear
	printf "Nalezen disk /dev/sd%s\nNačítání S.M.A.R.T hodnot..."\
	"$diskletter"
	prevserialnumber=$serialnumber
	status=$(sudo smartctl /dev/sd"$diskletter" -a -f brief)
	reallocseccount=$(echo "$status" | grep Reallocated_Sector_Ct | tr -s ' ' | cut -d " " -f "$cutpos")
	startstopcount=$(echo "$status" | grep Start_Stop_Count | tr -s ' '  | cut -d " " -f "$cutpos")
	pocetspusteni=$(( startstopcount / 2 ))
	poweronhours=$(echo "$status" | grep Power_On_Hours | tr -s ' '  | cut -d " " -f "$cutpos")
	currentpendingcount=$(echo "$status" | grep Current_Pending_Sector | tr -s ' '  | cut -d " " -f "$cutpos2")
	uncorrectablesectorcount=$(echo "$status" | grep Offline_Uncorrectable | tr -s ' '  | cut -d " " -f "$cutpos2")
	modelfamily=$(echo "$status" | grep "Model Family" | tr -s ' ' | cut -d ' ' -f 3-)
	devicemodel=$(echo "$status" | grep "Device Model" | tr -s ' ' | cut -d ' ' -f 3-)
	capacity=$(echo "$status" | grep "User Capacity" | tr -s ' ' | cut -d ' ' -f 5- | tr -d "]" | tr -d [)
	serialnumber=$(echo "$status" | grep "Serial Number" | tr -s ' ' | cut -d ' ' -f 3-)
	score=$(( reallocseccount + currentpendingcount + uncorrectablesectorcount))
}
CheckSmart()
{
	if [[ $score == 0 ]];
	then
		statuscolor="\e[32m"
		echo -e "$statuscolor --- \e[4mDisk OK\e[24m ---\e[0m"
	else
		statuscolor="\e[91m"
		echo -e "$statuscolor --- \e[4mDisk špatný\e[24m ---\e[0m"
	fi
	echo "Série:				$modelfamily"
	echo "Model:				$devicemodel"
	echo "Sériové číslo:			$serialnumber"
	echo "Velikost:			$capacity"
	echo
	echo "Počet přemapovaných sektorů:	$statuscolor$reallocseccount\e[0m"
	echo "Počet podezřelých sektorů:	$statuscolor$currentpendingcount\e[0m"
	echo "Počet neopravitelných sektorů:	$statuscolor$uncorrectablesectorcount\e[0m"
	echo
	echo "\e[1mPočet spuštění disku:		\e[34m$pocetspusteni	krát\e[0m"
	echo "\e[1mCelková doba provozu:		\e[34m$poweronhours	hodin\e[0m"
	echo
	if [[ $serialnumber = "$prevserialnumber" ]]
	then
		printf "\e[91mVAROVÁNÍ: Byl načten stejný disk jako předchozí.\e[0m\nZkus načíst S.M.A.R.T ještě jednou.\n"
	else
		:
	fi
}
DeleteDisk ()
{
	printf "Vymazávání tabulky oddílů...\n"
	if sudo wipefs /dev/sd"$diskletter" -faq
	then
		printf "Tabulka oddílů vymazána."
	else
		printf "Chyba: Nepodařilo se vymazat tabulku oddílů. Restartování skriptu...\n"
		sleep 2
		Repeat
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
	    error
	fi
}
Repeat()
{
	clear
	WaitDisk
	ReadSmart
	CheckSmart
	DeleteDisk
	RepeatPrompt
}
error ()
{
	exit
}
chars="/-\|"
cutpos=9
cutpos2=8

clear
printf "\e[31mVAROVÁNÍ:\e[0m Tento skript vymaže veškeré oddíly na testovaném disku.\nBuď opatrný.\n"
CheckDisks
WaitDisk
ReadSmart
CheckSmart
DeleteDisk
RepeatPrompt