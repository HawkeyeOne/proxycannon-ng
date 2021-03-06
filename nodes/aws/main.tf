provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  region = "us-east-1"
}

resource "aws_instance" "exit-node" {
  ami           = "ami-07d25496ed9d672f0"
  instance_type = "t2.micro"
  key_name      = "pc-key"
  vpc_security_group_ids = ["${aws_security_group.exit-node-sec-group.id}"]
  subnet_id	= "${var.subnet-id}"
  # we need to disable this for internal routing
  source_dest_check	= false
  count		= var.countOf


  tags = {
    Name = "exit-node"
  }

  # upload our provisioning scripts
  provisioner "file" {
    source      = "${path.module}/configs/"
    destination = "/tmp/"

    connection {
      type     = "ssh"
      user     = "ubuntu"
      #private_key = "${file("${var.aws_priv_key}")}"
      private_key = var.mainKey 
      host = self.public_ip 

    }
  }

  # execute our provisioning scripts
  provisioner "remote-exec" {
    script = "${path.module}/configs/node_setup.bash"

    connection {
      type     = "ssh"
      user     = "ubuntu"
      #private_key = "${file("${var.aws_priv_key}")}"
      private_key = var.mainKey
      host = self.public_ip 
      
    }
  }

  # modify our route table when we bring up an exit-node
  provisioner "remote-exec" {
    #command = "sudo ./add_route.bash ${self.private_ip}"
    inline = [ 
	"cd proxycannon-ng/nodes/aws/",
        "sudo ./add_route.bash ${self.private_ip}"
    ]


    connection {
      type = "ssh"
      user = "ubuntu" 
      private_key = var.mainKey
      host = var.controller_ip

    }
  }

  # modify our route table when we destroy an exit-node
  provisioner "remote-exec" {
    when = destroy
    #command = "sudo ./del_route.bash ${self.private_ip}"
    inline = [
	"cd proxycannon-ng/nodes/aws/",
        "sudo ./del_route.bash ${self.private_ip}"
    ]

    connection {
      type = "ssh"
      user = "ubuntu" 
      private_key = var.mainKey
      host = var.controller_ip

    }
  }

}

resource "aws_security_group" "exit-node-sec-group" {
  vpc_id = var.vpc_id
  name = "exit-node-sec-grp"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0 
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


