Import-Module Pode
Import-Module SimplySql

#  PREPARATION: Check if connection to DB Server is possible
Write-Host ("[Preparation] Trying to reach MariaDB Server '$env:MariaDBHost' on Port $env:MariaDBPort with user '$env:MariaDBUsername'...") -ForegroundColor Blue
try {
    Open-MySqlConnection -ConnectionName "Test" -CommandTimeout 5000 -Server $env:MariaDBHost -Port $env:MariaDBPort -Credential (New-Object System.Management.Automation.PSCredential ($env:MariaDBUsername, (ConvertTo-SecureString $env:MariaDBPassword -AsPlainText -Force))) -WarningAction SilentlyContinue -ErrorAction Stop
    Close-SqlConnection -ConnectionName "Test"
    Write-Host (" -> Connection possible!") -ForegroundColor Green
}
catch {
    Write-Host (" -> Connection cannot be etablished! " + $_.Exception.Message) -ForegroundColor Red
    Write-Host (" -> FATAL! The App needs a Database to function!") -ForegroundColor Red
    Throw ("FATAL! Connection to the MariaDB Server '$env:MariaDBHost' on Port $env:MariaDBPort with user '$env:MariaDBUsername' cannot be etablished! " + $_.Exception.Message + ". The App needs a Database to work as intended, cannot continue!")
    Exit 
}   
Write-Host ""

#  PREPARATION: Check if Database is already present
Write-Host ("[Preparation] Checking if Database '$env:MariaDBDatabase' is already present...") -ForegroundColor Blue
try {
    Open-MySqlConnection  -ConnectionName "Test" -CommandTimeout 5000 -Server $env:MariaDBHost -Port $env:MariaDBPort -Credential (New-Object System.Management.Automation.PSCredential ($env:MariaDBUsername, (ConvertTo-SecureString $env:MariaDBPassword -AsPlainText -Force))) -Database $env:MariaDBDatabase -WarningAction SilentlyContinue -ErrorAction Stop
    Close-SqlConnection -ConnectionName "Test"
    Write-Host (" -> Database is present!") -ForegroundColor Green
    $DBPresent = $true
}
catch {
    Write-Host (" -> Database is not present!") -ForegroundColor Yellow
    $DBPresent = $false
} 
Write-Host ""

#  PREPARATION: Create Database if not already present
if (!$DBPresent) {
    Write-Host ("[Preparation] Creating Database '$env:MariaDBDatabase'...") -ForegroundColor Blue
    try {
        Open-MySqlConnection -CommandTimeout 5000 -Server $env:MariaDBHost -Port $env:MariaDBPort -Credential (New-Object System.Management.Automation.PSCredential ($env:MariaDBUsername, (ConvertTo-SecureString $env:MariaDBPassword -AsPlainText -Force))) -WarningAction SilentlyContinue -ErrorAction Stop
        Invoke-SqlUpdate -Query ((Get-Content ($PSScriptRoot + "/sql/ai-people-counter.sql") -Raw).Replace("ai-people-counter", $env:MariaDBDatabase)) -ErrorAction Stop | Out-Null
        Write-Host (" -> Database has been created!") -ForegroundColor Green
    }
    catch {
        Write-Host (" -> Database cannot be created! " + $_.Exception.Message) -ForegroundColor Red
        Write-Host (" -> FATAL!") -ForegroundColor Red
        Throw ("FATAL! Database '$env:MariaDBDatabase' cannot be created! " + $_.Exception.Message + ". Cannot continue!")
        Exit 
    }
}
Write-Host ("")

# Start Pode Server
Write-Host ("[API Server] API Server is now Starting log output of it will follow here...") -ForegroundColor Blue
if ($env:OS -match "Windows") {
    $env:PodeExposureAddress = "localhost"
    Write-Host ("[API Server] OS: Windows ($env:OS)") 
}
else {
    $env:PodeExposureAddress = "*"
    Write-Host ("[API Server] OS: Linux ($env:OS)") 
}
Start-PodeServer {
    Add-PodeEndpoint -Address $env:PodeExposureAddress -Port 8081 -Protocol Http

    #Initialize OpenApi
    Enable-PodeOpenApi -Path '/docs/openapi' -Title 'AI Object Counter - Swagger aPI Documentation' -Description "" -RouteFilter '/api/*'

    # Ensable Swagger
    Enable-PodeOpenApiViewer -Type Swagger -Path '/swagger' -OpenApiUrl '/docs/openapi' -DarkMode
    
    # Landing Page
    Add-PodeRoute -Method Get, Post -Path '/' -ScriptBlock {
        # Load Functions
        . ($PSScriptRoot + "/functions.ps1")

        # Perform Post Action
        $PostActionToast = ""
        if ($webevent.Method -ieq "post") {
            switch ($webevent.data.action) {
                "add" { 
                    try {
                        Set-ScheduledCountJob -JobName $webevent.data.jobname -Model $webevent.data.model -Object $webevent.data.object -FrequencyMinutes $webevent.data.frequency -URL $webevent.data.url
                        $PostActionToast += Get-ToastHTML -ToastHeader '<i style="color: #46a832" class="bi bi-check-square"></i> Success' -ToastIcon '' -ToastBody ("Job <b>" + $webevent.data.jobname + "</b> has been created!")
                    }
                    catch {
                        $PostActionToast += Get-ToastHTML -ToastHeader '<i style="color: #8a242e" class="bi bi-x-square"></i> Failed!' -ToastIcon '' -ToastBody ("Job <b>" + $webevent.data.jobname + "</b> could not be created! " + $_.Exception.Message)
                    }
                }
                "delete" { 
                    $RemoveResult = Remove-ScheduledCountJob -Id $webevent.data.id
                    if ($RemoveResult -ne "0") {
                        $PostActionToast += Get-ToastHTML -ToastHeader '<i style="color: #46a832" class="bi bi-check-square"></i> Success' -ToastIcon '' -ToastBody ("Job <b>" + $webevent.data.id + "</b> has been removed!")
                    }
                    else {
                        $PostActionToast += Get-ToastHTML -ToastHeader '<i style="color: #8a242e" class="bi bi-x-square"></i> Failed!' -ToastIcon '' -ToastBody ("Job <b>" + $webevent.data.id + "</b> could not be removed!")
                    }
                }
                "changestate" { 
                    $CurrectState = (Get-ScheduledCountJob | Where-Object { $_.id -eq $webevent.data.id }).enabled
                    if ($CurrectState -eq $false) {
                        Set-ScheduledCountJob -ID $webevent.data.id -Enable
                        $PostActionToast += Get-ToastHTML -ToastHeader '<i style="color: #46a832" class="bi bi-play">  Enabled</i> ' -ToastIcon '' -ToastBody ("Job <b>" + $webevent.data.id + "</b> has been Enabled! The System will now start collecting Data in the set Frequency.")
                    }
                    else {
                        Set-ScheduledCountJob -ID $webevent.data.id -Disable
                        $PostActionToast += Get-ToastHTML -ToastHeader '<i style="color: #46a832" class="bi bi-pause">  Disabled</i> ' -ToastIcon '' -ToastBody ("Job <b>" + $webevent.data.id + "</b> has been Disabled! Data will not be collected automatically")
                    }
                }
                Default {}
            }
        }


        # Load and fill HTML Template
        $HTML = Get-Content ($PSScriptRoot + "/html/template_landing.html") -raw
        $HTML = $HTML.Replace("///NAVBAR", (Get-NavMenuHTML -ActiveItem "scheduled-counts"))
        $HTML = $HTML.Replace("///OPTIONSAvailableAiModels", (Get-AvailableAiModels -OutputAsHTMLOptions))
        $HTML = $HTML.Replace("///POSTTOAST", ($PostActionToast -join ""))
        $HTML = $HTML.Replace("///SCHEDULEDCOUNTJOB", (Get-ScheduledCountJob -AsHTMLTable))

        Write-PodeHtmlResponse $HTML
    }

    # Test Page
    Add-PodeRoute -Method Get, Post -Path '/test' -ScriptBlock {
        # Load Functions
        . ($PSScriptRoot + "/functions.ps1")

        # Load and fill HTML Template
        $HTML = Get-Content ($PSScriptRoot + "/html/template_test.html") -raw
        $HTML = $HTML.Replace("///NAVBAR", (Get-NavMenuHTML -ActiveItem "test"))
        $HTML = $HTML.Replace("///AIMODELSCARDS", (Get-AvailableAiModels -OutputAsHTMLCards))
        $HTML = $HTML.Replace("///OPTIONSAvailableAiModels", (Get-AvailableAiModels -OutputAsHTMLOptions))
        Write-PodeHtmlResponse $HTML
    }

    # Info Page
    Add-PodeRoute -Method Get, Post -Path '/info' -ScriptBlock {
        # Load Functions
        . ($PSScriptRoot + "/functions.ps1")

        # Load and fill HTML Template
        $HTML = Get-Content ($PSScriptRoot + "/html/template_info.html") -raw
        $HTML = $HTML.Replace("///NAVBAR", (Get-NavMenuHTML -ActiveItem "info"))
        $HTML = $HTML.Replace("///AIMODELSCARDS", (Get-AvailableAiModels -OutputAsHTMLCards))
        $HTML = $HTML.Replace("///GPUINFO", (Get-GPUInfo -AsHTMLTable).Replace('<table>', '<table class="table table-striped">'))
        if ($webevent.Method -ieq "post") {
            $HTML = $HTML.Replace("///POSTVARIABLES", ("<h2>Post Variables</h2>" + ($webevent.data | ConvertTo-Html -Fragment).Replace('<table>', '<table class="table">') + "</pre>"))
        }
        else {
            $HTML = $HTML.Replace("///POSTVARIABLES", "")
        }
        Write-PodeHtmlResponse $HTML
    }

    # Swagger Page
    Add-PodeRoute -Method Get -Path '/swagger-api' -ScriptBlock {
        # Load Functions
        . ($PSScriptRoot + "/functions.ps1")

        # Load and fill HTML Template
        $HTML = Get-Content ($PSScriptRoot + "/html/template_swagger.html") -raw
        $HTML = $HTML.Replace("///NAVBAR", (Get-NavMenuHTML -ActiveItem "swagger"))

        Write-PodeHtmlResponse $HTML
    }

    # API : Get-AvailableAiModels
    Add-PodeRoute -Method Get -Path "/api/Get-AvailableAiModels" -ScriptBlock {
        # Load Functions
        . ($PSScriptRoot + "/functions.ps1")

        Get-AvailableAiModels | ConvertTo-Json | Write-PodeJsonResponse
    } -PassThru | Set-PodeOARouteInfo -Summary 'Get availalbe AIs for processing Images' -Tag "General"

    # API : Analyze-URL
    New-PodeOAStringProperty -Name 'URL' -Description "URL to image which should be analyized by the AI, e.g. https://webcams.com/queue_entrance2.jpeg" -Required | ConvertTo-PodeOAParameter -In Query | Add-PodeOAComponentParameter -Name 'Set2' 
    Add-PodeRoute -Method Post -Path "/api/Analyze-URL" -ScriptBlock {
        # Load Functions
        . ($PSScriptRoot + "/functions.ps1")

        if ($null -ne $webevent.data.URL -and $webevent.data.URL -ne "") {
            $AIResult = Get-AIAnalysis -URL $webevent.data.URL -Model $webevent.data.model
            if ($null -ne $webevent.data.minconfidence -or $webevent.data.minconfidence -ne "") {
                $AIResult = $AIResult | Where-Object { $_.score -ge $webevent.data.minconfidence }
            }
            if ($webevent.data.astable -ne 1) {
                Write-PodeJsonResponse (($AIResult | ConvertTo-Json))
            }
            else {
                Write-PodeJsonResponse (($AIResult | ConvertTo-Html -Fragment).Replace('<table>', '<table class="table">'))
            }
        }
        else {
            Write-PodeJsonResponse ((('{ "Error":  "Parameter URL is missing in Body" }') | ConvertTo-Json))
        }
    } -PassThru | Set-PodeOARouteInfo -Summary 'Analyze URL' -Tag "General" -PassThru | Set-PodeOARequest -Parameters @(ConvertTo-PodeOAParameter -Reference 'Set2' )

    # API : Get-ScheduledCountJob
    Add-PodeRoute -Method Get -Path "/api/Get-ScheduledCountJob" -ScriptBlock {
        # Load Functions
        . ($PSScriptRoot + "/functions.ps1")

        Get-ScheduledCountJob | Select-Object id, jobname, object, frequencymin, URL, enabled, created, lastchanged  | ConvertTo-Json | Write-PodeJsonResponse   
    } -PassThru | Set-PodeOARouteInfo -Summary 'Get All Scheduled Count Jobs' -Tag "Job Management"

    # API : Set-ScheduledCountJob
    New-PodeOAStringProperty -Name 'Jobname' -Description "Will also be used as MariaDB Datatablename (all lowercase + spaces are `"-`") no special chars allowed! e.g. Queue Entrance 2" -Required | ConvertTo-PodeOAParameter -In Query | Add-PodeOAComponentParameter -Name 'Set' 
    New-PodeOAStringProperty -Name 'Object' -Description "Name of the Object which should be counted, e.g. Person" -Required | ConvertTo-PodeOAParameter -In Query | Add-PodeOAComponentParameter -Name 'Set'
    New-PodeOAIntProperty  -Name 'Frequency' -Description "Frequency how often the AI Should analyize the given image in Minutes. e.g. 5" -Required | ConvertTo-PodeOAParameter -In Query | Add-PodeOAComponentParameter -Name 'Set'
    New-PodeOAStringProperty -Name 'URL' -Description "URL to image which should be analyized by the AI, e.g. https://webcams.com/queue_entrance2.jpeg" -Required | ConvertTo-PodeOAParameter -In Query | Add-PodeOAComponentParameter -Name 'Set'
    New-PodeOAStringProperty -Name 'Model' -Description "Choose which AI Model should anaylze your Picture" -Required | ConvertTo-PodeOAParameter -In Query | Add-PodeOAComponentParameter -Name 'Set'
    Add-PodeRoute -Method Post -Path "/api/Set-ScheduledCountJob" -ScriptBlock {
        # Load Functions
        . ($PSScriptRoot + "/functions.ps1")

        Get-ScheduledCountJob | Select-Object id, jobname, object, frequencymin, URL, enabled, created, lastchanged  | ConvertTo-Json | Write-PodeJsonResponse   
    } -PassThru | Set-PodeOARouteInfo -Summary 'Change or Set a Count Job' -Tag "Job Management" -PassThru | Set-PodeOARequest -Parameters @(ConvertTo-PodeOAParameter -Reference 'Set' )
    
    # API : Remove-ScheduledCountJob
    New-PodeOAStringProperty -Name 'ID' -Description "ID of Record to remove" -Required | ConvertTo-PodeOAParameter -In Query | Add-PodeOAComponentParameter -Name 'Remove'
    Add-PodeRoute -Method Delete -Path "/api/Remove-ScheduledCountJob" -ScriptBlock {
        # Load Functions
        . ($PSScriptRoot + "/functions.ps1")

        Remove-ScheduledCountJob -Id $webevent.data.id  
    } -PassThru | Set-PodeOARouteInfo -Summary 'Change or Set a Count Job' -Tag "Job Management" -PassThru | Set-PodeOARequest -Parameters @(ConvertTo-PodeOAParameter -Reference 'Remove' )



} -Verbose -Debug