# Remote Log Cleanup Script
# Requires: Current session running with domain admin privileges

# ===== Configuration =====
$ComputerName = "YOUR_SERVER_NAME"   # Replace with target server name or IP
$LogPath = "D:\Logs\YourService"     # Replace with actual log directory path
# =========================

try {
    # Establish remote session
    $session = New-PSSession -ComputerName $ComputerName -ErrorAction Stop
    
    # Get disk space before cleanup
    $before = Invoke-Command -Session $session -ScriptBlock {
        Get-Volume -DriveLetter D | Select-Object -ExpandProperty SizeRemaining
    }
    Write-Host "Pre-cleanup D: drive free space: $([math]::Round($before/1GB, 2)) GB" -ForegroundColor Cyan

    # Perform log cleanup
    Invoke-Command -Session $session -ScriptBlock {
        param($Path)
        
        Write-Host "Cleaning log files older than 2 days in $Path..."
        
        # Find and delete files older than 2 days
        $oldFiles = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | 
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-2) }
        
        if ($oldFiles) {
            $totalSize = ($oldFiles | Measure-Object -Property Length -Sum).Sum
            $oldFiles | Remove-Item -Force -Verbose
            Write-Host "Cleaned $($oldFiles.Count) files, freed $([math]::Round($totalSize/1GB, 2)) GB"
        }
        else {
            Write-Host "No log files found for cleanup" -ForegroundColor Yellow
        }
        
    } -ArgumentList $LogPath

    # Get disk space after cleanup
    $after = Invoke-Command -Session $session -ScriptBlock {
        Get-Volume -DriveLetter D | Select-Object -ExpandProperty SizeRemaining
    }
    Write-Host "Post-cleanup D: drive free space: $([math]::Round($after/1GB, 2)) GB" -ForegroundColor Green

}
catch {
    Write-Host "`nERROR: $_" -ForegroundColor Red
    exit 1
}
finally {
    # Cleanup session
    if ($session) { Remove-PSSession $session }
}