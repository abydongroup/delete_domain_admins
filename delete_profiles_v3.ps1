# Benutzerprofil-Verzeichnis festlegen
$profilePath = "C:\Users"

# Maximalalter für Benutzerprofile in Tagen
$maxAgeInDays = 60

# Benutzerkonten, die ausgeschlossen werden sollen
$excludeUsers = @("HauptBenutzer", "Administrator")

# Gruppen, deren Mitgliederprofile nicht gelöscht werden sollen
$excludeGroups = @("Domain Admins")

# Logdatei erstellen oder vorhandene Logdatei laden
$logPath = Join-Path -Path $env:TEMP -ChildPath "ProfileCleanupLog.txt"

# Logdatei vorbereiten: Wenn die Logdatei größer als 10 MB ist, älteste Einträge löschen
if (Test-Path $logPath) {
    $logSize = (Get-Item $logPath).length
    if ($logSize -ge 10MB) {
        $logContent = Get-Content $logPath
        $logContent | Select-Object -Last 100 | Set-Content $logPath
    }
} else {
    New-Item -ItemType File -Path $logPath | Out-Null
}

function Log-Message {
    param (
        [string]$message
    )
    Add-Content -Path $logPath -Value "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - $message"
}

# Benutzerprofile älter als $maxAgeInDays löschen
$deletedProfiles = @()
$deletedDomainAdmins = @()

$oldProfiles = Get-ChildItem $profilePath | Where-Object {
    $_.PsIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays(-$maxAgeInDays)
}

foreach ($profile in $oldProfiles) {
    $username = $profile.Name
    if ($username -in $excludeUsers -or (Get-LocalGroupMember -Group $excludeGroups -Member $username -ErrorAction SilentlyContinue)) {
        Continue  # Benutzer ausschließen
    }

    Write-Host "Lösche Benutzerprofil: $username"
    Remove-Item -Path $profile.FullName -Recurse -Force
    $deletedProfiles += $username
    if ($username -in (Get-LocalGroupMember -Group $excludeGroups).Name) {
        $deletedDomainAdmins += $username
    }
    Log-Message "Gelöschtes Benutzerprofil: $username"
}

# Log-Einträge erstellen
if ($deletedProfiles.Count -gt 0) {
    Log-Message "Gelöschte Benutzerprofile: $($deletedProfiles -join ', ')"
}

if ($deletedDomainAdmins.Count -gt 0) {
    Log-Message "Gelöschte Domain Admins: $($deletedDomainAdmins -join ', ')"
}

Write-Host "Benutzerprofile gelöscht."

# Logdatei anzeigen
Get-Content $logPath
