#!/bin/bash

# Step 3

mkdir iac
cat <<EOF > ./iac/Dockerfile
FROM nginx:1.21.6-alpine

CMD ["nginx", "-g", "daemon off;"]
EOF

cat <<EOF > ./iac/main.tf
resource "aws_kms_key" "this" {
  description             = "WeScale"
  deletion_window_in_days = 10
}
EOF

mkdir iac-ok
cat <<EOF > ./iac-ok/Dockerfile
FROM nginx:1.21.6-alpine

USER toto

CMD ["nginx", "-g", "daemon off;"]
EOF

cat <<EOF > ./iac-ok/main.tf
resource "aws_kms_key" "this" {
  description             = "WeScale"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}
EOF


# Step 4

mkdir fs-scan
cat <<EOF > ./fs-scan/credentials
[admin]
aws_access_key_id=ASIAWESCALEGM6CP2NRR
aws_secret_access_key=macarenaaa+D9WOaVtBqz7GSH5rpe8C21Vu5G+wt
EOF

cat <<EOF > ./fs-scan/README.md
[admin]
aws_access_key_id=ASIAWESCALEGM6CP2NRR
aws_secret_access_key=macarenaaa+D9WOaVtBqz7GSH5rpe8C21Vu5G+wt
EOF

# Step 5

mkdir config

# Step 8

mkdir sbom
cat <<EOF > ./sbom/requirements.txt
wikipedia==1.4.0
xmltodict==0.12.0
yamllint==1.28.0
yarl==1.7.2
zope.component==4.3.0
zope.event==4.2.0
zope.interface==5.4.0
Pillow==2.3.0
EOF

pip3 install cyclonedx-bom

