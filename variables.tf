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

variable "ec2_instance_type" {
  description = "EC2 instance type used by the launch template, such as t3.micro."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*\\.[a-z0-9-]+$", var.ec2_instance_type))
    error_message = "ec2_instance_type must be an EC2 instance type in the form family.size, such as t3.micro."
  }
}

variable app_name {
  description = "Name of the application."
  type        = string
  default     = "custom-app"
}

variable app_port {
  description = "Port on which the application listens."
  type        = number

  validation {
    condition     = var.app_port > 0 && var.app_port <= 65535 && floor(var.app_port) == var.app_port
    error_message = "app_port must be an integer between 1 and 65535."
  }
}

variable app_artifact_bucket{
  description = "Name of the S3 bucket containing the application artifact."
  type        = string
}

variable app_artifact_key{
  description = "Key of the application artifact in the S3 bucket."
  type        = string
}

variable app_artifact_version{
  description = "Version of the application artifact in the S3 bucket."
  type        = string
}

variable asg_health_check_grace_period{
  description = "The amount of time, in seconds, that the Auto Scaling Group waits before checking the health status of an instance after it has been launched or restarted."
  type        = number
  default     = 300
  validation {
    condition     = var.asg_health_check_grace_period >= 0 && floor(var.asg_health_check_grace_period) == var.asg_health_check_grace_period
    error_message = "health_check_grace_period must be a non-negative integer."
  }
}

variable asg_default_cooldown{
  description = "The amount of time, in seconds, that the Auto Scaling Group waits before allowing another scaling activity to start after a previous scaling activity has completed."
  type        = number
  default     = 300
  validation {
    condition     = var.asg_default_cooldown >= 0 && floor(var.asg_default_cooldown) == var.asg_default_cooldown
    error_message = "default_cooldown must be a non-negative integer."
  }
}

variable asg_instance_warmup{
  description = "The amount of time, in seconds, that the Auto Scaling Group waits for an instance to warm up before it can contribute to the desired capacity."
  type        = number
  default     = 300
  validation {
    condition     = var.asg_instance_warmup >= 0 && floor(var.asg_instance_warmup) == var.asg_instance_warmup
    error_message = "instance_warmup must be a non-negative integer."
  }
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS listener."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:acm:[a-z0-9-]+:[0-9]{12}:certificate/[0-9a-fA-F-]+$", var.acm_certificate_arn))
    error_message = "The acm_certificate_arn must be a valid ACM certificate ARN."
  }
}

