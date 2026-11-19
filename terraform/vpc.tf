# =============================================================================
# Sieć dla RDS - własne VPC z 2 prywatnymi podsieciami w różnych AZ.
# Dzięki temu `terraform plan -var="env=dev"` działa bez żadnych ręcznie
# przygotowanych zasobów sieciowych. Podsieci nie mają route do Internet
# Gateway, więc są faktycznie prywatne.
#
# Ustaw create_vpc = false, aby zamiast tego użyć istniejącego VPC
# (vpc_id + private_subnet_ids).
# =============================================================================

data "aws_availability_zones" "available" {
  count = var.create_vpc ? 1 : 0
  state = "available"
}

resource "aws_vpc" "this" {
  count = var.create_vpc ? 1 : 0

  cidr_block           = var.vpc_network_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-vpc" })

  lifecycle {
    precondition {
      # 1) maska VPC jest węższa lub równa masce vpc_cidr
      # 2) adres sieci VPC przycięty do maski vpc_cidr == adres sieci vpc_cidr
      condition = (
        local.vpc_network_prefix >= local.vpc_cidr_prefix &&
        cidrhost("${cidrhost(var.vpc_network_cidr, 0)}/${local.vpc_cidr_prefix}", 0) == cidrhost(var.vpc_cidr, 0)
      )
      error_message = "vpc_network_cidr musi mieścić się w vpc_cidr (inaczej security group RDS nie wpuści ruchu z VPC)."
    }
  }
}

resource "aws_subnet" "private" {
  count = var.create_vpc ? 2 : 0

  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = cidrsubnet(var.vpc_network_cidr, 4, count.index)
  availability_zone       = data.aws_availability_zones.available[0].names[count.index]
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-${data.aws_availability_zones.available[0].names[count.index]}"
    Tier = "private"
  })
}
