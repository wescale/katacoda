Il existe plusieurs façons d'installer **Trivy** : gestionnaire de paquets, brew, MacPorts, Docker, les binaires, etc.
Pour cette démo nous l'installerons par un script fourni par Aqua Security.

# Installer Trivy via un gestionnaire de paquet

Installez Trivy :
`curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.34.0`{{execute}}

Vérifiez que Trivy est bien installé :

`trivy --version`{{execute}}

Vous devriez obtenir :
```
$ trivy --version
Version: 0.34.0
```

Vous pouvez obtenir un aperçu des possibilités de Trivy avec le drapeau `--help` :

`trivy --help`{{execute}}
