# Analyser de l'IaC

Avec l'argument `config` on demande à Trivy de scanner des fichiers IaC. Cela peut être un Dockerfile, un manifeste Kubernetes ou encore un fichier Terraform.

`trivy config ./iac`{{execute}}

>**NB**: On peut remarquer que les ressources sont triées par type (ici, Terraform et Dockerfile).

## Corrections

Si vous le souhaitez, vous pouvez essayer de corriger les faiblesses détectées par Trivy! Les solutions sont dans le répertoire `iac-ok`.

## Trivy vs TFSec

Mais TFSec, également développé par Aqua Security, est dédié à ca ! Quel est l'intérêt ?

Selon la documentation officielle, Trivy utilise TFSec de manière interne mais n'en supporte pas toutes les fonctionnalités. Aqua Security recommande de favoriser TFSec si vos besoins concernent uniquement le scan de fichiers Terraform. Si vos besoins sont plus étendus, a contrario, de favoriser Trivy.

## Documentations associées

- Documentation officielle : https://aquasecurity.github.io/trivy/v0.34/docs/misconfiguration/scanning/#type-detection
- Trivy vs TFSec : https://aquasecurity.github.io/trivy/v0.19.2/misconfiguration/comparison/tfsec/