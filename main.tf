locals {
    ssh_user = "ubuntu"
    key_name = "main-key"
}

provider "aws" {
    region ="us-east-1"
}

resource "aws_vpc" "prod-vpc"{
    cidr_block ="10.0.0.0/16" #vpc private area in the cloud 
    tags ={
        Name ="production"
    }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.prod-vpc.id #gateway to access internet from vpc
    
}

resource "aws_route_table" "prod-route-table"{
    vpc_id =aws_vpc.prod-vpc.id

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
        Name="production"
    }
}

#subnet for server
resource "aws_subnet" "subnet-1" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block ="10.0.1.0/24" #defines ip range?
    availability_zone = "us-east-1a"

    tags = {
        Name ="prod-subnet"
    }
}

#associate the subnet with the route table
resource "aws_route_table_association" "a" {
    subnet_id = aws_subnet.subnet-1.id
    route_table_id = aws_route_table.prod-route-table.id #connects the subnet to the route_table
}

#security group for port traffic, allows ssh,http,https
resource "aws_security_group" "allow_web" {
    name = "allow_web_traffic"
    description ="allows web traffic"
    vpc_id = aws_vpc.prod-vpc.id 

    ingress {
        description ="https"
        from_port =443
        to_port =443
        protocol ="tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description ="http"
        from_port =80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

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
        Name = "allow_web"
    }
}

resource "aws_network_interface" "web-server-nic"{
    subnet_id = aws_subnet.subnet-1.id
    private_ips = ["10.0.1.50"]
    security_groups =[aws_security_group.allow_web.id] #permissions for traffic

}

resource "aws_eip" "one" {
    #creates elastic ip for public ip that stays the same 
    vpc = true #if inside a vpc
    network_interface =aws_network_interface.web-server-nic.id #connect to the nic
    associate_with_private_ip = "10.0.1.50"     #assigns eip to the private ip in the nic

    depends_on = [aws_internet_gateway.gw]     # need the gateway to create eip
}

#make the server instance
resource "aws_instance" "web-server-instance" {
    count                       = 2                       #creates x copies of this resource
    ami                         = "ami-0747bdcabd34c712a" #os to be installed
    instance_type               = "t2.micro"              #type of instance
    availability_zone           = "us-east-1a"            
    key_name                    = local.key_name          #access key

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.web-server-nic.id    #connects to the nic
    }


    tags = {
        Name = "web-server"
    }
}

output "server_ip" {
    value = aws_instance.web-server-instance.public_ip            #outputs the eip to console
}

