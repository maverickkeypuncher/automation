import subprocess
import os


#requirementList = ["SMTP & Mailx Configured (for mail)", "Crash dump configured with enough space", "Synchronization with unix NTP Server", "Explorer or cfg2html configuration on OS", "AD integration", "In case RHEL cluster - fencing mode timeout should be configured for 120 seconds to avoid downtime", "NTP/Chrony configuration", "No application user in sudoers/rbac with root privilege", "Integrated with du ITOC monitoring tool", "Password policy compliance", "root password restriction (Only sys admins are allowed to use root)"]

requirementList = ["SMTP & Mailx Configured (for mail)", "Crash dump configured with enough space", "Synchronization with unix NTP Server", "Explorer or cfg2html configuration on OS", "AD integration", "NTP/Chrony configuration", "No application user in sudoers/rbac with root privilege", "Integrated with du ITOC monitoring tool", "Password policy compliance", "root password restriction (Only sys admins are allowed to use root)"]


#for index,items in (enumerate(requirementList)):
#	print("{0} : {1}".format(index, items))

## Append data to html
def appendHTML(ddict):
	print(ddict)
	global htmlvar3
	global firstfunc, comment1, comment2, comment3
	## here we will take  the key and value from dictionary and append in html file
	for key,val in ddict.items():
		comment_value_list = val.split()
		comment_list = val.split(",",1)
		if comment_value_list[-1].lower() == "compliant" or comment_value_list[-1] == "Normal":
			bgcolor = "lightgreen"
		else:
			bgcolor = "#FF7F7F"
		htmlvar1 = "<tr><td align='center'>" + key + "</td>"
		htmlvar2 = """<td>
						<table border='1'>
							<tr>
								<th>Server</th>
								<th>Status</th>
								<th>Comments</th>
							</tr>
							<tr>
								<td align=center>""" + srvname.decode() + """</td><td align=center bgcolor=""" + bgcolor  + ">" + comment_value_list[-1] + "</td><td>" + comment_list[0] + """</td></tr>
						</table>
					</td>
					</tr>"""
		htmlvar3 += htmlvar1 + htmlvar2
	
	print(comment_list)
	html = htmlvar + htmlvar3 + "</table></body></html>"
	f = open(filename,"w")
	f.write(html)
					

## Append to html ends here

## create html file
def createHTML(ddict):
	global filename, f, firstfunc
	filename = "/tmp/linux.html"
	appendHTML(ddict)

## Create html ends here

## Create a dict to append the output
def datadict(data1,data2,data3):
	## iterate list for each of the column names
	global i
	keyname = requirementList[i]
	val = str(data1)
	val += "," + str(data2) + "," + str(data3)
	ddict[keyname]=val
	i += 1


## Append data func ends here

## Below is the run command module and it will be called for each sub function
def run_command(cmd):
	try:
		response_run_command = subprocess.check_output(cmd, shell=True, stderr=subprocess.DEVNULL).strip()
		return response_run_command
	except:
		return 1


## command execution ends here

## Function to check SMTP and mailx configured
def checkSMTPandMailx():
	global firstfunc, comment1, comment2, comment3
	firstfunc = "True"
	command1 = "rpm -qa | grep -i sendmail"
	result_smtpfile = run_command(command1)
	if result_smtpfile == 1:	
		comment1 = "<td align=center>SMTP or Mailx is not configured</td>" 
		comment2 = "<td align=center>SMTP or Mailx is not configured</td>"
		comment3 = "Non-compliant"
	else:	
		comment1 = result_smtpfile.decode() + "binary is installed"
		command2 = "grep -i smtpint /etc/mail/sendmail.cf | echo $?" 
		result_smtp = run_command(command2)
		if result_smtp.decode() == "0":
			comment2 = "<td align=center>SMTP or Mailx is configured</td>"
			comment3 = " compliant"
		else:
			comment2 = "<td align=center>SMTP or Mailx is not configured</td>"
			comment3 = "Non-compliant"
				
		## decode function is used to decode bytes to string
		datadict(comment1,comment2,comment3)

## SMTP and mailx ends here

## function to check crash dump configured on the server
def checkCrashDump():
	global comment1, comment2, comment3
	command1 = "kdumpctl showmem"
	result_checkCrashdump = run_command(command1)
	if result_checkCrashdump == 1:
		comment2 = "<td align=center>Crash dump is not configured</td>"
		comment1 = "<td align=center>Crash dump is not configured</td>"
		comment3 = " Non-compliant"
		datadict(comment1,comment2,comment3)
	else:	
		command2 = "kdumpctl showmem | echo $?"
		result_checkCrashdump1 = run_command(command2)
		comment1 = result_checkCrashdump.decode()
		if result_checkCrashdump1.decode() == "0":
			comment2 = "<td align=center>" + result_checkCrashdump.decode() + "</td>"
			comment3 = " compliant"
		else:
			comment2 = "<td align=center>Crash dump is not configured</td>"
			comment3 = " Non-compliant"
		## decode function is used to decode bytes to string
		datadict(comment1,comment2,comment3)

## Crash dump function ends here 

## Function to check if NTP is configured and sync on the server
def checkTimeSyncNTP():
	global comment1, comment2, comment3
	command1 = "chronyc tracking"
	result_timesync = run_command(command1)
	if result_timesync == 1:
		comment2 = "<td align=center>NTP or Time Sync  is not configured</td>"
		comment3 = " Non-compliant"
		datadict(comment1,comment2,comment3)
	else:
		result_timesync_list = result_timesync.decode().split(":")
		ts = result_timesync_list[-1].strip()
		command2 = "chronyc tracking | echo $?"
		result_timesync1 = run_command(command2)	
		comment1 = result_timesync.decode()
		if result_timesync1.decode() == "0" and ts == "Normal":
			comment2 = "<td align=center>" + result_timesync.decode() + "</td>"
			comment3 = " Compliant"
		else:
			comment2 = "<td align=center>NTP or Time Sync  is not configured</td>"
			comment3 = " Non-compliant"
		datadict(comment1,comment2,comment3)

## NTP sync function ends here 


## Function to check if cfg2html is configured on OS
def checkcfg2html():
	global comment1, comment2, comment3
	command1 = "ls -lrth /usr/bin/cfg2html-linux 2> /dev/null"
	result_cfg1 = run_command(command1)
	if result_cfg1 == 1:
		comment1 = "cfg2html is not configured. No such file present in /usr/bin"
		comment2 = "cfg2html is not configured"
		comment3 = " Non-compliant"
		datadict(comment1,comment2,comment3)
	else:
		command2 = "ls -lrth /usr/bin/cfg2html-linux | echo $?"
		result_cfg2 = run_command(command2)
		comment1 = result_cfg1.decode()
		if result_cfg2.decode() == "0":
			comment2 = "<td align=center>" + result_cfg1.decode() + "</td>"
			comment3 = " Compliant"
		else:
			comment2 = "<td align=center>NTP or Time Sync  is not configured." + result_cfg1.decode() + "</td>"
			comment3 = " Non-compliant"
		datadict(comment1,comment2,comment3)

## cfg2html linux  function ends here

## Function to check if intergaiton with AD is done or not 
def checkADintegration():
	global comment1, comment2, comment3
	command1 = "realm list | grep -i corp.du.ae | grep -v "#" 2> /dev/null"
	result_ad1 = run_command(command1)
	if result_ad1 == 1:
		comment1 = "Server is not integrated with active directory"
		comment2 = "Server is not integrated with active directory"
		comment3 = " Non-compliant"
		datadict(comment1,comment2,comment3)
	else:
		command2 = "realm list | grep -i corp.du.ae | echo $?"
		result_ad2 = run_command(command2)
		comment1 = result_ad1.decode()
		if result_ad2.decode() == "0":
			comment2 = "<td align=center>Server is integrated with active directory" + result_ad1.decode() + "</td>"
			comment3 = " Compliant"
		else:
			comment2 = "<td align=center>Server is not integrated with active directory." + result_ad1.decode() + "</td>"
			comment3 = " Non-compliant"
		datadict(comment1,comment2,comment3)

## AD integration function ends here

## Function to get chrony configuration
def getChronyConfiguration():
	global comment1, comment2, comment3
	command1 = "grep -i server /etc/chrony.conf | grep -v '#'"
	result_chrony1 = run_command(command1)
	if result_chrony1 == 1:
		comment1 = "It seems could not find chrony.conf"
		comment2 = "It seems could not find chrony.conf"
		comment3 = " Non-compliant"
		datadict(comment1,comment2,comment3)
	else:
		command2 = "grep -i server /etc/chrony.conf | grep -v '#' | echo $?"
		result_chrony2 = run_command(command2)
		comment1 = result_chrony1.decode()
		if result_chrony2.decode() == "0":
			comment2 = "<td bgcolor='yellow' align=center>Please find the server configured in chrony.conf" + result_chrony1.decode() + "</td>"
			comment3 = " Compliant"
		datadict(comment1,comment2,comment3)

## Function for chrony config ends here


## Function to check root privelege starts here
def checkrootpriv():
	global comment1, comment2, comment3
	command1 = 'cat /etc/sudoers | egrep "ALL=" | egrep -v "#|root|sysadm|wheel"'
	result_rootp1 = run_command(command1)
	if result_rootp1 == 1:
		comment1 = "It seems could not find sudoers file"
		comment2 = "It seems could not find sudoers file"
		comment3 = " Non-compliant"
		datadict(comment1,comment2,comment3)
	else:
		command2 = 'cat /etc/sudoers | grep "ALL=" | egrep -v "#|root|sysadm|wheel" | echo $?'
		result_rootp2 = run_command(command2)
		comment1 = result_rootp1.decode()
		if result_rootp2.decode() == "0":
			comment2 = "<td align=center>Users are present with sudo root priveleges " + result_rootp1.decode() + "</td>"
			comment3 = " Non-compliant"
		else:
			comment2 = "<td align=center>No users present with sudo root priveleges" + result_rootp1.decode() + "</td>"
			comment3 = " Compliant"
		datadict(comment1,comment2,comment3)

## function to check root privilege ends here

## Function to check ITOC integration starts here
def checkITOC():
        global comment1, comment2, comment3
        command1 = "ps -ef | grep OV | grep -v grep"
        result_itoc1 = run_command(command1)
        if result_itoc1 == 2:
                comment1 = "It seems could not execute command. Please check manually"
                comment2 = "It seems could not execute command. Please check manually"
                comment3 = " Non-compliant"
                datadict(comment1,comment2,comment3)
        else:
                command2 = "ps -ef | grep OV | grep -v grep |  echo $?"
                result_itoc2 = run_command(command2)
                comment1 = result_itoc1
                if result_itoc2 == "0":
                        comment2 = "<td align=center>ITOC integration is present </td>"
                        comment3 = " Compliant"
                else:
                        comment2 = "<td align=center>ITOC integration is not present </td>"
                        comment3 = " Non-compliant"
                datadict(comment1,comment2,comment3)

## Function to check ITOC integration ends here

## function to check password policy compliance

def checkPasswordPolicy():
	global comment1, comment2, comment3
	command1 = 'grep -E "PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_MIN_LEN|PASS_WARN_AGE" /etc/login.defs |grep -v "#"'
	result_pp1 = run_command(command1)
	if result_pp1 == 1:
		comment1 = "It seems could not find /etc/login.defs file"
		comment2 = "It seems could not find /etc/login.defs file"
		comment3 = " Non-compliant"
		datadict(comment1,comment2,comment3)
	else:
		command2 = 'grep -E "PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_MIN_LEN|PASS_WARN_AGE" /etc/login.defs |grep -v "#" | echo $?'
		result_pp2 = run_command(command2)
		comment1 = {result_pp1.decode()}
		
		default_values = ['PASS_MAX_DAYS', '60', 'PASS_MIN_DAYS', '7', 'PASS_MIN_LEN', '8', 'PASS_WARN_AGE', '10']

		## Create a list from data retrieved from server
		for list_val in comment1:
			list_data = list_val.split()

		## Compare above list
		if default_values[1] == list_data[1]:
			#print("{0} value is compliant : {1}".format(default_values[0],default_values[1]))
			comment2 = default_values[0] + " is compliant. Value is " + default_values[1] + "<br>"
			comment3 = " Compliant"
		else:
			#print("{0} value is not compliant : {1}. Value should be {2}".format(default_values[0], list_data[1], default_values[1]))
			comment1 = default_values[0] + " is not compliant : " + list_data[1] + ". Value should be : " + default_values[1] + "<br>"
			comment3 = " Non-compliant"

		if default_values[3] == list_data[3]:
			#print("{0} value is compliant : {1}".format(default_values[1],default_values[2]))
			comment2 += default_values[1] + " is compliant. Value is " + default_values[2] + "<br>"
			comment3 += " Compliant"
		else:
			#print("{0} value is not compliant : {1}. Value should be {2}".format(default_values[2], list_data[3], default_values[3])
			comment1 += default_values[2] + "is not compliant : " + list_data[3] + ". Value should be : " + default_values[3] + "<br>"
			comment3 += " Non-compliant"

		if default_values[5] == list_data[5]:
			#print("{0} value is compliant : {1}".format(default_values[4],default_values[5]))
			comment2 += default_values[4] + " is compliant. Value is " + default_values[5] + "<br>"
			comment3 += " Compliant"
		else:
			#print("{0} value is not compliant : {1}. Value should be {2}".format(default_values[4], list_data[5], default_values[5]))
			comment1 += default_values[4] + " is not compliant : " + list_data[5] + ". Value should be : " + default_values[5] + "<br>"
			comment3 += " Non-compliant"

		if default_values[7] == list_data[7]:
			comment2 += default_values[6] + " is compliant. Value is " + default_values[7] + "<br>"
			comment3 += " Compliant"
			#print("{0} value is compliant : {1}".format(default_values[6],default_values[7]))
		else:
			#print("{0} value is not compliant : {1}. Value should be {2}".format(default_values[6], list_data[7], default_values[7]))
			comment1 += default_values[6] + " is not compliant : " + list_data[7] + ". Value should be : " + default_values[7] + "<br>"
			comment3 += " Non-compliant"

		datadict(comment1,comment2,comment3)	


i = 0
result = ""
ddict = {}

htmlvar = """<html>                                
                    <head><title>ACCEPTANCE REPORT</title>
                    <style>

    h1 {

        font-family: Arial, Helvetica, sans-serif;
        color: #e68a00;
        font-size: 28px;

    }

    
    h2 {

        font-family: Arial, Helvetica, sans-serif;
        color: #000099;
        font-size: 16px;

    }

    
    
   table {
		font-size: 12px;
		border: 0px; 
		font-family: Arial, Helvetica, sans-serif;
        	width:100%;
	} 
	
    td {
		padding: 4px;
		margin: 0px;
		border: 0;
        	width:33%;
	}
	
    th {
        background: #395870;
        background: linear-gradient(#49708f, #293f50);
        color: #fff;
        font-size: 11px;
        text-transform: uppercase;
        padding: 10px 15px;
        vertical-align: middle;
	}

    tbody tr:nth-child(even) {
        background: #f0f0f2;
    }

        #CreationDate {

        font-family: Arial, Helvetica, sans-serif;
        color: #ff3300;
        font-size: 12px;

    }
    



</style>
                     </head>
                    <body>
		    <table border = `1`>
                    <tr><td bgcolor='#DCDCDC' align='center'><b>VM Checklist</b></td><td bgcolor='#DCDCDC' align='center'><b>Compliance Check</b></td></tr>"""

filename = "/tmp/linux.html"
htmlvar1 = ""
htmlvar2 = ""
htmlvar3 = ""
srvname = subprocess.check_output("hostname", shell=True).strip()
if os.path.isfile(filename):
	## If the file is already present then delete the file
	os.remove(filename)

## function list
checkSMTPandMailx()
checkCrashDump()
checkTimeSyncNTP()
checkcfg2html()
checkADintegration()
getChronyConfiguration()
checkrootpriv()
checkITOC()
checkPasswordPolicy()
createHTML(ddict)	
