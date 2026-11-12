output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "route_tables_ids" {
  description = "List of route table IDs to which the VPN route will be added"
  value       = [aws_route_table.public.id]
}
