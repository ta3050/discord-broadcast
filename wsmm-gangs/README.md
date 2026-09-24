# WSMM GANGS

FiveM resource folder: `wsmm-gangs`

Copyright (c) 2026 **WSMM GANGS**. This resource belongs to WSMM GANGS. No other studio is credited.

Lightweight **ESX** gang resource: tablet, full gang summon, rankings, map blips, leader/admin menus, and gang-only wall spray.

Standalone FiveM resource. **No Discord** — no webhooks, no bot, no off-tablet logging. All logs live in the tablet (leader and admin only).

## Install

1. Copy `wsmm-gangs` into your server `resources` folder.
2. Items:
   - ESX: run `sql/items.sql`
   - ox_inventory: copy entries from `install/ox_inventory_items.lua`
3. `server.cfg`:
   ```
   ensure oxmysql
   ensure es_extended
   ensure wsmm-gangs
   ```
4. Admin (group `admin` / `superadmin` / ACE `wsmmgangs.admin`) opens the tablet with **F10** or `/gangadmin` and creates a gang, then assigns a leader.

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

## Tablet logs (leader + admin only)

Nothing is sent to Discord. Regular members cannot open these lists; the server does not send them.

1. **Spray log** — who / where / when / freehand vs text. Leader deletes own gang tags. Admin sees all gangs and can delete any.
2. **Activity log** — create/delete gang, set/remove leader, member add/kick/rank, full summon, icon approve/reject, guest invite/remove.

## Blips

| Blip | Who sees it |
|------|-------------|
| Public turf **square** (claimed + open zones) | Everyone |
| Gang HQ | That gang + admins |
| Active summon | That gang only |
| Spray wall markers | Leader + admin only |

Tablet map uses the real **Los Santos** image (`html/los-santos-map.png`). Territories are **squares**, never circles.

- **Claimed** (and open): colored square + gang name.
- **Open unclaimed**: faint dashed square only — the map stays clean (no colored blob).
- **Locked**: no overlay. Admin opens/locks which zones gangs may claim.

In-game pause map uses `AddBlipForArea` squares for claimed open turf. GTA cannot paint a custom PNG onto pause-map blips without a streamed texture dictionary, so those stay default sprites. Uploaded gang images show on the **tablet map** after admin approval.

Map icon: leader uploads PNG/JPG/WEBP (max 512 KB) or picks a list icon → **admin approve/reject**. Until approved, the old icon stays. Spray has **no** image upload (draw/text only).

## Ranks

1 member · 2 soldier · 3 lieutenant (can full-summon) · 4 underboss · 5 leader

## Locale

Default Arabic (`Config.Locale = 'ar'`). Toggle EN/AR in the tablet.

## Rights

Copyright (c) 2026 WSMM GANGS. See `LICENSE` in this folder.

