
New-Cluster -Name cluster1 -StaticAddress 10.0.1.25 -Node sql1,sql2 -NoStorage
Set-ClusterQuorum -InputObject $cluster -FileShareWitness "\\fsw\cluster1-fsw"