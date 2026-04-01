# root/outputs.tf
output "instance_public_ip" {
  # This tells Terraform to look inside the module instead of the root
  value = module.compute.instance_public_ip 
}