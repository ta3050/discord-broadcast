# wick-gangs

Lightweight **ESX** gang resource: tablet, full gang summon, rankings, map blips, leader/admin menus, and gang-only wall spray.

This folder is a drop-in FiveM resource. It does not change the Discord broadcast bot in the repo root.

## Install

1. Copy `wick-gangs` into your server `resources` folder.
2. Items:
   - ESX: run `sql/items.sql`
   - ox_inventory: copy entries from `install/ox_inventory_items.lua`
3. `server.cfg`:
   ```
   ensure oxmysql
   ensure es_extended
   ensure wick-gangs
   ```
4. Admin (group `admin` / `superadmin` / ACE `wickgangs.admin`) opens the tablet with **F10** or `/gangadmin` and creates a gang, then assigns a leader.

Tables are created automatically on start.

`ox_lib` is **not** required.

## Keys

| Key | Action |
|-----|--------|
| F6 / item `gang_tablet` / `/gangtablet` | Tablet (members, guests, admins) |
| F7 / `/gangleader` | Same tablet (leader pages if you are leader) |
| F10 / `/gangadmin` | Admin pages |
| `/gangsummon` | Full summon |
| item `gang_spray` | Spray (full members only) |

## Spray

- Gang members only. Not civilians, not guests.
- **No zone requirement** — any wall.
- Modes: **freehand** or **typed text**.
- No image/decal upload.
- Arabic + English profanity is blocked on the server. Rejected text never paints.
- Nearby players see tags (lines / 3D text). Not a per-tag DUI.

## Spray log (leader + admin only)

Members can spray. They **cannot** see who/where/when. Leader sees that gang’s list and can delete. Admin sees all gangs and can delete any.

## Blips

| Blip | Who sees it |
|------|-------------|
| Public turf radius + icon (claimed zones) | Everyone |
| Gang HQ | That gang + admins |
| Active summon | That gang only |
| Spray wall markers | Leader + admin only |

Map icon: leader picks from a list → **admin approve/reject**. Until approved, the old/default icon stays. Reject notifies the leader in the tablet.

## Ranks

1 member · 2 soldier · 3 lieutenant (can full-summon) · 4 underboss · 5 leader

## Locale

Default Arabic (`Config.Locale = 'ar'`). Toggle EN/AR in the tablet.
