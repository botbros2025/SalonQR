param(
    [string]$Source = "D:\ManageMySalon-Admin-Panel\frontend\supabase",
    [string]$Destination = "D:\SALONX.X\supabase"
)
#npm run sync:migrations

Write-Host "Syncing migrations..."
Write-Host "Source      : $Source"
Write-Host "Destination : $Destination"

if (!(Test-Path $Source)) {
    Write-Error "Source folder does not exist: $Source"
    exit 1
}

if (!(Test-Path $Destination)) {
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
}

robocopy $Source $Destination /E /XO /R:2 /W:1 /NFL /NDL /NJH /NJS /NP

# Robocopy exit codes:
# 0 = No changes
# 1 = Files copied successfully
# <8 = Success
# >=8 = Failure
if ($LASTEXITCODE -ge 8) {
    Write-Error "Migration sync failed."
    exit $LASTEXITCODE
}

Write-Host "[OK] Migrations synced successfully."
exit 0