#
# command line version of server shutdown for rFactor 2
#
# 02/2024 Dietmar Stein, info@simracingjustfair.org
#

# mandatory
#
# - script needs to be copied to rf2 root
#

# functions ...
#

function check4server {
    do { 
        start-sleep -seconds 5
        Invoke-WebRequest -Uri http://127.0.0.1:$RF2UIPORT/navigation/state -Method Get
        $RESULT = $?
        } until ($RESULT)
}

function start_server {

    write-host "starting server with profile "$PROFILE

    # specifying rfm file ... modname + version ... 
    # $ARGUMENTS=" +profile=player +rfm=dummy_10.rfm +oneclick"

    # as it might have run before we could try oneclick option ...
    $ARGUMENTS=" +profile=$PROFILE +oneclick"
    start-process -FilePath "bin64\rFactor2 Dedicated.exe" -ArgumentList $ARGUMENTS -NoNewWindow
    
}


# main
#

$RF2ROOT="$HOME\rf2ds"
$RF2USERDATA="$RF2ROOT\userdata"

# getting cmdline arguments
if ( $args[0] ) {
    $PROFILES=$args
 }
 else {
    # if no argument is given determine all profiles
    $PROFILES=(gci $RFUSERDATA multiplayer.json -recurse | select -Expand Directory| select -Expand Name)
 }



# check if we can find / read / modify multiplayer.json ...
#if (Test-Path $RF2USERDATA\multiplayer.json -PathType Leaf)
if ($PROFILES)
{
    ForEach($PROFILE in $PROFILES)
    {
    $RF2USERDIR="$RF2USERDATA\$PROFILE"
    $RF2UIPORT=(((gc $RF2USERDIR\$PROFILE.JSON)| select-string -Pattern "WebUI port""") -split ":")
    $RF2UIPORT=($RF2UIPORT[1] -replace ",",'')
    
    if ( $(Invoke-WebRequest -Uri http://127.0.0.1:$RF2UIPORT/navigation/state -Method Get) ) {
        write-host "Server with "$PROFILE" is already up" 
        }
    else {
        start_server
        check4server 
        Invoke-WebRequest -Uri http://127.0.0.1:$RF2UIPORT/rest/chat -Method Post -Body "simracingjustfair.org - go fast, drive fair" 
        }
    }
}
else
{
    write-host "could not find any multiplayer.json - are we running from rf2 root folder?"
}


