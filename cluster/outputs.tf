output "dns_ns_records" {
  description = "NS records for the DNS zone used throught the project"
  value       = aws_route53_zone.main[0].name_servers
}
