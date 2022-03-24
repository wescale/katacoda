Découvrons un troisième type d'évènement, le dépôt d'un fichier dans un ObjectStorage.
Pour cela, nous avons installé en arrière plan le projet open source Minio.

Pour des besoin de démonstration, nous allons exposer le service Minio directement sur le cluster, ceci afin de bénéficier simplement de la commande line. En revanche, pour le reste des opérations, nous passerons par le service Minio exposé en interne.

On récupère le nom du pod et on réalise un port forward.
`kubectl port-forward $(kubectl get pods --namespace default -l "release=minio" -o jsonpath="{.items[0].metadata.name}") 9000 &`{{execute HOST1}}

On configure ensuite la CLI afin que notre stockage local soit identifié par l'alias **minio**. Pour cela, on utilise le secret créer lors de l'installation de Minio.
`./mc config host \
add minio http://localhost:9000 \
$(kubectl get secret --namespace default minio -o jsonpath="{.data.rootUser}" | base64 --decode) \
$(kubectl get secret --namespace default minio -o jsonpath="{.data.rootPassword}" | base64 --decode)`{{execute HOST1}}

Ces actions préliminaires ayant été réalisées, attaquons nous maintenant à l'évènement correspondant à la création d'un fichier dans le bucket input :

```sh
cat << EOF > event-minio.yaml
---
apiVersion: argoproj.io/v1alpha1
kind: EventSource
metadata:
  name: minio
spec:
  minio:
    add-file-as-input:
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


Ajoutons maintenant un simple conteneur d'écho, afin de voir les résultats produits.

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
      eventName: add-file-as-input
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

La chaine étant complète, déposons un fichier dans notre bucket :

`touch start.txt`{{execute HOST1}}

`until kubectl --namespace argo-events get pods --selector sensor-name=minio --field-selector=status.phase=Running | grep "minio"; \
do : sleep 1 ; done && sleep 3 && \
./mc cp start.txt minio/input`{{execute HOST1}}

`kubectl --namespace argo-events logs --selector app=echo-payload`{{execute HOST1}}

On peut confirmer que le fichier est réellement présent en utilisant la CLI :
`./mc ls minio/input`{{execute HOST1}}

Faisons une dernière fois le ménage
`kubectl --namespace argo-events delete pods --selector app=echo-payload`{{execute HOST1}}
