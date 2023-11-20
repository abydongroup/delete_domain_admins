# PowerShell-Skript zum Löschen von lokalen und Domänenadministratorenprofilen, die älter als 60 Tage sind
# script design: I.Pielczyk

# Festlegen des Alters in Tagen
$maxAgeInDays = 60

# Funktion zum Löschen eines Benutzerprofils
function Remove-UserProfile($profilePath) {
    try {
        Remove-Item -Path $profilePath -Recurse -Force
        Write-Host "Profil gelöscht: $profilePath"
    } catch {
        Write-Host "Fehler beim Löschen des Profils: $_"
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
            Remove-UserProfile -profilePath $profilePath.FullName
        }
    }
}

# end script
