#
# command line version of server messaging for rFactor 2
#
# 11/2026 Dietmar Stein, info@simracingjustfair.org
#

function pushLines {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$textArray,

        [Parameter(Mandatory=$true)]
        [string]$url
    )

    foreach ($line in $textArray) {

      if ( $line -eq "#") {
        $line = ""
      }
        Write-Host "Sending message: $line"
        $response = Invoke-WebRequest -UseBasicParsing -Uri $url -Method Post -Body $line -ContentType "text/plain; charset=utf-8"
        # Write-Host "Return code: $($response.StatusCode)"
        # Start-Sleep -Seconds 2
    }
}

$initScript = [scriptblock]::Create("function pushLines { $function:pushLines }")

while( 0 -ne 1 ) 
  {
    # Array with strings sent
    $RF2CHAT = @(
      "#",
      "Welcome to Holos half-1h race for GTE",
      "every Thursday",
      "no mandatory pitstop",
      "standing start",
      " ",
      "visit https://simracingjustfair.org and https://motorlaps.com"
    )

    # URL and WebUI port Thursday
    $RF2UIPORT=5396
    $SWAGGERAPI = "http://127.0.0.1:$RF2UIPORT/rest/chat"

    if ($SESSION -notlike "*QUAL*" -or $SESSION -notlike "*RACE*") {
#    pushLines -textArray $RF2CHAT.Where({$true}) -url $SWAGGERAPI
    Start-Job -InitializationScript $initScript -ScriptBlock {
        param($chat, $url)
        pushLines -textArray $chat -url $url
    } -ArgumentList ($RF2CHAT.Where({$true})), $SWAGGERAPI | Out-Null
    }

    # Array with strings sent
    $RF2CHAT = @(
      " ",
      "Welcome to Holos 1h race for GTE",
      "every Sunday",
      "one mandatory pitstop with re-fueling and tire change",
      "standing start",
      " ",
      "visit https://simracingjustfair.org and https://motorlaps.com"
    )

    # URL and WebUI port Sunday
    $RF2UIPORT=5397
    $SWAGGERAPI = "http://127.0.0.1:$RF2UIPORT/rest/chat"

    if ($SESSION -notlike "*QUAL*" -or $SESSION -notlike "*RACE*") {
    #    pushLines -textArray $RF2CHAT.Where({$true}) -url $SWAGGERAPI
    Start-Job -InitializationScript $initScript -ScriptBlock {
        param($chat, $url)
        pushLines -textArray $chat -url $url
    } -ArgumentList ($RF2CHAT.Where({$true})), $SWAGGERAPI | Out-Null
    }

    Start-Sleep -Seconds 60
  }