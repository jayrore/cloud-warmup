

resource "aws_security_group" "bastion_ssh" {
  name        = "bastion-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = "${data.aws_vpc.default.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    # $(curl -s http://checkip.amazonaws.com)
    # cidr_blocks = [] # add a CIDR block here
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

    
data "template_cloudinit_config" "user_data" {
  gzip          = false
  base64_encode = true
  # Setup bastion stuff
}


resource "aws_launch_template" "bastion" {
  name_prefix                          = "bastion-"
  image_id                             = "ami-0a313d6098716f372"
  instance_type                        = "t2.micro"
  key_name                             = ""
  user_data                            = "${data.template_cloudinit_config.user_data.rendered}"
  instance_initiated_shutdown_behavior = "terminate"
  ebs_optimized                        = false
  network_interfaces {
    associate_public_ip_address        = true
    delete_on_termination              = true
    subnet_id                          = "${element(data.aws_subnet_ids.default,0)}"
    security_groups                    = [
      "${aws_security_group.bastion_ssh.id}"
      ]
  }
}

resource "aws_autoscaling_group" "bastion" {
  name = "bastion-ag"

  launch_template = {
    id = "${aws_launch_template.bastion}"
    version = "$LATEST"
  }

  vpc_zone_identifier = [
    "${data.aws_subnet_ids.default}",
  ]
  desired_capacity          = "${local.agCapacity}"
  min_size                  = "${local.agCapacity}"
  max_size                  = "${local.agCapacity}"
  health_check_grace_period = "60"
  health_check_type         = "EC2"
  force_delete              = true
  wait_for_capacity_timeout = 0
}