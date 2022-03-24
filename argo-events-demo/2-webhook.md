Nous avons arbitrairement choisi de commencer par un évènement de type Webhook entrant.
Utilisons le CRD EventSource, qui va créer à la fois le controller ad-hoc, mais aussi le service associé.

```sh
cat << EOF > event-source.yaml
---
apiVersion: argoproj.io/v1alpha1
kind: EventSource
metadata:
  name: webhook
spec:
  service:
    ports:
      - port: 15000
        targetPort: 15000
  webhook:
    notify-me:
      port: "15000"
      endpoint: /notify-me
      method: POST
EOF
```{{execute}}

`kubectl --namespace argo-events apply --filename event-source.yaml`{{execute HOST1}}

Vous devriez voir apparaître votre premier Event. Depuis l'interface graphique, vous pouvez accéder au descripteur, ainsi qu'aux logs.

On peut confirmer à l'aide de la ligne de commande.

`kubectl --namespace argo-events get eventsources`{{execute HOST1}}

`kubectl --namespace argo-events get services`{{execute HOST1}}

`kubectl --namespace argo-events get pods`{{execute HOST1}}


Nous allons exposer notre Webhook via un ingress.

```sh
cat << EOF > ingress.yaml
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: default-ingress
  namespace : argo-events
spec:
  rules:
  - host: controlplane
    http:
      paths:
      - path: /notify-me
        backend:
          serviceName: webhook-eventsource-svc
          servicePort: 15000
EOF
```{{execute HOST1}}

`kubectl apply -f ingress.yaml`{{execute HOST1}}

Nous pouvons maintenant envoyer des évènements à notre hook (les commandes until permettent d'attendre que les évènements ArgoEvents soient prêts) :

`until kubectl -n argo-events get ingress --output=jsonpath='{.items[0].status.loadBalancer}' | grep "ingress"; \
do : sleep 1 ; done && sleep 3 && \
curl -X POST -H "Content-Type: application/json" -d '{"message":"My first message"}' http://controlplane/notify-me`{{execute HOST1}}


En consultant les logs de notre pod, on constate que l'évènement est reçu.
`kubectl logs -n argo-events $(kubectl --namespace argo-events get pods -l eventsource-name=webhook -o jsonpath="{.items[0].metadata.name}")`{{execute HOST1}}


Pour l'instant, cet évènement ne déclenche aucune réaction.
Pour cela, il nous faut le lier à un sensor (qui détecte ses occurences) et à un ou plusieurs triggers, les actions déclenchées sur réception.

```sh
cat << EOF > sensor.yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: webhook
spec:
  template:
    serviceAccountName: argo-events-sa
  dependencies:
  - name: echo-payload
    eventSourceName: webhook
    eventName: notify-me
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
                args: ["J'ai reçu un nouveau message:\n", ""]
              restartPolicy: Never
        parameters:
          - src:
              dependencyName: echo-payload
              dataKey: body
            dest: spec.containers.0.args.1
EOF
```{{execute HOST1}}

`kubectl --namespace argo-events apply --filename sensor.yaml`{{execute HOST1}}

Dans l'interface graphique, on constate que la chaine se complète.

Renvoyons un évènement à notre Webhook quand il est prêt :
`until kubectl --namespace argo-events get pods --selector sensor-name=webhook --field-selector=status.phase=Running | grep "webhook-sensor"; \
do : sleep 1 ; done && sleep 3 && \
curl -X POST -H "Content-Type: application/json" -d '{"message":"My first message"}' http://controlplane/notify-me`{{execute HOST1}}

On constate que de nouveux pods sont créés

`kubectl --namespace argo-events get pods`{{execute HOST1}}

Et qu'ils ont correctement réagi à nos évènements.

`kubectl --namespace argo-events logs --selector app=echo-payload`{{execute HOST1}}


Avant de poursuivre, faisons un peu de ménage
`kubectl --namespace argo-events delete pods --selector app=echo-payload`{{execute HOST1}}
