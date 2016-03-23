# Define the AWS provider attributes
provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region     = "${var.aws_region}"
}

# Create a VPC so we have a container for all of our resources
resource "aws_vpc" "aws_hybrid_network_vpc" {
  cidr_block = "${var.vpc_cidr}"
}

# Create an EIP to attach to our VPN server
resource "aws_eip" "default" {
  #instance = "${aws_instance.vpn_server.id}"
  #use static EIP
  instance = "${aws_instance.vpn_server.id}"
  vpc = true
}

# Create an internet gateway so we can hit the internet
resource "aws_internet_gateway"  "aws_hybrid_network_gateway" {
  vpc_id = "${aws_vpc.aws_hybrid_network_vpc.id}"
}

# setup the VPC route table so we can route to the internet
resource "aws_route" "hybrid_network_internet_access" {
  route_table_id         = "${aws_vpc.aws_hybrid_network_vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.aws_hybrid_network_gateway.id}"
}

#add routes for Azure servers
resource "aws_route" "vpn" {
  route_table_id         = "${aws_vpc.aws_hybrid_network_vpc.main_route_table_id}"
  destination_cidr_block = "${var.azure_subnet_cidr}"
  instance_id               = "${aws_instance.vpn_server.id}"
}

# Create a subnet for our VMS - we should isolate web and internal but it's a demo
resource "aws_subnet" "aws_hybrid_network_subnet1" {
  vpc_id                  = "${aws_vpc.aws_hybrid_network_vpc.id}"
  cidr_block              = "${var.aws_subnet_cidr}"
  map_public_ip_on_launch = true
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "aws_hybrid_network" {
  name        = "aws_hybrid_network"
  description = "For accessing the hybrid network example"
  vpc_id      = "${aws_vpc.aws_hybrid_network_vpc.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Openswan IKE protocol
  ingress {
    from_port = 500
    to_port = 500
    protocol = "udp"
    cidr_blocks = ["${var.azure_public_ip}"]
  }

  #Openswan IKE Nat Traversal
  ingress {
    from_port = 4500
    to_port = 4500
    protocol = "udp"
    cidr_blocks = ["${var.azure_public_ip}"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.aws_subnet_cidr}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  #all pings
  ingress {
    from_port = 8
    to_port = 0
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #iperf
  ingress {
    from_port = 5001
    to_port = 5001
    protocol = "tcp"
    cidr_blocks = ["${var.aws_subnet_cidr}"]
  }

  #postgresql
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["${var.aws_subnet_cidr}"]
  }

}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "vpn_server" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "ubuntu"
    agent = true
    #private_key = "${file(var.private_key_path)}"
    # The connection will use the local SSH agent for authentication.
  }

  #TODO: what can we shrink this to?
  instance_type = "m3.large"

  # AMI
  ami = "${var.aws_server_ami}"

  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.auth.id}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.aws_hybrid_network.id}"]

  # We're going to launch into a single common subnet. In production
  # environments, there should be a separate subnet for each tier in the
  # solution architecture.
  subnet_id = "${aws_subnet.aws_hybrid_network_subnet1.id}"

  # Turn off source/destination checking so routing will work
  source_dest_check = "false"

  #Pin to a predictable private IP address
  private_ip = "${var.aws_vpn_server_ip}"


  # We run a remote provisioner on the instance after creating it.
  # Install OpenSwan and config
  provisioner "remote-exec" {
    scripts = [
      #"..\\..\\shared\\vpn_common.sh"
      "../../shared/vpn_common.sh"
    ]
  }
}

resource "aws_instance" "postgres_master" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "ubuntu"
    # The connection will use the local SSH agent for authentication.
    agent = true
    #private_key = "${file(var.private_key_path)}"
  }

  instance_type = "m3.large"

  # AMI
  ami = "${var.aws_server_ami}"

  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.auth.id}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.aws_hybrid_network.id}"]

  # We're going to launch into a single common subnet. In production
  # environments, there should be a separate subnet for each tier in the
  # solution architecture.
  subnet_id = "${aws_subnet.aws_hybrid_network_subnet1.id}"

  #Pin to a predictable private IP address
  private_ip = "${var.aws_db_server_ip}"

  # We run remote provisioners on the instance after creating it.
  # Install postgresql and config

  provisioner "file" {
   source = "../../shared/db_common.sh"
   destination = "/tmp/db_common.sh"
  }

  provisioner "file" {
    source = "db_post_install.sh"
    destination = "/tmp/db_post_install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/db_common.sh",
      "/tmp/db_common.sh ${var.db_replication_password}",
      "chmod +x /tmp/db_post_install.sh",
      /tmp/db_post_install.sh
    ]
  }
}
