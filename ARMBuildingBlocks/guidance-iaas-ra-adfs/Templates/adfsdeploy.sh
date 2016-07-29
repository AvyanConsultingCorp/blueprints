
############################################################################
# Install New ADFS Farm in the first VM 
############################################################################
############################################################################
if [ "${Prompting}" == "true" ]; then
	echo
	echo
	read -p "Press any key to install a new ADFS Farm to the first VM ... " -n1 -s
fi

do
	VM_NAME=${BASE_NAME}-${VM_NAME_PREFIX}1-vm
	TEMPLATE_URI=${URI_BASE}/ARMBuildingBlocks/Templates/bb-vm-install-adfs-farm-extension.json
	PARAMETERS="{\"vmName\":{\"value\":\"${VM_NAME}\"},\"adminUser\":{\"value\":\"${ADMIN_USER_NAME}\"},\"adminPassword\":{\"value\":\"${ADMIN_PASSWORD}\"},\"netBiosDomainName\":{\"value\":\"${NET_BIOS_DOMAIN_NAME}\"},\"fqDomainName\":{\"value\":\"${DOMAIN_NAME}\"},\"gmsaName\":{\"value\":\"${ADFS_GMSA_NAME}\"},\"federationName\":{\"value\":\"${ADFS_FEDERATION_NAME}\"},\"description\":{\"value\":\"${NET_BIOS_DOMAIN_NAME}\"},}"
	echo
	echo
	echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS} --subscription ${SUBSCRIPTION}
	     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS} --subscription ${SUBSCRIPTION}
done  


if [ "${Prompting}" == "true" ]; then
	echo
	echo Please log into the first ADFS VM to verify the installation
	echo
	echo You can browse to https://adfs.contoso.com/adfs/ls/idpinitiatedsignon.htm to verify the installation
	echo
	read -p "Press any key to continue ... " -n1 -s
fi
	 

