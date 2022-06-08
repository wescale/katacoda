# Corriger le problème

Ouvrez dans un nouvel onglet le lien de la documentation TFSec :
 <a href="https://aquasecurity.github.io/tfsec/v1.0.2/checks/aws/kms/auto-rotate-keys/" target="_blank">Documentation TFSec - aws/kms/auto-rotate-keys</a>

Vous y obtenez de nombreuses informations, dont le moyen de corriger le problème détecté :
 ![Secure Example]](./assets/secure-example.png)

> **NB** : La documentation nous informe que la bonne pratique de sécurité est d'activer la rotation automatique des clés.

Corrigez le problème comme indiqué dans la documentation :
`sed -i 's/false/true/' main.tf`{{execute}}

Regardez le contenu du fichier :
`cat main.tf`{{execute}}

Vérifiez que plus aucun problème n'est détecté :
`tfsec .`{{execute}}
