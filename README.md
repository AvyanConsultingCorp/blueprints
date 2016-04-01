# Blue Prints Readme

The following readme goes over the requirements to run and test the blue print deployments.
The scripts support Linux or a Windows deployment.

Prerequisites:

- Azure CLI: https://azure.microsoft.com/en-us/documentation/articles/xplat-cli-install/
- Azure Subscription 


## Running the Blue Print scripts

Copy the files to a location on your targeted


### Windows

- Open a command windows
- Navigate to file location
- Run the selected scipts

### Linux

Linux deployments are using SSH public/private keys to log on to the linux deployment.
To generate your public private key pair, run the following command and provide it with the name for your key.

`ssh-keygen -t rsa -b 2048`

The key will be generated at the location "/home/username/.ssh/yoursshfile.pub".  
Provide this full path when the script ask for your public key. For example: 

`./azurecli-single-vm-sample.sh your-subscription-id`

`Enter username: name you'll use to logon to the box`

`Enter public Key file: /home/username/.ssh/your-ssh-file.pub`


To login into your Linux box with your SSH key.

`ssh user@yourmachine -i fullpathforprivatekeyfile`


## Running test to validate the Blue Print deployments

Under the test folder are some tools to help validate your deployment or search through the log file for a mistakes.

ValidateRG tool validates your blueprint deployment based on known deployment in a JSON file.

Here's how you run the tool:

ValidateRG.cmd your-subscription-id name-of-your-targeted-RG  select-desiredstate.JSON

For example

ValidateRG.cmd your-subscription-id my-singlevm-RG  singlevm-desiredstate.json



