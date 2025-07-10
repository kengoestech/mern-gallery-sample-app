# Output block for vpc
output "vpc-id" {
  value = aws_vpc.vpc_fp.id
}

# Output block for frontend-instance-1 private ip
output "frontend1-private-ip" {
  value = aws_instance.frontend_instance_1.private_ip
}

# Output block for frontend-instance-2 private ip
output "frontend2-private-ip" {
  value = aws_instance.frontend_instance_2.private_ip
}