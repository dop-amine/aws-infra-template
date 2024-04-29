env          = "staging"
region       = "us-east-1"
domain       = "domain.com"
cidr_block   = "10.1.0.0/16"

db_allowed_ips = [
]

services = {
  "service1" = {
    name   = "service1",
    domain = "service1.domain.com"
  },
  "service2" = {
    name   = "service2",
    domain = "service2.domain.com"
  }
}
