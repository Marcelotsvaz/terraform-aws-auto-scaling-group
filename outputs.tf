output arn {
	# Manually construct the ARN so we can reference it in the Launch Templates used by the Auto
	# Scaling Group without creating circular dependencies.
	value = provider::aws::arn_build(
		"aws",
		"autoscaling",
		data.aws_region.main.name,
		data.aws_caller_identity.main.account_id,
		"autoScalingGroup:*:autoScalingGroupName/${local.auto_scaling_group_name}",
	)
	description = "Auto scaling group ARN."
}

output name {
	value = local.auto_scaling_group_name
	description = "Auto scaling group name."
}


data aws_region main {}

data aws_caller_identity main {}