# Aller plus loin

Il y a plusieurs éléments que nous n'avons pas présenté qui sont très intéressants à creuser :

## Autres Scanners

Avec Trivy vous pouvez également scanner un cluster K8S ou vos environnements Cloud!

- Scan K8S : https://aquasecurity.github.io/trivy/v0.34/tutorials/kubernetes/cluster-scanning/
- Scan Cloud AWS : https://aquasecurity.github.io/trivy/v0.34/docs/cloud/aws/scanning/

## Intégration CI

Il est aussi important de noter que pour obtenir la meilleure plus-value de Trivy, il est intéressant de l'intégrer à votre CI !

- Intégration à la CI : https://aquasecurity.github.io/trivy/v0.34/tutorials/integrations/

## Cosign

Avec l'aide de Cosign vous pouvez signer un fichier de scan Trivy et l'ajouter à vos images!

- Répertoire GitHub de Cosign : https://github.com/sigstore/cosign/
- Documentation Trivy liée à Cosign : https://aquasecurity.github.io/trivy/v0.34/docs/attestation/vuln/