resource "aws_security_group" "app" {
  name   = "${var.app_name}-app-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "Application traffic from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-app-sg"
  }
}

resource "aws_launch_template" "custom_app" {
  name_prefix   = "${var.app_name}-"
  image_id      = var.ami_id
  instance_type = var.ec2_instance_type
  update_default_version = true
  # This is keypair is optional, so we can comment it out if not needed. 
  # If you want to use a key pair, uncomment the line below and provide the key name in variables.tf.
  #key_name = var.key_name

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs{
        delete_on_termination = true
        encrypted             = true
        #kms_key_id             = data.aws_kms_key.ebs_key.arn
        volume_size           = 8
        volume_type           = "gp3"    
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.custom_app.name
  }

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint               = "enabled" # Enables the Instance Metadata Service (IMDS). curl http://169.254.169.254/latest/meta-data/
    http_tokens                 = "required" # It forces the use of IMDSv2 instead of IMDSv1.
    http_put_response_hop_limit = 1 # 1 for EC2 based workloads, 2 for ECS/EKS workloads
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app.id]
  }
  
  # this is for instance tags, which are different from ASG tags. 
  # ASG tags are applied to the instances when they are launched by the ASG, 
  # but instance tags are applied to the instances themselves and can be used for cost allocation, organization, etc.
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.app_name}-instance"
    }
  }
  
  # this is for root ebs volume tagging, which is different from instance tags.
  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.app_name}-root-volume"
    }
  }

  user_data = base64encode(
  templatefile("${path.module}/user_data.sh", {
    app_port         = var.app_port
    bucket_name      = var.app_artifact_bucket
    object_key       = var.app_artifact_key
    object_version   = var.app_artifact_version
  })
)
}

resource aws_autoscaling_group "custom_app_asg" {
  #name                      = "${var.app_name}-asg"
  name_prefix               = "${var.app_name}-asg-"
  
  desired_capacity          = var.asg_desired_capacity
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  target_group_arns          = [aws_lb_target_group.custom_app_tg.arn]

  vpc_zone_identifier       = var.private_subnets

  # allow ASG to terminate instances during scale-in events. Set to true if you want to protect instances from being terminated during scale-in events.
  # Scale Out -> Add instances / Scale In  -> Remove instances
  protect_from_scale_in     = false
  # ASG waits before allowing another scaling policy to execute. 
  # Otherwise, it can execute multiple scaling policies in a short period of time, which can lead to unexpected behavior.
  default_cooldown = var.asg_default_cooldown
  default_instance_warmup = var.asg_instance_warmup
  metrics_granularity = "1Minute"
  #capacity_rebalance = false this isuseful for Splot instances. Now much use for on-demand instances.
  
  launch_template {
    id      = aws_launch_template.custom_app.id
    version = var.launch_template_version
  }
  health_check_type         = "ELB" # Why not EC2? Because we want to use the ALB health check, which is more accurate for our application.
  health_check_grace_period = var.asg_health_check_grace_period
  max_instance_lifetime       = 0 # It is not used. No default termination of instances based on age. If you want to use it, set it to a positive integer in seconds.
  
  instance_refresh {
    strategy = "Rolling"
    triggers = ["launch_template"]

    preferences {
      instance_warmup        = 300
      min_healthy_percentage = 100
      max_healthy_percentage = 150
      auto_rollback = true
      skip_matching = true
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.app_name}-instance"
    propagate_at_launch = true # This is important. It ensures that the tag is applied to the instances launched by the ASG.
  }
}

resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${var.app_name}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.custom_app_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value     = 70
    disable_scale_in = false
  }
}

# this is lifecycle hooks, which can be used to perform actions when an instance 
# is launched or terminated. 
# For example, you can use a lifecycle hook to run a script on the instance before it is terminated, 
# or to send a notification when an instance is launched.

resource "aws_autoscaling_lifecycle_hook" "terminate" {
  name                   = "instance-terminating"
  autoscaling_group_name = aws_autoscaling_group.custom_app_asg.name

  lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"

  heartbeat_timeout = 300
  default_result    = "CONTINUE"
}

# Below is useful if you want to use a simple scaling policy instead of target tracking.
# if you want scale up 

# resource aws_autoscaling_policy "scale_up" {
#   name                   = "${var.app_name}-scale-up"
#   autoscaling_group_name = aws_autoscaling_group.custom_app_asg.name
#   policy_type            = "SimpleScaling"
#   adjustment_type        = "ChangeInCapacity"
#   scaling_adjustment     = 1
#   cooldown               = 300
#   estimated_instance_warmup = 300
# }

# resource "aws_cloudwatch-metrics_alarm" "cpu_utilization_high" {
#   alarm_name          = "${var.app_name}-cpu-utilization-high"
#   alarm_description   = "This metric monitors EC2 CPU utilization and triggers scale-up policy when it exceeds the threshold."
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 2
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/EC2"
#   period              = 300
#   statistic           = "Average"
#   threshold           = 70

#   dimensions = {
#     AutoScalingGroupName = aws_autoscaling_group.custom_app_asg.name
#   }
#   actions_enabled   = true
#   alarm_actions     = [aws_autoscaling_policy.scale_up.arn]
# }