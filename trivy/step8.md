# SBOM

Trivy est aussi capable de prendre un SBOM en tant qu'input avec l'argument `sbom`.

Nous expliquons en détail l'intérêt et le fonctionnement d'un SCA dans cet article: https://blog.wescale.fr/securisation-du-cycle-de-developpement-applicatif-analyse-des-dependances

**SCA (Software Composition Analysis)**: en français analyse de la composition du logiciel, sont des outils permettant de découvrir les vulnérabilités connues associées aux composants/librairies tierces d’un projet. Cela inclut bien entendu les librairies open-sources, mais aussi les composants développés en interne si une base de données de vulnérabilités est maintenue.
**SBoM (Software Build of Material)**: Liste des dépendances d'une application.

## Analyser un SBOM python

Générez le SBOM d'un fichier de dépendance Python à l'aide de CycloneDX :

`python3 -m cyclonedx_py -r --format json -i "sbom/requirements.txt" -o sbom/sbom.json`{{execute}}

Analysez le SBOM à l'aide de Trivy :

`trivy sbom ./sbom/sbom.json`{{execute}}

Nous aurions pu obtenir le même résultat directement avec `fs` par exemple:

`trivy fs ./sbom/`{{execute}}

>**NB**: L'intérêt du passage par SBOM dépend de votre contexte et de votre intégration avec d'autres outils. On peut notamment citer **[Dependency-Track](https://dependencytrack.org/)** qui utilise des SBOMs comme matière première.

## Documentations associées

- Répertoire GitHub de CycloneDX : https://github.com/CycloneDX/cyclonedx-python
- Documentation Trivy liée au SBOM : https://aquasecurity.github.io/trivy/v0.34/docs/references/cli/sbom/