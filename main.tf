terraform { 
	required_version = ">= 0.11.0"
}

resource "tls_private_key" "ssh" {
	algorithm = "RSA"
	rsa_bits = 4096
}
