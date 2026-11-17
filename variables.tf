variable "vpc_id" {
  description = "ID of the VPC where the load balancer and Auto Scaling Group will run."
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-fA-F]+$", var.vpc_id))
    error_message = "The vpc_id must be a VPC ID in the form vpc-<hexadecimal characters>."
  }
}

variable "public_subnets" {
  description = "IDs of the public subnets used by the load balancer."
  type        = list(string)

  validation {
    condition     = length(var.public_subnets) > 0 && alltrue([for subnet_id in var.public_subnets : can(regex("^subnet-[0-9a-fA-F]+$", subnet_id))])
    error_message = "public_subnets must contain at least one valid subnet ID in the form subnet-<hexadecimal characters>."
  }
}

variable "private_subnets" {
  description = "IDs of the private subnets used by the Auto Scaling Group."
  type        = list(string)

  validation {
    condition     = length(var.private_subnets) > 0 && alltrue([for subnet_id in var.private_subnets : can(regex("^subnet-[0-9a-fA-F]+$", subnet_id))])
    error_message = "private_subnets must contain at least one valid subnet ID in the form subnet-<hexadecimal characters>."
  }
}

variable "asg_desired_capacity" {
  description = "The desired number of instances in the Auto Scaling Group."
  type        = number

  validation {
    condition     = var.asg_desired_capacity >= var.asg_min_size && var.asg_desired_capacity <= var.asg_max_size && floor(var.asg_desired_capacity) == var.asg_desired_capacity
    error_message = "asg_desired_capacity must be an integer between asg_min_size and asg_max_size."
  }
}

variable "asg_min_size" {
  description = "The minimum number of instances in the Auto Scaling Group."
  type        = number

  validation {
    condition     = var.asg_min_size >= 0 && var.asg_min_size <= var.asg_max_size && floor(var.asg_min_size) == var.asg_min_size
    error_message = "asg_min_size must be a non-negative integer no greater than asg_max_size."
  }
}

variable "asg_max_size" {
  description = "The maximum number of instances in the Auto Scaling Group."
  type        = number

  validation {
    condition     = var.asg_max_size >= 0 && floor(var.asg_max_size) == var.asg_max_size
    error_message = "asg_max_size must be a non-negative integer."
  }
}

variable "ami_id" {
  description = "ID of the AMI used by the launch template."
  type        = string

  validation {
    condition     = can(regex("^ami-[0-9a-fA-F]+$", var.ami_id))
    error_message = "The ami_id must be an AMI ID in the form ami-<hexadecimal characters>."
  }
}

variable "launch_template_version" {
  description = "Launch template version number, $Latest, or $Default."
  type        = string

  validation {
    condition     = can(regex("^(\\$Latest|\\$Default|[1-9][0-9]*)$", var.launch_template_version))
    error_message = "launch_template_version must be a positive version number, $Latest, or $Default."
  }
}

variable "ec2_instance_size" {
  description = "EC2 instance type used by the launch template, such as t3.micro."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*\\.[a-z0-9-]+$", var.ec2_instance_size))
    error_message = "ec2_instance_size must be an EC2 instance type in the form family.size, such as t3.micro."
  }
}
