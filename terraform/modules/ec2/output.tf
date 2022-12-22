output "theId" {
  value = join("", aws_instance.this.*.id)
}

output "instance_az" {
  value = join("", aws_instance.this.*.availability_zone)
}

