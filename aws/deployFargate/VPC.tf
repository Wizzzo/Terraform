resource "aws_vpc" "demoAppVPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name        = "Demo App VPC"
    Environment = "demoApp"
  }
}


resource "aws_subnet" "demoAppSubnet1" {
  vpc_id            = aws_vpc.demoAppVPC.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"
#   map_public_ip_on_launch = true

  tags = {
    Name        = "Demo App Subnet 1"
    Environment = "demoApp"
  }
}

resource "aws_subnet" "demoAppSubnet2" {
  vpc_id            = aws_vpc.demoAppVPC.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1b"
#   map_public_ip_on_launch = true


  tags = {
    Name        = "Demo App Subnet 2"
    Environment = "demoApp"
  }
}


resource "aws_internet_gateway" "demoAppInternetGateway" {
  vpc_id = aws_vpc.demoAppVPC.id

  tags = {
    Name        = "Demo App Internet Gateway"
    Environment = "demoApp"
  }
}

resource "aws_route_table" "demoAppRouteTable" {
  vpc_id = aws_vpc.demoAppVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demoAppInternetGateway.id
  }
}

resource "aws_route_table_association" "demoAppSubnet1Ass" {
  subnet_id      = aws_subnet.demoAppSubnet1.id
  route_table_id = aws_route_table.demoAppRouteTable.id
}

resource "aws_route_table_association" "demoAppSubnet2Ass" {
  subnet_id      = aws_subnet.demoAppSubnet2.id
  route_table_id = aws_route_table.demoAppRouteTable.id
}

# resource "aws_internet_gateway_attachment" "demoAppInternetGatewayAttachment" {
#   internet_gateway_id = aws_internet_gateway.demoAppInternetGateway.id
#   vpc_id              = aws_vpc.demoAppVPC.id
# }