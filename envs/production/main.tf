module "vpc" {
  source     = "../../modules/vpc"
  env        = var.env
  cidr_block = var.cidr_block
}

module "alb" {
  source            = "../../modules/alb"
  services          = var.services
  env               = var.env
  domain            = var.domain
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

module "ecr" {
  source   = "../../modules/ecr"
  services = var.services
  env      = var.env
}

module "eks" {
  source                = "../../modules/eks"
  services              = var.services
  env                   = var.env
  region                = var.region
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_security_group_id = module.alb.alb_security_group_id
  rds_security_group_id = module.rds.rds_security_group_id
}

module "rds" {
  source                = "../../modules/rds"
  env                   = var.env
  region                = var.region
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  public_subnet_one_id  = module.vpc.public_subnet_one_id
  eks_security_group_id = module.eks.eks_security_group_id
  db_allowed_ips        = var.db_allowed_ips
}

module "elasticache" {
  source                = "../../modules/elasticache"
  services              = var.services
  env                   = var.env
  region                = var.region
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  eks_security_group_id = module.eks.eks_security_group_id
}
