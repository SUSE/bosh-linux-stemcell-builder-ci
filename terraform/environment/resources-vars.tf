# input variables

# key pair
variable "keypair_suffix" {
  description = "Disambiguate keypairs with this suffix"
  default = ""
}

variable "env_prefix" {
  description = "Prefix to reference an environment when using the same project for multiple bosh"
  default = ""
}
