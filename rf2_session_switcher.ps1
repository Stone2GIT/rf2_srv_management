#
# command line version of session switcher for rFactor 2
#
# 02/2024 Dietmar Stein, info@simracingjustfair.org
#

# mandatory
#
# - script needs to be copied to rf2 root
#

. .\variables.ps1

# variable definitions
if ( $args[0] ) {
    $PLRPROFILE=$args[0]
 }
 else {
    $PLRPROFILE="player"
 }


    $RF2USERDATA="$RF2ROOT\USERDATA\$PLRPROFILE"
    $RF2UIPORT=(((gc $RF2USERDATA\$PLRPROFILE.JSON)| select-string -Pattern "WebUI port""") -split ":")
    $RF2UIPORT=($RF2UIPORT[1] -replace ",",'')

function check4server {
    do { 
        start-sleep -seconds 15
        Invoke-WebRequest -Uri http://127.0.0.1:$RF2UIPORT/navigation/state -Method Get
        $RESULT = $?
        } until (!$RESULT)
}

function change_configuration {

    # if test day mode is enabled switch to race mode and start session and we rely on the else :-/
    if ((gc $RF2USERDATA\Multiplayer.JSON) | select-string -Pattern """Test Day"":true")
    {
    write-host "preparing race weekend"
    prepare4race
    }
    else
    {
    write-host "preparing test day mode"
    prepare4testday
    }

}

function prepare4testday {
    
    # set test day mode and pause server after last driver left (this will help write times to logfile for e.g. loganalyzer from Nibo)
    (gc "$RF2USERDATA\multiplayer.json") -replace """Test Day"":.*","""Test Day"":true," | set-content -Path "$RF2USERDATA\multiplayer.json"
    (gc "$RF2USERDATA\multiplayer.json") -replace """Pause While Zero Players"":.*","""Pause While Zero Players"":true," | set-content -Path "$RF2USERDATA\multiplayer.json"

}

function prepare4race {
    
    # switch off test day mode (which enables race mode) and set pause to false, so if there are people not joining at the race weekend start they are the lazy ones ...
    (gc "$RF2USERDATA\multiplayer.json") -replace """Test Day"":.*","""Test Day"":false," | set-content -Path "$RF2USERDATA\multiplayer.json"
    (gc "$RF2USERDATA\multiplayer.json") -replace """Pause While Zero Players"":.*","""Pause While Zero Players"":false," | set-content -Path "$RF2USERDATA\multiplayer.json"

}


function start_server {

    change_configuration

    write-host "starting server"

    # specifying rfm file ... modname + version ... 
    # $ARGUMENTS=" +profile=player +rfm=dummy_10.rfm +oneclick"

    # as it might have run before we could try oneclick option ...
    $ARGUMENTS=" +profile=player +oneclick"

    start-process -FilePath "bin64\rFactor2 Dedicated.exe" -ArgumentList $ARGUMENTS -NoNewWindow
    
    do { 
        start-sleep -seconds 5
        Invoke-WebRequest -Uri http://127.0.0.1:$RF2UIPORT/navigation/state -Method Get
        $RESULT = $?
        } until ($RESULT)

    Invoke-WebRequest -Uri http://127.0.0.1:$RF2UIPORT/rest/chat -Method Post -Body "simracingjustfair.org - go fast, drive fair"
}

function shutdown_server {

    write-host "shutdown server in 1 minute"

    # sending message to server and players
    if ((Invoke-WebRequest -Uri http://127.0.0.1:$RF2UIPORT/rest/chat -Method POST -Body "Server shutdown in 1 minute"))
    {
        Start-Sleep -Seconds 60
    }

    # shutdown the server (as we need to write to json files and they are opened while server is running), assuming default port
    Invoke-WebRequest -Uri http://127.0.0.1:$RF2UIPORT/navigation/action/NAV_EXIT -Method POST
    
    # the server needs some time to go down ... and close the files
    check4server
}

# check if we can find / read / modify multiplayer.json ...
if (Test-Path $RF2USERDATA\multiplayer.json -PathType Leaf)
{
    # if so ... run the script
    write-host "multiplayer.json exists"
    
    shutdown_server

    start-sleep -seconds 30
    
    start_server
}
else
{
    write-host "could not find multiplayer.json - please copy the script to rFactor 2 dedicated server root"
}
