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
}
catch {
    Write-Host (" -> Database is not present!") -ForegroundColor Yellow
    Throw ("FATAL! Connection to the MariaDB Server is possible but not to the Database '$env:MariaDBDatabase'. Error: " + $_.Exception.Message + ". The App needs a Database to work as intended, cannot continue!")
    Exit 
} 
Write-Host ""

# Loop