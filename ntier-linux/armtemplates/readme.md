1. open deployCassandradc1.json
2. open ntiertemplate.json
3. validate that the ip ranges match the same network segment as in
 dcployCassandra.json. for example 10.8.0.0/24 and 10.8.2.0/24 have to match in CASSANDRA_SUBNET_IP_RANGE 
 with VnetAddressPrefix and CASSANDRA_SUBNET_IP_RANGE with cassdcSubnetPrefix. The other addresses in ntiertemplate.json the netwok
 portion have to match. for example 10.8
 
 "VNET_IP_RANGE": "10.8.0.0/16",
 "SUBNET_DEFAULT": "10.8.0.0/24",
 "SERVICE_SUBNET_IP_RANGE_1": "10.8.10.0/24",
 "MGT_SUBNET_IP_RANGE": "10.8.4.0/26",
 "SERVICE_SUBNET_IP_RANGE_2": "10.8.3.0/24",
 "DMZ_SUBNET_IP_RANGE_1": "10.8.5.0/26",
 "DMZ_SUBNET_IP_RANGE_2": "10.8.6.0/26",
 "CASSANDRA_SUBNET_IP_RANGE": "10.8.2.0/24",
 "SERVICE_TIER_COUNT": 2,
 "SERVICE_ILB_IP_1": "10.8.10.250",
 "SERVICE_ILB_IP_2": "10.8.3.250",
 
   "VnetAddressPrefix": {
            "type": "string",
            "defaultValue": "10.8.0.0/16",
            "metadata": {
                "description": "Address space one for the first VNET"
            }
        },
        "cassdcSubnetPrefix": {
            "type": "string",
            "defaultValue": "10.8.2.0/24",
            "metadata": {
                "description": "The IP address prefix for the frontend subnet in the first VNET."
            }
        },
4. VNET_NAME in ntiertemplate.json and vnetname in deployCassandradc1.json have to match

 "VNET_NAME": "primary-dc0-vnet"
 "vnetname": "primary-dc0-vnet",
 
5. deploy first deployCassandradc1.json then ntierteamplate.json
 