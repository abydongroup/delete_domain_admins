$removeThese = Get-CimInstance -Class Win32_UserProfile -verbose | Where-Object {(!$_.Special) -and ($_.LastUseTime -lt (Get-Date).AddDays(-1)) -and ($_.SID -notmatch '*500')}
foreach ($remove in $removeThese) {
Remove-CimInstance $remove -Confirm:$FALSE -ErrorAction continue -ErrorVariable RemoveError
}

get-localuser | where {$_.name -notmatch 'Administrator' -and $_.name -notlike 'LocalAdmin' -and $_.name -notmatch 'DefaultAccount' -and $_.name -notmatch 'Guest' -and $_.name -notmatch 'WDAGUtilityAccount'} | remove-localuser

$profiledirectory="C:\Users\"
Get-ChildItem -Path $profiledirectory -verbose | Where-Object {$_.LastAccessTime -lt (Get-Date).AddDays(-1) -and ($_.FullName -notmatch 'Administrator|Public|LocalAdmin') }
    ForEach-Object{
        Get-ChildItem 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\ProfileList' -verbose |
            ForEach-Object{
            $profilepath=$_.GetValue('ProfileImagePath')    
            if($profilepath -notmatch 'administrator|NetworkService|Localservice|systemprofile|LocalAdmin'){
                Write-Host "Removing item: $profilepath" -ForegroundColor green -verbose
                Remove-Item $_.PSPath -verbose
                Remove-Item $profilepath -Recurse -Force -verbose
            }else{
                Write-Host "Skipping item:$profilepath" -Fore blue -Back white -verbose
            }
        }
    }
