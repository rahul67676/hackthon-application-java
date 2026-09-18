
# 1. Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "DevOps EC2 Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "All Traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-security-group"
  }
}

# 2. IAM Role & Instance Profile for EC2
resource "aws_iam_role" "ec2_role" {
  name = "devops-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_admin" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "devops-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# 3. EC2 Instance (30 GB Disk)
resource "aws_instance" "web_server" {
  ami                         = "ami-0b6d9d3d33ba97d99"
  instance_type               = "t3.large"
  key_name                    = "autoscalling"
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("C:/Users/RAHUL REDDY/OneDrive/Desktop/autoscalling.pem")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "install.sh"
    destination = "/home/ubuntu/install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/install.sh",
      "sudo bash /home/ubuntu/install.sh"
    ]
  }

  depends_on = [
    aws_eks_node_group.main_nodes,
    aws_eks_access_policy_association.ec2_policy
  ]

  tags = {
    Name = "devops-server"
  }
}
