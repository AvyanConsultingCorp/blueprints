  "resources": [
        {
            "type": "Microsoft.Compute/availabilitySets",
            "name": "[concat(variables('APP_NAME'),'-dmz-as')]",
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "tags": { },
            "properties": {
                "platformUpdateDomainCount": 5,
                "platformFaultDomainCount": 3
            },
            "dependsOn": [ ]
        },
        {
            "type": "Microsoft.Compute/availabilitySets",
            "name": "[concat(variables('APP_NAME'),'-svc1-as')]",
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "tags": { },
            "properties": {
                "platformUpdateDomainCount": 5,
                "platformFaultDomainCount": 3
            },
            "dependsOn": [ ]
        },
        {
            "type": "Microsoft.Compute/availabilitySets",
            "name": "[concat(variables('APP_NAME'),'-svc2-as')]",
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "tags": { },
            "properties": {
                "platformUpdateDomainCount": 5,
                "platformFaultDomainCount": 3
            },
            "dependsOn": [ ]
        },
        {
            "type": "Microsoft.Compute/virtualMachines",
            "name": "[concat(variables('APP_NAME'),'-dmz-vm',copyIndex(1))]",
            "copy": {
                "name": "vmloop",
                "count": "[parameters('NUM_VM_INSTANCES_DMZ_TIER')]"
            },
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "tags": { },
            "properties": {
                "availabilitySet": {
                    "id": "[resourceId('Microsoft.Compute/availabilitySets', concat(variables('APP_NAME'),'-dmz-as'))]"
                },
                "hardwareProfile": {
                    "vmSize": "[parameters('vmSize')]"
                },
                "storageProfile": {
                    "imageReference":  "[variables('osSettings').imageReference]",
                      
                    "osDisk": {
                        "name": "osDisk",
                        "createOption": "FromImage",
                        "vhd": {
                            "uri": "[concat('https', '://', variables('APP_NAME'),'dmzvm',copyIndex(1),'st1', '.blob.core.windows.net', concat('/vhds/', concat(variables('APP_NAME'),'-dmz-vm',copyIndex(1),'-osdisk.vhd')))]"
                        },
                        "caching": "ReadWrite"
                    },
                    "dataDisks": [
                        {
                            "lun": 0,
                            "name": "datadisk",
                            "createOption": "Empty",
                            "vhd": {
                                "uri": "[concat('https', '://', variables('APP_NAME'),'dmzvm',copyIndex(1),'st1', '.blob.core.windows.net', concat('/vhds/', concat(variables('APP_NAME'),'-dmz-vm',copyIndex(1),'-data1.vhd')))]"
                            },
                            "caching": "ReadWrite",
                            "diskSizeGB": "128"
                        }
                    ]
                },
                "osProfile": {
                    "computerName": "[concat(variables('APP_NAME'),'-dmz-vm',copyIndex(1))]",
                    "adminUsername": "[parameters('adminUsername')]",
                    "linuxConfiguration": {
                        "disablePasswordAuthentication": false
                    },
                    "secrets": [ ],
                    "adminPassword": "[parameters('adminPassword')]"
                },
                "networkProfile": {
                    "networkInterfaces": [
                        {
                            "properties": {
                                "primary": true
                            },
                            "id": "[resourceId('Microsoft.Network/networkInterfaces', concat(variables('APP_NAME'),'-dmz-vm',copyIndex(1),'-nic1'))]"
                        },
                        {
                            "properties": {
                                "primary": false
                            },
                            "id": "[resourceId('Microsoft.Network/networkInterfaces', concat(variables('APP_NAME'),'-dmz-vm',copyIndex(1),'-nic2'))]"
                        }
                    ]
                }
            },
            "dependsOn": [
                "[resourceId('Microsoft.Compute/availabilitySets', concat(variables('APP_NAME'),'-dmz-as'))]",
                "[resourceId('Microsoft.Storage/storageAccounts', concat(variables('APP_NAME'), 'dmzvm', copyIndex(1), 'st1'))]",
                "[resourceId('Microsoft.Network/networkInterfaces', concat(variables('APP_NAME'),'-dmz-vm',copyIndex(1),'-nic1'))]",
                "[resourceId('Microsoft.Network/networkInterfaces', concat(variables('APP_NAME'),'-dmz-vm',copyIndex(1),'-nic2'))]"
            ]
        },
        {
            "type": "Microsoft.Compute/virtualMachines",
            "name": "[concat(variables('APP_NAME'),'-mgt-vm',copyIndex(1))]",
            "copy": {
                "name": "vmloop",
                "count": "[parameters('NUM_VM_INSTANCES_MANAGE_TIER')]"
            },
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "tags": { },
            "properties": {
                "hardwareProfile": {
                    "vmSize": "[parameters('vmSize')]"
                },
                "storageProfile": {
                    "imageReference":  "[variables('osSettings').imageReference]",
                    "osDisk": {
                        "name": "osdisk",
                        "createOption": "FromImage",
                        "vhd": {
                            "uri": "[concat('https', '://', variables('APP_NAME'),'mgtvm',copyIndex(1),'st1', '.blob.core.windows.net', concat('/vhds/', concat(variables('APP_NAME'),'-mgt-vm',copyIndex(1),'-osdisk.vhd')))]"
                        },
                        "caching": "ReadWrite"
                    },
                    "dataDisks": [
                        {
                            "lun": 0,
                            "name": "datadisk",
                            "createOption": "Empty",
                            "vhd": {
                                "uri": "[concat('https', '://', variables('APP_NAME'),'mgtvm',copyIndex(1),'st1', '.blob.core.windows.net', concat('/vhds/', concat(variables('APP_NAME'),'-mgt-vm',copyIndex(1),'-data1.vhd')))]"
                            },
                            "caching": "ReadWrite",
                            "diskSizeGB": "128"
                        }
                    ]
                },
                "osProfile": {
                    "computerName": "[concat(variables('APP_NAME'),'-mgt-vm',copyIndex(1))]",
                    "adminUsername": "[parameters('adminUsername')]",
                    "linuxConfiguration": {
                        "disablePasswordAuthentication": false
                    },
                    "secrets": [ ],
                    "adminPassword": "[parameters('adminPassword')]"
                },
                "networkProfile": {
                    "networkInterfaces": [
                        {
                            "id": "[resourceId('Microsoft.Network/networkInterfaces', concat(variables('APP_NAME'),'-mgt-vm',copyIndex(1),'-nic1'))]"
                        }
                    ]
                }
            },
            "dependsOn": [
                "[resourceId('Microsoft.Storage/storageAccounts', concat(variables('APP_NAME'), 'mgtvm', copyIndex(1), 'st1'))]",
                "[resourceId('Microsoft.Network/networkInterfaces', concat(variables('APP_NAME'),'-mgt-vm',copyIndex(1),'-nic1'))]"
            ]
        },
        {
            "type": "Microsoft.Compute/virtualMachines",
            "name": "[concat(variables('APP_NAME'),'-svc1-vm',copyIndex(1))]",
            "copy": {
                "name": "vmloop",
                "count": "[parameters('NUM_VM_INSTANCES_SERVICE_TIER_1')]"
            },
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "tags": { },
            "properties": {
                "availabilitySet": {
                    "id": "[resourceId('Microsoft.Compute/availabilitySets', concat(variables('APP_NAME'),'-svc1-as'))]"
                },
                "hardwareProfile": {
                    "vmSize": "[parameters('vmSize')]"
                },
                "storageProfile": {
                    "imageReference":  "[variables('osSettings').imageReference]",
                      
                    "osDisk": {
                        "name": "osDisk",
                        "createOption": "FromImage",
                        "vhd": {
                            "uri": "[concat('https', '://', variables('APP_NAME'),'svc1vm',copyIndex(1),'st1', '.blob.core.windows.net', concat('/vhds/', concat(variables('APP_NAME'),'-svc1-vm',copyIndex(1),'-osdisk.vhd')))]"
                        },
                        "caching": "ReadWrite"
                    },
                    "dataDisks": [
                        {
                            "lun": 0,
                            "name": "datadisk",
                            "createOption": "Empty",
                            "vhd": {
                                "uri": "[concat('https', '://', variables('APP_NAME'),'svc1vm',copyIndex(1),'st1', '.blob.core.windows.net', concat('/vhds/', concat(variables('APP_NAME'),'-svc1-vm',copyIndex(1),'-data1.vhd')))]"
                            },
                            "caching": "ReadWrite",
                            "diskSizeGB": "128"
                        }
                    ]
                },
                "osProfile": {
                    "computerName": "[concat(variables('APP_NAME'),'-svc1-vm',copyIndex(1))]",
                    "adminUsername": "[parameters('adminUsername')]",
                    "linuxConfiguration": {
                        "disablePasswordAuthentication": false
                    },
                    "secrets": [ ],
                    "adminPassword": "[parameters('adminPassword')]"
                },
                "networkProfile": {
                    "networkInterfaces": [
                        {
                            "properties": {
                                "primary": true
                            },
                            "id": "[resourceId('Microsoft.Network/networkInterfaces', concat(variables('APP_NAME'),'-svc1-vm',copyIndex(1),'-nic1'))]"
                        }                   
                    ]
                }
            },
            "dependsOn": [
                "[resourceId('Microsoft.Compute/availabilitySets', concat(variables('APP_NAME'),'-svc1-as'))]",
                "[resourceId('Microsoft.Storage/storageAccounts', concat(variables('APP_NAME'), 'svc1vm', copyIndex(1), 'st1'))]",
                "[resourceId('Microsoft.Network/networkInterfaces', concat(variables('APP_NAME'),'-svc1-vm',copyIndex(1),'-nic1'))]"
            ]
       },
        {
            "type": "Microsoft.Compute/virtualMachines",
            "name": "[concat(variables('APP_NAME'),'-svc2-vm',copyIndex(1))]",
            "copy": {
                "name": "vmcopy",
                "count": "[parameters('NUM_VM_INSTANCES_SERVICE_TIER_2')]"
            },
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "tags": { },
            "properties": {
                "availabilitySet": {
                    "id": "[resourceId('Microsoft.Compute/availabilitySets', concat(variables('APP_NAME'),'-svc2-as'))]"
                },
                "hardwareProfile": {
                    "vmSize": "[parameters('vmSize')]"
                },
                "storageProfile": {
                    "imageReference":  "[variables('osSettings').imageReference]",
                      
                    "osDisk": {
                        "name": "osDisk",
                        "createOption": "FromImage",
                        "vhd": {
                            "uri": "[concat('https', '://', variables('APP_NAME'),'svc2vm',copyIndex(1),'st1', '.blob.core.windows.net', concat('/vhds/', concat(variables('APP_NAME'),'-svc2-vm',copyIndex(1),'-osdisk.vhd')))]"
                        },
                        "caching": "ReadWrite"
                    },
                    "dataDisks": [
                        {
                            "lun": 0,
                            "name": "datadisk",
                            "createOption": "Empty",
                            "vhd": {
                                "uri": "[concat('https', '://', variables('APP_NAME'),'svc2vm',copyIndex(1),'st1', '.blob.core.windows.net', concat('/vhds/', concat(variables('APP_NAME'),'-svc2-vm',copyIndex(1),'-data1.vhd')))]"
                            },
                            "caching": "ReadWrite",
                            "diskSizeGB": "128"
                        }
                    ]
                },
                "osProfile": {
                    "computerName": "[concat(variables('APP_NAME'),'-svc2-vm',copyIndex(1))]",
                    "adminUsername": "[parameters('adminUsername')]",
                    "linuxConfiguration": {
                        "disablePasswordAuthentication": false
                    },
                    "secrets": [ ],
                    "adminPassword": "[parameters('adminPassword')]"
                },
                "networkProfile": {
                    "networkInterfaces": [
                        {
                            "properties": {
                                "primary": true
                            },
                            "id": "[resourceId('Microsoft.Network/networkInterfaces', concat(variables('APP_NAME'),'-svc2-vm',copyIndex(1),'-nic1'))]"
                        }                   
                    ]
                }
            },
            "dependsOn": [
                "[resourceId('Microsoft.Compute/availabilitySets', concat(variables('APP_NAME'),'-svc2-as'))]",
                "[resourceId('Microsoft.Storage/storageAccounts', concat(variables('APP_NAME'), 'svc2vm', copyIndex(1), 'st1'))]",
                "[resourceId('Microsoft.Network/networkInterfaces', concat(variables('APP_NAME'),'-svc2-vm',copyIndex(1),'-nic1'))]"
            ]
        },
        {
            "type": "Microsoft.Network/loadBalancers",
            "name": "[variables('DMZ_LB_NAME')]",
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "properties": {
                "frontendIPConfigurations": [
                    {
                        "name": "[variables('DMZ_LB_FRONTEND')]",
                        "properties": {
                            "privateIPAllocationMethod": "Dynamic",
                            "publicIPAddress": {
                                "id": "[resourceId('Microsoft.Network/publicIPAddresses', concat(variables('APP_NAME'),'-pip'))]"
                            }
                        }
                    }
                ],
                "backendAddressPools": [
                    {
                        "name": "[variables('DMZ_LB_BACKEND')]"
                    }
                ],
                "loadBalancingRules": [
                    {
                        "name": "[concat(variables('DMZ_LB_NAME'),'-rule-http')]",
                        "properties": {
                            "frontendIPConfiguration": {
                                "id": "[concat(resourceId('Microsoft.Network/loadBalancers',variables('DMZ_LB_NAME')),'/frontendIPConfigurations/',variables('DMZ_LB_FRONTEND'))]"
                            },
                            "frontendPort": 80,
                            "backendPort": 80,
                            "enableFloatingIP": false,
                            "idleTimeoutInMinutes": 4,
                            "protocol": "Tcp",
                            "loadDistribution": "Default",
                            "backendAddressPool": {
                                "id": "[concat(resourceId('Microsoft.Network/loadBalancers',variables('DMZ_LB_NAME')),'/backendAddressPools/',variables('DMZ_LB_BACKEND'))]"
                            },
                            "probe": {
                                "id": "[concat(resourceId('Microsoft.Network/loadBalancers',variables('DMZ_LB_NAME')),'/probes/',variables('DMZ_LB_PROBE'))]"
                            }
                        }
                    }
                ],
                "probes": [
                    {
                        "name": "[variables('DMZ_LB_PROBE')]",
                        "properties": {
                            "protocol": "Http",
                            "port": 80,
                            "requestPath": "/",
                            "intervalInSeconds": 5,
                            "numberOfProbes": 2
                        }
                    }
                ],
                "inboundNatRules": [ ],
                "outboundNatRules": [ ],
                "inboundNatPools": [ ]
            },
            "dependsOn": [
                "[resourceId('Microsoft.Network/publicIPAddresses', concat(variables('APP_NAME'),'-pip'))]"
            ]
        },
        {
            "type": "Microsoft.Network/loadBalancers",
            "name": "[variables('SVC1_LB_NAME')]",
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "properties": {
                "frontendIPConfigurations": [
                    {
                        "name": "[variables('SVC1_LB_FRONTEND')]",
                        "properties": {
                            "privateIPAddress": "[variables('SERVICE_ILB_IP_1')]",
                            "privateIPAllocationMethod": "Static",
                            "subnet": {
                                "id": "[concat(resourceId('Microsoft.Network/virtualNetworks', variables('VNET_NAME')), '/subnets/',variables('SVC1_SUBNET_NAME'))]"
                            }
                        }
                    }
                ],
                "backendAddressPools": [
                    {
                        "name": "[variables('SVC1_LB_BACKEND')]"
                    }
                ],
                "loadBalancingRules": [
                    {
                        "name": "[concat(variables('SVC1_LB_NAME'),'-rule-http')]",
                        "properties": {
                            "frontendIPConfiguration": {
                                "id": "[concat(resourceId('Microsoft.Network/loadBalancers',variables('SVC1_LB_NAME')),'/frontendIPConfigurations/',variables('SVC1_LB_FRONTEND'))]"
                            },
                            "frontendPort": 80,
                            "backendPort": 80,
                            "enableFloatingIP": false,
                            "idleTimeoutInMinutes": 4,
                            "protocol": "Tcp",
                            "loadDistribution": "Default",
                            "backendAddressPool": {
                                "id": "[concat(resourceId('Microsoft.Network/loadBalancers',variables('SVC1_LB_NAME')),'/backendAddressPools/',variables('SVC1_LB_BACKEND'))]"
                            },
                            "probe": {
                                "id": "[concat(resourceId('Microsoft.Network/loadBalancers',variables('SVC1_LB_NAME')),'/probes/',variables('SVC1_LB_PROBE'))]"

                            }
                        }
                    }
                ],
                "probes": [
                    {
                        "name": "[variables('SVC1_LB_PROBE')]",
                        "properties": {
                            "protocol": "Http",
                            "port": 80,
                            "requestPath": "/",
                            "intervalInSeconds": 5,
                            "numberOfProbes": 2
                        }
                    }
                ],
                "inboundNatRules": [ ],
                "outboundNatRules": [ ],
                "inboundNatPools": [ ]
            },
            "dependsOn": [
                "[resourceId('Microsoft.Network/virtualNetworks', variables('VNET_NAME'))]"
            ]
        },
        {
            "type": "Microsoft.Network/loadBalancers",
            "name": "[variables('SVC2_LB_NAME')]",
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "properties": {
                "frontendIPConfigurations": [
                    {
                        "name": "[variables('SVC2_LB_FRONTEND')]",
                        "properties": {
                            "privateIPAddress": "[variables('SERVICE_ILB_IP_2')]",
                            "privateIPAllocationMethod": "Static",
                            "subnet": {
                                "id": "[concat(resourceId('Microsoft.Network/virtualNetworks', variables('VNET_NAME')), '/subnets/',variables('SVC2_SUBNET_NAME'))]"
                            }
                        }
                    }
                ],
                "backendAddressPools": [
                    {
                        "name": "[variables('SVC2_LB_BACKEND')]"
                    }
                ],
                "loadBalancingRules": [
                    {
                        "name": "[concat(variables('SVC2_LB_NAME'),'-rule-http')]",
                        "properties": {
                            "frontendIPConfiguration": {
                                "id": "[concat(resourceId('Microsoft.Network/loadBalancers',variables('SVC2_LB_NAME')),'/frontendIPConfigurations/',variables('SVC2_LB_FRONTEND'))]"                                
                            },
                            "frontendPort": 80,
                            "backendPort": 80,
                            "enableFloatingIP": false,
                            "idleTimeoutInMinutes": 4,
                            "protocol": "Tcp",
                            "loadDistribution": "Default",
                            "backendAddressPool": {
                                "id": "[concat(resourceId('Microsoft.Network/loadBalancers',variables('SVC2_LB_NAME')),'/backendAddressPools/',variables('SVC2_LB_BACKEND'))]"
                            },
                            "probe": {
                                "id": "[concat(resourceId('Microsoft.Network/loadBalancers',variables('SVC2_LB_NAME')),'/probes/',variables('SVC2_LB_PROBE'))]"
                            }
                        }
                    }
                ],
                "probes": [
                    {
                        "name": "[variables('SVC2_LB_PROBE')]",
                        "properties": {
                            "protocol": "Http",
                            "port": 80,
                            "requestPath": "/",
                            "intervalInSeconds": 5,
                            "numberOfProbes": 2
                        }
                    }
                ],
                "inboundNatRules": [ ],
                "outboundNatRules": [ ],
                "inboundNatPools": [ ]
            },
            "dependsOn": [
                "[resourceId('Microsoft.Network/virtualNetworks', variables('VNET_NAME'))]"
            ]
        },
        {
            "type": "Microsoft.Network/networkInterfaces",
            "name": "[concat(variables('APP_NAME'),'-dmz-vm',copyIndex(1),'-nic1')]",
            "copy": {
                "name": "nicloop",
                "count": "[parameters('NUM_VM_INSTANCES_DMZ_TIER')]"
            },
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "properties": {
                "ipConfigurations": [
                    {
                        "name": "Nic-IP-config",
                        "properties": {
                            "privateIPAddress": "[concat('10.5.5.',copyIndex(4))]",
                            "privateIPAllocationMethod": "Dynamic",
                            "subnet": {
                                "id": "[concat(resourceId('Microsoft.Network/virtualNetworks', variables('VNET_NAME')), '/subnets/',variables('APP_NAME'),'-dmz-fe-subnet')]"
                            },
                            "loadBalancerBackendAddressPools": [
                                {
                                    "id": "[concat(resourceId('Microsoft.Network/loadBalancers', variables('DMZ_LB_NAME')), '/backendAddressPools/',variables('APP_NAME'),'-dmz-lb-backend-pool')]"
                                }
                            ]
                        }
                    }
                ],
                "dnsSettings": {
                    "dnsServers": [ ]
                },
                "enableIPForwarding": false
            },
            "dependsOn": [
                "[resourceId('Microsoft.Network/virtualNetworks', variables('VNET_NAME'))]",
                "[resourceId('Microsoft.Network/loadBalancers', variables('DMZ_LB_NAME'))]"
            ]
        },
        {
            "type": "Microsoft.Network/networkInterfaces",
            "name": "[concat(variables('APP_NAME'),'-dmz-vm',copyIndex(1),'-nic2')]",
            "copy": {
                "name": "nicloop",
                "count": "[parameters('NUM_VM_INSTANCES_DMZ_TIER')]"
            },
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "properties": {
                "ipConfigurations": [
                    {
                        "name": "Nic-IP-config",
                        "properties": {
                            "privateIPAddress": "[concat('10.5.6.',copyIndex(4))]",
                            "privateIPAllocationMethod": "Dynamic",
                            "subnet": {
                                "id": "[concat(resourceId('Microsoft.Network/virtualNetworks', variables('VNET_NAME')), '/subnets/',variables('APP_NAME'),'-dmz-be-subnet')]"
                            }
                        }
                    }
                ],
                "dnsSettings": {
                    "dnsServers": [ ]
                },
                "enableIPForwarding": false
            },
            "dependsOn": [
                "[resourceId('Microsoft.Network/virtualNetworks', variables('VNET_NAME'))]"
            ]
        },
        {
            "type": "Microsoft.Network/networkInterfaces",
            "name": "[concat(variables('APP_NAME'),'-mgt-vm',copyIndex(1),'-nic1')]",
            "copy": {
                "name": "nicloop",
                "count": "[parameters('NUM_VM_INSTANCES_MANAGE_TIER')]"
            },
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "properties": {
                "ipConfigurations": [
                    {
                        "name": "Nic-IP-config",
                        "properties": {
                            "privateIPAddress": "[concat('10.5.4.',copyIndex(4))]",
                            "privateIPAllocationMethod": "Dynamic",
                            "publicIPAddress": {
                                "id": "[resourceId('Microsoft.Network/publicIPAddresses', concat(variables('APP_NAME'),'-jumpbox-pip'))]"
                            },
                            "subnet": {
                                "id": "[concat(resourceId('Microsoft.Network/virtualNetworks', variables('VNET_NAME')), '/subnets/',variables('APP_NAME'),'-mgt-subnet')]"
                            }
                        }
                    }
                ],
                "dnsSettings": {
                    "dnsServers": [ ]
                },
                "enableIPForwarding": false,
                "networkSecurityGroup": {
                    "id": "[resourceId('Microsoft.Network/networkSecurityGroups', concat(variables('APP_NAME'),'-mgt-nsg'))]"
                }
            },
            "dependsOn": [
                "[resourceId('Microsoft.Network/publicIPAddresses', concat(variables('APP_NAME'),'-jumpbox-pip'))]",
                "[resourceId('Microsoft.Network/virtualNetworks', variables('VNET_NAME'))]",
                "[resourceId('Microsoft.Network/networkSecurityGroups', concat(variables('APP_NAME'),'-mgt-nsg'))]"
            ]
        },
        {
            "type": "Microsoft.Network/networkInterfaces",
            "name": "[concat(variables('APP_NAME'),'-svc1-vm',copyIndex(1),'-nic1')]",
            "copy": {
                "name": "nicloop",
                "count": "[parameters('NUM_VM_INSTANCES_SERVICE_TIER_1')]"
            },
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "properties": {
                "ipConfigurations": [
                    {
                        "name": "Nic-IP-config",
                        "properties": {
                            "privateIPAddress": "[concat('10.5.2.',copyIndex(4))]",
                            "privateIPAllocationMethod": "Dynamic",
                            "subnet": {
                                "id": "[concat(resourceId('Microsoft.Network/virtualNetworks', variables('VNET_NAME')), '/subnets/',variables('APP_NAME'),'-svc1-subnet')]"
                            },
                            "loadBalancerBackendAddressPools": [
                                {
                                    "id": "[concat(resourceId('Microsoft.Network/loadBalancers', variables('SVC1_LB_NAME')), '/backendAddressPools/',variables('APP_NAME'),'-svc1-lb-backend-pool')]"
                                }
                            ]
                        }
                    }
                ],
                "dnsSettings": {
                    "dnsServers": [ ]
                },
                "enableIPForwarding": false
            },
            "dependsOn": [
                "[resourceId('Microsoft.Network/virtualNetworks', variables('VNET_NAME'))]",
                "[resourceId('Microsoft.Network/loadBalancers', variables('SVC1_LB_NAME'))]"
            ]
        },
        {
            "type": "Microsoft.Network/networkInterfaces",
            "name": "[concat(variables('APP_NAME'),'-svc2-vm',copyIndex(1),'-nic1')]",
            "copy": {
                "name": "nicloop",
                "count": "[parameters('NUM_VM_INSTANCES_SERVICE_TIER_2')]"
            },
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "properties": {
                "ipConfigurations": [
                    {
                        "name": "Nic-IP-config",
                        "properties": {
                            "privateIPAddress": "[concat('10.5.3.',copyIndex(4))]",
                            "privateIPAllocationMethod": "Dynamic",
                            "subnet": {
                                "id": "[concat(resourceId('Microsoft.Network/virtualNetworks', variables('VNET_NAME')), '/subnets/',variables('APP_NAME'),'-svc2-subnet')]"
                            },
                            "loadBalancerBackendAddressPools": [
                                {
                                    "id": "[concat(resourceId('Microsoft.Network/loadBalancers', variables('SVC2_LB_NAME')), '/backendAddressPools/',variables('APP_NAME'),'-svc2-lb-backend-pool')]"
                                }
                            ]
                        }
                    }
                ],
                "dnsSettings": {
                    "dnsServers": [ ]
                },
                "enableIPForwarding": false
            },
            "dependsOn": [
                "[resourceId('Microsoft.Network/virtualNetworks', variables('VNET_NAME'))]",
                "[resourceId('Microsoft.Network/loadBalancers', variables('SVC2_LB_NAME'))]"
            ]
        },
        {
            "type": "Microsoft.Network/networkSecurityGroups",
            "name": "[concat(variables('APP_NAME'),'-mgt-nsg')]",
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "properties": {
                "securityRules": [
                    {
                        "name": "admin-ssh-allow",
                        "properties": {
                            "protocol": "Tcp",
                            "sourcePortRange": "*",
                            "destinationPortRange": "[variables('REMOTE_ACCESS_PORT')]",
                            "sourceAddressPrefix": "[parameters('SOURCEPREFIX')]",
                            "destinationAddressPrefix": "*",
                            "access": "Allow",
                            "priority": 100,
                            "direction": "Inbound"
                        }
                    }
                ]
            },
            "dependsOn": [ ]
        },
        {
            "type": "Microsoft.Network/networkSecurityGroups",
            "name": "[concat(variables('APP_NAME'),'-cassandra-nsg')]",
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "properties": {
                "securityRules": [
                    {
                        "name": "svc-cassandra-allow",
                        "properties": {
                            "protocol": "*",
                            "sourcePortRange": "*",
                            "destinationPortRange": "*",
                            "sourceAddressPrefix": "[variables('SERVICE_SUBNET_IP_RANGE_1')]",
                            "destinationAddressPrefix": "*",
                            "access": "Allow",
                            "priority": 100,
                            "direction": "Inbound"
                        }
                    },
                    {
                        "name": "manage-cassandra-allow",
                        "properties": {
                            "protocol": "Tcp",
                            "sourcePortRange": "*",
                            "destinationPortRange": "^",
                            "sourceAddressPrefix": "[variables('MGT_SUBNET_IP_RANGE')]",
                            "destinationAddressPrefix": "*",
                            "access": "Allow",
                            "priority": 200,
                            "direction": "Inbound"
                        }
                    },
                    {
                        "name": "vnet-deny",
                        "properties": {
                            "protocol": "*",
                            "sourcePortRange": "*",
                            "destinationPortRange": "*",
                            "sourceAddressPrefix": "VirtualNetwork",
                            "destinationAddressPrefix": "*",
                            "access": "Deny",
                            "priority": 1000,
                            "direction": "Inbound"
                        }
                    }
                ]
            },
            "dependsOn": [ ]
        },
        {
            "type": "Microsoft.Network/networkSecurityGroups",
            "name": "[concat(variables('APP_NAME'),'-svc1-nsg')]",
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "properties": {
                "securityRules": [
                    {
                        "name": "dmz-allow",
                        "properties": {
                            "protocol": "*",
                            "sourcePortRange": "*",
                            "destinationPortRange": "*",
                            "sourceAddressPrefix": "[variables('DMZ_SUBNET_IP_RANGE_2')]",
                            "destinationAddressPrefix": "*",
                            "access": "Allow",
                            "priority": 100,
                            "direction": "Inbound"
                        }
                    },
                    {
                        "name": "manage-ssh-allow",
                        "properties": {
                            "protocol": "Tcp",
                            "sourcePortRange": "*",
                            "destinationPortRange": "[variables('REMOTE_ACCESS_PORT')]",
                            "sourceAddressPrefix": "[variables('MGT_SUBNET_IP_RANGE')]",
                            "destinationAddressPrefix": "*",
                            "access": "Allow",
                            "priority": 200,
                            "direction": "Inbound"
                        }
                    },
                    {
                        "name": "vnet-deny",
                        "properties": {
                            "protocol": "*",
                            "sourcePortRange": "*",
                            "destinationPortRange": "*",
                            "sourceAddressPrefix": "VirtualNetwork",
                            "destinationAddressPrefix": "*",
                            "access": "Deny",
                            "priority": 1000,
                            "direction": "Inbound"
                        }
                    }
                ]
            },
            "dependsOn": [ ]
        },
        {
            "type": "Microsoft.Network/networkSecurityGroups",
            "name": "[concat(variables('APP_NAME'),'-svc2-nsg')]",
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "properties": {
                "securityRules": [
                    {
                        "name": "dmz-allow",
                        "properties": {
                            "protocol": "*",
                            "sourcePortRange": "*",
                            "destinationPortRange": "*",
                            "sourceAddressPrefix": "[variables('DMZ_SUBNET_IP_RANGE_2')]",
                            "destinationAddressPrefix": "*",
                            "access": "Allow",
                            "priority": 100,
                            "direction": "Inbound"
                        }
                    },
                    {
                        "name": "manage-ssh-allow",
                        "properties": {
                            "protocol": "Tcp",
                            "sourcePortRange": "*",
                            "destinationPortRange": "[variables('REMOTE_ACCESS_PORT')]",
                            "sourceAddressPrefix": "[variables('MGT_SUBNET_IP_RANGE')]",
                            "destinationAddressPrefix": "*",
                            "access": "Allow",
                            "priority": 200,
                            "direction": "Inbound"
                        }
                    },
                    {
                        "name": "vnet-deny",
                        "properties": {
                            "protocol": "*",
                            "sourcePortRange": "*",
                            "destinationPortRange": "*",
                            "sourceAddressPrefix": "VirtualNetwork",
                            "destinationAddressPrefix": "*",
                            "access": "Deny",
                            "priority": 1000,
                            "direction": "Inbound"
                        }
                    }
                ]
            },
            "dependsOn": [ ]
        },
        {
            "type": "Microsoft.Network/publicIPAddresses",
            "name": "[concat(variables('APP_NAME'),'-jumpbox-pip')]",
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "properties": {
                "publicIPAllocationMethod": "Dynamic",
                "idleTimeoutInMinutes": 4
            },
            "dependsOn": [ ]
        },
        {
            "type": "Microsoft.Network/publicIPAddresses",
            "name": "[concat(variables('APP_NAME'),'-pip')]",
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "properties": {
                "publicIPAllocationMethod": "Dynamic",
                "idleTimeoutInMinutes": 4,
                "dnsSettings": {
                    "domainNameLabel": "[concat(variables('APP_NAME'),'devlb')]"
                }
            },
            "dependsOn": [ ]
        },
        {
            "type": "Microsoft.Network/virtualNetworks",
            "name": "[variables('VNET_NAME')]",
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "properties": {
                "addressSpace": {
                    "addressPrefixes": [
                        "[variables('VNET_IP_RANGE')]"
                    ]
                },
                "subnets": [
                    {
                        "name": "default",
                        "properties": {
                            "addressPrefix": "[variables('SUBNET_DEFAULT')]"
                        }
                    },
                    {
                        "name": "[variables('SVC1_SUBNET_NAME')]",
                        "properties": {
                            "addressPrefix": "[variables('SERVICE_SUBNET_IP_RANGE_1')]",
                            "networkSecurityGroup": {
                                "id": "[resourceId('Microsoft.Network/networkSecurityGroups', concat(variables('APP_NAME'),'-svc1-nsg'))]"
                            }
                        }
                    },
                    {
                        "name": "[variables('CASSANDRA_SUBNET_NAME')}",
                        "properties": {
                            "addressPrefix": "[variables('CASSANDRA_SUBNET_IP_RANGE')]",
                            "networkSecurityGroup": {
                                "id": "[resourceId('Microsoft.Network/networkSecurityGroups', concat(variables('APP_NAME'),'-cassandra-nsg'))]"
                            }
                        }
                    },
                    {
                        "name": "[concat(variables('APP_NAME'),'-svc2-subnet')]",
                        "properties": {
                            "addressPrefix": "[variables('SERVICE_SUBNET_IP_RANGE_2')]",
                            "networkSecurityGroup": {
                                "id": "[resourceId('Microsoft.Network/networkSecurityGroups', concat(variables('APP_NAME'),'-svc2-nsg'))]"
                            }
                        }
                    },
                    {
                        "name": "[concat(variables('APP_NAME'),'-mgt-subnet')]",
                        "properties": {
                            "addressPrefix": "[variables('MGT_SUBNET_IP_RANGE')]"
                        }
                    },
                    {
                        "name": "[concat(variables('APP_NAME'),'-dmz-fe-subnet')]",
                        "properties": {
                            "addressPrefix": "[variables('DMZ_SUBNET_IP_RANGE_1')]"
                        }
                    },
                    {
                        "name": "[concat(variables('APP_NAME'),'-dmz-be-subnet')]",
                        "properties": {
                            "addressPrefix": "[variables('DMZ_SUBNET_IP_RANGE_2')]"
                        }
                    }
                ]
            },
            "dependsOn": [
                "[resourceId('Microsoft.Network/networkSecurityGroups', concat(variables('APP_NAME'),'-svc1-nsg'))]",
                "[resourceId('Microsoft.Network/networkSecurityGroups', concat(variables('APP_NAME'),'-svc2-nsg'))]",
                "[resourceId('Microsoft.Network/networkSecurityGroups', concat(variables('APP_NAME'),'-cassandra-nsg'))]"
            ]
        },
        {
            "type": "Microsoft.Storage/storageAccounts",
            "name": "[concat(variables('APP_NAME'),'diag')]",
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "tags": { },
            "properties": {
                "accountType": "Standard_LRS"
            },
            "dependsOn": [ ]
        },
        {
            "type": "Microsoft.Storage/storageAccounts",
            "name": "[concat(variables('APP_NAME'),'dmzvm',copyIndex(1),'st1')]",
            "copy": {
                "name": "storageloop",
                "count": "[parameters('NUM_VM_INSTANCES_DMZ_TIER')]"
            },
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "tags": { },
            "properties": {
                "accountType": "Premium_LRS"
            },
            "dependsOn": [ ]
        },
        {
            "type": "Microsoft.Storage/storageAccounts",
            "name": "[concat(variables('APP_NAME'),'mgtvm',copyIndex(1),'st1')]",
            "copy": {
                "name": "storageloop",
                "count": "[parameters('NUM_VM_INSTANCES_MANAGE_TIER')]"
            },
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "tags": { },
            "properties": {
                "accountType": "Premium_LRS"
            },
            "dependsOn": [ ]
        },
        {
            "type": "Microsoft.Storage/storageAccounts",
            "name": "[concat(variables('APP_NAME'),'svc1vm',copyIndex(1),'st1')]",
            "copy": {
                "name": "storageloop",
                "count": "[parameters('NUM_VM_INSTANCES_SERVICE_TIER_1')]"
            },
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "tags": { },
            "properties": {
                "accountType": "Premium_LRS"
            },
            "dependsOn": [ ]
        },
        {
            "type": "Microsoft.Storage/storageAccounts",
            "name": "[concat(variables('APP_NAME'),'svc2vm',copyIndex(1),'st1')]",
            "copy": {
                "name": "storageloop",
                "count": "[parameters('NUM_VM_INSTANCES_SERVICE_TIER_2')]"
            },
            "apiVersion": "2015-06-15",
            "location": "[variables('LOCATION')]",
            "tags": { },
            "properties": {
                "accountType": "Premium_LRS"
            },
            "dependsOn": [ ]
        }
    ]