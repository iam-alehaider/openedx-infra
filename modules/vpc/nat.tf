

#=========================================
#  Elastic IPs for NAT Gateways
#=======================================

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.azs)) : 0
  domain = "vpc"
  tags   = merge(local.tags, { Name = "${local.name}-nat-eip-${count.index}" })

  depends_on = [aws_internet_gateway.main]
}

#===========================
# ─── NAT Gateways ───
#===========================

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.azs)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id

  tags       = merge(local.tags, { Name = "${local.name}-nat-${count.index}" })
  depends_on = [aws_internet_gateway.main]
}

