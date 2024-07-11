variable "vpc_cidr" {
  default = "172.16.0.0/16"
}

variable "public_cidr" {
  type    = list(string)
  default = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
}
variable "ingress_cidr" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "am_i" {
  default = "ami-094be4c7f1e506a7a"
}

variable "file_name" {
  default = "nginx-key"
}

variable "key_path" {
  default = "/terraform-keys"
}