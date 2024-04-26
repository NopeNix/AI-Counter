# FAKE function for dev
function Get-AIAnalysis {
    return ((Get-Content ($PSScriptRoot + "/../misc/testdata.json") -Raw) | ConvertFrom-Json)
}

#Real Function
<# function Get-AIAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $URL
    )

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "python"
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = ("/data/script.py " + $URL)
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    $stdout = $p.StandardOutput.ReadToEnd()
    #$stderr = $p.StandardError.ReadToEnd()

    # Use regex to find the JSON part
    $jsonObject = [regex]::Match($stdout, '\{(?:[^{}]|(?<o>\{)|(?<-o>\}))+(?(o)(?!))\}').Value

    # Output the captured output
    Return (($jsonObject | convertfrom-json).detections)
}  #>



############################################################################################

function Get-NavMenuHTML {
    param (
        [Parameter()]
        [ValidateSet('scheduled-counts', 'info', 'swagger','phpMyAdmin')]
        [string]
        $ActiveItem
    )

    switch ($ActiveItem) {
        "scheduled-counts" { $scheduledCountsActiveFlag = "active" }
        "info" { $infoActiveFlag = "active" }
        "swagger" { $swaggerActiveFlag = "active" }
        Default {}
    }

    $HTML = ('
        <nav class="navbar navbar-expand-sm bg-body-tertiary rounded">
            <div class="container-xxl">
                <a class="navbar-brand" href="#">AI-Object Counter</a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbar"
                    aria-controls="navbar" aria-expanded="false" aria-label="Toggle navigation">
                    <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse" id="navbar">
                    <ul class="navbar-nav me-auto mb-2 mb-lg-0">
                        <li class="nav-item">
                            <a class="nav-link ' + $scheduledCountsActiveFlag + '" aria-current="page" href="/">Scheduled Counts</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link ' + $infoActiveFlag + '" href="/info">Info</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link ' + $swaggerActiveFlag + '" href="/swagger-api">API Docu (Swagger)</a>
                        </li>
                    </ul>
                </div>
            </div>
        </nav>')

        Return $HTML
}