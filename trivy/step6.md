# Scan de répertoire GitHub

Trivy permet également de scanner directement un repo Git avec l'argument `repo`. Il est important de préciser que ce scan n'analyse pas la configuration du repo en lui-même mais bien son contenu!

`trivy repo https://github.com/wescale/killercoda-trivy-git-step`{{execute}}

Vous pouvez gagner en granluarité avec les flags suivants:
- `--branch <nom_branche>`: pour scanner une branche spécifique
- `--commit <condensat_commit>`: pour scanner un commit précis
- `--tag <nom_tag>`: pour scanner un tag particulié

Vous pouvez essayer ces options sur le répertoire mis à disposition :

- Branche: `trivy repo --branch=wescale https://github.com/wescale/killercoda-trivy-git-step`{{execute}}
- Commit: `trivy repo --commit=84949f3f93a5f60f5d3534ab5d0d3172054a01b8 https://github.com/wescale/killercoda-trivy-git-step`{{execute}}
- Tag: `trivy repo --tag=1.0.0 https://github.com/wescale/killercoda-trivy-git-step`{{execute}}


>**NB**: Vous remarquerez qu'un fichier `main.tf`, contenant une faiblesse, comme vu dans une étape précédente, n'a pas été détecté. C'est parce que ce type de fichier n'est pas pris en compte par le scan de type `repo`. Voir la documentation associée ci-après.

## Documentations associées

- Documentation officielle `repo` : https://aquasecurity.github.io/trivy/v0.34/docs/vulnerability/scanning/git-repository/
- Détection par option Trivy : https://aquasecurity.github.io/trivy/v0.34/docs/vulnerability/detection/language/
