# check_SynologyLastRecording.sh

This is a bash script that runs on my nagios server and goes out to a Synology Video server to check the Last Recording Start Time field of each camera. It needs the video URL, a (read-only) username and password and a camera number to function.

It depends on the small 'jq' package, which is readily available. See https://stedolan.github.io/jq/ for more information.

Once jq is installed, you might need to change the full path of jq in the shell script. Add commands.cfg to etc/objects/commands.cfg. 
You'll also need to generate a read-only user/password in your Synology Surveillance Station.
You may also want to change the warning and critical thresholds to something more appropriate to your environment. 

I've also included a sample service check command, which you have to add into Nagios

I also had to change the permissions on the script to allow the nagios user to run it. Simply do a chmod 755 on the file and restart the nagios service.

The code isn't perfect, but gets the job done for what I needed. If you have any issues or quesitons, I'm glad to help as I can. 
This could probably be easily modified to check any number of variables on the cameras. 

Thanks for taking a look!
