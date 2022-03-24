https://[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com/

Créer une porte d'entrée html

```sh
cat << EOF > event-source.yaml
---
apiVersion: argoproj.io/v1alpha1
kind: EventSource
metadata:
  name: download-inside-out-file
spec:
  service:
    ports:
      - port: 15001
        targetPort: 15001
  webhook:
    download-inside-out-file:
      port: "15001"
      endpoint: /download-inside-out
      method: POST
EOF
```{{execute}}

`kubectl --namespace argo-events apply --filename event-source.yaml`{{execute HOST1}}

```sh
cat << EOF > ingress-inside-out-download.yaml
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: inside-out-download-ingress
  namespace : argo-events
spec:
  rules:
  - host: controlplane
    http:
      paths:
      - path: /download-inside-out
        backend:
          serviceName: download-inside-out-file-eventsource-svc
          servicePort: 15001
EOF
```{{execute HOST1}}

`kubectl apply -f ingress-inside-out-download.yaml`{{execute HOST1}}

Déclencher le téléchargement d'une image dans minio

```sh
cat << EOF > url-downloader.yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: url-downloader
spec:
  template:
    serviceAccountName: argo-events-sa
  dependencies:
  - name: url-downloader
    eventSourceName: download-inside-out-file
    eventName: download-inside-out-file
  triggers:
  - template:
      name: url-downloader
      k8s:
        group: ""
        version: v1
        resource: pods
        operation: create
        source:
          resource:
            apiVersion: v1
            kind: Pod
            metadata:
              generateName: url-downloader-
              labels:
                app: url-downloader
            spec:
              containers:
              - name: url-downloader
                image: rg.fr-par.scw.cloud/katacoda/url-downloader:1.0.16
                args: ["tbd at runtime"]
                command: ["sh", "/run.sh"]
                env:
                 - name: MINIO_ACCESS_KEY
                   valueFrom:
                     secretKeyRef:
                       name: artifacts-minio
                       key: accesskey
                 - name: MINIO_SECRET_KEY
                   valueFrom:
                     secretKeyRef:
                       name: artifacts-minio
                       key: secretkey
                 - name: MINIO_URL
                   value: http://minio-svc.default:9000
              restartPolicy: Never
        parameters:
          - src:
              dependencyName: url-downloader
              dataKey: body.url
            dest: spec.containers.0.args.0
EOF
```{{execute HOST1}}

`kubectl --namespace argo-events apply \
    --filename url-downloader.yaml`{{execute HOST1}}

`curl -X POST \
    -H "Content-Type: application/json" \
    -d '{"url":"https://static.wikia.nocookie.net/pixar/images/0/06/Io_Sadness_standard2.jpg/revision/latest/scale-to-width-down/200"}' \
    http://controlplane/download-inside-out`{{execute HOST1}}

`./mc ls minio/input`{{execute HOST1}}

Créer un évènement minio
```sh
cat << EOF > event-minio.yaml
---
apiVersion: argoproj.io/v1alpha1
kind: EventSource
metadata:
  name: minio
spec:
  minio:
    image:
      bucket:
        name: input
      endpoint: minio-svc.default:9000
      events:
        - s3:ObjectCreated:Put
        - s3:ObjectRemoved:Delete
      insecure: true
      accessKey:
        key: accesskey
        name: artifacts-minio
      secretKey:
        key: secretkey
        name: artifacts-minio
EOF
```{{execute HOST1}}

`kubectl apply -n argo-events -f event-minio.yaml`{{execute HOST1}}

Analyser l'image et émettre un pubish Redis

```sh
cat << EOF > trigger-minio-tesseract.yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: minio
spec:
  template:
    serviceAccountName: argo-events-sa
  dependencies:
    - name: tesseract
      eventSourceName: minio
      eventName: image
  triggers:
  - template:
      name: tesseract
      k8s:
        group: ""
        version: v1
        resource: pods
        operation: create
        source:
          resource:
            apiVersion: v1
            kind: Pod
            metadata:
              generateName: tesseract-
              labels:
                app: tesseract
            spec:
              containers:
              - name: tesseract
                image: rg.fr-par.scw.cloud/katacoda/tesseract:1.0.5
                command: ["python3", "analyse.py"]
                args: [""]
                env:
                 - name: MINIO_ACCESS_KEY
                   valueFrom:
                     secretKeyRef:
                       name: artifacts-minio
                       key: accesskey
                 - name: MINIO_SECRET_KEY
                   valueFrom:
                     secretKeyRef:
                       name: artifacts-minio
                       key: secretkey
                 - name: MINIO_URL
                   value: minio-svc.default:9000
                 - name: REDIS_HOST
                   value: redis.default.svc
              restartPolicy: Never
        parameters:
          - src:
              dependencyName: tesseract
              dataKey: notification.0.s3
            dest: spec.containers.0.args.0
EOF
```{{execute HOST1}}

`kubectl apply -n argo-events -f trigger-minio-tesseract.yaml`{{execute HOST1}}

Créer un évènement Redis

```sh
cat << EOF > redis-tesseract.yaml
apiVersion: argoproj.io/v1alpha1
kind: EventSource
metadata:
  name: redis
spec:
  redis:
    redis-tesseract:
      hostAddress: redis.default.svc:6379
      db: 0
      # Channels to subscribe to listen events.
      channels:
        - tesseract
EOF
```{{execute HOST1}}

`kubectl apply --namespace argo-events --filename redis-tesseract.yaml`{{execute HOST1}}

Déclencher un appel http

```sh
cat << EOF > redis-trigger.yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: redis-sensor
spec:
  template:
    container:
      env:
        - name: DEBUG_LOG
          value: "true"
  dependencies:
    - name: redis-tesseract
      eventSourceName: redis
      eventName: redis-tesseract
  triggers:
  - template:
      name: change-background
      http:
        url: http://flask-service.default.svc.cluster.local:5000/flask/admin
        payload:
          - src:
              dependencyName: redis-tesseract
              dataKey: body
            dest: emotion
        method: POST
EOF
```{{execute HOST1}}

`kubectl apply --namespace argo-events --filename slack-trigger.yaml`{{execute HOST1}}
