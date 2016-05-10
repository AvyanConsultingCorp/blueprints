1. create resource group in eastus2 
2.deploy deployCassandradc1.json in resource group
2. in portal in the outputs copy the content of variables uniquestr and opsCenterURL
3. open deployCassandradc2.json and replace the content of variable beleow with uniquestr 
 "uniqueString": "2t4mq67ouk57c"
4. create resource group in west us
5. deploy deployCassandradc2.json
6. deploy configurefirstvnet.json in first resource group. the vnet names and ip addresses in deployCassandra1.json
and configurefirstvent.jsone have to match
7. deploy configurefirstvnet.json in first resource group. the vnet names and ip addresses in deployCassandra1.json
and configurefirstvent.jsone have to match
8. deploy configuretrafficmanager.json