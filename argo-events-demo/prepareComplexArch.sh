#/bin/bash
docker pull rg.fr-par.scw.cloud/katacoda/flask-argo:1.0.15 >> /root/prepare.log
docker pull rg.fr-par.scw.cloud/katacoda/url-downloader:1.0.16 >> /root/prepare.log
docker pull rg.fr-par.scw.cloud/katacoda/tesseract:1.0.5 >> /root/prepare.log

kubectl apply -f deployment-flask.yaml >> /root/prepare.log

kubectl exec $(kubectl get pods -l app=redis -o jsonpath="{.items[0].metadata.name}") -- redis-cli publish tesseract "C'est le premier message du sujet Tesseract" >> /root/prepare.log
