Maintenant que nous avons posé les bases, il est temps de nous attaquer à une architecture "complexe", qui enchaine les évènements.

Pour cela, nous allons créer l'application suivante : permettre à un collaborateur d'envoyer une url d'image, qui sera analysée par un OCR, et qui pilotera la mise à jour d'un serveur Web.

Nous allons donc enchainer les étapes suivantes :
WebHook -> conteneur de téléchargement et dépot dans S3 -> conteneur OCR et notification Redis -> mise à jour du serveur Web
(remplacer par un joli dessin)

Pour réduire la variance des résultats, nous nous limiterons à 5 images prétestées, qui donne d'excellents résultats au passage par l'OCR. Nous utiliserons les cinq émotions du film Vice et Versa de Pixar.

Vous êtes prêts ? C'est parti !

# Créer un hook html permettant à un utlisateur d'envoyer au système l'image de son choix

Commençons par créer le webhook

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

Exposons ce webhook à l'extérieur via un ingress :

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

# Créer un trigger permettant de télécharger le fichier et de le stocker dans Minio

Créons le trigger correspondant à ce webhook, qui va télécharger le fichier via un simple curl et le poster dans Minio via la CLI mc, sous un UUID générique. Ce conteneur a été précédement construit et déployé sur notre registry.

Vous pouvez en consulter le code ici :<br/>
`cat downloader/Dockerfile`{{execute HOST1}}<br/>
`cat downloader/run.sh`{{execute HOST1}}

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
                args: ["to be determined at runtime"]
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

`kubectl --namespace argo-events apply --filename url-downloader.yaml`{{execute HOST1}}

Attendons que le sensor soit disponible
`until kubectl --namespace argo-events get pods --selector sensor-name=url-downloader --field-selector=status.phase=Running | grep "url-downloader"; do : sleep 1 ; done && sleep 3 && echo "Sensor ready"`{{execute HOST1}}

En fonction de votre humeur du moment, vous pouvez envoyer la photo de votre choix au **downloader**

![Sadness](./assets/sadness.jpg)<br/>
Tristesse : `curl -X POST -H "Content-Type: application/json" -d '{"url":"https://static.wikia.nocookie.net/pixar/images/0/06/Io_Sadness_standard2.jpg/revision/latest/scale-to-width-down/200"}' http://controlplane/download-inside-out`{{execute HOST1}}

![Joy](./assets/joy.jpg)<br/>
Joie : `curl -X POST -H "Content-Type: application/json" -d '{"url":"https://static.wikia.nocookie.net/pixar/images/7/75/Io_Joy_standard2.jpg/revision/latest/scale-to-width-down/200"}' http://controlplane/download-inside-out`{{execute HOST1}}

![Fear](./assets/fear.jpg)<br/>
Peur : `curl -X POST -H "Content-Type: application/json" -d '{"url":"https://static.wikia.nocookie.net/pixar/images/7/79/Io_Fear_standard2.jpg/revision/latest/scale-to-width-down/200"}' http://controlplane/download-inside-out`{{execute HOST1}}

![Anger](./assets/anger.jpg)<br/>
Colère : `curl -X POST -H "Content-Type: application/json" -d '{"url":"https://static.wikia.nocookie.net/pixar/images/7/7a/Io_Anger_standard2.jpg/revision/latest/scale-to-width-down/200"}' http://controlplane/download-inside-out`{{execute HOST1}}

![Disgust](./assets/disgust.jpg)<br/>
Dégout : `curl -X POST -H "Content-Type: application/json" -d '{"url":"https://static.wikia.nocookie.net/pixar/images/9/98/Io_Disgust_standard2.jpg/revision/latest/scale-to-width-down/200"}' http://controlplane/download-inside-out`{{execute HOST1}}

Vérifions qu'un fichier a bien été téléchargé dans notre bucket :

`./mc ls minio/input`{{execute HOST1}}

# Créer un évènement sur réception dans un bucket Minio

Rien de très nouveau ici, on peut utiliser le même évènement que précédement.

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

# Créer un trigger permettant d'analyse une image en mode OCR et de publier le résultat dans Redis.

Là encore, nous allons utiliser un conteneur spéciliasé, en utilisant les logiciels opensource OpenCV (pour amplifier les contrastes des images) et Tesseract pour réaliser la reconnaissance de caractère.
En entrée, nous téléchargeons le fichier depuis minio, et en sortie nous postons le résultat dans Redis. En utilisant les services exposés par le cluster.

Le code est disponible ici :<br/>
`cat tesseract/Dockerfile`{{execute HOST1}}<br/>
`cat tesseract/analyse.py`{{execute HOST1}}

En lui même, le trigger n'est pas plus complexe que notre conteneur "echo-payload".

```sh
cat << EOF > trigger-minio-tesseract.yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: minio-tesseract
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

Pour tester que la chaine se complète, on peut utiliser la CLI redis dans un nouvel onglet :
`kubectl exec $(kubectl get pods -l app=redis -o jsonpath="{.items[0].metadata.name}") -- redis-cli subscribe tesseract`{{execute T2}}

Comme nous ne sommes pas forcément confiant, postons Peur : <br/>
`until kubectl --namespace argo-events get pods --selector sensor-name=minio-tesseract --field-selector=status.phase=Running | grep "minio-tesseract"; do : sleep 1 ; done && sleep 3 && curl -X POST -H "Content-Type: application/json" -d '{"url":"https://static.wikia.nocookie.net/pixar/images/7/79/Io_Fear_standard2.jpg/revision/latest/scale-to-width-down/200"}' http://controlplane/download-inside-out`{{execute T1}}

Le message FEAR devrait apparaitre dans Redis.

# Créer un évènement de souscription Redis

Nous sommes bientôt à la fin de la chaîne. Créons un évènement sur réception de message dans la file tesseract. Là encore, rien de stupéfiant par rapport à ce que nous avons déjà vu.

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

# La dernière marche : créer un trigger HTTP

Pour la dernière étape de notre architecture, nous allons utiliser un trigger HTTP. La syntaxe est des plus simple, le tout est de savoir ce que nous allons en faire.

Nous avons préalablement déployé un simple serveur web Flask, capable d'afficher les 5 émotions de Vice et Versa.
Ce serveur est disponible via un ingress [ici](https://[[HOST_SUBDOMAIN]]-80-[[KATACODA_HOST]].environments.katacoda.com/flask).
Par défaut, il affiche la tristesse, à nous de changer cela !

`cat flask/Dockerfile`{{execute HOST1}}<br/>
`cat flask/app.py`{{execute HOST1}}<br/>
`cat deployment-flask.yaml`{{execute HOST1}}

Ce serveur expose une url d'administration sur /admin, qui traite un json simple contenant l'émotion que l'on veut afficher, et change ainsi l'image par défaut. Nous allons lui envoyer l'émotion décryptée par Tesseract, et qui transite par Redis.

Le résultat devrait être visible en quelques secondes, le temps que tous les conteneurs et tous les triggers s'exécutent.

Déployons le trigger :

```sh
cat << EOF > redis-trigger.yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: redis-flask-sensor
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

`kubectl apply --namespace argo-events --filename redis-trigger.yaml`{{execute HOST1}}

et procédons au test final !
![Joy](./assets/joy.jpg)<br/>
Joie : `until kubectl --namespace argo-events get pods --selector sensor-name=redis-flask-sensor --field-selector=status.phase=Running | grep "redis-flask-sensor"; do : sleep 1 ; done && sleep 3 && curl -X POST -H "Content-Type: application/json" -d '{"url":"https://static.wikia.nocookie.net/pixar/images/7/75/Io_Joy_standard2.jpg/revision/latest/scale-to-width-down/200"}' http://controlplane/download-inside-out`{{execute HOST1}}
