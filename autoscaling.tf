resource "aws_appautoscaling_target" "this" {
  for_each = var.create_table ? var.autoscaling : {}

  max_capacity       = each.value.max_capacity
  min_capacity       = each.value.min_capacity
  resource_id        = "table/${try(aws_dynamodb_table.autoscaled[0].name, aws_dynamodb_table.autoscaled_gsi_ignore[0].name)}"
  scalable_dimension = each.value.scalable_dimension
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "this" {
  # Filter the var.autoscaling map to include only items with a non-empty policy_name
  for_each = var.create_table ? {
    for k, v in var.autoscaling : k => v if v.policy_name != null && v.policy_name != ""
  } : {}

  name               = each.value.policy_name
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.this[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = each.value.predefined_metric_type
    }

    scale_in_cooldown  = each.value.scale_in_cooldown
    scale_out_cooldown = each.value.scale_out_cooldown
    target_value       = each.value.target_value
  }
}
