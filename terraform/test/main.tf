provider "aws" {
    region = "us-east-1"
}

data "aws_ami" "ubuntu" {
    most_recent = 1
    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-zesty-17.04-amd64-server-*"]
    }
}

resource "aws_vpc" "test" {
    cidr_block = "10.0.0.0/16"
    tags {
        Name = "Test VPC"
        TM   = "Yes"
    }
}

resource "aws_subnet" "test" {
    vpc_id     = "${aws_vpc.test.id}"
    cidr_block = "10.0.1.0/24"
    tags {
        Name = "Test Subnet"
        TM   = "Yes"
    }
}

resource "aws_internet_gateway" "test" {
    vpc_id = "${aws_vpc.test.id}"

    tags {
        Name = "Test Internet Gateway"
        TM   = "Yes"
    }
}

resource "aws_route_table" "test" {
    vpc_id = "${aws_vpc.test.id}"

    route {
        cidr_block = "10.0.1.0/16"
        gateway_id = "${aws_internet_gateway.test.id}"
    }

    tags {
        Name = "Test Route Table"
        TM   = "Yes"
    }
}

resource "aws_route_table_association" "test" {
    subnet_id = "${aws_subnet.test.id}"
    route_table_id = "${aws_route_table.test.id}"
}

resource "aws_security_group" "allow_all" {
    name        = "allow_all"
    description = "Allow all inbound traffic"
    vpc_id      = "${aws_vpc.test.id}"

    ingress {
        from_port = 0
        to_port   = 0
        protocol  = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port   = 0
        protocol  = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_key_pair" "test" {
    key_name   = "test2"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCR48HoxasqlAkn7CKA+JWSiZ9q9NLAO9QUQK1/R5Oz5Y0s6D798DXhvnxyzlIYWQfVpfXAoSGGBSsei7iM0Ec4qt99ojzwXL1VktQVLaBXmqzy3iDXVC/9W6sNLigDVSdiwjJ997ZAoZPeXcjwMEr6bjr7LmIaSmh8fWLxx804n2kow22k3eTtgncxms8GxgpbSKEfpHAPtSeINfbaHzwfbTiXf0yBoWrU3XbHDLrpp+MmnS2iYjA1OWsCPpkTm1JUcyoy6NYaeMJrQmWaRJnC2nck8a3m4Yw904Ddfm8tJUHtF6gIZSDdQY+mGBlygicQIHLrjh2jNu1Br63lHDVv"
}

resource "aws_instance" "test" {
    ami = "${data.aws_ami.ubuntu.id}"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.test.id}"
    key_name  = "test"
}
