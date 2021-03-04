﻿<#
    .SYNOPSIS  
        Collects data from Microsoft Exchange Servers that assist in indentifying if the system was exploited via CVEs 2021-26855, 26857, 26858, and 27065. Some
        analysis is automatically done while other parts requires analysis. 

    .EXAMPLE
        PS C:\> .\Invoke-HAFNIUMCheck.ps1

    .LINKS
        https://www.microsoft.com/security/blog/2021/03/02/hafnium-targeting-exchange-servers/
        https://www.volexity.com/blog/2021/03/02/active-exploitation-of-microsoft-exchange-zero-day-vulnerabilities/

#>

# Creating data directory
function dirCreate{
    write-host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Creating the Data Directory ($env:SystemRoot\temp\$env:COMPUTERNAME-exch)..."
    if(-not(test-path $env:SystemRoot\temp\$env:COMPUTERNAME-exch)){
        new-item -Path $env:SystemRoot\temp\$env:COMPUTERNAME-exch -ItemType Directory | out-null
    }
}

# Retrieving version of Exchange
function version{
    write-host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Retrieving Microsoft Exchange version..."
    $keys = (Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall).pspath
    foreach($key in $keys){
        $out = Get-ItemProperty $key | Select-Object displayname , displayversion, installdate, installlocation, publisher
        if($out.displayname -eq "Microsoft Exchange Server"){
            $out | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\Version.txt
        }
    }
    Remove-Variable out -ErrorAction SilentlyContinue
}

# CVE-2021-26855
function CVE-2021-26855{
    write-host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Retrieving data for CVE-2021-26855..."
    if(test-path $env:ExchangeInstallPath\V15\Logging\HttpProxy){
        $out = Import-Csv -Path (Get-ChildItem -Recurse -Path "$env:ExchangeInstallPath\V15\Logging\HttpProxy" -Filter '*.log').FullName | Where-Object {  $_.AuthenticatedUser -eq '' -and $_.AnchorMailbox -like 'ServerInfo~*/*' } | select DateTime, AnchorMailbox
        if($out){
            $out | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\HTTProxy.txt
            Write-Host -ForegroundColor yellow "[+] " -NoNewline; Write-Host -ForegroundColor green "Suspicious Data in HTTP Proxy Log"
        }
        else{
            Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor yellow "System Not Affected Based on the HTTP Proxy Log"
            Write-Output "System Not affected" | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\httpproxy.txt
        }
    }
    elseif(test-path $env:ExchangeInstallPath\Logging\HttpProxy){
        $out = Import-Csv -Path (Get-ChildItem -Recurse -Path "$env:ExchangeInstallPath\Logging\HttpProxy" -Filter '*.log').FullName | Where-Object {  $_.AuthenticatedUser -eq '' -and $_.AnchorMailbox -like 'ServerInfo~*/*' } | select DateTime, AnchorMailbox
        if($out){
            $out | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\httpproxy.txt
            Write-Host -ForegroundColor yellow "[+] " -NoNewline; Write-Host -ForegroundColor green "Suspicious Data in HTTP Proxy Log"
        }
        else{
            Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "System Not Affected Based on the HTTP Proxy"
            Write-Output "System Not affected" | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\httpproxy.txt
        }    
    }
    else{
        Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "HTTP Proxy Log Doesn't Exist"
        Write-Output "Log doesn't exist" | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\HTTPProxy.txt
    }
    Remove-Variable out -ErrorAction SilentlyContinue
}

# CVE-2021-26857
function CVE-2021-26857{
    write-host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Retrieving data for CVE-2021-26857..."
    if(test-path "$env:ExchangeInstallPath\V15\Logging\OABGeneratorLog\*.log"){
        $out = select-string -path "$env:ExchangeInstallPath\V15\Logging\OABGeneratorLog\*.log" -Pattern "Download failed and temporary file"
        if($out){
            $out | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\OABGeneratorLog.txt
            Write-Host -ForegroundColor yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Suspicious data in OAB Logs"
        }
        else{
            Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Nothing Suspicious in OAB Logs"
            Write-Output "Nothing Suspicious in OAB Logs" | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\OABGeneratorLog.txt        
        }
    }
    elseif(test-path "$env:ExchangeInstallPath\Logging\OABGeneratorLog\*.log"){
        $out = select-string -path "$env:ExchangeInstallPath\Logging\OABGeneratorLog\*.log" -Pattern "Download failed and temporary file"
        if($out){
            $out | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\OABGeneratorLog.txt
            Write-Host -ForegroundColor yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Suspicious data in OAB Logs"
        }
        else{
            Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Nothing Suspicious in OAB Logs"
            Write-Output "Nothing Suspicious in OAB Logs" | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\OABGeneratorLog.txt        
        }
    }
    else{
        Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "OAB Logs Don't Exist"
        Write-Output "Log Doesn't Exist" | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\OABGeneratorLog.txt    
    }
    Remove-Variable out -ErrorAction SilentlyContinue
}

# CVE-2021-26858
function CVE-2021-26858{
    write-host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Retrieving data for CVE-2021-26858..."
    try{
        $out = Get-EventLog -LogName Application -Source "MSExchange Unified Messaging" -EntryType Error -ErrorAction Stop | Where-Object { $_.Message -like "*System.InvalidCastException*" } 
        $out | export-csv $env:SystemRoot\temp\$env:COMPUTERNAME-exch\EventLogs.csv
        Write-Host -ForegroundColor yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Suspicious data in MSExchange Unified Messaging Logs"
        }
    catch{
        Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "No Applicable MSExchange Unified Messaging Logs Exist"
        Write-Output "No Applicable Event Logs Exist" | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\ECPLogs.txt  
    }
    Remove-Variable out -ErrorAction SilentlyContinue
}

# CVE-2021-27065
function CVE-2021-27065{
    write-host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Retrieving data for CVE-2021-27065..."
    if(test-path "$env:ExchangeInstallPath\V15\Logging\ECP\Server\*.log"){
        $out = Select-String -Path "$env:ExchangeInstallPath\V15\Logging\ECP\Server\*.log" -Pattern 'Set-.+VirtualDirectory' -ErrorAction SilentlyContinue
        if($out){
            $out | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\ECPLogs.txt 
            Write-Host -ForegroundColor yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Suspicious Data in ECP Logs"
        }
        else{
            Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Nothing Suspicious in ECP Logs"
            Write-Output "Nothing Suspicious in ECP Logs" | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\ECPLogs.txt         
        }
    }
    elseif(test-path "$env:ExchangeInstallPath\Logging\ECP\Server\*.log"){
        $out = Select-String -Path "$env:ExchangeInstallPath\Logging\ECP\Server\*.log" -Pattern 'Set-.+VirtualDirectory' -ErrorAction SilentlyContinue
        if($out){
            $out | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\ECPLogs.txt 
            Write-Host -ForegroundColor yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Suspicious Data in ECP Logs"
        }
        else{
            Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Nothing Suspicious in ECP Logs"
            Write-Output "Nothing Suspicious in ECP Logs" | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\ECPLogs.txt         
        }
    }
    else{
        Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "ECP Logs Don't Exist"
        Write-Output "Log Doesn't Exist" | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\ECPLogs.txt 
    }
    Remove-Variable out -ErrorAction SilentlyContinue
}

# Hash validation
function hash{
    Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Checking Webshell Hashes..."
    $paths = "C:\inetpub\wwwroot\aspnet_client\","C:\inetpub\wwwroot\aspnet_client\system_web\","$env:ExchangeInstallPath\V15\FrontEnd\HttpProxy\owa\auth\","$env:ExchangeInstallPath\FrontEnd\HttpProxy\owa\auth\","C:\Exchange\FrontEnd\HttpProxy\owa\auth\", "$env:ExchangeInstallPath\FrontEnd\HttpProxy\owa\auth\"
    $hashes = "b75f163ca9b9240bf4b37ad92bc7556b40a17e27c2b8ed5c8991385fe07d17d0","097549cf7d0f76f0d99edf8b2d91c60977fd6a96e4b8c3c94b0b1733dc026d3e","2b6f1ebb2208e93ade4a6424555d6a8341fd6d9f60c25e44afe11008f5c1aad1","65149e036fff06026d80ac9ad4d156332822dc93142cf1a122b1841ec8de34b5","511df0e2df9bfa5521b588cc4bb5f8c5a321801b803394ebc493db1ef3c78fa1","4edc7770464a14f54d17f36dc9d0fe854f68b346b27b35a6f5839adf1f13f8ea", "811157f9c7003ba8d17b45eb3cf09bef2cecd2701cedb675274949296a6a183d", "1631a90eb5395c4e19c7dbcbf611bbe6444ff312eb7937e286e4637cb9e72944"

    $out = (Get-ChildItem $Paths -Recurse -Filter "*.aspx" -ErrorAction SilentlyContinue).FullName
    foreach($path in $out){
        $sysHashes = get-filehash $path -Algorithm SHA1
        foreach($sysHash in $sysHashes){
            if($hashes -contains $sysHash.hash){
                $sysHash | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\HashesMatch.csv -Append 
                $sys = $sysHash.hash 
                write-host -ForegroundColor yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "$sys Matched Known Actor Hashes"
                }
            }
        }
    Remove-Variable out -ErrorAction SilentlyContinue
}

# Compressed Files
function exfilStage{
    write-host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Checking for potential data staged for exfil..."
    $out = (Get-ChildItem $env:systemdrive\ProgramData\*.zip, $env:systemdrive\ProgramData\*.7z, $env:systemdrive\ProgramData\*.rar  -ErrorAction SilentlyContinue).FullName
    if($out){
            Write-Host -ForegroundColor yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Potential Data Exfil Staging in the ProgramData Directory"
            $out | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\CompressedFiles.txt 
    }
    else{
            Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "No Compressed Items within the ProgramData Directory"
            Write-Output "No Compressed Items within the ProgramData Directory" | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\CompressedFiles.txt 
    }
    Remove-Variable out -ErrorAction SilentlyContinue
}

# Searching for potential LSASS dumps
function lsass{
    write-host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Checking for potential LSASS dumps..."
    new-item -Path $env:SystemRoot\temp\$env:COMPUTERNAME-exch\dumps -ItemType Directory | out-null

    $files = (Get-ChildItem c:\root, c:\windows\temp -File).FullName
    foreach($file in $files){
    $byte = [Byte[]](Get-Content -Path $file -TotalCount 4 -Encoding Byte -ErrorAction SilentlyContinue) -join('')
        if($byte-eq 77687780){
            Write-Host -ForegroundColor yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "$file is a possible LSASS dump"
            Copy-item $file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\dumps -Force  
            $count++  
        }
    }
    if($count){
        Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "No Potential LSASS Dumps Found"       
    }
}

# Sysinternals Check
function sysinternals{
    write-host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Checking for the use of Procdump or PSExec..."
    $out = (Get-childitem HKCU:\Software\sysinternals\p[r-s]*).pschildname
    if(Get-childitem HKCU:\Software\sysinternals\p[r-s]*){
        Write-Host -ForegroundColor yellow "[+] " -NoNewline; Write-Host -ForegroundColor Green "Procdump or PSExec has been used on the system"
        $out | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\SysInternals.txt    
    }
    else{
        Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "No Sysinternals tools were used on this system"
        Write-Output "No Sysinternals tools were used on this system" | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\Sysinternals.txt   
    }
    Remove-Variable out -ErrorAction SilentlyContinue
}

# Other Event Logs
function eventLogs{
    write-host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Retrieving PowerShell logs..."
    try{
        $out = Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -ErrorAction stop | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\PSLog.csv -Append
        }
    catch{
        Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "No PowerShell Logs Exist"
        Write-Output "No Applicable Event Logs Exist" | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\ECPLogs.txt  
    }
    write-host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Retrieving Process Creation logs..."
    try{
        $out = Get-WinEvent -FilterHashtable @{logname='security'; id='4688'} -ErrorAction stop | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\PSLog.csv -Append
        }
    catch{
        Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "No Process Creation Events Exist"
        Write-Output "No Applicable Event Logs Exist" | out-file $env:SystemRoot\temp\$env:COMPUTERNAME-exch\ECPLogs.txt  
    }
}

# Retreiving SRU DB, if present
function sru{
    write-host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Checking if SRU DB exists..."
    if(test-path "C:\Windows\system32\sru\srudb.dat"){
        Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Copying SRU DB"
        copy-item "C:\Windows\system32\sru\srudb.dat" "$env:SystemRoot\temp\$env:COMPUTERNAME-exch\"
    }
    else{
        Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "SRU DB doesn't exist"
    }
}

# Zips data that was gathered
function zip{
    $src = "$env:SystemRoot\temp\$env:COMPUTERNAME-exch"
    $dst = "$env:SystemRoot\temp\$env:COMPUTERNAME-exch.zip"
    try {
        Add-Type -assembly "system.io.compression.filesystem"
        [io.compression.zipfile]::CreateFromDirectory($src,$dst)
        Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Zipping $env:SystemRoot\temp\$env:COMPUTERNAME-exch..."
        Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "$env:SystemRoot\temp\$env:COMPUTERNAME-exch.zip has been created in $env:SystemRoot\temp"
    }
    catch {
        Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-host "Could not zip the $env:SystemRoot\temp\$env:COMPUTERNAME-exch, please do it manually." -foregroundcolor red
    }
    Write-Host -ForegroundColor cyan "[+] " -NoNewline; Write-Host -ForegroundColor Green "Done!"
}

dirCreate
version
CVE-2021-26855
CVE-2021-26857
CVE-2021-26858
CVE-2021-27065
hash
exfilStage
lsass
sysinternals
eventLogs
sru
zip