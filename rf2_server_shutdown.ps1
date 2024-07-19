#
# command line version of server shutdown for rFactor 2
#
# 02/2024 Dietmar Stein, info@simracingjustfair.org
#

# mandatory
#
# - script needs to be copied to rf2 root if rf2root is kind of program files (xc86)
#

# functions ...
#
function shutdown_server {

    write-host "shutdown server in 1 minute"

#    # sending message to server and players
#    if ((Invoke-WebRequest -Uri http://127.0.0.1:$RF2UIPORT/rest/chat -Method POST -Body "Server shutdown in 1 minute"))
#    {
#        Start-Sleep -Seconds 60
#    }

    # shutdown the server (as we need to write to json files and they are opened while server is running), assuming default port
    Invoke-WebRequest -Uri http://127.0.0.1:$RF2UIPORT/navigation/action/NAV_EXIT -Method POST

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
    $PROFILES=(gci $RF2USERDATA multiplayer.json -recurse | select -Expand Directory| select -Expand Name)
 }

# check if we can find / read / modify multiplayer.json ...
#if (Test-Path $RF2USER\multiplayer.json -PathType Leaf)
if ($PROFILES)
{
    ForEach($PROFILE in $PROFILES)
    {
    $RF2USERDIR="$RF2USERDATA\$PROFILE"
    $RF2UIPORT=(((gc $RF2USERDIR\$PROFILE.JSON)| select-string -Pattern "WebUI port""") -split ":")
    $RF2UIPORT=($RF2UIPORT[1] -replace ",",'')
    Invoke-WebRequest -Uri http://127.0.0.1:$RF2UIPORT/rest/chat -Method POST -Body "Server shutdown in 1 minute"
    }

    Start-Sleep -Seconds 60

    ForEach($PROFILE in $PROFILES)
    {
    $RF2USERDIR="$RF2USERDATA\$PROFILE"
    $RF2UIPORT=(((gc $RF2USERDIR\$PROFILE.JSON)| select-string -Pattern "WebUI port""") -split ":")
    $RF2UIPORT=($RF2UIPORT[1] -replace ",",'')
    
    shutdown_server
    }

    # if we are using rfactor 2 log analyzer ...
    #
    $RF2LAPID=(gc "C:\Users\rfactor2\rf2la\web2py\httpserver.pid")
    stop-process -id $RF2LAPID
    stop-process -id (get-process web2py).id
    
}
else
{
    write-host "could not find any multiplayer.json - are we running from rf2 root folder?"
}