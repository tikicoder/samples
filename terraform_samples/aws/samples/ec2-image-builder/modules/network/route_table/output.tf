output "routeTables_byvpcgroup" {
  value = {
    for key in keys(local.keys): 
      key => {
        for rtKey in keys(aws_route_table.ec2ImageBuilder_RouteTables): 
          rtKey=>aws_route_table.ec2ImageBuilder_RouteTables[rtKey]
        if substr(rtKey, 0, length(key)+1) == "${key}:"
      }
  }
}


output "routeTables" {
  value = aws_route_table.ec2ImageBuilder_RouteTables
}