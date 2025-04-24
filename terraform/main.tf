provider "aws" {
  region = "us-east-1"
}

# 🔶 VPC + Subnet + Internet Gateway
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc-postgres"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "subnet-postgres"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 🔐 Security Group
resource "aws_security_group" "postgres_sg" {
  name        = "postgres-sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow SSH and PostgreSQL"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-postgres"
  }
}

# 🔧 EC2 instance
resource "aws_instance" "postgres_instance" {
  ami                    = "ami-084568db4383264d4"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  key_name               = "aws-key"
  vpc_security_group_ids = [aws_security_group.postgres_sg.id]

  tags = {
    Name = "PostgreSQL-Server"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/aws-key")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update"
    ]
  }
}

# 📦 EBS Volume
resource "aws_ebs_volume" "postgres_volume" {
  availability_zone = aws_instance.postgres_instance.availability_zone
  size              = 8
  type              = "gp2"

  tags = {
    Name = "postgres-ebs-volume"
  }
}

resource "aws_volume_attachment" "ebs_attach" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.postgres_volume.id
  instance_id = aws_instance.postgres_instance.id
}

# 💾 Snapshot automatique (manuel via apply)
resource "aws_ebs_snapshot" "postgres_snapshot" {
  volume_id = aws_ebs_volume.postgres_volume.id

  tags = {
    Name      = "postgres-snapshot-${timestamp()}"
    CreatedBy = "terraform"
  }
}
