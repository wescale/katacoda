#/bin/bash
helm repo add minio https://charts.min.io/ >> /root/background.log

helm repo update >> /root/background.log

helm install  --set persistence.enabled=false \
 --set buckets[0].name=input,buckets[0].policy=none,buckets[0].purge=false \
 --set rootUser=rootuser,rootPassword=rootpass123 \
--set replicas=4 \
--set resources.requests.memory=250M \
--version 3.5.9 \
minio \
minio/minio >> /root/background.log

sleep 5;

wget https://katacoda-assets.s3.amazonaws.com/mc >> /root/background.log
chmod +x mc >> /root/background.log

# sleep 5;

cat << EOF > secret-minio.yaml
---
apiVersion: v1
data:
  accesskey: cm9vdHVzZXI=
  secretkey: cm9vdHBhc3MxMjM=
kind: Secret
metadata:
  name: artifacts-minio
  namespace: argo-events
EOF

kubectl apply -n argo-events -f secret-minio.yaml >> /root/background.log
