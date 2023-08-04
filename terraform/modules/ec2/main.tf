module "label" {
  source  = "cloudposse/label/null"
  context = var.tags_context
}

resource "aws_instance" "this" {
  count = var.enabled ? 1 : 0

  ami                     = var.aws_ami_id
  instance_type           = var.instance_type
  key_name                = var.key_name
  monitoring              = var.monitoring
  ebs_optimized           = var.ebs_optimized
  disable_api_termination = var.disable_api_termination
  vpc_security_group_ids  = var.security_groups
  subnet_id               = var.subnet_id
  get_password_data       = var.get_password_data
  iam_instance_profile    = var.iam_instance_profile

  root_block_device {
    volume_type           = var.volume_type
    volume_size           = var.volume_size
    encrypted             = var.encrypted
    kms_key_id            = var.kms_key_id
    delete_on_termination = true
  }

  dynamic "network_interface" {
    for_each = var.static_ips
    content {
      device_index         = network_interface.key
      network_interface_id = aws_network_interface.nic[network_interface.key].id
    }
  }

  tags = module.label.tags

  lifecycle {
    ignore_changes = [
      root_block_device,
      ebs_block_device,
    ]
  }
}

module "label_ebs_vol" {
  source  = "cloudposse/label/null"
  context = var.tags_context
}

resource "aws_ebs_volume" "ebs_vol" {
  count             = var.additional_ebs[0].device_name == "NA" ? 0 : length(var.additional_ebs)
  availability_zone = aws_instance.this[0].availability_zone
  size              = var.additional_ebs[count.index].volume_size
  type              = var.additional_ebs[count.index].volume_type
  encrypted         = var.encrypted
  kms_key_id        = var.kms_key_id
  tags              = module.label.tags
  iops              = var.additional_ebs[count.index].iops
}

resource "aws_volume_attachment" "ebs_att" {
  count       = var.additional_ebs[0].device_name == "NA" ? 0 : length(var.additional_ebs)
  device_name = var.additional_ebs[count.index].device_name
  volume_id   = aws_ebs_volume.ebs_vol[count.index].id
  instance_id = aws_instance.this[0].id
}

module "label_nic" {
  source  = "cloudposse/label/null"
  context = var.tags_context
}

resource "aws_network_interface" "nic" {
  count           = length(var.static_ips)
  subnet_id       = var.subnet_id
  private_ips     = [var.static_ips[count.index]]
  security_groups = var.security_groups
  tags            = module.label_nic.tags
}
