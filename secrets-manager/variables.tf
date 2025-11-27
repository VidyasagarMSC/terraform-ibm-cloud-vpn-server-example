variable "region_name" {
  type    = string
  default = "us-south"
}

variable "service_plan" {
  type    = string
  default = "trial"
}

variable "pre-create-secmgr-name" {
  type    = string
  default = ""
}
