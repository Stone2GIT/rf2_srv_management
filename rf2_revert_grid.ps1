#
# simple script to revert the grid in rFactor 2 while in warmup phase
#
# 03/2024 Dietmar Stein, info@simracingjustfair.org
#

#
# ATTENTION: due to a bug in dedicated server this script must be run on a participating client
#

. ./variables.ps1

$RF2CLTIP="127.0.0.1"
$RF2WEBPORT="5397"
$RF2SRVIP="domainname.in.the.world.or.ip"
$RF2ADMINPW="adminpw"

# we need to become administrator
Invoke-WebRequest -Uri http://$RF2CLTIP:$RF2WEBPORT/rest/chat -Method POST -Body "/admin $RF2ADMINPW"


# looping until session is RACE1
$SESSIONSTATE = (Invoke-WebRequest "http://$RF2CLTIP:$RF2WEBPORT/rest/watch/sessionInfo"| ConvertFrom-Json).session
echo "session state"
$SESSIONSTATE

while( $SESSIONSTATE -ne "RACE1" )
 {
  sleep 30
  $SESSIONSTATE = (Invoke-WebRequest "http://$RF2CLTIP:$RF2WEBPORT/rest/watch/sessionInfo"| ConvertFrom-Json).session
 }

# RACE1 has been reached and we are now wating for PRACTICE1 (automatic restart weekend)
echo "session state"
$SESSIONSTATE

while( $SESSIONSTATE -ne "PRACTICE1" )
 {
  sleep 30
  $SESSIONSTATE = (Invoke-WebRequest "http://$RF2CLTIP:$RF2WEBPORT/rest/watch/sessionInfo"| ConvertFrom-Json).session
 }

echo "session state"
$SESSIONSTATE

# we need a huge timeout because clients may need a lot of time for switching and loading sessions
start-sleep -seconds 180

# if we have reached PRACTICE1 after RACE1 ...
# message
Invoke-WebRequest -Uri http://$RF2CLTIP:$RF2WEBPORT/rest/chat -Method POST -Body "DOING REVERSE GRID - DO NOT PRESS DRIVE"

# change dir ... maybe necessary
cd "$RF2ROOT"

# getting results of the race session
$RESULTFILE=(gci -Filter BatchTemplateR1.ini -Depth 1 -File -Name -Path "$RF2ROOT\UserData\Log\Results") | sort | select -last 1
echo "Guess result file is ... "
echo $RESULTFILE

#
# 14.08.2023: counting entries in BatchTemplateR1.ini
#
(get-content $RESULTFILE).replace('// ','') |out-file $RESULTFILE.tmp
[int]$numnames = $RESULTFILE.tmp.count


# generate batch file ...
$line = 0
del "$RF2ROOT\UserData\Log\Results\\reversegrid.raw"
del "$RF2ROOT\UserData\Log\Results\\reversegrid.ini"

sleep 3

0..($numnames-1) | ForEach-Object { if ( $finishs[$line+1] -ne "DNF" ) { [int]$pos = $positions[$line]  ; "/editgrid "+($numpositions-$pos+1-$dnf)+" "+$names[$line] }; $line++ } | out-file -Append "$RF2ROOT\UserData\Log\Results\reversegrid.raw"

sleep 3

$string = get-content "$RF2ROOT\UserData\Log\Results\reversegrid.raw"
$myobjecttosort=@()
$string | ForEach{
    $myobjecttosort+=New-Object PSObject -Property @{    
    'String'=$_
    'Numeric'=[int]([regex]::Match($_,'\d+')).Value
    }
}
$myobjecttosort | Sort-Object Numeric | select -Expand string | out-file -Append "$RF2ROOT\UserData\Log\Results\reversegrid.ini"

$SESSIONSTATE = (Invoke-WebRequest "http://$RF2CLTIP:$RF2WEBPORT/rest/watch/sessionInfo"| ConvertFrom-Json).session

while( $SESSIONSTATE -ne "PRACTICE1" )
 {
  write-host "Waiting for PRACTICE1"
  write-host "Session state "$SESSIONSTATE
  sleep 10
  $SESSIONSTATE = (Invoke-WebRequest "http://$RF2CLTIP:$RF2WEBPORT/rest/watch/sessionInfo"| ConvertFrom-Json).session
 }

Invoke-WebRequest -Uri http://$RF2CLTIP:$RF2WEBPORT/rest/chat -Method POST -Body "Skipping to warmup ..."

while( $SESSIONSTATE -ne "WARMUP" )
 {
  write-host "Waiting for warmup ..."
  write-host "Session state "$SESSIONSTATE
  Invoke-WebRequest -Uri http://$RF2CLTIP:$RF2WEBPORT/rest/chat -Method POST -Body "/callvote nextsession"
  sleep 10
  $SESSIONSTATE = (Invoke-WebRequest "http://$RF2CLTIP:$RF2WEBPORT/rest/watch/sessionInfo"| ConvertFrom-Json).session
 }

# working ...
ForEach ($APICOMMAND in "Reverting the grid ...","/batch reversegrid.ini","Reverting for safety reasons again ...","/batch $RF2ROOT\reversegrid.ini")
 {
    $APICOMMAND
    Invoke-WebRequest -Uri http://$RF2CLTIP:$RF2WEBPORT/rest/chat -Method POST -Body "$APICOMMAND"
    #
    # TODO: we need to make sure we are IN next session ...
    #       sleep is not reliable :-(
    #
    sleep 10
  }

Invoke-WebRequest -Uri http://$RF2CLTIP:$RF2WEBPORT/rest/chat -Method POST -Body "Going straight to race ..."
Invoke-WebRequest -Uri http://$RF2CLTIP:$RF2WEBPORT/rest/chat -Method POST -Body "/callvote nextsession"

# TODO: ggf. den DS nach dem zweiten Rennen loeschen (mit den Schleifen, wie oben ...)

# as we are again in a RACE session we are going to wait until race has finished and we would reach PRACTICE1 again then ...
echo "session state"
$SESSIONSTATE

while( $SESSIONSTATE -ne "PRACTICE1" )
 {
  sleep 30
  $SESSIONSTATE = (Invoke-WebRequest "http://$RF2CLTIP:$RF2WEBPORT/rest/watch/sessionInfo"| ConvertFrom-Json).session
 }

# Dedicated Server shutdown ... that does work if the webui port of the dedicated server is reachable
Invoke-WebRequest -Uri http://$RF2SRVIP:$RF2WEBPORT/rest/chat -Method POST -Body "Thanks for racing."
Invoke-WebRequest -Uri http://$RF2SRVIP:$RF2WEBPORT/navigation/action/NAV_EXIT -Method POST
