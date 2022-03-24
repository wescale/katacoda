Après ce premier évènement, nous allons compléter notre panoplie, avec deux types d'évènements représentatifs.

Commençons par un évènement de type Publish / Subscribe.
Pour des questions de simplicité d'installation, notre choix se porte sur l'évènement Pub/Sub au sein de Redis (mais d'autres types sont disponibles : NATS, Kafka, Pulsar...)

Commençons par installer Redis, en tant que service, à partir d'un yaml simple :
`cat redis.yaml`{{execute HOST1}}

`kubectl apply --filename redis.yaml`{{execute HOST1}}

Comme pour le webhook, nous commencerons par l'évènement à capter.

```sh
cat << EOF > redis-event.yaml
apiVersion: argoproj.io/v1alpha1
kind: EventSource
metadata:
  name: redis
spec:
  redis:
    redis-notify:
      hostAddress: redis.default.svc:6379
      db: 0
      # Channels to subscribe to listen events.
      channels:
        - NOTIFY
EOF
```{{execute HOST1}}

`kubectl apply --namespace argo-events --filename redis-event.yaml`{{execute HOST1}}


Si vous souhaitez poursuivre cette démonstration, vous aurez besoin d'un compte Slack et d'insérer votre Slack Token dans un secret appelé slack-secret.

A defaut, nous vous proposons une version alternative qui réutilise le conteneur "echo-payload"

## Version Slack
Commençons par créer le secret :
```sh
cat << EOF > secret.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: slack-secret
data:
  token: XXXX-insert-token-here-XXXX
EOF
```{{execute HOST1}}

`kubectl apply -n argo-events -f secret.yaml`{{execute HOST1}}

Puis créons le trigger
```sh
cat << EOF > slack-trigger.yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: redis-sensor
spec:
  dependencies:
    - name: redis-notification
      eventSourceName: redis
      eventName: redis-notify
  triggers:
    - template:
        name: slack-trigger
        slack:
          channel: katacoda-demo
          slackToken:
            key: token
            name: slack-secret
      parameters:
        - src:
            dependencyName: redis-notification
            dataKey: body
          dest: slack.message
EOF
```{{execute HOST1}}

`kubectl apply --namespace argo-events --filename slack-trigger.yaml`{{execute HOST1}}

## Version Echo Payload

```sh
cat << EOF > echo-trigger.yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: redis-sensor
spec:
  dependencies:
    - name: redis-notification
      eventSourceName: redis
      eventName: redis-notify
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
                args: ["J'ai reçu un nouveau message dans Redis:\n", ""]
              restartPolicy: Never
        parameters:
          - src:
              dependencyName: redis-notification
              dataKey: body
            dest: spec.containers.0.args.1
EOF
```{{execute HOST1}}

`kubectl apply --namespace argo-events --filename echo-trigger.yaml`{{execute HOST1}}

## Tronc commun

Envoyons un message dans un topic Redis.

`until kubectl --namespace argo-events get pods --selector sensor-name=redis-sensor --field-selector=status.phase=Running | grep "redis-sensor"; \
do : sleep 1 ; done && sleep 3 && \
kubectl exec $(kubectl get pods -l app=redis -o jsonpath="{.items[0].metadata.name}") -- redis-cli publish NOTIFY "Test de Julien"`{{execute HOST1}}

Si vous aide en mode Slack, vous devriez voir apparaitre un message dans le topic katacoda-demo.

Sinon, allez voir les logs du conteneur echo :
`kubectl --namespace argo-events logs --selector app=echo-payload`{{execute HOST1}}

Avant de poursuivre, faisons un peu de ménage
`kubectl --namespace argo-events delete pods --selector app=echo-payload`{{execute HOST1}}
