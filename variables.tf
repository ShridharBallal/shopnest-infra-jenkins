variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"   # 🔥 PUT YOUR REGION HERE
}

variable "ami_id" {
  description = "Ubuntu AMI ID"
  type        = string
  default     = "ami-03446a3af42c5e74e"   # 🔥 PUT YOUR UBUNTU AMI HERE
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.large"   # 🔥 You can change if needed
}

variable "key_name" {
  description = "EC2 Key Pair Name"
  type        = string
  default     = "s-all"   # 🔥 PUT YOUR AWS KEYPAIR NAME HERE
}

variable "root_volume_size" {
  description = "EC2 root volume size in GB"
  type        = number
  default     = 26    # 🔥 Change internal storage size here
}