En ces temps de pandémies, le travail de modélisation d'accompagnement nous oblige à explorer des voient qu'on avait remis à plus tard. Je veux parler de HubNet.
Si netlogo est capable de générer un serveur sur un réseau local, passer a un usage d'internet n'était que de l'admin réseau et de la plomberie. Et effectivement! Voilà une solution de bricolage.

<img src="img/Capture d’écran de 2020-11-13 18-44-54.png"></img>

## No-ip

Le premier problème est que la plupart du temps, les fournisseurs d’accès a internet ne fournissent pas des IP fixes sur nos box à la maison (on parle de DNS dynamique). Ce qui permet à des services [No-ip](https://www.noip.com/remote-access/?utm_source=adwords&utm_medium=cpc&utm_campaign=international&gclid=Cj0KCQiAnb79BRDgARIsAOVbhRoAyw7thoeKJKZ7qaE99ohVntQI4bN5wMpa3gkFK6eUzXJ9EciyGxkaAiZnEALw_wcB) d’exister. C’est un service en ligne qui permet, une fois que vous avez procédé à la création d’un compte, de faire le lien entre une machine de votre réseau domestique et l’internet via un nom de domaine. Vous devez donc une fois le compte créé, créer votre premier nom de domaine.

Ensuite, vous pouvez installer un utilitaire qui permettra de faire le lien entre le domaine créé sur no-ip et votre machine (pour Linux un exemple avec [ubuntu](https://doc.ubuntu-fr.org/dns_dynamique)). Ce nom de domaine sera valable 30 jours.

## Lever le pare-feu

Après avoir installées et configurées les briques, il reste à lever le pare-feu de la box sur votre machine. Là c’est dans la configuration de votre box que ça se passe. De manière standard, les box, elles aussi, utilisent des IP locales dynamiques (généralement en fonction de qui s’est connecté en premier.). La première chose à faire est donc de définir un IP fixe pour votre ordinateur sur lequel Netlogo va fonctionner.

Avec cette IP-fixe sur votre réseau local, il faut mettre votre machine à l’extérieur du pare feu de votre box. Là c’est un peu risqué, votre machine sera accessible depuis l’extérieur du réseau (et c’est d’autant plus vrai que le DNS Dynamique va en faciliter l’accès). Pour le faire, il faut chercher la DMZ (Zone démilitarisée) et ajouter l’IP (fix) de votre machine dans cette zone. Ce qui rend votre machine accessible depuis l’extérieur de votre réseau.

## Netlogo et HubNet

Une fois que vous avez rendu accessible votre machine depuis l’extérieur, il vous reste à lancer le modèle Netlogo qui a l’extension HubNet (pour l’exemple nous avons essayé avec le modèle `bee smart` de la bibliothèque de modèle de netlogo).

Le modèle `bee smart` s’ouvre et lance une interface serveur. Une fois que c’est fait, vos complices aux 4 coins du monde peuvent de leur côté lancer l’exécutable HubnetClient . Celui-là demande de renseigner le nom du joueur (_user name_), et l’adresse du serveur. Si le nom du joueur est laissé à la discrétion de vos joueurs, l’adresse du serveur devra être le nom de domaine que no-ip vous a fourni.

Si tout se passe bien vous devriez pouvoir organiser des simulations participatives !

<img src="img/Capture d’écran de 2020-11-19 11-47-25.png"></img>
