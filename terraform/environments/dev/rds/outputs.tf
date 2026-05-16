output "db_instance_id" {
  description = "The RDS instance ID"
  value       = module.rds.db_instance_id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.rds.db_instance_arn
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = module.rds.db_instance_endpoint
}

output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.rds.db_instance_address
}

output "db_instance_port" {
  description = "The database port"
  value       = module.rds.db_instance_port
}

output "db_instance_engine" {
  description = "The database engine"
  value       = module.rds.db_instance_engine
}

output "db_instance_engine_version" {
  description = "The database engine version"
  value       = module.rds.db_instance_engine_version
}

output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = module.rds.db_subnet_group_id
}

output "db_parameter_group_id" {
  description = "The db parameter group id"
  value       = module.rds.db_parameter_group_id
}

output "security_group_id" {
  description = "The security group ID"
  value       = module.rds.security_group_id
}

output "db_credentials_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing database credentials"
  value       = module.rds.db_credentials_secret_arn
}

output "read_replica_ids" {
  description = "List of read replica instance IDs"
  value       = module.rds.read_replica_ids
}

output "read_replica_endpoints" {
  description = "List of read replica endpoints"
  value       = module.rds.read_replica_endpoints
}
