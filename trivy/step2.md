# Analyser une image de conteneur

L'une des premières utilité de Trivy est évidemment sa capacité à analyser une image de conteneur.
Analysons la dernière image de conteneur Nginx :

`trivy image nginx:latest`{{execute}}

Par défaut il y a 4 colonnes :
- **Library**: Le nom de la librairie détectée comme vulnérable.
- **Vulnerability**: La vulnérabilité (**CVE***) associée à la librairie.
- **Severity**: La niveau de sévérité (**CVSS***) associé à la vulnérabilité.
- **Installed Version**: La version de la librairie détectée comme vulnérable.
- **Fixed Version**: La version de la librairie n'étant plus vulnérable/patchée.
- **Title**: Cette partie contient un très court extrait explicitant la vulnérabilité mais surtout un lien vers la "**Aqua vulnerability database**", une base de donnée de vulnérabilités d'Aqua Security. Elle contient tout ce qui a à savoir sur la vulnérabilité (nom, description, versions concernées, résolutions, etc.).

***CVE (Common Vulnerabilities and Exposures)**: Vulnérabilité spécifique d'un produit ou d'un système, et non les failles sous-jacentes.

***CVSS (Common Vulnerability Scoring System)**: est un système normalisé d'évaluation de la criticité des vulnérabilités (CVE) basé sur des critères objectifs et mesurables.

Maintenant que nous comprenons mieux le résultat il est important de noter que même une image Nginx latest contient des paquets avec des vulnérabilités connues, même des critiques. D'où l'importance de sécuriser ses images et l'écosystème technique dans lequel elles évoluent.

## Ignorer les vulnérabilités

### Par sévérité

Il faut reconnaître que le résultat n'est pas forcément lisible tel quel et que les vulnérabilités faibles ne sont pas la priorité. On peut évidemment filtrer.

Avec le drapeau `--severity` on peut filtrer les sévérités selon leur niveau (UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL).

`trivy image nginx:latest --severity HIGH,CRITICAL`{{execute}}

### Incorrigibles

Avec le drapeau `--ignore-unfixed` : on peut ignorer les vulnérabilités qui n'ont pas de solutions connues. Evidemment une vulnérabilité critique, même sans solution, n'est pas à ignorer, mais ce drapeau a le mérite d'atténuer le bruit.

`trivy image nginx:latest --ignore-unfixed`{{execute}}

### Par type

Avec le drapeau `--vuln-type os` vous pouvez sélectionner un type de vulnérabilité en particulier. Soit os ou librairie.

OS : `trivy image nginx:latest --vuln-type os`{{execute}}

Librairie : `trivy image nginx:latest --vuln-type library`{{execute}}

### Par CVE

A l'aide du fichier `.trivyignore` vous pouvez ignorer certaines vulnérabilités en les énumérant dans ce fichier.

Si vous scannez l'image `nginx:1.21.6-alpine`, vous devriez obtenir plusieurs vulnérabilités critiques.

`trivy image --severity CRITICAL nginx:1.21.6-alpine`{{execute}}

Ajoutez le fichier `.trivyignore` avec la configuration ci-dessous.

```plain
cat <<EOF> .trivyignore
CVE-2022-32207
CVE-2022-42915
CVE-2022-32207
CVE-2022-42915
CVE-2022-1586
CVE-2022-1587
CVE-2022-37434
EOF
```{{execute}}

Scannez de nouveau, les CVE ont été ignorées.

`trivy image --severity CRITICAL nginx:1.21.6-alpine`{{execute}}

>**NB**: Pour spécifier un fichier/chemin autre que `.trivyignore` il faut utiliser le drapeau `--ignorefile <file_path>`
