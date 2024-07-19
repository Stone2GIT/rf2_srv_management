# simple script to change to next event mod

# paths
$RF2ROOT="$HOME\rf2ds"
$RF2USERDATA="$RF2ROOT\userdata"

# a prefix for mods
$RF2MODPREFIX="SRJF-"

# time between events in days
$RF2EVENTPERIOD=7

# todays date
$RF2EVENTDATE=get-date -Format "yyyyMMdd"

# add period
[int]$RF2EVENTDATE += $RF2EVENTPERIOD

# switch the session in advance (should be race now, will be testday then)
cd $RF2ROOT
.\rf2_session_switcher.ps1 player

# start the server with the next event mod (assuming mod is version 1.0)
cd $RF2ROOT\bin64

$ARGUMENTS=" +path="".."" +profile=player +rfm=${RF2MODPREFIX}${RF2EVENTDATE}_10.rfm +oneclick"
start-process -FilePath "$RF2ROOT\bin64\rFactor2 Dedicated.exe" -ArgumentList $ARGUMENTS -NoNewWindow