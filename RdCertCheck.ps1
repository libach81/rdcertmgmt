#-----------------------------------------------

#This Powershell script compares the certificate currently configured on the Remote Desktop Connection Broker to the specified certificate in Windows Certificate Store.
#If the certificate in the Certificate Store is newer, it will perform an export from the store and import it to the Remote Desktop Connection Broker.
#On running, the script will also write the results of its run in the event log to allow monitoring.
#This script was written with Let's Encrypt in mind, but is provider agnostic and can be used where-ever.

#-----------------------------------------------

#RUN ONCE Settings
#These settings are needed before the script can be used. You can copy/paste them to an elevated powershell prompt for running.

#This line is used to create a password for the script to use when exporting/importing the certificate and storing it encrypted in a file.
#Note that the script will fail if it is run under a different account than the one that generated the password. You only need to run it once when setting the password to begin with, and in case you want to change it.

#"3nter.A.Rea11y.S3cur3.Passw0rd." | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File "C:\RdCertMgmt\Password.txt"

#This line creates the event log source used for logging status of the script to the event log.
#New-EventLog -LogName Application -Source RdCertMgMt

#-----------------------------------------------

#Variables used for running the script

#Specify where to read the password file generated previously
$pass = Get-Content "C:\RdCertMgMt\Password.txt" | ConvertTo-SecureString
#Specify the Subject (CN) of the certificate, eg "CN=www.microsoft.com"
$certforexport = get-childitem Cert:\LocalMachine\WebHosting | Where-Object {$_.Subject -eq "CN=www.microsoft.com"} | select -Last 1
#This line specifies which role to check for the currently used certificate. Can be RDGateway, RDWebaccess, RDRedirector or RDPublisher
$certused = Get-RDCertificate -Role RDGateway
#This line can be used for manual testing by setting a random date in the past
#$certused = "01/17/2018 16:37:29"

#-----------------------------------------------

IF($certforexport.NotAfter -gt $certused.ExpiresOn)
    {
        Write-EventLog -LogName Application -Source RdCertMgmt -EntryType Information -EventId 1 -Message "Certificate renewal detected. Changing certificate on RD server. Certificate in machine store was dated $($certforexport.NotAfter) and certificate on RD server was dated $($certused.ExpiresOn)"
        Export-PfxCertificate -Cert Cert:\LocalMachine\WebHosting\$($certforexport.thumbprint) -FilePath "C:\RdCertMgmt\rdcert.pfx" -Password $pass
        Set-RDCertificate -Role RDGateway -ImportPath C:\RdCertMgmt\rdcert.pfx -Password $pass -Force
        Set-RDCertificate -Role RDPublishing -ImportPath C:\RdCertMgmt\rdcert.pfx -Password $pass -Force
        Set-RDCertificate -Role RDRedirector -ImportPath C:\RdCertMgmt\rdcert.pfx -Password $pass -Force
        Set-RDCertificate -Role RDWebAccess -ImportPath C:\RdCertMgmt\rdcert.pfx -Password $pass -Force
    }
ELSE
    {
        Write-EventLog -LogName Application -Source RdCertMgmt -EntryType Information -EventId 2 -Message "Certificate valid. No changes where made. Certificate in machine store was dated $($certforexport.NotAfter) and certificate on RD server was dated $($certused.ExpiresOn)"
    }
