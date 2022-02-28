output "route_table" {
  value = try(aws_route_table.route_table[0], null)
}