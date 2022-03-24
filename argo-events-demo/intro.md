# ArgoEvents, un outil pour piloter votre achitecture orientée évènements.

Argo Events est un framework d'automatisation de workflow qui tourne au sein de Kubernetes. Il permet de déclencher des réactions (Triggers) à des évènements (Events), via un certain nombre de conditions (portées par des Sensors).

C’est un premier pas vers une implémentation de référence d’une norme en cours d’écriture, Cloud Events, qui vise à unifier les données et métadonnées associées aux événements dans le monde du Cloud Native.

Comme l’ensemble de la suite Argo, ce framework est open-source et indépendant des autres produits de la suite (Argo CD, Workflow et Rollout), bien qu’il y soit très bien intégré.

## Description

Dans ce tutoriel, nous explorerons les mécanismes internes de ArgoEvents à travers quelques exemples simples et nous terminerons en construisant une architecture "complexe"

## Sommaire

- Installer ArgoEvents
- Notre premier évènement, le Webhook.
- Un évènement de type message avec Redis
- Se brancher sur un bucket S3
- Bâtir une architecture complexe
