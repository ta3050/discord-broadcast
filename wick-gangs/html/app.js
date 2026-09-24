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
  document.body.classList.toggle('rtl', lang === 'ar');
  document.body.classList.toggle('ltr', lang !== 'ar');
  document.documentElement.lang = lang;
}

function navItems() {
  const items = [
    ['home', 'home'],
    ['places', 'places'],
    ['rankings', 'rankings'],
    ['members', 'members'],
    ['summon', 'summon'],
    ['guest', 'guest'],
    ['notifs', 'notifs']
  ];
  if (S.isLeader) items.push(['spraylog', 'spray_log'], ['leader', 'leader']);
  if (S.isAdmin) items.push(['admin', 'admin']);
  return items;
}

function renderNav() {
  $('nav').innerHTML = navItems().map(([id, key]) =>
    `<button data-page="${id}" data-on="${page === id ? 1 : 0}">${t(key)}</button>`
  ).join('');
}

function esc(s) {
  return String(s == null ? '' : s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');
}

function colorHex(id) {
  const c = (S.colors || []).find((x) => x.id === id);
  return c ? c.hex : '#e74c3c';
}

function iconLabel(id) {
  const ic = (S.icons || []).find((x) => x.id === id);
  if (!ic) return id || '';
  return lang === 'ar' ? ic.ar : ic.en;
}

function home() {
  const g = S.gang;
  if (!g) return `<div class="card">${t('not_member')}</div>`;
  return `<div class="card">
    <div>${esc(g.label)} <span class="muted">${esc(g.tag)}</span></div>
    <div class="muted">${t('points')}: ${g.points || 0} · ${t('spray')}: ${g.sprays || 0}</div>
    <div class="muted">${t('icon')}: ${esc(iconLabel(g.icon))}
      ${g.pendingIcon ? ' · ' + t('pending') + ': ' + esc(iconLabel(g.pendingIcon)) : ''}</div>
  </div>`;
}

function places() {
  return (S.places || []).map((z) => `<div class="card">
    <div>${esc(z.label)}</div>
    <div class="muted">${t('owner')}: ${esc(z.owner || t('none'))}</div>
  </div>`).join('') || `<div class="card">${t('none')}</div>`;
}

function rankings() {
  return (S.rankings || []).map((g, i) => `<div class="card">
    <div>#${i + 1} ${esc(g.label)} <span class="muted">${esc(g.tag)}</span></div>
    <div class="muted">${t('points')} ${g.points} · ${t('spray')} ${g.sprays} · ${t('places')} ${g.zones} · ${g.score}</div>
  </div>`).join('') || `<div class="card">${t('none')}</div>`;
}

function members() {
  return (S.members || []).map((m) => `<div class="card">
    <span class="dot ${m.online ? 'on' : 'off'}"></span>
    ${esc(m.name)} · ${esc(m.rankLabel)}
    <span class="muted">${m.online ? t('online') : t('offline')}${m.guest ? ' · ' + t('guest_tag') : ''}</span>
  </div>`).join('') || `<div class="card">${t('none')}</div>`;
}

function summon() {
  if (S.isGuest) return `<div class="card">${t('summon_need_rank')}</div>`;
  return `<div class="card">
    <p>${t('summon_hint')}</p>
    <button class="ok" data-act='{"a":"summon"}'>${t('send_summon')}</button>
  </div>`;
}

function guest() {
  let html = '';
  if (S.isLeader) {
    html += `<div class="card">
      <input id="guest-id" placeholder="${t('invite_guest')}"/>
      <button class="ok" id="guest-go">${t('invite_guest')}</button>
    </div>`;
  }
  html += (S.guests || []).map((g) => `<div class="card">
    ${esc(g.name)}
    ${S.isLeader ? `<button data-act='{"a":"removeGuest","identifier":"${esc(g.identifier)}"}'>${t('remove')}</button>` : ''}
  </div>`).join('') || `<div class="card">${t('none')}</div>`;
  return html;
}

function notifs() {
  return (S.notifs || []).map((n) => `<div class="card">
    <div>${esc(n.title)}</div>
    <div class="muted">${esc(n.message)} · ${esc(n.created_at || '')}</div>
  </div>`).join('') || `<div class="card">${t('no_notifs')}</div>`;
}

function spraylog() {
  if (!S.isLeader && !S.isAdmin) return '';
  const rows = S.sprayLog || [];
  if (!rows.length) return `<div class="card">${t('no_log')}</div>`;
  return rows.map((r) => `<div class="card">
    <div>${esc(r.player_name)} · ${r.mode === 'text' ? t('mode_text') : t('mode_free')}</div>
    <div class="muted">${esc(r.text_content || '')} · ${esc(r.zone_id || '')} · ${esc(r.created_at || '')}</div>
    <div class="muted">${Number(r.x).toFixed(1)}, ${Number(r.y).toFixed(1)}</div>
    <button data-act='{"a":"deleteSpray","id":${r.id}}'>${t('delete')}</button>
  </div>`).join('');
}

function leader() {
  if (!S.isLeader) return '';
  const icons = (S.icons || []).map((ic) =>
    `<button data-act='{"a":"requestIcon","icon":"${ic.id}"}'>${lang === 'ar' ? ic.ar : ic.en}</button>`
  ).join('');
  const colors = (S.colors || []).map((c) =>
    `<button data-act='{"a":"setColor","color":"${c.id}"}' style="background:${c.hex};color:#111">${lang === 'ar' ? c.ar : c.en}</button>`
  ).join('');
  const mem = (S.members || []).filter((m) => !m.guest).map((m) => `<div class="card">
    ${esc(m.name)} · ${esc(m.rankLabel)}
    <button data-act='{"a":"setRank","identifier":"${esc(m.identifier)}","rank":${Math.min((m.rank || 1) + 1, 4)}}'>${t('promote')}</button>
    <button data-act='{"a":"setRank","identifier":"${esc(m.identifier)}","rank":${Math.max((m.rank || 1) - 1, 1)}}'>${t('demote')}</button>
    <button data-act='{"a":"kick","identifier":"${esc(m.identifier)}"}'>${t('kick')}</button>
  </div>`).join('');
  return `<div class="card"><button class="ok" data-act='{"a":"setHQ"}'>${t('set_hq')}</button></div>
    <div class="card">${t('color')}<div class="row">${colors}</div></div>
    <div class="card">${t('icon')}<div class="row">${icons}</div>
      <div class="muted">${t('pending')}</div></div>
    <div class="card"><input id="ann" placeholder="${t('announce')}"/><button id="ann-go">${t('announce')}</button></div>
    <div class="card"><button data-act='{"a":"wipeGangSprays"}'>${t('wipe_gang_sprays')}</button></div>
    ${mem}`;
}

function admin() {
  if (!S.isAdmin) return '';
  const gangs = (S.gangs || []).map((g) => `<option value="${g.id}">${esc(g.label)}</option>`).join('');
  const pending = (S.pendingIcons || []).map((p) => `<div class="card">
    ${esc(p.label)}: ${esc(iconLabel(p.current))} → ${esc(iconLabel(p.pending))}
    <button class="ok" data-act='{"a":"approveIcon","gangId":${p.id}}'>${t('approve')}</button>
    <button data-act='{"a":"rejectIcon","gangId":${p.id}}'>${t('reject')}</button>
  </div>`).join('') || `<div class="card">${t('none')}</div>`;
  const logs = (S.adminSprays || []).map((r) => `<div class="card">
    <div>${esc(r.gang_label)} · ${esc(r.player_name)} · ${r.mode === 'text' ? t('mode_text') : t('mode_free')}</div>
    <div class="muted">${esc(r.text_content || '')} · ${esc(r.created_at || '')}</div>
    <button data-act='{"a":"deleteSpray","id":${r.id}}'>${t('delete')}</button>
  </div>`).join('') || `<div class="card">${t('no_log')}</div>`;
  return `<div class="card">
      <input id="g-name" placeholder="${t('name')}"/>
      <input id="g-label" placeholder="${t('label')}"/>
      <input id="g-tag" placeholder="${t('tag')}"/>
      <button class="ok" id="g-create">${t('create_gang')}</button>
    </div>
    <div class="card">
      <select id="g-sel">${gangs}</select>
      <input id="g-sid" placeholder="ID"/>
      <button id="g-leader">${t('set_leader')}</button>
      <button id="g-add">${t('add_member')}</button>
      <button id="g-del">${t('delete_gang')}</button>
      <button id="g-wipe">${t('wipe_gang_sprays')}</button>
      <input id="g-pts" placeholder="${t('points')}"/>
      <button id="g-pts-go">${t('adjust_points')}</button>
    </div>
    <div class="card"><button id="wipe-all">${t('wipe_all_sprays')}</button></div>
    <h4>${t('pending_icons')}</h4>${pending}
    <h4>${t('all_sprays')}</h4>${logs}`;
}

const views = { home, places, rankings, members, summon, guest, notifs, spraylog, leader, admin };

function render() {
  const g = S.gang;
  $('gang-name').textContent = g ? g.label : t('tablet_title');
  $('gang-meta').textContent = g ? `${t('points')} ${g.points || 0}` : '';
  document.getElementById('tablet').style.setProperty('--gang', g ? colorHex(g.color) : '#c0392b');
  $('btn-lang').textContent = t('lang');
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
  render();
}

$('btn-close').onclick = () => { $('tablet').hidden = true; post('close'); };
$('btn-lang').onclick = () => {
  lang = lang === 'ar' ? 'en' : 'ar';
  post('setLang', { lang }).then((r) => {
    if (r && r.strings) S.strings = r.strings;
    else S.strings = lang === 'ar' ? S.strings : S.strings;
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
let hex = '#e74c3c';

function clearCv() {
  ctx.fillStyle = '#0c0c0c';
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

$('mode-free').onclick = () => {
  sprayMode = 'freehand';
  $('spray-text').hidden = true;
};
$('mode-text').onclick = () => {
  sprayMode = 'text';
  $('spray-text').hidden = false;
};
$('spray-ok').onclick = () => {
  post('spraySubmit', { mode: sprayMode, text: $('spray-text').value, strokes });
  $('spray').hidden = true;
};
$('spray-cancel').onclick = () => {
  post('sprayCancel');
  $('spray').hidden = true;
};

window.addEventListener('keydown', (e) => {
  if (e.key !== 'Escape') return;
  if (!$('spray').hidden) {
    post('sprayCancel');
    $('spray').hidden = true;
  } else if (!$('tablet').hidden) {
    post('close');
  }
});

window.addEventListener('message', (e) => {
  const d = e.data || {};
  if (d.action === 'openTablet') openTablet(d.data);
  if (d.action === 'close') $('tablet').hidden = true;
  if (d.action === 'toast') toast(d.data.text);
  if (d.action === 'summon') showSummon(d.data);
  if (d.action === 'hideSummon') $('summon').hidden = true;
  if (d.action === 'openSpray') {
    hex = (d.data && d.data.hex) || '#e74c3c';
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
  const strings = {
    tablet_title: 'تابلت العصابة', close: 'إغلاق', home: 'الرئيسية', places: 'الأماكن',
    points: 'النقاط', rankings: 'الترتيب', members: 'الأعضاء', summon: 'استدعاء كامل',
    guest: 'ضيف', notifs: 'تنويهات', spray_log: 'سجل البخ', leader: 'القائد', admin: 'أدمن',
    spray: 'بخاخ', online: 'أونلاين', offline: 'أوفلاين', guest_tag: 'ضيف',
    owner: 'المسيطر', none: 'فاضي', send_summon: 'استدعاء العصابة كلها',
    summon_hint: 'كل الأعضاء الأونلاين ياخذون علامة على الخريطة.',
    invite_guest: 'دعوة ضيف (آيدي)', remove: 'إزالة', delete: 'حذف', announce: 'إعلان',
    set_hq: 'تعيين المقر هنا', color: 'اللون', icon: 'أيقونة الخريطة', pending: 'بانتظار الأدمن',
    promote: 'ترقية', demote: 'تنزيل', kick: 'طرد', create_gang: 'إنشاء عصابة',
    delete_gang: 'حذف العصابة', set_leader: 'تعيين قائد', add_member: 'إضافة عضو',
    wipe_gang_sprays: 'مسح بخاخات هالعصابة', wipe_all_sprays: 'مسح كل البخاخات',
    adjust_points: 'تعيين النقاط', approve: 'موافقة', reject: 'رفض',
    pending_icons: 'أيقونات معلّقة', all_sprays: 'كل البخاخات',
    mode_free: 'رسم حر', mode_text: 'نص', spray_free: 'ارسم', spray_text: 'اكتب',
    spray_ok: 'بخ', spray_cancel: 'إلغاء', text_placeholder: 'النص على الجدار',
    accept: 'قبول', ignore: 'تجاهل', summon_banner: 'استدعاء كامل للعصابة',
    lang: 'EN / عربي', name: 'الاسم', label: 'العنوان', tag: 'الوسم', no_log: 'ما في بخاخات',
    no_notifs: 'ما في تنويهات', not_member: 'أنت مو في عصابة.', summon_need_rank: 'رتبتك ما تكفي.'
  };
  const isLeader = location.search.indexOf('member=1') === -1;
  const isAdmin = location.search.indexOf('member=1') === -1;
  openTablet({
    lang: 'ar', strings, isAdmin, isLeader, isGuest: false, isMember: true,
    gang: { id: 1, label: 'الذيب', tag: 'WLF', color: 'red', icon: 'skull', pendingIcon: 'crown', points: 42, sprays: 3 },
    colors: [{ id: 'red', hex: '#e74c3c', ar: 'أحمر', en: 'Red' }, { id: 'blue', hex: '#3498db', ar: 'أزرق', en: 'Blue' }],
    icons: [{ id: 'skull', ar: 'جمجمة', en: 'Skull' }, { id: 'crown', ar: 'تاج', en: 'Crown' }, { id: 'gang', ar: 'عصابة', en: 'Gang' }],
    places: [{ label: 'قروف ستريت', owner: 'الذيب' }, { label: 'ديفيس', owner: null }],
    rankings: [{ label: 'الذيب', tag: 'WLF', points: 42, sprays: 3, zones: 1, score: 56 }],
    members: [
      { identifier: 'a', name: 'حمود', rank: 5, rankLabel: 'قائد', online: true },
      { identifier: 'b', name: 'سالم', rank: 1, rankLabel: 'عضو', online: false }
    ],
    guests: [{ identifier: 'c', name: 'ضيف تجريبي' }],
    notifs: [{ title: 'استدعاء كامل', message: 'حمود', created_at: 'الآن' }],
    sprayLog: [{ id: 1, player_name: 'حمود', mode: 'text', text_content: 'WLF', x: 1, y: 2, created_at: 'الآن' }],
    adminSprays: [{ id: 1, gang_label: 'الذيب', player_name: 'حمود', mode: 'freehand', created_at: 'الآن' }],
    pendingIcons: [{ id: 1, label: 'الذيب', current: 'skull', pending: 'crown' }],
    gangs: [{ id: 1, label: 'الذيب' }]
  });
  if (location.search.indexOf('spray=1') !== -1) {
    $('spray').hidden = false;
    $('mode-free').textContent = 'ارسم';
    $('mode-text').textContent = 'اكتب';
    $('spray-ok').textContent = 'بخ';
    $('spray-cancel').textContent = 'إلغاء';
    clearCv();
  }
}
