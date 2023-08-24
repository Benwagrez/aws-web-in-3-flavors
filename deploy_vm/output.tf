output "vm_publicip" {
    value = aws_instance.web_server.public_ip
}