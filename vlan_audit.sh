#!/bin/bash
# Author: Leigh Davies
# Version History:
#### 27/02/2017 0.1 - Basic script. Cloudstack checking implemented
#### 28/02/2017 0.2 - Created git repo. Fixed log file blankspace bug. Added proper check for vlan_audit_funcs

# This script hopes to automate the VLAN auditing process. For the moment it will just return info from CloudStack, but I hope to implement score checking as well.
# IMPORTANT: Script is dependent on vlan_audit_funcs file for login details/zone names etc. Will not work without this!

# Check for presence of functions file
if [ ! -f $HOME/scripts/vlan_audit_funcs ]; then
    echo "vlan_audit_funcs not found! Exiting script...";
    exit 0;
fi
# Import functions from vlan_audit_funcs
. $HOME/scripts/vlan_audit_funcs
echo -e "$PRP""vlan_audit_funcs loaded$RST";

# Get the name of the input file
vlanFile=$1;

# If no input file is given, ask if we want to use the default list
if [[ -z $vlanFile ]]; then
    echo "You have not specified a list of VLANs. Do you want to use 1-1000? (y/n)"
    while true; do
        read answer
	      if [[ $answer = [nN] ]]; then
	          echo "Exiting..."
	          exit 0;
	      elif [[ $answer = [yY] ]]; then
	          echo "OK, using VLANs 1-1000"
	          vlans=$(seq 1000);
       	else 
	          echo "Please answer y/n"
	          continue
	      fi
	  break
    done
# Otherwise put the contents of the file into the list
else vlans=$(cat $vlanFile)
fi

# Give some info about the list of vlans
echo -e "$PRP""Using list of VLANs starting:$RST"
echo "$vlans" | head
echo "..."
echo -e "$PRP""The list is$BLD `echo "$vlans" | wc -l` "$RST$PRP"VLANs long$RST"
	
# Choose the zone
echo "Please choose the zone to check:"
zonechoice;

# Generate the query and run it on the selected cloudstack db
# Returns a list of VLANs and the display_text of the corresponding network, if there is a network present
dbquery;
logFile="${zone,,}_output"
logFileFixed="${logFile//[[:blank:]]/}"
echo -e "$RED""Do you want to output the result to console? $BLD(y/n)$RST$RED The output will be saved to the logfile ($logFileFixed) either way$RST"
while true; do
    read answer
    if [[ $answer = [nN] ]]; then
        for i in $vlans; do echo $i `mysql -u$mysqlUser -p$mysqlPass -P $mysqlPort -h $mysqlHost $mysqlDB -Nse "select display_text from networks where broadcast_uri='"vlan://$i"' and data_center_id='"$zoneid"' and removed is null order by created"`; done | tee $logFileFixed >/dev/null
	      echo "Done! Output saved to $logFileFixed";
	      exit 0;
    elif [[ $answer = [yY] ]]; then
	      for i in $vlans; do echo $i `mysql -u$mysqlUser -p$mysqlPass -P $mysqlPort -h $mysqlHost $mysqlDB -Nse "select display_text from networks where broadcast_uri='"vlan://$i"' and data_center_id='"$zoneid"' and removed is null order by created"`; done | tee $logFileFixed
	      echo "Done! Output saved to $logFileFixed";
	      exit 0;
    else
	      echo "Please answer y/n"
	      continue
    fi
    break
done
