#!/bin/bash
# echo "export MINIO_URL=${MINIO_URL}"
# echo "export MINIO_ACCESS=${MINIO_ACCESS_KEY}"
# echo "export MINIO_SECRET_KEY=${MINIO_SECRET_KEY}"
# echo "message = ${1}"

./mc config host add minio $MINIO_URL $MINIO_ACCESS_KEY $MINIO_SECRET_KEY
uuid=$(uuidgen)

echo $1
wget $1 -O $uuid
./mc cp $uuid minio/input
