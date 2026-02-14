output "ec2_public_ip" {
  value = aws_instance.shopnest_ec2.public_ip
}
