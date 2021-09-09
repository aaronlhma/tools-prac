locals {
    instance_count = 1
    key_name = "main-key"
}

provider "aws" {
    region = "us-east-1"
    profile = "devops_learn"
}

resource "aws_vpc" "jenkins-vpc"{
    cidr_block ="10.0.0.0/16" #vpc private area in the cloud 
    tags ={
        Name ="jenkins"
    }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.jenkins-vpc.id #gateway to access internet from vpc
    
}

resource "aws_route_table" "jenkins-route-table"{
    vpc_id =aws_vpc.jenkins-vpc.id

    #default routes through the gateway
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }

    route {
        ipv6_cidr_block = "::/0"
        gateway_id = aws_internet_gateway.gw.id
    }
    tags = {
        Name="jenkins"
    }
}

#subnet for server
resource "aws_subnet" "subnet-j" {
    vpc_id = aws_vpc.jenkins-vpc.id
    cidr_block ="10.0.2.0/24" #defines ip range?
    availability_zone = "us-east-1a"

    tags = {
        Name ="jenkins-subnet"
    }
}

#associate the subnet with the route table
resource "aws_route_table_association" "a" {
    subnet_id = aws_subnet.subnet-j.id
    route_table_id = aws_route_table.jenkins-route-table.id #connects the subnet to the route_table
}

resource "aws_security_group" "allow_ssh" {
    name = "allow_ssh_traffic"
    description ="allows ssh traffic"
    vpc_id = aws_vpc.jenkins-vpc.id 

    # ingress {
    #     description ="https"
    #     from_port =443
    #     to_port =443
    #     protocol ="tcp"
    #     cidr_blocks = ["0.0.0.0/0"]
    # }

    # ingress {
    #     description ="http"
    #     from_port =80
    #     to_port = 80
    #     protocol = "tcp"
    #     cidr_blocks = ["0.0.0.0/0"]
    # }

    ingress {
        description ="ssh"
        from_port =22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress{
        from_port =0
        to_port = 0
        protocol ="-1" #any protocol
        cidr_blocks =["0.0.0.0/0"]
    }

    tags = {
        Name = "allow_ssh"
    }
}

resource "aws_network_interface" "jenkins-nic"{
    subnet_id = aws_subnet.subnet-j.id
    private_ips = ["10.0.2.50"]
    security_groups =[aws_security_group.allow_ssh.id] #permissions for traffic

}

resource "aws_instance" "jenkins" {
    count                       = local.instance_count   
    ami                         = "ami-0747bdcabd34c712a" #os to be installed
    instance_type               = "t2.micro"              #type of instance
    availability_zone           = "us-east-1a"            
    key_name                    = local.key_name          #access key

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.jenkins-nic.id    #connects to the nic
    }

    tags = {
        Name = "jenkins"
    }

}

output "ec2" {
    value = aws_instance.jenkins.*.public_ip
}