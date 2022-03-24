`export POD_NAME=$(kubectl get pods --namespace default -l "release=minio" -o jsonpath="{.items[0].metadata.name}")`{{execute HOST1}}

`kubectl port-forward $POD_NAME 9000 --namespace default &`{{execute HOST1}}

`./mc config host add minio http://localhost:9000 $(kubectl get secret --namespace default minio -o jsonpath="{.data.rootUser}" | base64 --decode) $(kubectl get secret --namespace default minio -o jsonpath="{.data.rootPassword}" | base64 --decode)`{{execute HOST1}}

```sh
cat << EOF > event-minio.yaml
---
apiVersion: argoproj.io/v1alpha1
kind: EventSource
metadata:
  name: minio
spec:
  minio:
    example:
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

```sh
cat << EOF > trigger-minio.yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: minio
spec:
  template:
    serviceAccountName: argo-events-sa
  dependencies:
    - name: echo-payload
      eventSourceName: minio
      eventName: example
  triggers:
  - template:
      name: echo-payload
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
              generateName: echo-payload-
              labels:
                app: echo-payload
            spec:
              containers:
              - name: alpine
                image: alpine
                command: ["echo"]
                args: ["J'ai reçu un nouveau fichier:\n", ""]
              restartPolicy: Never
        # The container args from the workflow are overridden by the s3 notification key
        parameters:
          - src:
              dependencyName: echo-payload
              dataKey: notification.0.s3
            dest: spec.containers.0.args.1
EOF
```{{execute HOST1}}

`kubectl apply -n argo-events -f trigger-minio.yaml`{{execute HOST1}}


`kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/sensors/minio.yaml`{{execute HOST1}}

`touch start.txt`{{execute HOST1}}

`./mc cp start.txt minio/input`{{execute HOST1}}

`kubectl --namespace argo-events logs \
    --selector app=echo-payload`{{execute HOST1}}
