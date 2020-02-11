resource "aws_efs_file_system" "this-efs-file-system" {
  tags = var.tags
}

resource "aws_efs_mount_target" "this-efs-mount-target" {

  count          = var.subnet_count
  file_system_id = aws_efs_file_system.this-efs-file-system.id
  subnet_id      = var.subnets[count.index]
  security_groups = var.security_groups

}
