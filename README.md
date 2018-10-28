# Remote Desktop Certificate Management


This Powershell script compares the certificate currently configured on the Remote Desktop Connection Broker to the specified certificate in Windows Certificate Store.

If the certificate in the Certificate Store is newer, it will perform an export from the store and import it to the Remote Desktop Connection Broker.

On running, the script will also write the results of its run in the event log to allow monitoring.

This script was written with Let's Encrypt in mind, but is provider agnostic and can be used where-ever.
