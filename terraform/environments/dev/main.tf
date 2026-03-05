# ============================================
# STAGE 1: AWS INFRASTRUCTURE
# ============================================

module "aws_networking" {
  source = "../../modules/aws-networking"

  environment = var.environment
  vpc_cidr    = var.vpc_cidr

  subnets = {
    app = {
      cidr = "172.20.10.0/24"
      az   = "us-east-1a"
      tier = "application"
    }
    db = {
      cidr = "172.20.20.0/24"
      az   = "us-east-1b"
      tier = "database"
    }
    web = {
      cidr = "172.20.30.0/24"
      az   = "us-east-1a"
      tier = "web"
    }
  }

  tags = {
    Project     = "TechCorp-Inventory"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ============================================
# STAGE 2: REGISTER IN INFOBLOX IPAM
# ============================================

module "infoblox_ipam" {
  source = "../../modules/infoblox-ipam"

  ip_space_name = "TechCorp-Cloud"

  address_block = {
    address = "172.20.0.0"
    cidr    = 16
    name    = "AWS-${var.environment}-VPC"
    comment = "Synced from AWS VPC ${module.aws_networking.vpc_id}"
  }

  subnets = {
    app = {
      address = "172.20.10.0"
      cidr    = 24
      name    = "AWS-${var.environment}-App-Tier"
      comment = "AWS Subnet: ${module.aws_networking.subnet_ids["app"]}"
    }
    db = {
      address = "172.20.20.0"
      cidr    = 24
      name    = "AWS-${var.environment}-DB-Tier"
      comment = "AWS Subnet: ${module.aws_networking.subnet_ids["db"]}"
    }
    web = {
      address = "172.20.30.0"
      cidr    = 24
      name    = "AWS-${var.environment}-Web-Tier"
      comment = "AWS Subnet: ${module.aws_networking.subnet_ids["web"]}"
    }
  }

  depends_on = [module.aws_networking]
}

# ============================================
# STAGE 3: DNS FOUNDATION
# ============================================

module "infoblox_dns" {
  source = "../../modules/infoblox-dns"

  dns_view_name = "techcorp-${var.environment}"
  zone_fqdn     = "inventory.techcorp.com."

  initial_records = {
    "api" = {
      type    = "A"
      address = "172.20.10.10"
      comment = "Inventory API endpoint"
    }
    "monitoring" = {
      type    = "A"
      address = "172.20.10.20"
      comment = "Monitoring dashboard endpoint"
    }
  }

  depends_on = [module.infoblox_ipam]
}
