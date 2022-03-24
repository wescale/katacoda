#!/bin/bash

show_progress()
{
  echo "Il reste 10 étapes à paramétrer avant de démarrer ce tuto"
  echo -n " "

  echo -n "[Etape 1/10] K8S est en train de chauffer"
  local -r pid="${1}"
  local -r delay='0.75'
  local spinstr='\|/-'
  local temp
  while true; do
    kubectl version &> /dev/null
    if [[ "$?" -ne 0 ]]; then
      temp="${spinstr#?}"
      printf " [%c]  " "${spinstr}"
      spinstr=${temp}${spinstr%"${temp}"}
      sleep "${delay}"
      printf "\b\b\b\b\b\b"
    else
      break
    fi
  done
  printf "    \b\b\b\b"
  echo ""
  clear && echo -n "[Etape 2/10] Les noeuds rejoignent le cluster K8S"
  echo -n " "

  #docker pull alpine
  #docker pull redis
  #docker pull quay.io/argoproj/argocli:latest

  kubectl wait --for=condition=Ready nodes --all --timeout=120s
  ssh -q $(kubectl get node --selector='!node-role.kubernetes.io/master' -o jsonpath={.items[*].status.addresses[?\(@.type==\"InternalIP\"\)].address}) 'mkdir -p /root/.kube'
  scp -q /root/.kube/config $(kubectl get node --selector='!node-role.kubernetes.io/master' -o jsonpath={.items[*].status.addresses[?\(@.type==\"InternalIP\"\)].address}):/root/.kube/config
  clear && echo -n "[Etape 3/10] Création du namespace dédié au tuto\n\n"

  kubectl create namespace argo-events

  clear && echo -n "[Etape 4/10] Déploiement des CRDs de l'ingress Nginx"
  echo -n " "

  kubectl create namespace ingress-nginx

  helm upgrade --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress-nginx --version='<4'

  clear && echo -n "[Etape 5/10] Déploiement des compte de service Argo"
  echo -n " "
  wget -q https://raw.githubusercontent.com/argoproj/argo-workflows/master/manifests/base/argo-server/argo-server-sa.yaml

  kubectl apply -f argo-server-sa.yaml

  clear && echo -n "[Etape 6/10] Déploiement de l'interface graphique ArgoServer"
  echo -n " "

  kubectl apply -f deployment.yaml

  clear && echo -n "[Etape 7/10] Déploiement des services Argo"
  echo -n " "

  wget -q https://raw.githubusercontent.com/argoproj/argo-workflows/master/manifests/base/argo-server/argo-server-service.yaml
  kubectl apply -f argo-server-service.yaml

  clear && echo -n "[Etape 8/10] Installation de ArgoWorkflow (suppression des messages d'erreur de l'UI)"
  kubectl apply -n argo -f https://raw.githubusercontent.com/argoproj/argo-workflows/master/manifests/install.yaml

  clear && echo -n "[Etape 9/10] En attente de l'ingress Nginx"
  echo -n " "

  kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

  clear && echo -n "[Etape 10/10] Creation d'un ingress pour ArgoServer"
  echo -n " "

  kubectl apply -f deployment-flask.yaml

  kubectl apply -f ingress.yaml

  until kubectl get ingress --output=jsonpath='{.items[0].status.loadBalancer}' | grep "ingress"; do : sleep 1 ; done

  sleep 5

  echo -n "Paramétrage effectué, paré au lancement"
  echo -n ""
}

show_progress
