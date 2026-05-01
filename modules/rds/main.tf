

resource "aws_db_instance" "main" {
  identifier     = "${local.name}-mysql"
  engine         = "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  #=========================
  # Database Identity
  #=========================

  db_name  = var.db_name
  username = var.db_username
  # AWS Secrets Manager manages and rotates the master password automatically
  manage_master_user_password = true

  #===================
  # Storage
  #===================

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  # FIX: Use customer-managed KMS key instead of AWS default key
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  #=======================
  # Networking
  #=======================

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  #=======================
  # Configuration
  #======================

  parameter_group_name = aws_db_parameter_group.mysql.name

  # FIX: Enable IAM database authentication — short-lived tokens, no static passwords
  iam_database_authentication_enabled = true

  #===========================
  # High Availability
  #===========================

  multi_az = var.multi_az

  #====================
  # Protection
  #====================

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${local.name}-mysql-final-snapshot" : null

  #==================
  # Backup
  #==================

  backup_retention_period = var.backup_retention
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true

  #==================
  # Logging
  #==================

  # FIX: Expose via variable — general log is very expensive; disable in prod
  enabled_cloudwatch_logs_exports = var.cloudwatch_log_exports

  #==================================
  # Performance Insights
  #===================================

  performance_insights_enabled          = var.performance_insights_enabled
  # FIX: Set retention to avoid silent cost growth (was unset = default 7 days)
  performance_insights_retention_period = var.performance_insights_retention_days

  #=============================
  # Enhanced Monitoring
  #=============================

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  tags = merge(local.tags, { Name = "${local.name}-mysql" })

  # FIX: Prevent accidental destruction of the database
  lifecycle {
    prevent_destroy = true
  }
}



