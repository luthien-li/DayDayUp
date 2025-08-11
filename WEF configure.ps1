
$Servers = Get-Content -Path ".\servers.txt"

foreach ($Server in $Servers) {
    Write-Host "`n==== $Server ====" -ForegroundColor Cyan

    try {
        Invoke-Command -ComputerName $Server -ScriptBlock {

          
            Set-Service -Name WinRM -StartupType Automatic
            Start-Service -Name WinRM -ErrorAction SilentlyContinue

           
            $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog\EventForwarding\SubscriptionManager"
            if (-not (Test-Path $RegPath)) {
                New-Item -Path $RegPath -Force | Out-Null
            }

         
            New-ItemProperty -Path $RegPath -Name "1" -Value "Server=http://xxxxx1/wsman/SubscriptionManager/WEC" -PropertyType String -Force | Out-Null
            New-ItemProperty -Path $RegPath -Name "2" -Value "Server=http://xxxxx2/wsman/SubscriptionManager/WEC" -PropertyType String -Force | Out-Null


            Restart-Service -Name WinRM -Force

         
            $Today = (Get-Date).Date
            $Events = Get-WinEvent -LogName "Microsoft-Windows-Event-ForwardingPlugin/Operational" |
                      Where-Object { $_.Id -eq 100 -and $_.TimeCreated -ge $Today }

           
            $Success = $false
            foreach ($event in $Events) {
                if ($event.Message -match "created successfully" -and $event.Message -notmatch "failed") {
                    $Success = $true
                    break
                }
            }

            if ($Success) {
                Write-Host "$Server is successfully completed" -ForegroundColor Green
            }
            else {
                Write-Host "$Server is not completed" -ForegroundColor Yellow
            }

        } -ErrorAction Stop

    }
    catch {
        Write-Warning "error: $Server"
    }
}
