resource "aws_autoscaling_group" "k3s_servers_asg" {
  name                      = "k3s_servers"
  wait_for_capacity_timeout = "5m"
  vpc_zone_identifier       = var.vpc_subnets

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [load_balancers, target_group_arns]
  }

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = var.install_longhorn ? 100 : 20
      spot_allocation_strategy                 = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.k3s_server.id
        version            = "$Latest"
      }

      dynamic "override" {
        for_each = var.instance_types
        content {
          instance_type     = override.value
          weighted_capacity = "1"
        }
      }

    }
  }

  desired_capacity          = var.k3s_server_desired_capacity
  min_size                  = var.k3s_server_min_capacity
  max_size                  = var.k3s_server_max_capacity
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-k3s-server-${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "provisioner"
    value               = "terraform"
    propagate_at_launch = true
  }

  tag {
    key                 = "environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "k3s-instance-type"
    value               = "k3s-server"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = ""
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value               = ""
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "k3s_workers_asg" {
  name                = "k3s_workers"
  vpc_zone_identifier = var.vpc_subnets

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 20
      spot_allocation_strategy                 = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.k3s_agent.id
        version            = "$Latest"
      }

      dynamic "override" {
        for_each = var.instance_types
        content {
          instance_type     = override.value
          weighted_capacity = "1"
        }
      }

    }
  }

  desired_capacity          = var.k3s_worker_desired_capacity
  min_size                  = var.k3s_worker_min_capacity
  max_size                  = var.k3s_worker_max_capacity
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-k3s-worker-${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "provisioner"
    value               = "terraform"
    propagate_at_launch = true
  }

  tag {
    key                 = "environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "k3s-instance-type"
    value               = "k3s-worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = ""
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value               = ""
    propagate_at_launch = true
  }
}
