output "website_url" {
  value = "http://${aws_instance.web.public_ip}"
}