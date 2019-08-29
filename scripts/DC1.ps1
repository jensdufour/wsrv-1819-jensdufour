Workflow DC_Setup {
    $hostname = "WS-CLI"
    $domainname = "AXXESTRAINEE.COM"
    $ip = "172.16.1.1"
    $password = ConvertTo-SecureString -String "P@ssw0rd" -AsPlainText -Force
    # Change hostname
    Rename-Computer -PSComputerName $env:COMPUTERNAME -newName $hostname -Force
    Restart-Computer -Wait
    # Change networksettings
    New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress $ip -PrefixLength 24 -DefaultGateway $ip
    Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses $ip, "8.8.8.8"   
    # Install Forest
    InlineScript { Install-WindowsFeature AD-Domain-Services -IncludeManagementTools }
    InlineScript { Install-ADDSForest `
            -DomainName $domainname `
            -CreateDnsDelegation:$false `
            -DatabasePath "C:\Windows\NTDS" `
            -DomainMode "7" `
            -DomainNetbiosName "REBELADMIN" `
            -ForestMode "7" `
            -InstallDns:$true `
            -LogPath "C:\Windows\NTDS" `
            -NoRebootOnCompletion:$True `
            -SysvolPath "C:\Windows\SYSVOL" `
            -SafeModeAdministratorPassword:($password) `
            -Force:$true }
    Unregister-ScheduledJob -Name ResumeScript
    Restart-computer
}
# -------------------------------------------------------------------------
# Resume at Startup-Trigger
# -------------------------------------------------------------------------
$adm = "Administrator"
$pwd = ConvertTo-SecureString -String "P@ssw0rd" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($adm, $pwd)
$AtStartup = New-JobTrigger -AtStartup
Register-ScheduledJob -Name ResumeScript `
    -Credential $cred `
    -Trigger $AtStartup `
    -ScriptBlock { Import-Module PSWorkflow; `
        Get-Job -Name ServerProvisioning -State Suspended `
    | Resume-Job }
DC_Setup -JobName ServerProvisioning