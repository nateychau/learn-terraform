resource "aws_ecs_cluster" "sushibar-cluster" {
  name = "sushibar-cluster"
}

resource "aws_default_vpc" "default_vpc" {}

resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "us-west-2a"
}

resource "aws_ecs_task_definition" "sushibar-task" {
  family = "sushibar-task"
  network_mode = "awsvpc"
  requires_compatibilities = [ "FARGATE" ]
  execution_role_arn = "${aws_iam_role.ecsTaskExecutionRole.arn}"
  memory = "512"
  cpu = "256"
  container_definitions = <<EOF
  [
    {
      "name": "sushibar-container",
      "image": "${aws_ecr_repository.sushibar.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ],
      "environment": ${jsonencode(var.env_vars)} 
    }
  ]
  EOF
}
//NOTE: variables.tf is gitignored


resource "aws_ecs_service" "sushibar-service" {
  name = "sushibar"
  cluster = aws_ecs_cluster.sushibar-cluster.id 
  task_definition = aws_ecs_task_definition.sushibar-task.arn 
  launch_type = "FARGATE"
  desired_count = 1

  network_configuration {
    subnets = ["${aws_default_subnet.default_subnet_a.id}"]
    assign_public_ip = true 
  }

}