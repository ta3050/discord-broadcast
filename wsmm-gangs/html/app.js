/* WSMM GANGS. Copyright (c) 2026 WSMM GANGS. */
const MOCK = typeof GetParentResourceName !== 'function';
let S = {};
let page = 'home';
let lang = 'ar';
let sprayMode = 'freehand';
let strokes = [];
let drawing = false;

function t(k) {
  return (S.strings && S.strings[k]) || k;
}

function $(id) { return document.getElementById(id); }

function post(name, data) {
  if (MOCK) {
    if (name === 'action' && data && data.a === 'setZoneOpen') {
      const z = (S.places || []).find((p) => p.id === data.zoneId);
      if (z) {
        z.open = Number(data.open) === 1;
        render();
      }
    }
    console.log(name, data);
    return Promise.resolve({ ok: true });
  }
  return fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {})
  }).then((r) => r.json()).catch(() => ({ ok: true }));
}

function toast(text) {
  const el = $('toast');
  el.textContent = text;
  el.hidden = false;
  setTimeout(() => { el.hidden = true; }, 2800);
}

function setDir() {
  const rtl = lang === 'ar';
  document.body.classList.toggle('rtl', rtl);
  document.body.classList.toggle('ltr', !rtl);
  document.documentElement.lang = lang;
  document.documentElement.dir = rtl ? 'rtl' : 'ltr';
}

function navItems() {
  const items = [
    ['home', 'home'],
    ['members', 'members'],
    ['guest', 'guest'],
    ['rankings', 'rankings'],
    ['map', 'places'],
    ['summon', 'summon'],
    ['spray', 'spray'],
    ['notifs', 'notifs']
  ];
  if (S.isLeader || S.isAdmin) items.push(['logs', 'logs']);
  if (S.isLeader || (S.isAdmin && S.gang)) items.push(['leader', 'leader']);
  if (S.isAdmin) items.push(['admin', 'admin']);
  return items;
}

const NAV_ICONS = {
  home: '👥', members: '👤', guest: '✉', rankings: '🏆',
  map: '🗺', summon: '📢', spray: '🎨', notifs: '🔔',
  logs: '📋', leader: '⚙', admin: '🛡'
};

function renderNav() {
  $('nav').innerHTML = navItems().map(([id, key]) =>
    `<button class="nav ${page === id ? 'active' : ''}" data-page="${id}"><span class="nav-ic">${NAV_ICONS[id] || ''}</span>${t(key)}</button>`
  ).join('');
  syncRail();
}

function menuScroller() {
  return $('side-pane') || document.querySelector('.side');
}

function scrollMenu(dy) {
  const pane = menuScroller();
  const main = $('page');
  if (!pane) return;
  const max = Math.max(0, pane.scrollHeight - pane.clientHeight);
  const next = Math.min(max, Math.max(0, pane.scrollTop + dy));
  if (max > 1 && ((dy < 0 && pane.scrollTop > 0) || (dy > 0 && pane.scrollTop < max))) {
    pane.scrollTop = next;
  } else if (main) {
    main.scrollTop += dy;
  }
  syncRail();
}

function syncRail() {
  const pane = menuScroller();
  const thumb = $('rail-thumb');
  const track = $('rail-track');
  if (!pane || !thumb || !track) return;
  const view = pane.clientHeight || 1;
  const full = pane.scrollHeight || 1;
  const trackH = track.clientHeight || 1;
  const thumbH = Math.max(40, Math.min(trackH, (view / full) * trackH));
  const maxTop = Math.max(0, trackH - thumbH);
  const maxScroll = Math.max(1, full - view);
  thumb.style.height = thumbH + 'px';
  thumb.style.top = (pane.scrollTop / maxScroll) * maxTop + 'px';
}

function bindSideRail() {
  if (bindSideRail.done) return;
  bindSideRail.done = true;
  const pane = $('side-pane');
  const up = $('rail-up');
  const down = $('rail-down');
  const track = $('rail-track');
  const thumb = $('rail-thumb');
  if (pane) {
    pane.addEventListener('scroll', syncRail);
    pane.addEventListener('wheel', (e) => {
      e.preventDefault();
      scrollMenu(e.deltaY);
    }, { passive: false });
  }
  if (up) up.onclick = () => scrollMenu(-72);
  if (down) down.onclick = () => scrollMenu(72);
  if (track && thumb && pane) {
    const jump = (clientY) => {
      const r = track.getBoundingClientRect();
      const y = clientY - r.top - thumb.offsetHeight / 2;
      const maxTop = Math.max(1, r.height - thumb.offsetHeight);
      const ratio = Math.min(1, Math.max(0, y / maxTop));
      pane.scrollTop = ratio * Math.max(0, pane.scrollHeight - pane.clientHeight);
      syncRail();
    };
    track.onmousedown = (e) => {
      jump(e.clientY);
      const move = (ev) => jump(ev.clientY);
      const upl = () => {
        window.removeEventListener('mousemove', move);
        window.removeEventListener('mouseup', upl);
      };
      window.addEventListener('mousemove', move);
      window.addEventListener('mouseup', upl);
    };
  }
}

function esc(s) {
  return String(s == null ? '' : s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');
}

function safeImg(src) {
  return (src && /^data:image\/(png|jpeg|webp);base64,[A-Za-z0-9+/]+=*$/.test(src)) ? src : '';
}

function colorHex(id) {
  const c = (S.colors || []).find((x) => x.id === id);
  return c ? c.hex : '#c43b4a';
}

function iconLabel(id) {
  const ic = (S.icons || []).find((x) => x.id === id);
  if (!ic) return id || '';
  return lang === 'ar' ? ic.ar : ic.en;
}

function pageTitle() {
  const map = {
    home: 'home', members: 'members', guest: 'guest', rankings: 'rankings',
    map: 'places', places: 'places', summon: 'summon', spray: 'spray',
    notifs: 'notifs', logs: 'logs', leader: 'leader', admin: 'admin'
  };
  return t(map[page] || 'home');
}

function home() {
  const g = S.gang;
  if (!g) return `<div class="card">${t('not_member')}</div>`;
  const rank = (S.rankings || []).findIndex((x) => x.id === g.id);
  const live = safeImg(g.iconImage);
  const pend = (S.isLeader || S.isAdmin) ? safeImg(g.pendingIconImage) : '';
  return `<div class="cards">
      <div class="card">${t('points')}<b class="big">${g.points || 0}</b></div>
      <div class="card">${t('sprays')}<b class="big">${g.sprays || 0}</b></div>
      <div class="card">${t('place')}<b class="big">#${rank >= 0 ? rank + 1 : '—'}</b></div>
    </div>
    <div class="card">${esc(g.label)} <span class="tag">[${esc(g.tag || '')}]</span>
      <div class="xp">${t('color')}: ${esc(g.color || '')}
        ${(S.isLeader || S.isAdmin) && (g.pendingIcon || pend) ? ' · ' + t('pending') + (g.pendingIcon ? ': ' + esc(iconLabel(g.pendingIcon)) : '') : ''}
      </div>
      <div class="row" style="margin-top:10px">
        ${live ? `<img class="icon-prev" alt="" src="${live}"/>` : ''}
        ${pend ? `<div><div class="lbl">${t('pending')}</div><img class="icon-prev" alt="" src="${pend}"/></div>` : ''}
      </div>
    </div>`;
}

function hexRgba(hex, a) {
  const h = String(hex || '#8d9199').replace('#', '');
  const n = parseInt(h.length === 3 ? h.split('').map((c) => c + c).join('') : h, 16);
  if (Number.isNaN(n)) return `rgba(141,145,153,${a})`;
  return `rgba(${(n >> 16) & 255},${(n >> 8) & 255},${n & 255},${a})`;
}

function mapBox(z) {
  if (z.map && z.map.w) {
    return { left: z.map.x, top: z.map.y, w: z.map.w, h: z.map.h || z.map.w };
  }
  const x = Number(z.x), y = Number(z.y);
  const left = 12 + ((x + 1850) / 2950) * 60;
  const top = 12 + ((400 - y) / 3200) * 70;
  const w = Math.max(5.2, Math.min(10, (Number(z.size || z.radius) || 90) * 0.055));
  if (!Number.isFinite(left) || !Number.isFinite(top)) return null;
  if (left < -3 || left > 103 || top < -3 || top > 103) return null;
  return { left, top, w, h: w };
}

function mapView() {
  const zones = S.places || [];
  const claimed = zones.filter((z) => z.open !== false && z.claimed && z.owner && mapBox(z));
  const boxes = zones.map((z) => {
    if (z.open === false) return '';
    const p = mapBox(z);
    if (!p) return '';
    const claimedZone = !!(z.claimed && z.owner);
    const c = z.hex || colorHex(z.color);
    const img = claimedZone ? safeImg(z.iconImage) : '';
    const cls = claimedZone ? 'turf claimed' : 'turf open';
    const style = claimedZone
      ? `left:${p.left}%;top:${p.top}%;width:${p.w}%;height:${p.h}%;--c:${c};border-color:${c};background:${hexRgba(c, 0.32)}`
      : `left:${p.left}%;top:${p.top}%;width:${p.w}%;height:${p.h}%`;
    return `<div class="${cls}" style="${style}">
        ${img ? `<img class="turf-icon" alt="" src="${img}"/>` : ''}
        ${claimedZone ? `<span class="lab">${esc(z.owner)}</span>` : ''}
      </div>`;
  }).join('');
  return `<div class="gta-map">${boxes}
      ${claimed.length ? `<div class="legend"><b>${t('map_legend')}</b>
        ${claimed.map((z) => `<div><i style="background:${z.hex || colorHex(z.color)}"></i> ${esc(z.label)} — ${esc(z.owner)}</div>`).join('')}
      </div>` : ''}
    </div>
    <p class="hint">${t('map_hint')}</p>
    ${S.isAdmin ? zoneAdmin() : ''}`;
}

function zoneAdmin() {
  const zones = S.places || [];
  if (!zones.length) return '';
  return `<div class="card"><b>${t('zones_admin')}</b>
    <p class="hint">${t('map_open_hint')}</p>
    ${zones.map((z) => `<div class="log">
      <b>${esc(z.label)}</b>
      <span class="xp">${z.open === false ? t('zone_locked_state') : t('zone_open_state')}${z.owner ? ' · ' + esc(z.owner) : ''}</span>
      ${z.open === false
        ? `<button class="btn ok" data-act='{"a":"setZoneOpen","zoneId":"${esc(z.id)}","open":1}'>${t('zone_open')}</button>`
        : `<button class="btn2" data-act='{"a":"setZoneOpen","zoneId":"${esc(z.id)}","open":0}'>${t('zone_lock')}</button>`}
    </div>`).join('')}
  </div>`;
}

function places() { return mapView(); }

function rankings() {
  const list = S.rankings || [];
  if (!list.length) return `<div class="card">${t('none')}</div>`;
  const a = list[0], b = list[1], c = list[2];
  const rest = list.slice(3);
  const spot = (g, cls, place, medal) => {
    if (!g) return `<div class="spot ${cls}"></div>`;
    const img = safeImg(g.iconImage);
    return `<div class="spot ${cls}">
      <div class="avatar">${img ? `<img alt="" src="${img}"/>` : medal}</div>
      <div class="name">${esc(g.label)}</div>
      <div class="tag">[${esc(g.tag || '')}]</div>
      <div class="xp">${t('points')} ${g.score || g.points || 0} · ${g.sprays || 0} ${t('sprays')}</div>
      <div class="plinth">${place}</div>
    </div>`;
  };
  return `${list.length ? `<div class="podium">
      ${spot(c, 'bronze', t('third'), '🎖')}
      ${spot(a, 'gold', t('first'), '🏆')}
      ${spot(b, 'silver', t('second'), '🥈')}
    </div>` : ''}
    <div class="list">${rest.map((g, i) => `
      <div class="rank-row">
        <span class="rank-num">${i + 4}</span>
        <div><b>${esc(g.label)}</b> <span class="tag">[${esc(g.tag || '')}]</span></div>
        <span class="xp">${t('points')} ${g.score || g.points || 0} · ${g.sprays || 0} ${t('sprays')}</span>
      </div>`).join('')}</div>`;
}

function membersView() {
  const q = (($('search') && $('search').value) || '').trim();
  const rows = (S.members || []).filter((m) => !q || String(m.name).includes(q));
  if (!rows.length) return `<div class="card">${t('none')}</div>`;
  const canManage = S.isLeader || S.isAdmin;
  return `<table>
    <thead><tr>
      ${canManage ? '<th></th>' : ''}
      <th>${t('col_status')}</th>
      <th>${t('col_name')}</th>
      <th>${t('col_role')}</th>
      <th>${t('col_sprays')}</th>
    </tr></thead>
    <tbody>${rows.map((m) => `<tr>
      ${canManage ? `<td><button class="manage" data-act='{"a":"kick","identifier":"${esc(m.identifier)}"}'>${t('manage')}</button></td>` : ''}
      <td class="${m.online ? 'on' : 'off'}">${m.online ? '● ' + t('connected') : '○ ' + t('offline')}</td>
      <td><b>${esc(m.name)}</b></td>
      <td><span class="pill">${esc(m.rankLabel)}${m.guest ? ' · ' + t('guest_tag') : ''}</span></td>
      <td>${m.sprays || 0}</td>
    </tr>`).join('')}</tbody>
  </table>`;
}

function summon() {
  if (S.isGuest) return `<div class="card">${t('summon_need_rank')}</div>`;
  return `<div class="card"><p>${t('summon_hint')}</p><br/><button class="btn" data-act='{"a":"summon"}'>${t('send_summon')}</button></div>`;
}

function guest() {
  let html = `<div class="card"><p>${t('invite_guest')}</p>`;
  if (S.isLeader) {
    html += `<br/><input class="search" id="guest-id" placeholder="${t('invite_guest')}"/>
      <button class="btn" id="guest-go">${t('invite_guest')}</button>`;
  }
  html += '</div>';
  html += (S.guests || []).map((g) => `<div class="log"><b>${esc(g.name)}</b>
    ${S.isLeader ? `<button class="manage" data-act='{"a":"removeGuest","identifier":"${esc(g.identifier)}"}'>${t('remove')}</button>` : ''}
  </div>`).join('') || `<div class="xp">${t('none')}</div>`;
  return html;
}

function sprayPage() {
  if (S.isGuest) return `<div class="card">${t('guest_no_spray')}</div>`;
  return `<div class="card">
      <p>${t('spray_hint')}</p>
      <p class="hint">${t('spray_wall_hint')}</p>
      <button class="btn2" id="mfree">${t('spray_free')}</button>
      <button class="btn2" id="mtext">${t('spray_text')}</button>
      <canvas id="spray-cv" width="900" height="280"></canvas>
      <input class="inp hidden" id="stxt" maxlength="28" placeholder="${t('text_placeholder')}"/>
    </div>`;
}

function iconGangId() {
  const sel = $('g-sel');
  if (sel && sel.value) return Number(sel.value);
  return S.gang && S.gang.id;
}

function compressIcon(file) {
  return new Promise((resolve, reject) => {
    if (!file || !/^image\/(png|jpeg|jpg|webp)$/i.test(file.type)) {
      reject('icon_bad_type');
      return;
    }
    if (file.size > 512 * 1024) {
      reject('icon_too_big');
      return;
    }
    const img = new Image();
    const url = URL.createObjectURL(file);
    img.onload = () => {
      const size = 128;
      const c = document.createElement('canvas');
      c.width = size;
      c.height = size;
      c.getContext('2d').drawImage(img, 0, 0, size, size);
      URL.revokeObjectURL(url);
      let out = '';
      try { out = c.toDataURL('image/jpeg', 0.82); } catch (err) { out = ''; }
      if (!out || out.length < 32) out = c.toDataURL('image/png');
      if (out.length > 700000) reject('icon_too_big');
      else resolve(out);
    };
    img.onerror = () => { URL.revokeObjectURL(url); reject('icon_bad_type'); };
    img.src = url;
  });
}

function bindIconUpload() {
  const f = $('iconfile');
  if (!f) return;
  f.onchange = () => {
    const file = f.files && f.files[0];
    f.value = '';
    if (!file) return;
    compressIcon(file).then((dataUrl) => {
      if (MOCK) {
        if (!S.gang) S.gang = {};
        S.gang.pendingIconImage = dataUrl;
        S.pendingIcons = S.pendingIcons || [];
        if (S.pendingIcons[0]) S.pendingIcons[0].pendingImage = dataUrl;
        else S.pendingIcons.push({
          id: S.gang.id || 1, label: S.gang.label || '', current: S.gang.icon,
          pending: S.gang.pendingIcon, pendingImage: dataUrl
        });
        toast(t('icon_pending'));
        render();
        return;
      }
      post('uploadIcon', { image: dataUrl, gangId: iconGangId() });
      toast(t('icon_pending'));
      setTimeout(() => post('refresh'), 400);
    }).catch((key) => toast(t(key)));
  };
}

function bindSprayPage() {
  const cv = $('spray-cv');
  if (!cv) return;
  const ctx = cv.getContext('2d');
  let draw = false;
  const pos = (e) => {
    const r = cv.getBoundingClientRect();
    return { x: (e.clientX - r.left) * cv.width / r.width, y: (e.clientY - r.top) * cv.height / r.height };
  };
  cv.onpointerdown = (e) => {
    draw = true;
    const p = pos(e);
    ctx.beginPath();
    ctx.moveTo(p.x, p.y);
    cv.setPointerCapture(e.pointerId);
  };
  cv.onpointermove = (e) => {
    if (!draw) return;
    const p = pos(e);
    ctx.strokeStyle = colorHex(S.gang && S.gang.color);
    ctx.lineWidth = 4;
    ctx.lineCap = 'round';
    ctx.lineTo(p.x, p.y);
    ctx.stroke();
  };
  cv.onpointerup = () => { draw = false; };
  const txt = $('stxt');
  if ($('mtext')) $('mtext').onclick = () => { txt.classList.remove('hidden'); };
  if ($('mfree')) $('mfree').onclick = () => { txt.classList.add('hidden'); };
}

function notifs() {
  const rows = S.notifs || [];
  if (!rows.length) return `<div class="card">${t('no_notifs')}</div>`;
  return rows.map((n) => {
    const key = n.title || n.type || '';
    const title = t(key) !== key ? t(key) : (t('act_' + key) !== ('act_' + key) ? t('act_' + key) : key);
    return `<div class="log"><b>${esc(title)}</b>
      <div class="xp">${esc(n.message || '')} · ${esc(n.created_at || '')}</div></div>`;
  }).join('');
}

function logs() {
  if (!S.isLeader && !S.isAdmin) return `<div class="card">${t('logs_only')}</div>`;
  const sprays = S.isAdmin ? (S.adminSprays || S.sprayLog || []) : (S.sprayLog || []);
  const acts = S.activityLog || [];
  let html = `<p class="hint">${t('logs_only')}</p><div class="card"><b>${t('spray_log')}</b></div>`;
  html += sprays.length ? sprays.map((r) => `<div class="log">
      <b>${esc(r.player_name || '')}${r.gang_label ? ' · ' + esc(r.gang_label) : ''}</b>
      <div class="xp">${r.mode === 'text' ? t('mode_text') : t('mode_free')} · ${esc(r.text_content || '')} · ${esc(r.created_at || '')}</div>
      <button class="manage" data-act='{"a":"deleteSpray","id":${r.id}}'>${t('delete')}</button>
    </div>`).join('') : `<div class="xp">${t('no_log')}</div>`;
  html += `<div class="log"><b>${t('activity_log')}</b></div>`;
  html += acts.length ? acts.map((r) => `<div class="log">
      <b>${esc(t('act_' + r.action) === 'act_' + r.action ? r.action : t('act_' + r.action))}</b>
      <div class="xp">${esc(r.actor_name || '')} · ${esc(r.detail || '')} · ${esc(r.created_at || '')}</div>
    </div>`).join('') : `<div class="xp">${t('no_activity')}</div>`;
  return html;
}

function iconEditor() {
  const can = S.isLeader || (S.isAdmin && S.gang);
  if (!can && !S.isAdmin) return '';
  const icons = (S.icons || []).map((ic) =>
    `<option value="${ic.id}">${lang === 'ar' ? ic.ar : ic.en}</option>`
  ).join('');
  const g = S.gang || {};
  const live = safeImg(g.iconImage);
  const pend = safeImg(g.pendingIconImage);
  return `<div class="card"><b>${t('icon')}</b>
      <p class="hint">${t('icon_upload_hint')}</p>
      <select class="inp" id="icon-sel">${icons}</select>
      <input type="file" id="iconfile" accept="image/png,image/jpeg,image/webp" class="hidden"/>
      <div class="row">
        <button class="btn" id="icon-upload" type="button">${t('upload_icon')}</button>
        <button class="btn2" id="icon-go" type="button">${t('request_icon')}</button>
      </div>
      <p class="hint">${t('icon_blip_note')}</p>
      <div class="row">
        ${live ? `<div><div class="lbl">${t('icon_preview')}</div><img class="icon-prev" alt="" src="${live}"/></div>` : ''}
        ${pend ? `<div><div class="lbl">${t('pending')}</div><img class="icon-prev" alt="" src="${pend}"/></div>` : ''}
      </div>
    </div>`;
}

function leader() {
  if (!S.isLeader && !(S.isAdmin && S.gang)) return `<div class="card">${t('not_leader')}</div>`;
  const colors = (S.colors || []).map((c) =>
    `<button class="swatch" data-act='{"a":"setColor","color":"${c.id}"}' style="background:${c.hex}" title="${lang === 'ar' ? c.ar : c.en}"></button>`
  ).join(' ');
  const mem = (S.members || []).filter((m) => !m.guest).map((m) => `<div class="log">
    ${esc(m.name)} · ${esc(m.rankLabel)}
    <button class="btn2" data-act='{"a":"setRank","identifier":"${esc(m.identifier)}","rank":${Math.min((m.rank || 1) + 1, 4)}}'>${t('promote')}</button>
    <button class="btn2" data-act='{"a":"setRank","identifier":"${esc(m.identifier)}","rank":${Math.max((m.rank || 1) - 1, 1)}}'>${t('demote')}</button>
    <button class="manage" data-act='{"a":"kick","identifier":"${esc(m.identifier)}"}'>${t('kick')}</button>
  </div>`).join('');
  return `<div class="grid2">
      <div class="card"><b>${t('set_hq')}</b><p class="hint">${t('color')}</p>
        <button class="btn" data-act='{"a":"setHQ"}'>${t('set_hq')}</button>
        <p class="hint">${t('color')}</p>
        <div class="row">${colors}</div>
      </div>
      ${iconEditor()}
    </div>
    <div class="card"><b>${t('announce')}</b><input class="inp" id="ann" placeholder="${t('announce')}"/><button class="btn" id="ann-go">${t('announce')}</button></div>
    <div class="card"><b>${t('members')}</b>${mem}
      <button class="btn no" data-act='{"a":"wipeGangSprays"}'>${t('wipe_gang_sprays')}</button>
    </div>`;
}

function admin() {
  if (!S.isAdmin) return `<div class="card">${t('not_admin')}</div>`;
  const gangs = (S.gangs || []).map((g) => `<option value="${g.id}">${esc(g.label)}</option>`).join('');
  const pending = (S.pendingIcons || []).map((p) => {
    const img = safeImg(p.pendingImage) || safeImg(p.currentImage);
    const nextLabel = p.pendingImage ? t('icon_image_pending') : iconLabel(p.pending);
    return `<div class="log spray-item">
      ${img ? `<img class="spray-thumb" alt="" src="${img}"/>` : `<div class="spray-thumb wall-text">${esc(nextLabel || t('icon'))}</div>`}
      <div><b>${esc(p.label)}</b>
        <div class="xp">${esc(iconLabel(p.current) || t('none'))} → ${esc(nextLabel)}</div>
      </div>
      <div>
        <button class="btn ok" data-act='{"a":"approveIcon","gangId":${p.id}}'>${t('approve')}</button>
        <button class="btn no" data-act='{"a":"rejectIcon","gangId":${p.id}}'>${t('reject')}</button>
      </div>
    </div>`;
  }).join('') || `<div class="xp">${t('none')}</div>`;
  return `<div class="grid2">
      <div class="card"><b>${t('create_gang')}</b>
        <input class="inp" id="g-name" placeholder="${t('name')}"/>
        <input class="inp" id="g-label" placeholder="${t('label')}"/>
        <input class="inp" id="g-tag" placeholder="${t('tag')}"/>
        <button class="btn" id="g-create">${t('create_gang')}</button>
      </div>
      <div class="card"><b>${t('set_leader')}</b>
        <select class="inp" id="g-sel">${gangs}</select>
        <input class="inp" id="g-sid" placeholder="ID"/>
        <button class="btn" id="g-leader">${t('set_leader')}</button>
        <button class="btn2" id="g-clear-leader">${t('clear_leader')}</button>
        <button class="btn2" id="g-add">${t('add_member')}</button>
        <button class="btn no" id="g-del">${t('delete_gang')}</button>
      </div>
    </div>
    ${iconEditor()}
    ${zoneAdmin()}
    <div class="card"><b>${t('pending_icons')}</b>${pending}</div>
    <div class="card"><b>${t('all_sprays')}</b>
      <button class="btn2" id="g-wipe">${t('wipe_gang_sprays')}</button>
      <input class="inp" id="g-pts" placeholder="${t('points')}"/>
      <button class="btn2" id="g-pts-go">${t('adjust_points')}</button>
      <button class="btn no" id="wipe-all">${t('wipe_all_sprays')}</button>
    </div>`;
}

const views = {
  home, places, map: mapView, rankings, members: membersView,
  summon, guest, spray: sprayPage, notifs, logs, leader, admin
};

function render() {
  const g = S.gang;
  document.getElementById('tablet').style.setProperty('--gang', g ? colorHex(g.color) : '#c43b4a');
  $('page-title').textContent = pageTitle();
  $('btn-lang').textContent = t('lang');
  $('search').placeholder = t('search_member');
  $('search').classList.toggle('hidden', page !== 'members');
  renderNav();
  $('page').innerHTML = (views[page] || home)();
  if (page === 'spray') bindSprayPage();
  bindIconUpload();
  bindSideRail();
  requestAnimationFrame(syncRail);
}

function openTablet(data) {
  S = data;
  lang = data.lang || 'ar';
  S.strings = data.strings || S.strings;
  setDir();
  $('tablet').hidden = false;
  page = 'home';
  if (MOCK) {
    const q = new URLSearchParams(location.search).get('page');
    if (q === 'places') page = 'map';
    else if (q && views[q]) page = q;
  }
  render();
}

$('btn-close').onclick = () => { $('tablet').hidden = true; post('close'); };
$('btn-lang').onclick = () => {
  lang = lang === 'ar' ? 'en' : 'ar';
  post('setLang', { lang }).then((r) => {
    if (r && r.strings) S.strings = r.strings;
    setDir();
    post('refresh');
    render();
  });
};

$('nav').onclick = (e) => {
  const b = e.target.closest('button[data-page]');
  if (!b) return;
  page = b.getAttribute('data-page');
  render();
};

$('search').addEventListener('input', () => {
  if (page === 'members') $('page').innerHTML = membersView();
});

$('page').onclick = (e) => {
  const b = e.target.closest('button[data-act]');
  if (b) {
    post('action', JSON.parse(b.getAttribute('data-act')));
    setTimeout(() => post('refresh'), 250);
    return;
  }
  if (e.target.id === 'icon-upload') {
    const f = $('iconfile');
    if (f) f.click();
    return;
  }
  if (e.target.id === 'icon-go') {
    post('action', { a: 'requestIcon', icon: $('icon-sel').value, gangId: iconGangId() });
    setTimeout(() => post('refresh'), 250);
    return;
  }
  if (e.target.id === 'guest-go') {
    post('action', { a: 'inviteGuest', id: $('guest-id').value });
    setTimeout(() => post('refresh'), 250);
  }
  if (e.target.id === 'ann-go') {
    post('action', { a: 'announce', text: $('ann').value });
    setTimeout(() => post('refresh'), 250);
  }
  if (e.target.id === 'g-create') {
    post('action', { a: 'adminCreate', name: $('g-name').value, label: $('g-label').value, tag: $('g-tag').value });
    setTimeout(() => post('refresh'), 250);
  }
  if (e.target.id === 'g-leader') {
    post('action', { a: 'adminSetLeader', gangId: $('g-sel').value, id: $('g-sid').value });
    setTimeout(() => post('refresh'), 250);
  }
  if (e.target.id === 'g-clear-leader') {
    post('action', { a: 'adminClearLeader', gangId: $('g-sel').value });
    setTimeout(() => post('refresh'), 250);
  }
  if (e.target.id === 'g-add') {
    post('action', { a: 'adminAddMember', gangId: $('g-sel').value, id: $('g-sid').value });
    setTimeout(() => post('refresh'), 250);
  }
  if (e.target.id === 'g-del') {
    post('action', { a: 'adminDelete', gangId: $('g-sel').value });
    setTimeout(() => post('refresh'), 250);
  }
  if (e.target.id === 'g-wipe') {
    post('action', { a: 'wipeGangSprays', gangId: $('g-sel').value });
    setTimeout(() => post('refresh'), 250);
  }
  if (e.target.id === 'g-pts-go') {
    post('action', { a: 'adminPoints', gangId: $('g-sel').value, points: $('g-pts').value });
    setTimeout(() => post('refresh'), 250);
  }
  if (e.target.id === 'wipe-all') {
    post('action', { a: 'wipeAllSprays' });
    setTimeout(() => post('refresh'), 250);
  }
};

$('summon-ok').onclick = () => post('acceptSummon');
$('summon-no').onclick = () => post('ignoreSummon');

function showSummon(d) {
  $('summon-title').textContent = (d.strings && d.strings.summon_banner) || t('summon_banner');
  $('summon-sub').textContent = d.caller || '';
  $('summon-ok').textContent = (d.strings && d.strings.accept) || t('accept');
  $('summon-no').textContent = (d.strings && d.strings.ignore) || t('ignore');
  $('summon').hidden = false;
}

const cv = $('cv');
const ctx = cv.getContext('2d');
let hex = '#c43b4a';

function clearCv() {
  ctx.fillStyle = '#0c0708';
  ctx.fillRect(0, 0, cv.width, cv.height);
  strokes = [];
}

function pt(e) {
  const r = cv.getBoundingClientRect();
  return { x: (e.clientX - r.left) / r.width, y: (e.clientY - r.top) / r.height };
}

cv.addEventListener('pointerdown', (e) => {
  if (sprayMode !== 'freehand') return;
  drawing = true;
  strokes.push([pt(e)]);
  cv.setPointerCapture(e.pointerId);
});
cv.addEventListener('pointermove', (e) => {
  if (!drawing) return;
  const p = pt(e);
  const line = strokes[strokes.length - 1];
  line.push(p);
  ctx.strokeStyle = hex;
  ctx.lineWidth = 4;
  ctx.lineCap = 'round';
  const a = line[line.length - 2];
  ctx.beginPath();
  ctx.moveTo(a.x * cv.width, a.y * cv.height);
  ctx.lineTo(p.x * cv.width, p.y * cv.height);
  ctx.stroke();
});
cv.addEventListener('pointerup', () => { drawing = false; });

$('mode-free').onclick = () => { sprayMode = 'freehand'; $('spray-text').hidden = true; };
$('mode-text').onclick = () => { sprayMode = 'text'; $('spray-text').hidden = false; };
$('spray-ok').onclick = () => {
  post('spraySubmit', { mode: sprayMode, text: $('spray-text').value, strokes });
  $('spray').hidden = true;
};
$('spray-cancel').onclick = () => { post('sprayCancel'); $('spray').hidden = true; };

window.addEventListener('keydown', (e) => {
  if (e.key !== 'Escape') return;
  if (!$('spray').hidden) { post('sprayCancel'); $('spray').hidden = true; }
  else if (!$('tablet').hidden) post('close');
});

window.addEventListener('message', (e) => {
  const d = e.data || {};
  if (d.action === 'openTablet') openTablet(d.data);
  if (d.action === 'close') $('tablet').hidden = true;
  if (d.action === 'toast') toast(d.data.text);
  if (d.action === 'summon') showSummon(d.data);
  if (d.action === 'hideSummon') $('summon').hidden = true;
  if (d.action === 'openSpray') {
    hex = (d.data && d.data.hex) || '#c43b4a';
    S.strings = (d.data && d.data.strings) || S.strings;
    $('mode-free').textContent = t('spray_free');
    $('mode-text').textContent = t('spray_text');
    $('spray-ok').textContent = t('spray_ok');
    $('spray-cancel').textContent = t('spray_cancel');
    $('spray-text').placeholder = t('text_placeholder');
    $('spray-text').value = '';
    sprayMode = 'freehand';
    $('spray-text').hidden = true;
    clearCv();
    $('spray').hidden = false;
  }
});

if (MOCK) {
  document.body.classList.add('mock');
  const strings = {
    tablet_title: 'WSMM GANGS', close: 'إغلاق', home: 'عصابتي', places: 'الخريطة',
    points: 'النقاط', rankings: 'ترتيب العصابات', members: 'أعضاء العصابة', summon: 'استدعاء كامل',
    guest: 'الدعوات', logs: 'السجلات', sprays: 'البخات', place: 'الترتيب',
    notifs: 'التنويهات',     map_legend: 'مناطق العصابات',
    map_hint: 'خريطة لوس سانتوس: المربع الملوّن = تيرف عصيبة. المتقطع = مفتوح فاضي. المقفول نظيف بدون رسم.',
    map_open_hint: 'الأدمن يفتح أو يقفل المطالبة. المقفول ما ينرسم على الخريطة وما ينأخذ.',
    zones_admin: 'المناطق (فتح / قفل)',
    zone_open: 'فتح', zone_lock: 'قفل',
    zone_open_state: 'مفتوحة للمطالبة', zone_locked_state: 'مقفلة',
    spray_hint: 'وضعين: رسم حر أو كتابة. بدون رفع صور. الكلام الوسخ ينحجب.',
    spray_wall_hint: 'البخ الحقيقي على الجدار بعلبة البخاخ. هالصفحة للتجربة داخل التابلت.',
    logs_only: 'السجلات لليدر والإدارة فقط.', request_icon: 'طلب الأيقونة',
    icon_upload_hint: 'ارفع صورة الأيقونة (PNG/JPEG). ما تظهر إلا بعد موافقة الأدمن.',
    upload_icon: 'رفع أيقونة', icon_blip_note: 'الأيقونة تظهر على الخريطة بعد الموافقة.',
    icon_preview: 'معاينة', icon_pending: 'بانتظار موافقة الأدمن',
    icon_image_pending: 'صورة مرفوعة', icon_bad_type: 'نوع الصورة غلط', icon_too_big: 'الصورة أكبر من المسموح',
    guest_no_spray: 'الضيف ما يقدر يبخ.', not_leader: 'هالخيار للقائد فقط.', not_admin: 'هالخيار للأدمن فقط.',
    no_notifs: 'ما في تنويهات.', all_sprays: 'كل البخاخات',
    activity_log: 'سجل النشاط', no_activity: 'ما في نشاط.', clear_leader: 'إزالة القائد',
    spray_log: 'سجل البخ', leader: 'قائمة الليدر', admin: 'قائمة الإدارة',
    spray: 'البخاخ', online: 'أونلاين', offline: 'غير متصل', connected: 'متصل', guest_tag: 'ضيف',
    owner: 'المسيطر', none: 'فاضي', send_summon: 'استدعاء العصابة كلها',
    summon_hint: 'كل الأعضاء الأونلاين ياخذون علامة على الخريطة.',
    invite_guest: 'دعوة ضيف (آيدي)', remove: 'إزالة', delete: 'حذف', announce: 'إعلان',
    set_hq: 'تعيين المقر هنا', color: 'اللون', icon: 'أيقونة الخريطة', pending: 'بانتظار الأدمن',
    promote: 'ترقية', demote: 'تنزيل', kick: 'طرد', create_gang: 'إنشاء عصابة',
    delete_gang: 'حذف العصابة', set_leader: 'تعيين قائد', add_member: 'إضافة عضو',
    wipe_gang_sprays: 'مسح بخاخات هالعصابة', wipe_all_sprays: 'مسح كل البخاخات',
    adjust_points: 'تعيين النقاط', approve: 'موافقة', reject: 'رفض',
    pending_icons: 'أيقونات معلّقة',
    mode_free: 'رسم حر', mode_text: 'نص', spray_free: 'ارسم', spray_text: 'اكتب',
    spray_ok: 'بخ', spray_cancel: 'إلغاء', text_placeholder: 'النص على الجدار',
    accept: 'قبول', ignore: 'تجاهل', summon_banner: 'استدعاء كامل للعصابة',
    lang: 'EN', name: 'الاسم', label: 'العنوان', tag: 'الوسم', no_log: 'ما في بخاخات',
    search_member: 'البحث عن عضو..', col_status: 'الحالة', col_name: 'الاسم', col_role: 'الدور',
    col_sprays: 'البخات', first: 'الأول', second: 'الثاني', third: 'الثالث', manage: 'إدارة',
    not_member: 'أنت مو في عصابة.', summon_need_rank: 'رتبتك ما تكفي.',
    act_create_gang: 'إنشاء عصابة', act_set_leader: 'تعيين قائد', act_summon: 'استدعاء كامل',
    act_icon_approve: 'قبول أيقونة', act_guest_invite: 'دعوة ضيف'
  };
  const isLeader = location.search.indexOf('member=1') === -1;
  const isAdmin = location.search.indexOf('member=1') === -1;
  openTablet({
    lang: 'ar', strings, isAdmin, isLeader, isGuest: false, isMember: true,
    gang: { id: 1, label: 'آل فخامة', tag: 'DARK', color: 'red', icon: 'skull', pendingIcon: 'crown', points: 35135, sprays: 12 },
    colors: [
      { id: 'red', hex: '#e74c3c', ar: 'أحمر', en: 'Red' },
      { id: 'green', hex: '#27ae60', ar: 'أخضر', en: 'Green' },
      { id: 'blue', hex: '#3498db', ar: 'أزرق', en: 'Blue' },
      { id: 'yellow', hex: '#e2b039', ar: 'أصفر', en: 'Yellow' },
      { id: 'purple', hex: '#9b59b6', ar: 'بنفسجي', en: 'Purple' }
    ],
    icons: [
      { id: 'gang', ar: 'عصابة', en: 'Gang' }, { id: 'skull', ar: 'جمجمة', en: 'Skull' },
      { id: 'crown', ar: 'تاج', en: 'Crown' }, { id: 'gun', ar: 'سلاح', en: 'Gun' }
    ],
    places: [
      { id: 'grove', label: 'قروف ستريت', owner: 'آل فخامة', hex: '#e74c3c', claimed: true, open: true, map: { x: 46.5, y: 55.5, w: 6.4, h: 6.2 } },
      { id: 'davis', label: 'ديفيس', owner: 'بلوود', hex: '#9b1c2c', claimed: true, open: true, map: { x: 51.4, y: 59.2, w: 6.4, h: 6.2 } },
      { id: 'strawberry', label: 'ستروبيري', owner: 'قولدن', hex: '#e2b039', claimed: true, open: true, map: { x: 47.2, y: 48.8, w: 6.2, h: 5.8 } },
      { id: 'vinewood', label: 'فاينوود', owner: 'آل تشابو', hex: '#e67e22', claimed: true, open: true, map: { x: 55.4, y: 15.6, w: 8.0, h: 7.2 } },
      { id: 'delperro', label: 'ديل بيرو', owner: null, claimed: false, open: true, map: { x: 16.8, y: 32.4, w: 8.8, h: 8.2 } },
      { id: 'mirror', label: 'ميرور بارك', owner: null, claimed: false, open: true, map: { x: 70.4, y: 31.4, w: 7.4, h: 7.0 } },
      { id: 'rancho', label: 'رانشو', owner: null, claimed: false, open: true, map: { x: 57.2, y: 64.4, w: 7.2, h: 6.8 } },
      { id: 'elburro', label: 'إل بورّو', owner: 'آل بارود', hex: '#9b59b6', claimed: true, open: true, map: { x: 75.4, y: 65.6, w: 8.6, h: 8.0 } },
      { id: 'chamberlain', label: 'تشامبرلين', owner: null, claimed: false, open: false, map: { x: 41.8, y: 51.8, w: 5.6, h: 5.6 } },
      { id: 'forum', label: 'فوروم درايف', owner: null, claimed: false, open: false, map: { x: 40.6, y: 57.4, w: 5.2, h: 5.2 } },
      { id: 'lamesa', label: 'لا ميسا', owner: null, claimed: false, open: true, map: { x: 65.8, y: 57.6, w: 7.2, h: 6.8 } },
      { id: 'cypress', label: 'سايبريس فلاتس', owner: null, claimed: false, open: true, map: { x: 64.8, y: 70.8, w: 7.6, h: 7.0 } },
      { id: 'sandy', label: 'ساندي شورز', owner: 'آل محترم', hex: '#3498db', claimed: true, open: true },
      { id: 'paleto', label: 'باليتو باي', owner: null, claimed: false, open: false }
    ],
    rankings: [
      { id: 1, label: 'آل فخامة', tag: 'DARK', points: 35135, sprays: 12, zones: 1, score: 35135 },
      { id: 2, label: 'بلوود', tag: 'BLOOD', points: 33645, sprays: 12, zones: 0, score: 33645 },
      { id: 3, label: 'قولدن', tag: 'GOLDEN', points: 32087, sprays: 11, zones: 0, score: 32087 },
      { id: 4, label: 'آل تشابو', tag: 'CHAPO', points: 25534, sprays: 10, zones: 0, score: 25534 },
      { id: 5, label: 'آل محترم', tag: 'M7TRM', points: 2500, sprays: 3, zones: 0, score: 2500 },
      { id: 6, label: 'آل بارود', tag: '90s', points: 150, sprays: 1, zones: 0, score: 150 }
    ],
    members: [
      { identifier: 'a', name: 'محمد بن نايف', rank: 1, rankLabel: 'عضو', online: true, sprays: 4 },
      { identifier: 'b', name: 'أنس الزهراني', rank: 1, rankLabel: 'عضو', online: true, sprays: 1 },
      { identifier: 'c', name: 'قولدن تصوير', rank: 5, rankLabel: 'قائد', online: true, sprays: 9 },
      { identifier: 'd', name: 'طارق بن عبدالله', rank: 1, rankLabel: 'عضو', online: true, sprays: 0 },
      { identifier: 'e', name: 'محمد المطيري', rank: 4, rankLabel: 'نائب القائد', online: true, sprays: 2 }
    ],
    guests: [{ identifier: 'g', name: 'ضيف تجريبي' }],
    notifs: [
      { title: 'summon_banner', message: 'قولدن تصوير', created_at: 'الآن' },
      { title: 'rival_spray', message: 'قروف ستريت', created_at: 'قبل شوي' },
      { title: 'icon_approved', message: 'تاج', created_at: 'أمس' }
    ],
    sprayLog: isLeader ? [{ id: 1, player_name: 'حمود', mode: 'text', text_content: 'WLF', x: 1, y: 2, created_at: 'الآن' }] : null,
    activityLog: isLeader ? [{ actor_name: 'أدمن', action: 'set_leader', detail: 'حمود', created_at: 'الآن' }] : null,
    adminSprays: [{ id: 1, gang_label: 'آل فخامة', player_name: 'حمود', mode: 'freehand', created_at: 'الآن' }],
    pendingIcons: [{ id: 1, label: 'آل فخامة', current: 'skull', pending: 'crown' }],
    gangs: [{ id: 1, label: 'آل فخامة' }]
  });
}
