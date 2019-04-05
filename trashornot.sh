#!/bin/bash

Splash()
{
	printf "((	TrashOrNot\n";
	printf "((	Skript pro zjišťování stavu disků\n";
	printf "((	Vytvořil David Jenne pro Elektroodpad Vysočany\n";
	printf "((	Maximální povolené hodiny: $MAXHOURS hodin\n";
	printf "((	Maximální povolený počet spuštění disku: $MAXSTARTS spuštění\n";
}
WaitDisk()
{
	while ! ls /dev/sdb -R 0>/dev/null 1>/dev/null 2>/dev/null; do
	  for (( i=0; i<${#chars}; i++ )); do
	    sleep 0.3
	    echo -en "Čekání na připojení disku... ${chars:$i:1}" "\r"
	  done
	done
}
ReadSmart()
{
	printf "Disk nalezen\nNačítání S.M.A.R.T. hodnot...\n"
	reallocseccount=$(sudo smartctl /dev/sda -a -f brief | grep Reallocated_Sector_Ct | tr -s ' ' | cut -d " " -f $cutpos)
	startstopcount=$(sudo smartctl /dev/sda -a -f brief | grep Start_Stop_Count | tr -s ' '  | cut -d " " -f $cutpos)
	poweronhours=$(sudo smartctl /dev/sda -a -f brief | grep Power_On_Hours | tr -s ' '  | cut -d " " -f $cutpos)
	currentpendingcount=$(sudo smartctl /dev/sda -a -f brief | grep Current_Pending_Sector | tr -s ' '  | cut -d " " -f $cutpos2)
	uncorrectablesectorcount=$(sudo smartctl /dev/sda -a -f brief | grep Offline_Uncorrectable | tr -s ' '  | cut -d " " -f $cutpos2)
}
CheckSmart()
{
	if [ $reallocseccount = 0 ] || [ $currentpendingcount = 0 ] || [ $uncorrectablesectorcount = 0 ];
	then
		statuscolor="\e[32m"
		printf "Disk OK\n"
		printf "Počet přemapovaných sektorů:	$statuscolor$reallocseccount\e[0m\n"
		printf "Počet podezřelých sektorů:	$statuscolor$currentpendingcount\e[0m\n"
		printf "Počet neopravitelných sektorů:	$statuscolor$uncorrectablesectorcount\e[0m\n"
		printf "Počet spuštění disku:		$statuscolor$startstopcount krát\e[0m\n"
		printf "Celková doba provozu:		$statuscolor$poweronhours hodin\e[0m\n"
	else
		printf "Disk ded"
	fi
}

chars="/-\|"
cutpos=9
cutpos2=8


Splash
WaitDisk
ReadSmart
CheckSmart