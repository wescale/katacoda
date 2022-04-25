[**Pre-commit**](https://pre-commit.com) est un outil qui va déclencher des scripts lors de certains stages Git. Si le code retour du script est en erreur, Git empêchera l'action de se réaliser.

Ici, il nous servira à déclencher un scan TFSec lors du commit.

Il existe plusieurs façons d'installer Pre-commit (brew, conda, pip, etc.). Pour ce tutoriel nous allons utiliser **pip**.

Installez pre-commit :

`pip install pre-commit`{{execute}}
