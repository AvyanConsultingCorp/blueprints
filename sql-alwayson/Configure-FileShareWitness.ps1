# Format F: drive
Initialize-Disk -Number 2
New-Partition -DiskNumber 2 -UseMaximumSize -DriveLetter F
Format-Volume -DriveLetter F -Force

# Create new share
New-Item f:\cluster1-fsw -ItemType directory
New-SmbShare -Name cluster1-fsw -Path F:\cluster1-fsw -FullAccess Administrators

