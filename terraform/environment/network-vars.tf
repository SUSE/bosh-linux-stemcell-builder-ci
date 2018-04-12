# input variables

variable "ext_net_id" {
  description = "OpenStack external network id to create router interface port"
}

variable "availability_zone" {
  description = "OpenStack availability zone name"
}

variable "dns_nameservers" {
  description = "Comma-separated list of DNS server IPs"
  default = "8.8.8.8"
}

variable "outer_bosh_router_id" {
  description = "Outer bosh router id"
}

variable "environment_id" {
  description = "Id of the environment"
}
