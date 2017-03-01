#!/bin/bash
# Author: Leigh Davies
# Version History:
#### 27/02/2017 0.1 - Basic script. Cloudstack checking implemented
#### 28/02/2017 0.2 - Looks prettier. Created git repo. Fixed log file blankspace bug. Better logging in general. 
####                  Added proper check for vlan_audit_funcs. Added initial menu for the type of check to run.
#### 01/03/2017 0.3 - Added score check

# This script hopes to automate the VLAN auditing process. 
# IMPORTANT: Script is dependent on vlan_audit_funcs file for login details/zone names etc. Will not work without this!

# Check for presence of functions file
if [ ! -f $HOME/scripts/vlan_audit_funcs ]; then
    echo "vlan_audit_funcs not found! Exiting script...";
    exit 0;
fi
# Import functions from vlan_audit_funcs
. $HOME/scripts/vlan_audit_funcs
echo -e "$PRP""vlan_audit_funcs loaded$RST";
# Make the log directory
mkdir $HOME/scripts/vlanauditlogs/ &> /dev/null

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

# What type of check do we want to run?
echo "Where do you want to check?"
checkType;

# Choose the zone
echo "Please choose the zone to check:"
zoneChoice;

if [ $choice = vdc ]; then
    # Generate the query and run it on the selected cloudstack db
    # Returns a list of VLANs and the display_text of the corresponding network if there is a network present
    dbQuery;
    # Sort out the log file name and location
    logDate=`date +%Y-%m-%d:%H:%M:%S`
    logFile="${zone,,}_output_vdc."$logDate
    logFileFixed="${logFile//[[:blank:]]/}"
    logFilePath="$HOME/scripts/vlanauditlogs/$logFileFixed"
    echo -e "$RED""Do you want to output the result to console? $BLD(y/n)$RST$RED"
    echo -e "The output will be saved to the logfile ($logFileFixed) either way$RST"
    while true; do
        read answer
        if [[ $answer = [nN] ]]; then
            for i in $vlans; do echo $i `mysql -u$mysqlUser -p$mysqlPass -P $mysqlPort -h $mysqlHost $mysqlDB -Nse "select 
            display_text from networks where broadcast_uri='"vlan://$i"' and data_center_id='"$zoneid"' 
            and removed is null order by created"`; done | tee $logFilePath >/dev/null
            echo "Done! Output saved to $logFilePath";
	    exit 0;
        elif [[ $answer = [yY] ]]; then
            for i in $vlans; do echo $i `mysql -u$mysqlUser -p$mysqlPass -P $mysqlPort -h $mysqlHost $mysqlDB -Nse "select 
            display_text from networks where broadcast_uri='"vlan://$i"' and data_center_id='"$zoneid"' 
            and removed is null order by created"`; done | tee $logFilePath
            echo "Done! Output saved to $logFilePath";
            exit 0;
        else
            echo "Please answer y/n"
           continue
        fi
        break
    done
elif [ $choice = sc ]; then 
    scoreGet;
    scoreSearch;
    echo -e "$PRP""Output saved to $HOME/scripts/vlanauditlogs/$scoreName-checkoutput. Do you want to print the output now? $BLD (y/n)$RST"
    while true; do
        read answer
        if [[ $answer = [nN] ]]; then
            echo "Exiting."
            exit 0;
        elif [[ $answer = [yY] ]]; then
            cat $HOME/scripts/vlanauditlogs/$scoreName-checkoutput
            exit 0;
        else
            echo "Please answer y/n"
            continue
        fi
    done
fi
