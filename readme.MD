This readme.MD is for https://github.com/FariusGitHub/terraform_ansible
Please refer to https://medium.com/p/7bffc4edf285/edit for more detailed story about this code.

You may need to install Visual Code with Terraform to run main.tf file.
Download these four file and initiate the project by running below command at where these files are located

A. WITH TERRAFORM
terraform init && terraform plan && terraform apply -auto-approve

To delete them all, you may use
terraform destroy -auto-approve


B. WITH ANSIBLE

We can use something like below, change the pem section below according to your pem file location
ansible-playbook ansible.yml --key-file ~/Downloads/wcd-projects.pem

The first half of Ansible code is similar to Terraform which is to develop the Infrastructure.
The second half of Ansible code is just a tool for destroying AWS Resources.
You may want to uncommented all lines to destroying all AWS resources.
