#!/usr/bin/python

import subprocess
import sys
import os

if os.geteuid() == 0:
    exit("You cant run this script with 'root' privileges.\nPlease try again, this time not using 'sudo'. Exiting.")

projects = subprocess.check_output('gcloud projects list | tail -n +2', shell=True)
projects_f=open('projects.txt','w')
projects_f.write(projects)
projects_f.close()

projects_l=open('projects.lst','w')
for line in open("projects.txt"):
    columns = line.split()
    if len(columns) >= 1:
	projects_l.write(columns[1] + '\n')
projects_l.close()
os.remove('projects.txt')

project_lines = sum(1 for line in open('projects.lst'))

def show_projects():
	add_exit=open('projects.lst')
	add_exit.seek(0)
	print "[0]EXIT"
	add_exit.close()

	count=1
	for lines in open('projects.lst'):
		print '['+ str(count)+']'+lines[:-1]
		count+=1
		
	try:
		user_choice = int(raw_input("Please select project by number" + '\n'))
		if (user_choice == 0):
			print("exiting...")
			os.remove('projects.lst')
			sys.exit()
		elif (user_choice < 0) or (user_choice > project_lines):
			print("You selected non existing project, or project witout running instances, exiting...")
			sys.exit()
		o_file=open('projects.lst','r')
		lines=o_file.readlines()
		project=lines[user_choice-1]
		project=project[:-1]
		print ("Project select " + project)
		try:
			x=subprocess.check_output("gcloud compute instances list --project %s | tail -n +2 | grep RUNNING "% project,shell=True)
			o_file=open(project,'w')
			o_file2=open("project.txt",'w')
			o_file2.write(x)
			o_file.write(x)
			o_file.close()
			o_file2.close()
		except:
			print("project is empty")
			show_projects()
	except ValueError:
		print ("You Must select project by number only")
		show_projects()
	
	if os.stat(project).st_size == 0:
        	print("project is empty")
		os.remove(project)
	else:
        	def show_instances():
			instance_o=open(project,'w')
			for line in open("project.txt"):
				columns = line.split()
				if len(columns) >= 1:
					instance_o.write(columns[0] + '\n')
			instance_o.close()
			count=1
			add_exit=open(project)
		        add_exit.seek(0)
		        print "[0]EXIT"
		        add_exit.close()
			for lines in open(project):
		             	print '['+ str(count)+']'+lines[:-1]
				count+=1
			instance_lines = sum(1 for line in open(project))
			back = instance_lines+1
			print '['+ str(back) + ']'+'BACK'
			try:
				user_choice = int(raw_input("Please select instance by number" + '\n'))
				if (user_choice == 0):
                       			print("exiting...")
					os.remove('projects.lst')
					os.remove('project.txt')
					os.remove(project)
                       		 	sys.exit()
                		elif (user_choice < 0) or (user_choice > back):
                        		print("You selected non existing project, or project witout running instances, exiting...")
                        		sys.exit()
				elif (user_choice == back):
					show_projects()
				else:
					o_file=open('project.txt','r')
			                lines=o_file.readlines()
			                instance=lines[user_choice-1]
					instance = instance.split()
					instance_r=instance[0]
					zone_r=instance[1]
					print ("gcloud compute --project %s ssh --zone %s %s") % (project, zone_r, instance_r)
					os.system("gcloud compute --project "+ project+" ssh --zone "+zone_r +" "+ instance_r)
					o_file.close()
					os.remove('projects.lst')
                                        os.remove('project.txt')
                                        os.remove(project)
			except ValueError:
                		print ("You Must select project by number only")
                		show_instances()
		show_instances()
show_projects()

