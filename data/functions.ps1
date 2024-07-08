# FAKE data for dev (to get super quick response during testing)
$FAKETESTDATA = Get-Content ($PSScriptRoot + "/faketestdata.txt") -Raw -ErrorAction SilentlyContinue

function Get-AIAnalysis {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $URL,

        [Parameter()]
        [string]
        $Filter,

        [Parameter(HelpMessage = "mobilenet is a precice one which takes longer. efficientdet is a quick small allrounder")]
        [ValidateSet('https://tfhub.dev/google/openimages_v4/ssd/mobilenet_v2/1', 
            'tensorflow/efficientdet/tensorFlow2/d0')]
        [string]
        $Model = 'tensorflow/efficientdet/tensorFlow2/d0',

        [Parameter()]
        [bool]
        $RawOutput = $false,

        [Parameter()]
        [bool]
        $IncludePic = $false
    )
    
    try {
        
        if ($IncludePic) {
            $IncludePicSwitch = "--include-picture-with-boundingboxes"
        }
        else {
            $IncludePicSwitch = ""
        }

        $stdout = python /data/main.py --url $URL --filter $Filter --model $Model $IncludePicSwitch # Real Analysis
        #$stdout = $FAKETESTDATA # Fake Data for Dev

        # Use regex to find the JSON part
        $jsonObject = [regex]::Matches($stdout, '\{(?:[^{}]|(?<Open>\{)|(?<-Open>\}))*(?(Open)(?!))\}')[1].Value

        # Use regex to find base64 picture
        $base64Image = [regex]::Match($stdout, '"image-base64-encoded"\s*:\s*"\s*([^"]+)\s*"').Value
        
        # Output the captured output
        if ($RawOutput) {
            # Raw Return
            Return ($stdout | Out-String) 
        }
        else {
            if ((($jsonObject | convertfrom-json).detections.count) -ne 0) {
                # Normal Return
                $Return = [PSCustomObject]@{
                    json  = $jsonObject
                    image = $base64Image 
                }
                Return $Return
            }
            else {
                # Error no objects on pic Return
                Return ('{ "Error":  "No Objects found on picture, script output: ' + $stdout + '" }')  
            }
        }
    }
    catch {
        # Error Return
        Return ('{ "Error":  "' + $_.Exception.Message + '" }')  
    }
} 

function Get-NavMenuHTML {
    param (
        [Parameter()]
        [ValidateSet('scheduled-counts', 'test', 'info', 'swagger', 'phpMyAdmin')]
        [string]
        $ActiveItem
    )

    switch ($ActiveItem) {
        "scheduled-counts" { $scheduledCountsActiveFlag = "active" }
        "info" { $infoActiveFlag = "active" }
        "test" { $testActiveFlag = "active" }
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
                            <a class="nav-link ' + $scheduledCountsActiveFlag + '" href="/">Scheduled Counts</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link ' + $testActiveFlag + '" href="/test">Test</a>
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

function Get-AvailableAiModels {
    param (
        [Parameter()]
        [switch]
        $OutputAsHTMLOptions,

        [Parameter()]
        [switch]
        $OutputAsHTMLCards
    )

    if ($OutputAsHTMLOptions) {
        Return ('<option>https://tfhub.dev/google/openimages_v4/ssd/mobilenet_v2/1</option>
        <option>tensorflow/efficientdet/tensorFlow2/d0</option>')
    }
    elseif ($OutputAsHTMLCards) {
        Return ('<div class="card-group">
        <div class="card" style="width: 18rem;">
        <div class="card-body">
          <h5 class="card-title">mobilenet_v2</h5>
          <h6 class="card-subtitle mb-2 text-body-secondary"><i>by Google</i></h6>
          <p class="card-text">SSD-based object detection model trained on Open Images V4 with ImageNet pre-trained MobileNet V2 as image feature extractor.</p>
          <a href="https://www.kaggle.com/models/google/mobilenet-v2/tensorFlow1/openimages-v4-ssd-mobilenet-v2/1?tfhub-redirect=true" target="_blank" class="card-link">Further Info</a>
        </div>
      </div>
      <div class="card" style="width: 18rem;">
        <div class="card-body">
          <h5 class="card-title">efficientdet</h5>
          <h6 class="card-subtitle mb-2 text-body-secondary"><i>by tensorflow</i></h6>
          <p class="card-text">EfficientDet Object detection model (SSD with EfficientNet-b0 + BiFPN feature extractor, shared box predictor and focal loss), trained on COCO 2017 dataset.</p>
          <a href="https://www.kaggle.com/models/tensorflow/efficientdet/tensorFlow2/d0/1?tfhub-redirect=true" target="_blank" class="card-link">Further Info</a>
        </div>
      </div>
      </div>')
    } 
    else {
        Return ("https://tfhub.dev/google/openimages_v4/ssd/mobilenet_v2/1", "tensorflow/efficientdet/tensorFlow2/d0")
    }
}

function Get-ToastHTML {
    param (
        [Parameter()]
        [string]
        $ToastHeader,

        [Parameter()]
        [string]
        $ToastIcon,

        [Parameter()]
        [string]
        $ToastBody
    )
    
    return (('<div class="toast-container position-fixed bottom-0 end-0 p-3">
        <div class="toast show" role="alert" aria-live="assertive" aria-atomic="true">
            <div class="toast-header">
                ' + $ToastIcon + '
            <strong class="me-auto">' + $ToastHeader + '</strong>
            <button type="button" class="btn-close" data-bs-dismiss="toast" aria-label="Close"></button>
            </div>
            <div class="toast-body">
                ' + $ToastBody + '
            </div>
        </div>
    </div>'))

}

function Set-ScheduledCountJob {
    param (
        [Parameter()]
        [Int]
        $ID,
    
        [Parameter()]
        [String]
        $JobName,

        [Parameter()]
        [String]
        $Model,

        [Parameter()]
        [String]
        $Object,

        [Parameter()]
        [Int]
        $FrequencyMinutes,

        [Parameter()]
        [String]
        $URL,

        [Parameter()]
        [bool]
        $Enabled = $true,

        [Parameter()]
        [switch]
        $Enable,

        [Parameter()]
        [switch]
        $Disable
    )

    if ($Enabled) { $EnabledString = 1 } else { $EnabledString = 0 }

    if ($Enable -and $null -ne $ID) {
        Invoke-SqlUpdate -Query ("UPDATE ``scheduledcounts`` SET ``enabled`` = '1' WHERE ``scheduledcounts``.``id`` = " + $ID + ";")
        Return 0
    }
    elseif ($Disable -and $null -ne $ID) {
        Invoke-SqlUpdate -Query ("UPDATE ``scheduledcounts`` SET ``enabled`` = '0' WHERE ``scheduledcounts``.``id`` = " + $ID + ";")
        Return 0
    }

    Open-MySqlConnection -CommandTimeout 5000 -Server $env:MariaDBHost -Port $env:MariaDBPort -Credential (New-Object System.Management.Automation.PSCredential ($env:MariaDBUsername, (ConvertTo-SecureString $env:MariaDBPassword -AsPlainText -Force))) -Database $env:MariaDBDatabase -WarningAction SilentlyContinue -ErrorAction Stop
    if ($null -ne $ID -and $ID -ne "" -and !$Enable -and !$Disable) {
        try {
            Invoke-SqlUpdate -Query ("UPDATE `scheduledcounts` SET `jobname` = '" + $JobName + "', `model` = '" + $Model + "', `object` = '" + $Object + "', `frequencymin` = '" + $FrequencyMinutes + "', `URL` = '" + $URL + "', `enabled` = '" + $EnabledString + "' WHERE `scheduledcounts`.`id` = " + $ID + ";") -ErrorAction Stop
            Return 0
        }
        catch {
            Throw $_.Exception.Message
        }

    }
    else {
        try {
            Invoke-SqlUpdate -Query ("INSERT INTO ``scheduledcounts`` (``id``, ``jobname``, ``model``, ``object``, ``frequencymin``, ``URL``, ``enabled``, ``created``, `lastchanged`) 
            VALUES (NULL, '" + $JobName + "', '" + $Model + "', '" + $Object + "', '" + $FrequencyMinutes + "', '" + $URL + "', '" + $EnabledString + "', current_timestamp(), current_timestamp());") -ErrorAction Stop
            Return 0
        }
        catch {
            Throw $_.Exception.Message
        }
    }
}

function Get-ScheduledCountJob {
    param (
        [Parameter()]
        [switch]
        $AsHTMLTable
    )

    Open-MySqlConnection -CommandTimeout 5000 -Server $env:MariaDBHost -Port $env:MariaDBPort -Credential (New-Object System.Management.Automation.PSCredential ($env:MariaDBUsername, (ConvertTo-SecureString $env:MariaDBPassword -AsPlainText -Force))) -Database $env:MariaDBDatabase -WarningAction SilentlyContinue -ErrorAction Stop
    
    try {
        $Return = Invoke-SqlQuery -Query "SELECT * FROM ``scheduledcounts``" -ErrorAction Stop
    }
    catch {
        $Return = $_.Exception.Message
    }
    
    if ($AsHTMLTable) {
        $ReturnHTMLTable = ('<table class="table table-striped">
        <thead>
            <tr>
                <th scope="col">#</th>
                <th scope="col">Jobname</th>
                <th scope="col">AI Model</th>
                <th scope="col">Object</th>
                <th scope="col">Frequency</th>
                <th scope="col">URL</th>
                <th scope="col">Datatable Row Count</th>
                <th scope="col">Last count Date/Time</th>
                <th scope="col">Actions</th>
            </tr>
        </thead>
        <tbody>
            ')
        $Return | ForEach-Object {
            switch ($_.model) {
                "openimages_v4/ssd/mobilenet_v2/1" { $ModelLabel = "mobilenet" }
                "tensorflow/efficientdet/tensorFlow2/d0" { $ModelLabel = "efficientdet" }
                Default { $ModelLabel = $_.model }
            }
            switch ($_.enabled) {
                $false { $StatusIconButton = '<button type="submit" class="btn btn-outline-light" data-toggle="tooltip" data-placement="top" title="Scheduled Task is turned off right now, click to turn on"><i class="bi bi-play"></i></button>' }
                $True { $StatusIconButton = '<button type="submit" class="btn btn-outline-light" data-toggle="tooltip" data-placement="top" title="Scheduled Task is turned on right now, click to turn off"><i class="bi bi-pause"></i></button>' }
            }
            $ReturnHTMLTable = $ReturnHTMLTable + ('<tr>
            <th scope="row">' + $_.id + '</th>
            <td><b>' + $_.jobname + '</b></td>
            <td><b>' + $ModelLabel + '</b></td>
            <td>' + $_.object + '</td>
            <td>' + $_.frequencymin + ' min</td>
            <td ><a href="' + $_.URL + '"><p class="text-break">' + $_.URL + '</p></a></td>
            <td>tbp</td>
            <td>tbp</td>
            <td>
                <div class="btn-group" role="group">
                <!-- <button type="submit" class="btn btn-outline-primary" data-toggle="tooltip" data-placement="top" title="Edit"><i class="bi bi-pencil"></i></button> -->
                <button type="button" class="btn btn-outline-secondary"data-toggle="tooltip" data-placement="top" title="Inspect collected Data"><i
                class="bi bi-eye"></i></button>
                <button type="button" class="btn btn-outline-secondary" data-toggle="tooltip" data-placement="top" title="Download all collected Data as CSV"><i
                class="bi bi-download"></i></button>
                <form action="/" method="post">
                    ' + $StatusIconButton + '
                    <input type="hidden" name="action" value="changestate">
                    <input type="hidden" name="id" value="' + $_.id + '">
                </form>
                <form action="/" method="post">
                        <button type="submit" class="btn btn-outline-danger"><i class="bi bi-trash3"></i></button>
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="id" value="' + $_.id + '" required>
                    </form>
                </div>
            </td>
        </tr>
        ')
        }
        $ReturnHTMLTable = $ReturnHTMLTable + ('</tbody>
    </table>')
        $Return = $ReturnHTMLTable
    } 

    Return $Return
}

function Remove-ScheduledCountJob {
    param (
        [Parameter(Mandatory = $true)]
        [Int]
        $Id
    )
        
    try {
        Open-MySqlConnection -CommandTimeout 5000 -Server $env:MariaDBHost -Port $env:MariaDBPort -Credential (New-Object System.Management.Automation.PSCredential ($env:MariaDBUsername, (ConvertTo-SecureString $env:MariaDBPassword -AsPlainText -Force))) -Database $env:MariaDBDatabase -WarningAction SilentlyContinue -ErrorAction Stop
        $Return = Invoke-SqlUpdate -Query ("DELETE FROM scheduledcounts WHERE `scheduledcounts`.`id` = " + $Id)
        Return $Return
    }
    catch {
        Return $_.Exception.Message
    }
}


function Get-GPUInfo {
    param (
        [Parameter()]
        [switch]
        $AsHTMLTable
    )

    try {
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = "lshw"
        $pinfo.RedirectStandardError = $true
        $pinfo.RedirectStandardOutput = $true
        $pinfo.UseShellExecute = $false
        $pinfo.Arguments = ("-C display -json")
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $pinfo
        $p.Start() | Out-Null
        $p.WaitForExit()
        $stdout = $p.StandardOutput.ReadToEnd()

        $Return = $stdout | ConvertFrom-Json
        if ($AsHTMLTable) {
            $HTMLTable = "<table>"
            $Return | Get-Member -Type NoteProperty | ForEach-Object {
                $HTMLTable += "<tr>"
                $HTMLTable += "    <td><b>" + $_.name + "</b></td>"
                if ($_.name -ieq "configuration" -or $_.name -ieq "capabilities") {
                    $HTMLTable += "    <td>" + ($Return.($_.name) | ConvertTo-Html -Fragment) + "</td>"
                }
                else {
                    $HTMLTable += "    <td>" + $Return.($_.name) + "</td>"
                }
                $HTMLTable += "</tr>"
            }
            $HTMLTable += "</table>"
            
            $Return.configuration = $Return.configuration | ConvertTo-Html -Fragment
            $Return.capabilities = $Return.capabilities | ConvertTo-Html -Fragment
            $Return = $HTMLTable -join ""
        }
        Return $Return
    }
    catch {
        Return $_.Exception.Message
    }
    

}