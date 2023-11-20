# PowerShell-Skript zum Löschen von lokalen und Domänenadministratorenprofilen, die älter als 60 Tage sind
# script design: I.Pielczyk für task INFRA-1866

# Festlegen des Alters in Tagen
$maxAgeInDays = 60

# Logdatei festlegen
$logFile = "C:\Temp\RemoveProfiles_Log.txt"

# Funktion zum Löschen eines Benutzerprofils und zum Loggen des Vorgangs
function Remove-UserProfile($profilePath) {
    try {
        Remove-Item -Path $profilePath -Recurse -Force
        Add-Content -Path $logFile -Value "Profil gelöscht: $($profilePath.FullName)"
    } catch {
        Add-Content -Path $logFile -Value "Fehler beim Löschen des Profils $($profilePath.FullName): $_"
    }
}

# Lokale Administratoren abrufen
$localAdmins = net localgroup Administratoren | Select-Object -Skip 4

# Domänenadministratoren abrufen
$domainAdmins = Get-WmiObject Win32_GroupUser | Where-Object { $_.GroupComponent -match "Domain Admins" } | ForEach-Object {
    $adminName = $_.PartComponent -replace '^.*Name="([^"]+)".*$', '$1'
    $adminName
}

# Profile älter als 60 Tage löschen
foreach ($profilePath in (Get-ChildItem -Path "C:\Users" | Where-Object { $_.PSIsContainer -and (Test-Path (Join-Path $_.FullName 'NTUSER.DAT')) })) {
    $lastWriteTime = $profilePath.LastWriteTime
    $ageInDays = (Get-Date) - $lastWriteTime
    if ($ageInDays.Days -gt $maxAgeInDays) {
        if (($localAdmins -contains $profilePath.Name) -or ($domainAdmins -contains $profilePath.Name)) {
            Remove-UserProfile -profilePath $profilePath
        }
    }
}

# end script
