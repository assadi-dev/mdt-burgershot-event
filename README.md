# mdt-burgershot-event

Resource FiveM (QBox) qui déclenche des notifications en jeu lorsqu'une commande est effectuée depuis le MDT Burgershot web.

## Fonctionnement

Le MDT web envoie une requête HTTP au serveur FiveM via un webhook sécurisé. Le serveur identifie les employés Burgershot en service et leur envoie une notification (son + alerte visuelle ox_lib) directement dans le jeu.

## Dépendances

- [qbx_core](https://github.com/Qbox-project/qbx_core)
- [ox_lib](https://github.com/overextended/ox_lib)

## Installation

1. Placer le dossier dans `resources/[job]/`
2. Ajouter `ensure mdt-burgershot-event` dans `server.cfg`
3. Configurer `config.lua` (voir section ci-dessous)

## Configuration

```lua
-- config.lua
return {
    WebhookPath           = '/notify',       -- route de notification commande
    WebhookPathDutyPath   = '/duty',         -- route prise/fin de service
    WebhookPathDutyStatus = '/duty/status',  -- route statut de service

    WebhookSecret = "secret-password",       -- à changer, doit correspondre au MDT web

    -- Apparence de la notification ox_lib
    NotifyPosition = 'top-right',
    NotifyDuration = 10000,                  -- ms
    NotifyType     = 'info',
    NotifyTitle    = 'Burgershot',
    NotifyIcon     = 'fa-solid fa-burger',
}
```

> **Important** : changer `WebhookSecret` et utiliser la même valeur dans le MDT web.

## API HTTP

Toutes les routes nécessitent le header `x-secret: <WebhookSecret>`.

### `POST /notify`

Notifie tous les employés Burgershot **en service**.

**Body JSON**

| Champ     | Type   | Requis | Description                         |
|-----------|--------|--------|-------------------------------------|
| `message` | string | oui    | Contenu de la notification          |
| `title`   | string | non    | Titre (défaut : valeur du config)   |

**Réponse**

```json
{ "ok": true, "notified": 3 }
```

---

### `POST /duty`

Prise ou fin de service d'un employé.

**Body JSON**

| Champ        | Type    | Requis | Description                                    |
|--------------|---------|--------|------------------------------------------------|
| `citizenid`  | string  | oui    | Identifiant citoyen du joueur                  |
| `duty`       | boolean | non    | `true` = en service, `false` = hors service. Si absent, bascule l'état actuel. |

**Réponse**

```json
{ "ok": true, "citizenid": "ABC123", "onduty": true }
```

---

### `POST /duty/status`

Récupère le statut de service d'un employé.

**Body JSON**

| Champ       | Type   | Requis | Description                   |
|-------------|--------|--------|-------------------------------|
| `citizenid` | string | oui    | Identifiant citoyen du joueur |

**Réponse**

```json
{ "citizenid": "ABC123", "onduty": false }
```

## Codes d'erreur

| Code | Signification                            |
|------|------------------------------------------|
| 400  | Corps de requête manquant ou invalide    |
| 401  | Header `x-secret` absent                |
| 403  | Secret invalide                          |
| 404  | Route introuvable / joueur hors ligne    |
