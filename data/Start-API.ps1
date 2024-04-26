Import-Module Pode
Import-Module SimplySql

# Start Pode Server
Start-PodeServer {
    Add-PodeEndpoint -Address localhost -Port 8081 -Protocol Http

    #Initialize OpenApi
    Enable-PodeOpenApi -Path '/docs/openapi' -Title 'AI Object Counter - Swagger aPI Documentation' -Description ""

    # Ensable Swagger
    Enable-PodeOpenApiViewer -Type Swagger -Path '/swagger' -OpenApiUrl '/docs/openapi' -DarkMode
    
    # Landing Page
    Add-PodeRoute -Method Get -Path '/' -ScriptBlock {
        # Load Functions
        . ($PSScriptRoot + "/functions.ps1")

        # Load and fill HTML Template
        $HTML = Get-Content ($PSScriptRoot + "/html/template_landing.html") -raw
        $HTML = $HTML.Replace("///NAVBAR",(Get-NavMenuHTML -ActiveItem "scheduled-counts"))

        Write-PodeHtmlResponse $HTML
    }

    # Info Page
    Add-PodeRoute -Method Get -Path '/info' -ScriptBlock {
        # Load Functions
        . ($PSScriptRoot + "/functions.ps1")

        # Load and fill HTML Template
        $HTML = Get-Content ($PSScriptRoot + "/html/template_info.html") -raw
        $HTML = $HTML.Replace("///NAVBAR",(Get-NavMenuHTML -ActiveItem "info"))

        Write-PodeHtmlResponse $HTML
    }

    # Swagger Page
    Add-PodeRoute -Method Get -Path '/swagger-api' -ScriptBlock {
        # Load Functions
        . ($PSScriptRoot + "/functions.ps1")

        # Load and fill HTML Template
        $HTML = Get-Content ($PSScriptRoot + "/html/template_swagger.html") -raw
        $HTML = $HTML.Replace("///NAVBAR",(Get-NavMenuHTML -ActiveItem "swagger"))

        Write-PodeHtmlResponse $HTML
    }

} -Verbose -Debug