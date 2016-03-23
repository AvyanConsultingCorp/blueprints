variable "aws_access_key" {
  description = "AWS Access Key"
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
}
variable "aws_region" {
  description = "AWS region to launch servers."
}

variable "public_key_path" {}

variable "private_key_path" {}

variable "db_replication_password" {}

# Ubuntu  14.04 Trusty Tahr (x64)
variable "aws_server_ami" {
  default = "ami-59d6f933"
}

variable "key_name" {
  default = "boz"
}
variable "vpc_cidr" {
  description = "CIDR for the VPC"
  default = "192.168.0.0/16"
}

variable "aws_subnet_cidr" {
  description = "CIDR for the VPC"
  default = "192.168.0.0/16"
}

variable "azure_subnet_cidr" {
  description = "CIDR for  the Azure Subnet"
  default = "10.0.0.0/16"
}

variable "azure_db_server_ip" {
  description = "IP Address for the DB Server on the azure side"
  default = "10.0.1.4"
}

variable "azure_vpn_server_ip" {
  description = "IP Address for the VPN Server on the azure side"
  default = "10.0.0.4"
}

variable "aws_db_server_ip" {
  description = "IP Address for the DB Server on the AWS side"
  default = "192.168.1.4"
}

variable "aws_vpn_server_ip" {
  description = "IP Address for the VPN Server on the AWS side"
  default = "192.168.0.4"
}

variable "aws_public_ip" {
  description = "Public IP Address for the AWS environment"
  default = "52.7.20.19/32"
}

variable "azure_public_ip" {
  description = "Public IP Address for the Azure environment"
  default = "40.79.46.87/32"
}
