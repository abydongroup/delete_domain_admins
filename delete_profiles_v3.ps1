# Check, ob das Skript mit Administratorrechten ausgeführt wird
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Dieses Skript erfordert Administratorrechte. Führen Sie PowerShell als Administrator aus und starten Sie das Skript erneut."
    exit
}

# Benutzerprofile-Verzeichnis festlegen
$profilePath = "C:\Users"

# Maximalalter für Benutzerprofile in Tagen
$maxAgeInDays = 60

# Hauptbenutzer, der ausgeschlossen werden soll
$excludeUser = "HauptBenutzer"

# Gruppe, deren Mitgliederprofile nicht gelöscht werden sollen
$excludeGroup = "Domain Admins"

# Logdatei erstellen
$logPath = Join-Path -Path $PSScriptRoot -ChildPath "ProfileCleanupLog.txt"
$maxLogSize = 10MB

# Wenn die Logdatei die maximale Größe erreicht hat, älteste Einträge löschen
if (Test-Path $logPath -and (Get-Item $logPath).length -ge $maxLogSize) {
    $logContent = Get-Content $logPath
    $logContent | Select-Object -Skip 100 | Set-Content $logPath
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
    if ($username -ne $excludeUser -and -not (Get-LocalGroupMember -Group $excludeGroup -Member $username -ErrorAction SilentlyContinue)) {
        Write-Host "Lösche Benutzerprofil: $username"
        Remove-Item -Path $profile.FullName -Recurse -Force
        $deletedProfiles += $username
        if ($username -in (Get-LocalGroupMember -Group $excludeGroup).Name) {
            $deletedDomainAdmins += $username
        }
    }
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
