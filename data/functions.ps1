# FAKE data for dev (to get super quick response during testing)
$FAKETESTDATA = Get-Content ($PSScriptRoot + "/faketestdata.txt") -Raw -ErrorAction SilentlyContinue

function Get-AIAnalysis {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $URL,

        [Parameter(Mandatory = $true)]
        [float]
        $MinConfidence,

        [Parameter()]
        [string]
        $Filter,

        [Parameter(HelpMessage = "mobilenet is a precice one which takes longer. efficientdet is a quick small allrounder")]
        [ValidateSet('https://tfhub.dev/google/openimages_v4/ssd/mobilenet_v2/1', 
            'yolov3', 'yolov4', 'yolov5', 'fasterrcnn')]
        [string]
        $Model = 'https://tfhub.dev/google/openimages_v4/ssd/mobilenet_v2/1',

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

        if ($null -eq $Filter -or "" -eq $Filter) {
            $FilterSwitch = ''
        }
        else {
            $FilterSwitch = "--filter " + $Filter
        }

        switch ($Model) {
            'https://tfhub.dev/google/openimages_v4/ssd/mobilenet_v2/1' { 
                $stdout = Invoke-Expression -Command ("python3 $PSScriptRoot/models/ssd_mobilenet_v2_fpnlite_320x320/main.py --image-path $URL $FilterSwitch --min-confidence $MinConfidence $IncludePicSwitch") # Real Analysis
            }
            'yolov3' {
                $stdout = Invoke-Expression -Command ("python3 $PSScriptRoot/models/yolov3/main.py --image-path $URL $FilterSwitch --min-confidence $MinConfidence $IncludePicSwitch") # Real Analysis
            }
            'yolov4' {
                $stdout = Invoke-Expression -Command ("python3 $PSScriptRoot/models/yolov4/main.py --image-path $URL $FilterSwitch --min-confidence $MinConfidence $IncludePicSwitch") # Real Analysis
            }
            'yolov5' {
                $stdout = Invoke-Expression -Command ("python3 $PSScriptRoot/models/yolov5/main.py --image-path $URL $FilterSwitch --min-confidence $MinConfidence $IncludePicSwitch") # Real Analysis
            }
            'fasterrcnn' {
                $stdout = Invoke-Expression -Command ("python3 $PSScriptRoot/models/fasterrcnn/main.py --image-path $URL $FilterSwitch --min-confidence $MinConfidence $IncludePicSwitch") # Real Analysis
            }
            Default {}
        }
        $stdout = $stdout | ConvertFrom-Json
        
        #$stdout = $FAKETESTDATA # Fake Data for Dev
        
        # Output the captured output
        Return $stdout
    }
    catch {
        # Error Return
        $Return = [PSCustomObject]@{
            Error = "' + $_.Exception.Message + '"
        }
        Return $Return
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
                <a class="navbar-brand" href="#">AI Counter</a>
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
        Return ('<option>mobilenet_v2</option>
        <option>yolov3</option>
        <option>yolov4</option>
        <option>yolov5</option>
        <option>fasterrcnn</option>')
    }
    elseif ($OutputAsHTMLCards) {
        Return ('<div class="row row-cols-1 row-cols-md-2 g-4">
                    <div class="col">
                            <div class="card">
                                <div class="card-body">
                                <h5 class="card-title">mobilenet_v2</h5>
                                <h6 class="card-subtitle mb-2 text-body-secondary"><i>by Google</i></h6>
                                <p class="card-text">SSD-based object detection model trained on Open Images V4 with ImageNet pre-trained MobileNet V2 as image feature extractor.</p>
                                <a href="https://www.kaggle.com/models/google/mobilenet-v2/tensorFlow1/openimages-v4-ssd-mobilenet-v2/1?tfhub-redirect=true" target="_blank" class="card-link">Further Info</a>
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="card">
                                <div class="card-body">
                                <h5 class="card-title">yolov3</h5>
                                <h6 class="card-subtitle mb-2 text-body-secondary"><i>by Joseph Redmon</i></h6>
                                <p class="card-text">YOLOv3 is an object detection model that uses a single neural network to predict bounding boxes and class probabilities directly from full images in one evaluation.</p>
                                <a href="https://pjreddie.com/darknet/yolo/" target="_blank" class="card-link">Further Info</a>
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="card">
                            <div class="card-body">
                                <h5 class="card-title">yolov4</h5>
                                <h6 class="card-subtitle mb-2 text-body-secondary"><i>by Alexey Bochkovskiy</i></h6>
                                <p class="card-text">YOLOv4 is a state-of-the-art, real-time object detection system that builds on YOLOv3 with several improvements for better performance and accuracy.</p>
                                <a href="https://github.com/AlexeyAB/darknet" target="_blank" class="card-link">Further Info</a>
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="card">
                            <div class="card-body">
                                <h5 class="card-title">yolov5</h5>
                                <h6 class="card-subtitle mb-2 text-body-secondary"><i>by Ultralytics</i></h6>
                                <p class="card-text">YOLOv5 is the latest evolution in the YOLO family, optimized for speed and accuracy, and built with PyTorch framework.</p>
                                <a href="https://github.com/ultralytics/yolov5" target="_blank" class="card-link">Further Info</a>
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="card">
                            <div class="card-body">
                                <h5 class="card-title">fasterrcnn</h5>
                                <h6 class="card-subtitle mb-2 text-body-secondary"><i>by Shaoqing Ren</i></h6>
                                <p class="card-text">Faster R-CNN is a region-based convolutional neural network that improves the speed and accuracy of object detection by integrating region proposal networks.</p>
                                <a href="https://arxiv.org/abs/1506.01497" target="_blank" class="card-link">Further Info</a>
                            </div>
                        </div>
                    </div>
                </div>
  ')
    } 
    else {
        Return ("mobilenet_v2", "yolov3", "yolov4", "yolov5", "fasterrcnn")
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
        $X,

        [Parameter()]
        [Int]
        $Y,

        [Parameter()]
        [Int]
        $Width,

        [Parameter()]
        [Int]
        $Height,

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
        $Disable,

        [Parameter()]
        [String]
        $KeepPics
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
            Invoke-SqlUpdate -Query ("
                UPDATE `scheduledcounts` SET 
                    `jobname` = '" + $JobName + "', 
                    `model` = '" + $Model + "', 
                    `object` = '" + $Object + "', 
                    `x` = '" + $x + "', 
                    `y` = '" + $y + "', 
                    `width` = '" + $width + "', 
                    `height` = '" + $height + "', 
                    `frequencymin` = '" + $FrequencyMinutes + "', 
                    `URL` = '" + $URL + "', 
                    `enabled` = '" + $EnabledString + "',
                    `keeppics` = '" + $KeepPics + "' 
                WHERE 
                    `scheduledcounts`.`id` = " + $ID + ";") -ErrorAction Stop
            Return 0
        }
        catch {
            Throw $_.Exception.Message
        }

    }
    else {
        try {
            Invoke-SqlUpdate -Query ("INSERT INTO ``scheduledcounts`` (``id``, ``jobname``, ``model``, ``object``, ``x``, ``y``, ``width``, ``height``, ``frequencymin``, ``URL``, ``enabled``, ``created``, `lastchanged`, `keeppics`) 
            VALUES (NULL, '" + $JobName + "', '" + $Model + "', '" + $Object + "', '" + $x + "', '" + $y + "', '" + $width + "', '" + $height + "', '" + $FrequencyMinutes + "', '" + $URL + "', '" + $EnabledString + "', current_timestamp(), current_timestamp(), '" + $KeepPics + "');") -ErrorAction Stop
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
                <th scope="col">Keep All Pics</th>
                <th scope="col">Datatable Row Count</th>
                <th scope="col">Last count Date/Time</th>
                <th scope="col">Actions</th>
            </tr>
        </thead>
        <tbody>
            ')
        $Return | ForEach-Object {
            if ($_.keeppics -eq 0) {
                $KeepPics = "No"
            }
            else {
                $KeepPics = '<p class="text-danger-emphasis">Yes</p>'
            }
            $ModelLabel = $_.model
            switch ($_.model) {
                "https://tfhub.dev/google/openimages_v4/ssd/mobilenet_v2/1" { $ModelLabel = "mobilenet" }
                "tensorflow/efficientdet/tensorFlow2/d0" { $ModelLabel = "efficientdet" }
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
            <td >' + $KeepPics + '</td>
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