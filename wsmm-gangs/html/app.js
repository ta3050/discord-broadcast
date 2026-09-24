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
    ['places', 'places'],
    ['summon', 'summon']
  ];
  if (S.isLeader || S.isAdmin) items.push(['logs', 'logs']);
  if (S.isLeader) items.push(['leader', 'leader']);
  if (S.isAdmin) items.push(['admin', 'admin']);
  return items;
}

const NAV_ICONS = {
  home: '👥', members: '👤', guest: '✉', rankings: '🏆',
  places: '🗺', summon: '📢', logs: '📋', leader: '⚙', admin: '🛡'
};

function renderNav() {
  $('nav').innerHTML = navItems().map(([id, key]) =>
    `<button class="nav ${page === id ? 'active' : ''}" data-page="${id}"><span class="nav-ic">${NAV_ICONS[id] || ''}</span>${t(key)}</button>`
  ).join('');
}

function esc(s) {
  return String(s == null ? '' : s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');
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
    places: 'places', summon: 'summon', logs: 'logs', leader: 'leader', admin: 'admin'
  };
  return t(map[page] || 'home');
}

function home() {
  const g = S.gang;
  if (!g) return `<div class="card">${t('not_member')}</div>`;
  const rank = (S.rankings || []).findIndex((x) => x.id === g.id);
  return `<div class="cards">
      <div class="card">${t('points')}<b>${g.points || 0}</b></div>
      <div class="card">${t('sprays')}<b>${g.sprays || 0}</b></div>
      <div class="card">${t('place')}<b>#${rank >= 0 ? rank + 1 : '—'}</b></div>
    </div>
    <div class="card">${esc(g.label)} <span class="tag">[${esc(g.tag || '')}]</span>
      <div class="xp">${t('color')}: ${esc(g.color || '')}
        ${(S.isLeader || S.isAdmin) && g.pendingIcon ? ' · ' + t('pending') + ': ' + esc(iconLabel(g.pendingIcon)) : ''}
      </div>
    </div>`;
}

function places() {
  const zones = S.places || [];
  if (!zones.length) return `<div class="card">${t('none')}</div>`;
  return `<div class="zones">${zones.map((z) => `<div class="zone"><b>${esc(z.label)}</b>
    <div class="xp">${t('owner')}: ${esc(z.owner || t('none'))}</div></div>`).join('')}</div>`;
}

function rankings() {
  const list = S.rankings || [];
  if (!list.length) return `<div class="card">${t('none')}</div>`;
  const a = list[0], b = list[1], c = list[2];
  const rest = list.slice(3);
  const spot = (g, cls, place, medal) => {
    if (!g) return `<div class="spot ${cls}"></div>`;
    return `<div class="spot ${cls}">
      <div class="avatar">${medal}</div>
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

function logs() {
  if (!S.isLeader && !S.isAdmin) return '';
  const sprays = S.isAdmin ? (S.adminSprays || S.sprayLog || []) : (S.sprayLog || []);
  const acts = S.activityLog || [];
  let html = `<div class="log"><b>${t('spray_log')}</b></div>`;
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

function leader() {
  if (!S.isLeader) return '';
  const icons = (S.icons || []).map((ic) =>
    `<button data-act='{"a":"requestIcon","icon":"${ic.id}"}'>${lang === 'ar' ? ic.ar : ic.en}</button>`
  ).join('');
  const colors = (S.colors || []).map((c) =>
    `<button data-act='{"a":"setColor","color":"${c.id}"}' style="background:${c.hex};color:#111">${lang === 'ar' ? c.ar : c.en}</button>`
  ).join('');
  const mem = (S.members || []).filter((m) => !m.guest).map((m) => `<div class="log">
    ${esc(m.name)} · ${esc(m.rankLabel)}
    <button data-act='{"a":"setRank","identifier":"${esc(m.identifier)}","rank":${Math.min((m.rank || 1) + 1, 4)}}'>${t('promote')}</button>
    <button data-act='{"a":"setRank","identifier":"${esc(m.identifier)}","rank":${Math.max((m.rank || 1) - 1, 1)}}'>${t('demote')}</button>
    <button class="manage" data-act='{"a":"kick","identifier":"${esc(m.identifier)}"}'>${t('kick')}</button>
  </div>`).join('');
  return `<div class="card"><button class="btn" data-act='{"a":"setHQ"}'>${t('set_hq')}</button></div>
    <div class="card">${t('color')}<div class="row">${colors}</div></div>
    <div class="card">${t('icon')}<div class="row">${icons}</div><div class="xp">${t('pending')}</div></div>
    <div class="card"><input id="ann" placeholder="${t('announce')}"/><button class="btn" id="ann-go">${t('announce')}</button></div>
    <div class="card"><button data-act='{"a":"wipeGangSprays"}'>${t('wipe_gang_sprays')}</button></div>
    ${mem}`;
}

function admin() {
  if (!S.isAdmin) return '';
  const gangs = (S.gangs || []).map((g) => `<option value="${g.id}">${esc(g.label)}</option>`).join('');
  const pending = (S.pendingIcons || []).map((p) => `<div class="log">
    ${esc(p.label)}: ${esc(iconLabel(p.current))} → ${esc(iconLabel(p.pending))}
    <button class="btn" data-act='{"a":"approveIcon","gangId":${p.id}}'>${t('approve')}</button>
    <button data-act='{"a":"rejectIcon","gangId":${p.id}}'>${t('reject')}</button>
  </div>`).join('') || `<div class="xp">${t('none')}</div>`;
  return `<div class="card">
      <input id="g-name" placeholder="${t('name')}"/>
      <input id="g-label" placeholder="${t('label')}"/>
      <input id="g-tag" placeholder="${t('tag')}"/>
      <button class="btn" id="g-create">${t('create_gang')}</button>
    </div>
    <div class="card">
      <select id="g-sel">${gangs}</select>
      <input id="g-sid" placeholder="ID"/>
      <button id="g-leader">${t('set_leader')}</button>
      <button id="g-clear-leader">${t('clear_leader')}</button>
      <button id="g-add">${t('add_member')}</button>
      <button class="manage" id="g-del">${t('delete_gang')}</button>
      <button id="g-wipe">${t('wipe_gang_sprays')}</button>
      <input id="g-pts" placeholder="${t('points')}"/>
      <button id="g-pts-go">${t('adjust_points')}</button>
    </div>
    <div class="card"><button class="manage" id="wipe-all">${t('wipe_all_sprays')}</button></div>
    <div class="log"><b>${t('pending_icons')}</b></div>${pending}`;
}

const views = { home, places, rankings, members: membersView, summon, guest, logs, leader, admin };

function render() {
  const g = S.gang;
  document.getElementById('tablet').style.setProperty('--gang', g ? colorHex(g.color) : '#c43b4a');
  $('page-title').textContent = pageTitle();
  $('btn-lang').textContent = t('lang');
  $('search').placeholder = t('search_member');
  $('search').classList.toggle('hidden', page !== 'members');
  renderNav();
  $('page').innerHTML = (views[page] || home)();
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
    if (q && views[q]) page = q;
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
    activity_log: 'سجل النشاط', no_activity: 'ما في نشاط.', clear_leader: 'إزالة القائد',
    spray_log: 'سجل البخ', leader: 'القائد', admin: 'أدمن',
    spray: 'بخة', online: 'أونلاين', offline: 'غير متصل', connected: 'متصل', guest_tag: 'ضيف',
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
    colors: [{ id: 'red', hex: '#c43b4a', ar: 'أحمر', en: 'Red' }, { id: 'blue', hex: '#3498db', ar: 'أزرق', en: 'Blue' }],
    icons: [{ id: 'skull', ar: 'جمجمة', en: 'Skull' }, { id: 'crown', ar: 'تاج', en: 'Crown' }],
    places: [{ label: 'قروف ستريت', owner: 'آل فخامة' }, { label: 'ديفيس', owner: null }, { label: 'ساندي شورز', owner: null }, { label: 'باليتو باي', owner: null }],
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
    sprayLog: isLeader ? [{ id: 1, player_name: 'حمود', mode: 'text', text_content: 'WLF', x: 1, y: 2, created_at: 'الآن' }] : null,
    activityLog: isLeader ? [{ actor_name: 'أدمن', action: 'set_leader', detail: 'حمود', created_at: 'الآن' }] : null,
    adminSprays: [{ id: 1, gang_label: 'آل فخامة', player_name: 'حمود', mode: 'freehand', created_at: 'الآن' }],
    pendingIcons: [{ id: 1, label: 'آل فخامة', current: 'skull', pending: 'crown' }],
    gangs: [{ id: 1, label: 'آل فخامة' }]
  });
}
