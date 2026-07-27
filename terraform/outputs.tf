output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.chat_server.id
}

output "public_ip" {
  description = "EC2 Public IP"
  value       = aws_instance.chat_server.public_ip
}

output "application_url" {
  description = "WebSocket Chat Application URL"
  value       = "http://${aws_instance.chat_server.public_ip}"
}

output "netdata_url" {
  description = "Netdata Monitoring URL"
  value       = "http://${aws_instance.chat_server.public_ip}:19999"
}