variable "environment" {
    description = "env"
    type = string
}

variable "vpc_cidr" {
    description = "VPC cidr block"
    type = string
    default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
    description = "Public subnet CIDR blocks"
    type = list(string)
    default = ["10.0.0.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "private subnet CIDR blocks"
  type = list(string)
  default = ["10.0.10.0/24", "10.0.20.0/24"]
}
variable "availability_zones" { 
    description = "Availability zones"
    type = list(string)
    default = ["ap-south-1a", "ap-south-1b"]
  
}