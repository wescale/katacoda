# Scan de système de fichiers

Vous pouvez aussi scanner directement un système de fichier local avec l'argument `fs` :

`trivy fs ./fs-scan`{{execute}}

## Rootfs

Il existe aussi l'argument `rootfs` qui est relativement similaire.

Vous pouvez trouver les différences entre `fs` et `rootfs` ici: https://aquasecurity.github.io/trivy/v0.34/docs/vulnerability/detection/language/

## Documentations associées

- Documentation officielle `fs` : https://aquasecurity.github.io/trivy/v0.34/docs/vulnerability/scanning/filesystem/
- Documentation officielle `rootfs` : https://aquasecurity.github.io/trivy/v0.34/docs/vulnerability/scanning/rootfs/
