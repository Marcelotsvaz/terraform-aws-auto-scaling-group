# 
# Auto Scaling Group
#-------------------------------------------------------------------------------
resource aws_autoscaling_group main {
	name = local.auto_scaling_group_name
	vpc_zone_identifier = var.subnet_ids
	min_size = var.min_size
	max_size = var.max_size
	desired_capacity = var.desired_capacity
	protect_from_scale_in = var.protect_from_scale_in
	suspended_processes = var.suspended_processes
	
	dynamic initial_lifecycle_hook {
		for_each = var.lifecycle_hooks
		
		content {
			name = initial_lifecycle_hook.value.name
			lifecycle_transition = {
				launching = "autoscaling:EC2_INSTANCE_LAUNCHING"
				terminating = "autoscaling:EC2_INSTANCE_TERMINATING"
			}[initial_lifecycle_hook.value.type]
		}
	}
	
	mixed_instances_policy {
		instances_distribution {
			on_demand_percentage_above_base_capacity = 0	# Use only spot instances.
			on_demand_allocation_strategy = "lowest-price"	# Required for instance requirements.
			spot_allocation_strategy = "price-capacity-optimized"
			spot_max_price = var.max_instance_price
		}
		
		launch_template {
			launch_template_specification {
				launch_template_id = aws_launch_template.main.id
				version = aws_launch_template.main.default_version
			}
		}
	}
	
	dynamic tag {
		for_each = merge( { Name = "${var.name} Auto Scaling Group" }, data.aws_default_tags.main.tags )
		
		content {
			key = tag.key
			value = tag.value
			propagate_at_launch = false
		}
	}
}


resource aws_launch_template main {
	name = var.prefix
	update_default_version = true
	
	# Instance requirements.
	instance_type = var.instance_type
	dynamic instance_requirements {
		for_each = var.instance_type == null ? [ true ] : []
		
		content {
			vcpu_count { min = coalesce( var.min_vcpu_count, 1 ) }
			memory_mib { min = try( var.min_memory_gib * 1024, 1 ) }
			burstable_performance = var.burstable
			allowed_instance_types = data.aws_ec2_instance_types.main.instance_types
		}
	}
	
	# Configuration.
	image_id = coalesce( var.ami_id, data.aws_ami.main.id )
	user_data = var.user_data_base64
	iam_instance_profile { arn = aws_iam_instance_profile.main.arn }
	
	# Network.
	vpc_security_group_ids = var.security_group_ids
	# source_dest_check = var.source_dest_check
	
	# Storage.
	block_device_mappings {
		device_name = "/dev/xvda"
		
		ebs {
			volume_size = var.root_volume_size
			encrypted = true
		}
	}
	ebs_optimized = true
	
	dynamic tag_specifications {
		for_each = {
			spot-instances-request = {
				Name = "${var.name} Spot Request"
			}
			instance = {
				Name = var.name
			}
			volume = {
				Name = "${var.name} Root Volume"
			}
		}
		
		content {
			resource_type = tag_specifications.key
			tags = merge( data.aws_default_tags.main.tags, tag_specifications.value )
		}
	}
	
	tags = {
		Name = "${var.name} Launch Template"
	}
}


data aws_ec2_instance_types main {
	filter {
		name = "supported-boot-mode"
		values = [ "uefi" ]
	}
	
	filter {
		name = "supported-usage-class"
		values = [ "spot" ]
	}
	
	filter {
		name = "processor-info.supported-architecture"
		values = [ "x86_64" ]
	}
}


data aws_default_tags main {}



# 
# AMI
#-------------------------------------------------------------------------------
data aws_ami main {
	owners = [ "amazon" ]
	most_recent = true
	
	filter {
		name = "name"
		values = [ "al2023-ami-2023.*" ]
	}
	
	filter {
		name = "architecture"
		values = [ "x86_64" ]
	}
}



# 
# Instance Profile
#-------------------------------------------------------------------------------
resource aws_iam_instance_profile main {
	name = var.prefix
	role = var.role_name
	
	tags = {
		Name = "${var.name} Instance Profile"
	}
}