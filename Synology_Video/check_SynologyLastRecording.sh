#!/bin/bash

###### Last Recording Checker for Synology Surveillance Station for Nagios
###### Based on Unify Video checker Written by Brayden Santo
###### Adapted for Synology by Jaap Vermaas
###### This script uses JSON parsing to pull variables from the Synology API
###### It depends on the small 'jq' parsing package, so you'll need to install that first.

###### Instructions:

###### Change the warning and critical values to match what your environment requires
###### Change the full path to jq if necessary
###### Create a read-only user in Synology
###### Add the commands.cfg part to Nagios
###### Set the cameraURI, cameraNo (number of the camera), user and password in your 
###### Nagios service.cfg configuration
######
###### To test and find the cameraNo, you can run this script by hand:
###### ./check_SynologyLastRecording yourserver:port 0 username password
###### start with cameraNo=0, then try 1 and so on, until you find the right number for each camera.
###### Depending on the camera type and how many configurations you deleted before, they might start at 
###### 0, 1 or something else (usually low numbers)

###### tested with Nagios 4.4.3 and Synology Surveillance Station v 8.2.6-6009

#####Variable Init
cameraURI=$1
cameraNo=$2
synoUSER=$3
synoPASS=$4
fullURI="https://${cameraURI}/webapi"
jq="/usr/local/nagios/bin/jq"

#####Use Login to get SID
synoSID=$(curl -k -s "${fullURI}/auth.cgi?api=SYNO.API.Auth&method=Login&version=2&account=${synoUSER}&passwd=${synoPASS}&session=SurveillanceStation&format=sid" | ${jq} '.data.sid')

#####Use SID to read last recording info
record=$(curl -k -s "${fullURI}/entry.cgi?version=6&cameraIds=${cameraNo}&api=\"SYNO.SurveillanceStation.Recording\"&toTime=0&offset=0&limit=80&fromTime=0&method=\"List\"&_sid=${synoSID}")

#####Logout from Synology server
synoLogout=$(curl -k -s "${fullURI}/auth.cgi?api=SYNO.API.Auth&method=Logout&version=2&session=SurveillanceStation&_sid=${synoSID}" | ${jq} '.data.sid')

cameraName=$(echo ${record} | ${jq} '.data.recordings[0].cameraName')
filePath=$(echo ${record} | ${jq} '.data.recordings[0].filePath')

warningValue=$(date -d '-24 hours' '+%s')   #Epoch time for no recording in the last 48 hours
criticalValue=$(date -d '-48 hours' '+%s')  #Epoch time for no recording in the last 96 hours

######Convert filePath (which includes recording time) to timestamp
lastRec="$(echo ${filePath} | perl -pe 's/^.*\/.*-(\d\d\d\d)(\d\d)(\d\d)-(\d\d)(\d\d)(\d\d)-\d+\.mp4"/$1-$2-$3 $4:$5:$6/')"
lastRecordingEpochTimeInSeconds=$(date -d"${lastRec}" +%s)

######Compare time to decide to flag in Nagios
humanTime=$(date -d @"$lastRecordingEpochTimeInSeconds")

######If last recording time more than critical time, flag and out as critcal with name and last recording time
if [ "$lastRecordingEpochTimeInSeconds" -lt "$criticalValue" ]
then
echo 'Last Recording: '$humanTime 'on' $cameraName 'is more than 48 hours ago'
exit 2

######If last recording time less than critical time, but more than normal time, flag and out as warning with name and last recording time
elif [ "$lastRecordingEpochTimeInSeconds" -lt "$warningValue" -a "$lastRecordingEpochTimeInSeconds" -gt "$criticalValue" ]
then
echo 'Last Recording: '$humanTime 'on' $cameraName 'is more than 24 hours ago but less than 48 hours.'
exit 1

######If okay, out as okay and last recording time
elif [ "$lastRecordingEpochTimeInSeconds" -gt "$warningValue" ]
then
echo 'Last Recording: '$humanTime 'on' $cameraName 'is okay.'
exit 0

#####Exit as Unknown if something else happens...
else
echo 'Something else happened, script failed.'
exit 3
fi

