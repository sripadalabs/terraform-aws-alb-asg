resource "aws_launch_template" "custom_app" {
  name_prefix   = "custom-app-"
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
    security_groups             = [aws_security_group.custom_app_sg.id]
  }
  
  # this is for instance tags, which are different from ASG tags. 
  # ASG tags are applied to the instances when they are launched by the ASG, 
  # but instance tags are applied to the instances themselves and can be used for cost allocation, organization, etc.
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "custom-app-instance"
    }
  }
  
  # this is for root ebs volume tagging, which is different from instance tags.
  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "custom-app-root-volume"
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