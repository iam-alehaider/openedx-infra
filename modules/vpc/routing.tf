

#===============================
# Route Tables: Public
#==============================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = merge(local.tags, { Name = "${local.name}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#=============================================
#  Route Tables: Private (one per AZ for HA)
#=============================================

resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
    }
  }

  tags = merge(local.tags, { Name = "${local.name}-private-rt-${count.index}" })

  depends_on = [aws_nat_gateway.main]
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

#=============================================
# Route Tables: Database (ISOLATED — no internet route)
#=============================================

resource "aws_route_table" "database" {
  count  = length(var.database_subnets)
  vpc_id = aws_vpc.main.id

  # No 0.0.0.0/0 route — database subnets are fully isolated
  tags = merge(local.tags, { Name = "${local.name}-database-rt-${count.index}" })
}

resource "aws_route_table_association" "database" {
  count          = length(aws_subnet.database)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[count.index].id
}

