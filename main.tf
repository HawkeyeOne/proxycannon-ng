terraform { 
	required_version = ">= 0.11.0"
}

resource "tls_private_key" "ssh" {
	algorithm = "RSA"
	rsa_bits = 4096
	
	provisioner "local-exec" {
		command = "echo \"${tls_private_key.ssh.private_key_pem}\" > pc.pem"	
	}
	provisioner "local-exec" {
		when = destroy
		command = "rm ./pc.pem" 
		on_failure = continue
	}
}

resource "aws_key_pair" "generated_key" {
	key_name = "pc-key"
	public_key = tls_private_key.ssh.public_key_openssh
}

resource "aws_security_group" "allow_tls_ssh" {

	name = "allow-tls-ssh" 
	description = "Allow TLS/SSH inbound traffic"
	
	ingress {
		description = "Inbound TLS"
		from_port = 443
		to_port = 443
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]

	}
	ingress {
		description = "Inbound SSH"
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
	tags = {
		Name = "proxycannon" 
	}
}

data "aws_ami" "ubuntu" {
	most_recent = true
	
	filter { 
		name = "name"
		values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
	
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
	security_groups = ["allow-tls-ssh"]
	key_name = aws_key_pair.generated_key.key_name

	tags = {
		Name = "Controller"
	}

	connection {
		type = "ssh"
		user = "ubuntu"
		private_key = tls_private_key.ssh.private_key_pem
		host = aws_instance.controller.public_ip
	}
	provisioner "remote-exec" {
		inline = [
			"git clone https://github.com/proxycannon/proxycannon-ng",
#			"cd proxycannon-ng/setup/"
#			"sudo ./install.sh"
#			"cd ../..",
#			"cd nodes/aws/"
		]
	}
}

output "controller-ip" {
	value = aws_instance.controller.public_ip
	description = "Controller Public IP"
}

output "subnet-id" {
	value = aws_instance.controller.subnet_id
	description = "Subnet Id"
}
