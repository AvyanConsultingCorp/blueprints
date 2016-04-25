#!/bin/bash

AZURERG="tw-openswan-test09"
AZURELOCATION="East US"
AZURESTORAGEACCT="twawsvpnstg08"
AZUREVMPASSWD="AzureCATPassw0rd"

AWSSTACK="ccdeploy06"
AWSKEYPAIRNAME="AWStoAzureVPN"

AZUREPUBLICIP=""
AWSPUBLICIP=""

# error handling or interruption via ctrl-c.
# line number and error code of executed command is passed to errhandle function
SOURCEFILE=$0
trap 'errhandle $LINENO $?' SIGINT ERR

# Function errhandle()
#   Parameters: 
#     $1:  Line number to be logged. Can use $LINENO from caller.
#     $2:  Exit code which will be passed to "exit"
errhandle()
{
  echo "====== ERROR or Interruption, [`date`], ${SOURCEFILE}, line ${1}, exit code ${2}"
  exit ${2}
}

CreateAzurePublicIP()
{
  echo "Creating Azure Public IP"

  azure group create -l "$AZURELOCATION" -n "$AZURERG"
  
  # Create the Azure deployment, capturing the output. 
  MYOUTPUT=$(azure group deployment create -f "azure/templates/PublicIPDeployment.json" -g "$AZURERG")
  #echo "$MYOUTPUT"

  # Find the text line in the output that has "publicIPAddress"
  # The line we're looking for is like: 
  # "data:    publicIPAddress  String  xx.xx.xx.xx"
  PUBIPLINE=$(echo "$MYOUTPUT" | grep publicIPAddress)
  # Pattern match the line into 2 subexpressions. The 2nd one will be the IP
  [[ "$PUBIPLINE" =~ (.*publicIPAddress *String *)(.*) ]]
  AZUREPUBLICIP=${BASH_REMATCH[2]}

  if [ "$AZUREPUBLICIP" = "" ]; then
    echo "ERROR: Azure Public IP not found in output.  Output: "
    echo 
    echo "$MYOUTPUT"
    errhandle $LINENO 1 
  fi

  echo "Azure OpenSwan VM Public IP: $AZUREPUBLICIP"
}

AWSDeployment()
{
  #TODO parameterize KeyPairName 
  #TODO parameterize StackName 
  aws cloudformation create-stack --stack-name "$AWSSTACK" \
    --template-body file://./aws/cloudformation/DeploymentTemplate.template --output=text \
    --parameters \ 
      ParameterKey=AzurePublicIP,ParameterValue="$AZUREPUBLICIP" \ 
      ParameterKey=KeyPairName,ParameterValue="$AWSKEYPAIRNAME" 
      
  # Wait for the stack creation to complete
  aws cloudformation wait stack-create-complete --stack-name "$AWSSTACK"
  
  # Query the created stack for the "publicIPAddress" Output value
  AWSPUBLICIP=$(aws cloudformation describe-stacks --stack-name "$AWSSTACK" --output text \
    --query 'Stacks[0].Outputs[?OutputKey==`publicIPAddress`].OutputValue')
  
  if [ "$AWSPUBLICIP" = "" ]; then
    echo "ERROR: AWS Public IP not found in CloudFormation stack output!"
    echo
    errhandle $LINENO 1
  fi
}

CreateAzurePublicIP

# Do AWS deployment, collecting public IP of AWS OpenSwan VM. 
AWSDeployment

#azure group deployment create -f azure/templates/DeploymentTemplate.json \
#  -g "$AZURERG" \ 
#  -p '{"newStorageAccountName": {"value": "'$AZURESTORAGEACCT'"}, ' \ 
#      '"adminPassword": {"value": "'$AZUREVMPASSWD'"}, ' \
#      '"AWSPublicIP": {"value": "'$AWSPUBLICIP'"}' \
#    '}'


#azure group deployment create -f "azure\templates\DeploymentTemplate.json" -g "$AZURERG" 

