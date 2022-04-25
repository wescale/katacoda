Un répertoire git nommé **demo** a été créé. Il nous servira pour installer, configurer et tester Pre-commit.

Placez-vous dans le dossier **demo** :
`cd demo`{{execute}}

Ajoutez la configuration **pre-commit** :
```
cat << EOF > ./.pre-commit-config.yaml
default_stages: [commit]
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.62.3
    hooks:
      - id: terraform_tfsec
EOF
```{{execute}}

Pour expliquer brièvement ce fichier de configuration :
- **default_stage** : Définit à quel moment Pre-commit doit se déclencher.
- **repos** : Liste des répertoires où Pre-commit doit récupérer le code de ses hooks.
- **repo** : L'URL du répertoire à cloner.
- **rev** : La révision ou le tag à cloner.
- **hooks** : La liste des hooks à exploiter dans le répertoire.
- **id** : Le hook à utiliser dans le répertoire.

Hookez **Pre-commit** à notre git :
`pre-commit install`{{execute}}
