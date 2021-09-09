locals {
    instance_count = 1
    key_name = "main-key"
}

provider "aws" {
    region = "us-east-1"
    profile = "devops_learn"
}

resource "aws_instance" "jenkins" {
    count                       = local.instance_count   
    ami                         = "ami-0747bdcabd34c712a" #os to be installed
    instance_type               = "t2.micro"              #type of instance
    availability_zone           = "us-east-1a"            
    key_name                    = local.key_name          #access key

    tags = {
        Name = "jenkins"
    }

}

output "ec2" {
    value = aws_instance.jenkins.*.public_ip
}