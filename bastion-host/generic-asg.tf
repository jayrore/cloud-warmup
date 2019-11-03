resource "aws_security_group" "allow_bastion_ssh_into_generic" {
  name        = "bastion-ssh-generic"
  description = "Allow Bastion SSH into Generic ASG"
  vpc_id      = "${data.aws_vpc.default.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = ["${aws_security_group.bastion_ssh.id}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "generic" {
  name_prefix                          = "generic-"
  image_id                             = "ami-0a313d6098716f372"
  instance_type                        = "t2.micro"
  key_name                             = "${aws_key_pair.bastion.key_name}"
  instance_initiated_shutdown_behavior = "terminate"
  ebs_optimized                        = false
  network_interfaces {
    associate_public_ip_address        = false
    delete_on_termination              = true
    subnet_id                          = "${element(data.aws_subnet_ids.default.ids,0)}"
    security_groups                    = [
      "${aws_security_group.allow_bastion_ssh_into_generic.id}"
      ]
  }
}

resource "aws_autoscaling_group" "generic" {
  name = "generic-ag"

  launch_template = {
    id      = "${aws_launch_template.generic.id}"
    version = "$Latest"
  }

  vpc_zone_identifier = [
    "${data.aws_subnet_ids.default.ids}",
  ]
  desired_capacity          = "1"
  min_size                  = "1"
  max_size                  = "1"
  health_check_grace_period = "60"
  health_check_type         = "EC2"
  force_delete              = true
  wait_for_capacity_timeout = 0
}