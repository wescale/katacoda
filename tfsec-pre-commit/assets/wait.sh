#!/bin/bash

show_progress()
{

  echo "Please wait until everything is ready [~10s]"

  # Update packages
  echo -n "[1/4] Updating packages..."
  apt update &> /dev/null
  echo " Done !"

  # Install pip3 and set it as pip
  echo -n "[2/4] Installing pip..."
  apt install python3-pip -y &> /dev/null
  update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1 &> /dev/null
  echo " Done !"

  # Create demo git folder with a Terraform file
  echo -n "[3/4] Setting up demo environment..."
  git init &> /dev/null
  git config --global user.email "hellothere@obi-wan.kenobi" &> /dev/null
  git config --global user.name "Ewan McGregor" &> /dev/null
cat <<EOF > ./main.tf
resource "aws_kms_key" "this" {
  description             = "Je suis une clef KMS"
  deletion_window_in_days = 10
  enable_key_rotation     = false
}
EOF
  echo "Done !"

  # Install the TFSec binary
  echo -n "[4/4] Installing TFSec..."
  curl -o /usr/local/bin/tfsec -L -J -O https://github.com/aquasecurity/tfsec/releases/download/v1.1.5/tfsec-linux-amd64 &> /dev/null
  chmod u+x /usr/local/bin/tfsec
  echo " Done !"

  echo "You are all set ! Enjoy this course :)"
}

show_progress