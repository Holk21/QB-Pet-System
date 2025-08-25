let state = {
  animals: [],
  items: { food:[], drink:[], health:[] },
  pets: [],
  selectedPetId: null
};

const wrap = document.getElementById('wrap');
const closeBtn = document.getElementById('closeBtn');

// Helper to post back to Lua
function send(name, data = {}) {
  fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
}

// Simple card builder
function card(html) {
  const div = document.createElement('div');
  div.className = 'card';
  div.innerHTML = html;
  return div;
}

// DRAGGABLE PANEL
function enableDrag() {
  const panel = document.querySelector('.panel');
  const header = document.querySelector('.header');
  let dragging = false;
  let sx = 0, sy = 0, startLeft = 0, startTop = 0;

  function getPanelPos() {
    const rect = panel.getBoundingClientRect();
    return { left: rect.left, top: rect.top };
  }

  function setPanelPos(l, t) {
    panel.style.left = l + 'px';
    panel.style.top = t + 'px';
    panel.style.transform = 'translate(0,0)';
  }

  try {
    const saved = JSON.parse(localStorage.getItem('petshop_panel_pos') || 'null');
    if (saved && typeof saved.left === 'number' && typeof saved.top === 'number') {
      setPanelPos(saved.left, saved.top);
    }
  } catch (e) {}

  header.addEventListener('mousedown', (e) => {
    if (e.target && (e.target.id === 'closeBtn' || e.target.closest('#closeBtn'))) return;
    dragging = true;
    const pos = getPanelPos();
    sx = e.clientX; sy = e.clientY;
    startLeft = pos.left; startTop = pos.top;
    document.body.style.userSelect = 'none';
  });

  window.addEventListener('mousemove', (e) => {
    if (!dragging) return;
    const dx = e.clientX - sx;
    const dy = e.clientY - sy;
    let nl = startLeft + dx;
    let nt = startTop + dy;

    const bw = 16;
    const maxL = window.innerWidth - panel.offsetWidth + bw;
    const maxT = window.innerHeight - panel.offsetHeight + bw;
    nl = Math.max(-bw, Math.min(nl, maxL));
    nt = Math.max(-bw, Math.min(nt, maxT));

    setPanelPos(nl, nt);
  });

  window.addEventListener('mouseup', () => {
    if (!dragging) return;
    dragging = false;
    document.body.style.userSelect = '';
    const rect = panel.getBoundingClientRect();
    localStorage.setItem('petshop_panel_pos', JSON.stringify({ left: rect.left, top: rect.top }));
  });
}

// TABS
function setTab(name) {
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  document.querySelectorAll('.tabview').forEach(v => v.classList.remove('active'));
  const tabBtn = document.querySelector(`.tab[data-tab="${name}"]`);
  const tabView = document.getElementById(`tab-${name}`);
  if (tabBtn) tabBtn.classList.add('active');
  if (tabView) tabView.classList.add('active');
}

// RENDERERS
function mountAnimals() {
  const root = document.getElementById('tab-animals');
  if (!root) return;
  root.innerHTML = '';
  (state.animals || []).forEach(a => {
    const el = card(`
      <h3>${a.label}</h3>
      <p>A loyal companion.</p>
      <div class="row">
        <span class="price">$${a.price}</span>
        <button class="btn buy-pet" data-key="${a.key}">Buy</button>
      </div>
    `);
    root.appendChild(el);
  });
  root.querySelectorAll('.buy-pet').forEach(b => {
    b.addEventListener('click', () => send('buyPet', { key: b.dataset.key }));
  });
}

function mountItems() {
  const f = document.getElementById('tab-food');
  const h = document.getElementById('tab-health');
  if (!f || !h) return;
  f.innerHTML = '';
  h.innerHTML = '';

  const allFD = [
    ...(state.items.food || []).map(i => ({...i, cat:'Food'})),
    ...(state.items.drink || []).map(i => ({...i, cat:'Drink'})),
  ];

  allFD.forEach(i => {
    const el = card(`
      <h3>${i.label}</h3>
      <p class="small">${i.cat}</p>
      <div class="row">
        <span class="price">$${i.price}</span>
        <button class="btn buy-item" data-name="${i.name}">Buy</button>
      </div>
    `);
    f.appendChild(el);
  });

  (state.items.health || []).forEach(i => {
    const el = card(`
      <h3>${i.label}</h3>
      <p>Heal your pet.</p>
      <div class="row">
        <span class="price">$${i.price}</span>
        <button class="btn buy-item" data-name="${i.name}">Buy</button>
      </div>
    `);
    h.appendChild(el);
  });

  document.querySelectorAll('.buy-item').forEach(b => {
    b.addEventListener('click', () => send('buyItem', { name: b.dataset.name }));
  });
}

function mountOwned() {
  const root = document.getElementById('tab-owned');
  if (!root) return;
  root.innerHTML = '';
  (state.pets || []).forEach(p => {
    const el = card(`
      <h3>${p.pet_name}</h3>
      <p>H:${p.hunger || 100} T:${p.thirst || 100} HP:${p.health || 100}</p>
      <span class="badge">${p.out_state == 1 ? 'Out' : 'Stowed'}</span>
    `);
    root.appendChild(el);
  });
}

function mountControl() {
  const root = document.getElementById('tab-control');
  if (!root) return;
  root.innerHTML = '';

  const picker = document.createElement('div');
  picker.className = 'card';
  let options = (state.pets || []).map(p => `<option value="${p.id}">${p.pet_name} (H:${p.hunger||100} T:${p.thirst||100} HP:${p.health||100})</option>`).join('');
  if (!state.selectedPetId && state.pets && state.pets[0]) state.selectedPetId = String(state.pets[0].id);
  picker.innerHTML = `
    <h3>Choose Pet</h3>
    <div class="row">
      <select id="petSelect" style="flex:1; padding:8px; background:#0b121a; color:#c6d4e3; border:1px solid #253348; border-radius:8px;">
        ${options}
      </select>
      <button class="btn" id="spawnBtn">Spawn</button>
    </div>
    <p class="small">Use buttons below to control your pet.</p>
  `;
  root.appendChild(picker);

  const btns = document.createElement('div');
  btns.className = 'card';
  btns.innerHTML = `
    <div class="row" style="flex-wrap:wrap; gap:8px">
      <button class="btn" data-act="PutAway">Put Away</button>
      <button class="btn" data-act="Bring">Bring</button>
      <button class="btn" data-act="Follow">Follow</button>
      <button class="btn" data-act="Stay">Stay</button>
      <button class="btn" data-act="Sit">Sit</button>
      <button class="btn" data-act="Lie">Lie Down</button>
      <button class="btn" data-act="Play">Play</button>
      <button class="btn" data-act="Feed">Feed</button>
      <button class="btn" data-act="Drink">Give Water</button>
      <button class="btn" data-act="Med">Use Medkit</button>
      <button class="btn" data-act="Carry">Carry</button>
      <button class="btn" data-act="PutInCar">Put In Car</button>
    </div>`;
  root.appendChild(btns);

  const sel = picker.querySelector('#petSelect');
  if (state.selectedPetId) sel.value = String(state.selectedPetId);
  sel.addEventListener('change', () => state.selectedPetId = sel.value);

  picker.querySelector('#spawnBtn').addEventListener('click', () => {
    state.selectedPetId = sel.value;
    send('petAction', { action: 'Spawn', id: parseInt(state.selectedPetId) });
  });

  btns.querySelectorAll('.btn').forEach(b => {
    b.addEventListener('click', () => {
      const act = b.dataset.act;
      send('petAction', { action: act, id: state.selectedPetId ? parseInt(state.selectedPetId) : null });
    });
  });
}

// Tab button listeners
document.querySelectorAll('.tab').forEach(tab => {
  tab.addEventListener('click', () => setTab(tab.dataset.tab));
});

// Close button
let uiOpen = false;
closeBtn.addEventListener('click', () => {
  send('close');
  wrap.classList.add('hidden');
  wrap.style.display = 'none';
  uiOpen = false;
});

// Messages from Lua
window.addEventListener('message', (e) => {
  const data = e.data;

  if (data.action === 'open') {
    state.animals = data.animals || [];
    state.items = data.items || { food:[], drink:[], health:[] };
    mountAnimals();
    mountItems();
    setTab('animals');
    wrap.classList.remove('hidden');
    wrap.style.display = 'block';
    uiOpen = true;
    enableDrag();
    send('initPets');
  }

  if (data.action === 'openPetPanel') {
    setTab('control');
    wrap.classList.remove('hidden');
    wrap.style.display = 'block';
    uiOpen = true;
    enableDrag();
  }

  if (data.action === 'pets') {
    state.pets = data.pets || [];
    mountOwned();
    mountControl();
  }
});
