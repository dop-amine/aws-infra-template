data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.env}-vpc"
    Environment = var.env
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.env}-igw"
    Environment = var.env
  }
}

resource "aws_subnet" "public_subnet_one" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 1)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "${var.env}-public-subnet-one"
    Environment = var.env
  }
}

resource "aws_subnet" "public_subnet_two" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 2)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "${var.env}-public-subnet-two"
    Environment = var.env
  }
}

resource "aws_subnet" "private_subnet_one" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 3) # Adjust the third parameter as necessary
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.env}-private-subnet-one"
    Environment = var.env
  }
}

resource "aws_subnet" "private_subnet_two" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 4) # Adjust the third parameter as necessary
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.env}-private-subnet-two"
    Environment = var.env
  }
}

resource "aws_eip" "nat_eip_one" {
  domain = "vpc"

  tags = {
    Name = "${var.env}-nat-eip-one"
  }
}

resource "aws_eip" "nat_eip_two" {
  domain = "vpc"

  tags = {
    Name = "${var.env}-nat-eip-two"
  }
}

resource "aws_nat_gateway" "nat_one" {
  allocation_id = aws_eip.nat_eip_one.id
  subnet_id     = aws_subnet.public_subnet_one.id

  tags = {
    Name = "${var.env}-nat-one"
  }
}

resource "aws_nat_gateway" "nat_two" {
  allocation_id = aws_eip.nat_eip_two.id
  subnet_id     = aws_subnet.public_subnet_two.id

  tags = {
    Name = "${var.env}-nat-two"
  }
}

resource "aws_route_table" "private_route_table_one" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_one.id
  }

  tags = {
    Name = "${var.env}-private-rt-one"
  }
}

resource "aws_route_table" "private_route_table_two" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_two.id
  }

  tags = {
    Name = "${var.env}-private-rt-two"
  }
}

resource "aws_route_table_association" "private_rta_one" {
  subnet_id      = aws_subnet.private_subnet_one.id
  route_table_id = aws_route_table.private_route_table_one.id
}

resource "aws_route_table_association" "private_rta_two" {
  subnet_id      = aws_subnet.private_subnet_two.id
  route_table_id = aws_route_table.private_route_table_two.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "${var.env}-public-rt"
    Environment = var.env
  }
}

resource "aws_route_table_association" "public_rta_one" {
  subnet_id      = aws_subnet.public_subnet_one.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_rta_two" {
  subnet_id      = aws_subnet.public_subnet_two.id
  route_table_id = aws_route_table.public_route_table.id
}
