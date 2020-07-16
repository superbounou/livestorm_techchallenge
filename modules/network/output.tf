output "aws_vpc" {
  description = "Ouput VPC"
  value       = aws_vpc.this
}

output "vpc_subnets_pub" {
  description = "A list of VPC subnet IDs."
  value       = [aws_subnet.pub1.id, aws_subnet.pub2.id]
}

output "vpc_subnets_priv" {
  description = "A list of VPC subnet IDs."
  value       = [aws_subnet.priv1.id, aws_subnet.priv2.id]
}