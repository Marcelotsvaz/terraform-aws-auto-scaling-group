# 
# Naming
#-------------------------------------------------------------------------------
variable name {
	description = "Pretty name for resources in this module. Used in tags."
	type = string
}

variable prefix {
	description = "Unique prefix for resources that require a (possibly unique) name or identifier."
	type = string
	
	validation {
		condition = length( regexall( "^[a-z0-9_-]+$", var.prefix ) ) > 0
		error_message = "`prefix` should contain only lower case letters, numbers, hyphens and underscores."
	}
}


# 
# Instance Requirements
#-------------------------------------------------------------------------------
variable instance_type {
	description = "Instance type."
	type = string
	default = null
	validation {
		condition = (
			var.instance_type != null
			&& var.min_vcpu_count == null
			&& var.min_memory_gib == null
		) || (
			var.instance_type == null
			&& ( var.min_vcpu_count != null || var.min_memory_gib != null )
		)
		error_message = "Either `instance_type` or one instance requirement must be provided."
	}
}

variable min_vcpu_count {
	description = "Minimum number of vCPUs."
	type = number
	default = null
}

variable min_memory_gib {
	description = "Minimum amount of memory."
	type = number
	default = null
}

variable burstable {
	description = "Whether to include burstable instance types."
	type = string
	default = "included"
}

variable max_instance_price {
	description = "Maximum spot instance price."
	type = number
	default = null
}


# 
# Configuration
#-------------------------------------------------------------------------------
variable ami_id {
	description = "AMI ID."
	type = string
	default = null
}

variable user_data_base64 {
	description = "Instance user data. Base64-encoded."
	type = string
	default = null
}

variable role_name {
	description = "Name of the IAM role assumed by the instances."
	type = string
	default = null
}


# 
# Network
#-------------------------------------------------------------------------------
variable subnet_ids {
	description = "Set of VPC subnet IDs. Will determine instance availability."
	type = set( string )
	default = []
}

variable security_group_ids {
	description = "Set of security group IDs."
	type = set( string )
	default = []
}


# 
# Storage
#-------------------------------------------------------------------------------
variable root_volume_size {
	description = "Size of the root volume in GB."
	type = number
	default = null
}


# 
# Auto Scaling
#-------------------------------------------------------------------------------
variable min_size {
	description = "Minimum number of instances."
	type = number
	default = 0
}

variable max_size {
	description = "Maximum number of instances."
	type = number
}

variable desired_capacity {
	description = "Desired number of instances."
	type = number
	default = null
}

variable protect_from_scale_in {
	description = "Enable scale in protection."
	type = bool
	default = false
}

variable suspended_processes {
	description = "Set of suspended auto scaling processes."
	type = set( string )
	default = []
}

variable lifecycle_hooks {
	description = "Lifecycle hooks."
	type = set(
		object( {
			name = string
			type = string
		} )
	)
	default = []
}



# 
# Locals
#-------------------------------------------------------------------------------
locals {
	auto_scaling_group_name = var.prefix
}