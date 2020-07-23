terraform { 
	required_version = ">= 0.11.0"
}

resource "tls_private_key" "ssh" {
	algorithm = "RSA"
	rsa_bits = 4096
}

resource "aws_key_pair" "generated_key" {
	key_name = "pc-key"
	public_key = tls_private_key.ssh.public_key_openssh
}

data "aws_ami" "ubuntu" {
	most_recent = true
	
	filter { 
		name = "name"
		values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
	
	}

	filter {
		name = "virtualization-type"
		values = ["hvm"]
	}

	owners = ["099720109477"]
}

resource "aws_instance" "controller" {
	ami = data.aws_ami.ubuntu.id
	instance_type = "t2.micro" 
	key_name = aws_key_pair.generated_key.key_name

	tags = {
		Name = "Controller"
	}
}
