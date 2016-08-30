#!/bin/bash

### Run on local machine and not as 'root'.
### If you got problems with running the script do: 'gcloud components update' and try again.

##checks if the user who runs the script is 'root', if yes, sends message and exits.
if [ "$(id -u)" = "0" ]; then
   printf "\e[1m\e[31mYou are trying to run the script as root, try CTRL+D and run again.\n\033[0m" 1>&2
   exit
else

##takes the project list and put it in projects.txt
gcloud projects list | tail -n +2 | awk '{ print $2 }' > projects.txt
##function to design the instances and projects txts to look like [Num]instance or [Num]project
design() {
	awk '{print NR,$'$3'}' $1 > /tmp/sed.tmp
	sed 's/\(.*\) \(.*\)/[\1] \2/' /tmp/sed.tmp > $2
	cat $2 > /tmp/sed.tmp
	sed 's/ //g' /tmp/sed.tmp > $2
	esc=$(printf '\033')
	cat $2 > /tmp/sed.tmp
	NL=$'\n'
	sed "1 s/^/${esc}[1m[0]EXIT${esc}[0m\\$NL/" /tmp/sed.tmp > $2
	rm /tmp/sed.tmp
}

##designing projects.txt
run_projects_section() {
design projects.txt projects.lst 0

##declare projects array
file_projects=projects.lst
declare -a projects
projects=(`cat "$file_projects"`)
##let the user select a project
for line in "${projects[@]}"; do
  echo "$line"
done
printf "\e[1m\e[32mPlease select project number\033[0m: "
read n
PROJECT=$( echo ${projects[$n]} | cut -d"]" -f2)

##checks if the input is an integer and if its matching any project number
if ! [[ $n = *[[:digit:]]* ]] ;
	then exec >&2; printf "\e[1m\e[31merror: Not a number...\033[0m\n"; run_projects_section;
		elif [[ ($n = 0) ]]; then
		printf "\e[1m\e[31mGood bye, exiting...\033[0m\n"; rm -rf projects.*; exit
		elif [ "$n" -ge "${#projects[@]}" ]
		then
                printf "\e[1m\e[31mYou selected non-existing project number...\033[0m\n"; rm -rf instances.*; run_projects_section;
fi
printf "\e[1m\e[32mProject selected: $PROJECT\033[0m\n"

##takes the instances list from selected project and put it in instances.txt
gcloud compute instances list --project $PROJECT 2>/dev/null | grep "RUNNING" > instances.txt

##designing instances.txt
design instances.txt instances.lst 1

##if instances.lst is not empty(there are running instances in selected project) declare an array of instances and let the user choose an instance
run_instances_section() {
if [ -s instances.lst ]
	then
		file_instances=instances.lst
		declare -a instances
		instances=(`cat "$file_instances"`)
		for line2 in "${instances[@]}"
		do
		echo "$line2"
		done
		printf "\e[1m[${#instances[@]}]BACK\033[0m"
		printf "\n\e[1m\e[32mPlease select instance number\033[0m: "
		read n2
		INSTANCE=$( echo ${instances[$n2]} | cut -d"]" -f2)
		instance_lines=${#instances[@]}
		if ! [[ $n2 = *[[:digit:]]* ]] ;
        	then exec >&2; printf "\e[1m\e[31merror: Not a number...\033[0m\n"; run_instances_section;
                	elif [[ ($n2 = 0) ]]; then
                        printf "\e[1m\e[31mGood bye, exiting...\033[0m\n"; rm -rf instances.*; rm -rf projects.*; exit
			elif [ "$n2" -gt "${#instances[@]}" ]
                then
                printf "\e[1m\e[31mYou selected non-existing project number...\033[0m\n"; rm -rf instances.*; run_instances_section;
			elif [ "$n2" -eq "${#instances[@]}" ]
		then
		printf "\e[1m\e[31mSelected: BACK\033[0m\n"
		run_projects_section
		else
	        ZONE=$(cat instances.txt | grep  "$INSTANCE " | sed -e 's/  */ /g' | cut -d" " -f2)
		printf "\e[1m\e[32mConnecting to [$INSTANCE] on [$PROJECT]...\033[0m"
		gcloud compute --project "$PROJECT" ssh --zone "$ZONE" "$INSTANCE"; rm -rf instances.*;	 rm -rf projects.*
		fi

	else
	printf "\e[1m\e[31mYou selected project with no running instances...\033[0m\n"; rm -rf instances.*; run_projects_section;
fi
}
run_instances_section
rm -rf instances.*
rm -rf projects.*
}
run_projects_section
fi
