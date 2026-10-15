# Terra Sana ASBL — site vitrine et hub d’applications

Ce dépôt contient le site web de Terra Sana ASBL et son espace d’administration. Le site présente l’association, ses activités et les projets numériques développés pour elle.

> **Pour commencer rapidement :** installez les prérequis, clonez le dépôt, préparez MySQL, puis lancez le backend et le frontend dans deux terminaux distincts. Ce guide vise principalement Windows 10/11.

## Sommaire

- [Fonctionnalités](#fonctionnalités)
- [Technologies et versions](#technologies-et-versions)
- [Prérequis](#prérequis)
- [Installation pas à pas](#installation-pas-à-pas)
- [Configuration locale](#configuration-locale)
- [Démarrer le projet](#démarrer-le-projet)
- [Tester et compiler](#tester-et-compiler)
- [Organisation du dépôt](#organisation-du-dépôt)
- [Sécurité](#sécurité)
- [Problèmes courants](#problèmes-courants)

## Fonctionnalités

Le périmètre décrit dans le rapport technique et dans le dépôt comprend notamment :

- **Site public** : accueil, présentation de l’association, blog, contact, bénévolat et stages, sponsors, aide/FAQ et pages d’information.
- **Hub de projets** : liste des projets, recherche, filtre par catégorie, détail et ouverture d’une application.
- **Espace administrateur** : gestion des projets et articles; consultation, filtrage, réponse et suppression des messages; suivi des messages lus/non lus; activation ou désactivation d’un projet; changement du mot de passe.
- **Bénévoles et événements** : inscriptions, liste d’attente et avis sont également présents dans les évolutions récentes du dépôt.
- **Fonctions complémentaires décrites dans le dépôt** : authentification avec jetons JWT, envoi de courriels et génération de documents PDF pour certains parcours.

Les écrans et fonctionnalités peuvent évoluer. Pour les détails des parcours et des règles métier, consulter le [cahier de recette](docs/Cahier_de_recette_Terra_Sana.docx) et le code de la branche `main`.

## Technologies et versions

Les valeurs ci-dessous proviennent des fichiers de configuration de la branche `main` consultés le 12 octobre 2026. En cas d’écart, `backend/pom.xml` et `frontend/package.json` font foi.

| Composant | Technologie / version déclarée |
|---|---|
| Backend | Java 21, Spring Boot 3.5.13 |
| Build backend | Maven Wrapper inclus (`backend/mvnw.cmd`) |
| Base de données | MySQL; base locale `terre_sana` |
| Frontend | React 19.2.4, React Router 7.14.0, Create React App (`react-scripts` 5.0.1) |
| Outils frontend | Node.js LTS et npm |
| Authentification | Spring Security et JWT (`jjwt` 0.11.5) |
| Environnement Windows décrit dans le rapport | WampServer 3.3.7, MySQL 9.1.0, phpMyAdmin 5.2.1 |

Le rapport technique fourni mentionne React 18.2.0. Le `package.json` actuel déclare React 19.2.4 : utilisez les versions définies par les fichiers du dépôt, pas celles de l’ancien rapport.

## Prérequis

Installez les outils suivants avant de commencer :

1. **JDK 21** pour compiler et lancer le backend.
2. **Git** pour récupérer le code.
3. **Node.js LTS** avec npm pour le frontend.
4. **MySQL Server**. Sur Windows, le rapport décrit une installation avec **WampServer** et phpMyAdmin.
5. **Visual Studio Code** ou un autre éditeur, facultatif mais pratique.

Maven n’a pas besoin d’être installé séparément : le dépôt contient le Maven Wrapper. Au premier lancement, le wrapper télécharge la version nécessaire de Maven.

### Téléchargements officiels

- [JDK 21 — Microsoft Build of OpenJDK](https://learn.microsoft.com/java/openjdk/download)
- [Git pour Windows](https://git-scm.com/download/win)
- [Node.js — version LTS](https://nodejs.org/en/download)
- [WampServer](https://www.wampserver.com/en/)
- [MySQL Installer](https://dev.mysql.com/downloads/installer/)
- [Visual Studio Code](https://code.visualstudio.com/Download)

Après l’installation, ouvrez PowerShell et vérifiez les commandes :

```powershell
java -version
node --version
npm --version
git --version
```

Java doit afficher une version 21. Node.js et npm doivent tous deux répondre à leur commande.

## Installation pas à pas

### 1. Cloner le dépôt

Dans PowerShell, placez-vous dans le dossier où vous souhaitez installer le projet, puis lancez :

```powershell
git clone https://github.com/sidanne/terra-sana-website.git
cd terra-sana-website
```

Vous pouvez ensuite ouvrir le dossier dans Visual Studio Code :

```powershell
code .
```

Si la commande `code` n’est pas disponible, ouvrez Visual Studio Code et choisissez **Fichier → Ouvrir un dossier**, puis sélectionnez le dossier `terra-sana-website`.

### 2. Démarrer MySQL

Si vous utilisez WampServer :

1. Lancez WampServer depuis le menu Démarrer.
2. Attendez que son icône devienne verte.
3. Ouvrez [phpMyAdmin](http://localhost/phpmyadmin).

Vous pouvez utiliser MySQL Server sans WampServer; dans ce cas, démarrez le service MySQL et utilisez votre outil de gestion préféré.

### 3. Créer la base de données

Dans phpMyAdmin, choisissez **SQL** et exécutez :

```sql
CREATE DATABASE terre_sana
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;
```

Le nom `terre_sana` correspond à celui indiqué dans la configuration du projet. Créez un utilisateur MySQL local réservé à cette application et notez son mot de passe dans un endroit sécurisé.

### 4. Configurer le backend

Le fichier principal de configuration se trouve ici :

```text
backend/src/main/resources/application.properties
```

Configurez la connexion MySQL locale. Exemple de propriétés à adapter :

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/terre_sana
spring.datasource.username=root
spring.datasource.password=
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.database-platform=org.hibernate.dialect.MySQL8Dialect
server.port=8080
spring.mail.host=smtp.gmail.com
spring.mail.port=587
spring.mail.username=your-email@gmail.com
spring.mail.password=your-gmail-app-password
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true

logging.file.name=backend.log
logging.level.org.springframework.mail=DEBUG
logging.level.com.terresana.backend=DEBUG


# Secrets JWT fixes (RG-24) : distincts admin / benevole, et stables entre redemarrages
# (sinon tous les tokens deviennent invalides a chaque redemarrage du backend)
# Generer par exemple avec : python -c "import secrets,base64; print(base64.b64encode(secrets.token_bytes(32)).decode())"
jwt.admin.secret=
jwt.volunteer.secret=
```

Dans le même terminal PowerShell qui servira à démarrer le backend, définissez vos valeurs locales :

```powershell
$env:DB_URL = "jdbc:mysql://localhost:3306/terre_sana"
$env:DB_USERNAME = "votre_utilisateur_mysql"
$env:DB_PASSWORD = "votre_mot_de_passe_mysql"
```

Les variables doivent correspondre aux noms utilisés dans `application.properties`. Si la configuration du dépôt n’utilise pas encore ces variables, adaptez-la localement sans publier vos valeurs privées.

Si vous souhaitez utiliser l’envoi de courriels, renseignez aussi les paramètres SMTP requis par la configuration du backend, notamment le compte et son secret d’application. Ces valeurs doivent rester dans l’environnement local, jamais dans Git.

> `spring.jpa.hibernate.ddl-auto=update` est indiqué ici pour le développement local décrit dans le rapport. Avant un déploiement réel, validez la stratégie de migration de la base et les paramètres de production.

### 5. Installer les dépendances frontend

Ouvrez un deuxième terminal PowerShell à la racine du dépôt :

```powershell
cd frontend
npm ci
```

`npm ci` utilise le fichier `package-lock.json` pour installer les dépendances du projet. Si ce fichier est absent ou volontairement modifié, utilisez `npm install`.

## Démarrer le projet

Les trois services doivent être actifs : MySQL, backend et frontend. Le backend et le frontend doivent rester ouverts dans deux terminaux distincts.

### Terminal 1 — Backend Spring Boot

À partir de la racine du dépôt :

```powershell
cd backend
mvn spring-boot:run
```

Au premier lancement, le téléchargement des dépendances peut prendre quelques minutes. Le backend écoute sur `http://localhost:8080`.

Pour arrêter le backend, utilisez `Ctrl+C` dans ce terminal.

### Terminal 2 — Frontend React

À partir de la racine du dépôt, ouvrez un nouveau terminal :

```powershell
cd frontend
npm start
```

Le navigateur ouvre normalement [http://localhost:3000](http://localhost:3000). Le frontend utilise l’API Spring Boot sur le port 8080.

Pour arrêter le frontend, utilisez `Ctrl+C` dans ce terminal.

### Adresses locales

| Service | Adresse |
|---|---|
| Site web | [http://localhost:3000](http://localhost:3000) |
| API backend | [http://localhost:8080](http://localhost:8080) |
| phpMyAdmin (si WampServer est installé) | [http://localhost/phpmyadmin](http://localhost/phpmyadmin) |

## Tester et compiler

Depuis `backend` :

```powershell
.\mvnw.cmd test
```

Depuis `frontend` :

```powershell
npm test -- --watchAll=false
npm run build
```

Le build frontend de production est généré dans `frontend/build/`.

## Organisation du dépôt

```text
terra-sana-website/
├── backend/                 API Spring Boot, configuration Maven et tests
│   ├── mvnw.cmd             Maven Wrapper pour Windows
│   ├── pom.xml              Dépendances et version Java
│   └── src/
├── frontend/                Application React
│   ├── package.json         Scripts et dépendances
│   ├── package-lock.json    Versions verrouillées des dépendances npm
│   └── src/                 Pages, composants et services frontend
├── docs/                    Documents du projet
└── memoire_assets/          Ressources visuelles du projet
```

Dans le backend, les packages sont organisés autour des contrôleurs, modèles, repositories, services et paramètres de sécurité. Dans le frontend, les pages sont dans `src/pages`, les composants réutilisables dans `src/components` et les appels API dans `src/services`.

## Sécurité

- Ne publiez jamais de mot de passe MySQL, compte administrateur, jeton JWT, clé de signature ou identifiant SMTP.
- Ne réutilisez pas de mot de passe de démonstration. Créez un mot de passe administrateur propre à votre environnement et modifiez-le après une première connexion si nécessaire.
- Gardez les secrets dans des variables d’environnement ou un fichier local exclu de Git; ne les ajoutez ni au README ni à `application.properties` commité.
- N’utilisez pas les paramètres de développement local tels quels en production. Configurez séparément la base, les clés, le courrier électronique, les sauvegardes et les règles d’accès.
- Les messages de contact et les informations de candidature peuvent contenir des données personnelles. Limitez l’accès à l’administration et définissez les règles de conservation avant le déploiement.

## Problèmes courants

| Symptôme | Vérification |
|---|---|
| `java` ou `node` n’est pas reconnu | Vérifiez l’installation et le `PATH`, puis ouvrez une nouvelle fenêtre PowerShell. |
| WampServer reste orange ou rouge | Démarrez les services depuis WampServer et vérifiez qu’aucun autre service n’occupe le port MySQL 3306. |
| Erreur de connexion à MySQL | Confirmez que MySQL est actif, que la base s’appelle `terre_sana` et que les paramètres locaux correspondent à ceux de l’application. |
| Le backend ne démarre pas | Vérifiez Java 21, les variables de configuration et la sortie complète du terminal. |
| Le site ne charge pas les données | Laissez le backend et MySQL en fonctionnement; vérifiez les ports 8080 et 3306 et consultez les erreurs des deux terminaux. |
| Le frontend ne démarre pas | Dans `frontend`, relancez `npm ci`; vérifiez que Node.js répond avec `node --version`. |
| Le port 3000 ou 8080 est déjà utilisé | Fermez l’application qui l’utilise ou changez le port correspondant dans la configuration. |

---

**Projet :** Terra Sana ASBL — Site web vitrine et hub d’applications  
**Dépôt :** [github.com/sidanne/terra-sana-website](https://github.com/sidanne/terra-sana-website)
