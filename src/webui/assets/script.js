let callbackCounter = 0;
function getUniqueCallbackName(prefix) {
  return `${prefix}_callback_${Date.now()}_${callbackCounter++}`;
}

function ksuExec(command, options) {
  if (typeof options === "undefined") {
    options = {};
  }

  return new Promise((resolve, reject) => {
    // Generate a unique callback function name
    const callbackFuncName = getUniqueCallbackName("exec");

    // Define the success callback function
    window[callbackFuncName] = (errno, stdout, stderr) => {
      resolve({ errno, stdout, stderr });
      cleanup(callbackFuncName);
    };

    function cleanup(successName) {
      delete window[successName];
    }

    try {
      if (typeof ksu === "undefined" || typeof ksu.exec !== "function") {
        throw new Error("ksu.exec bridge is not available on this manager");
      }
      ksu.exec(command, JSON.stringify(options), callbackFuncName);
    } catch (error) {
      reject(error);
      cleanup(callbackFuncName);
    }
  });
}

function Stdio() {
    this.listeners = {};
  }

  Stdio.prototype.on = function (event, listener) {
    if (!this.listeners[event]) {
      this.listeners[event] = [];
    }
    this.listeners[event].push(listener);
  };

  Stdio.prototype.emit = function (event, ...args) {
    if (this.listeners[event]) {
      this.listeners[event].forEach((listener) => listener(...args));
    }
  };

  function ChildProcess() {
    this.listeners = {};
    this.stdin = new Stdio();
    this.stdout = new Stdio();
    this.stderr = new Stdio();
  }

  ChildProcess.prototype.on = function (event, listener) {
    if (!this.listeners[event]) {
      this.listeners[event] = [];
    }
    this.listeners[event].push(listener);
  };

  ChildProcess.prototype.emit = function (event, ...args) {
    if (this.listeners[event]) {
      this.listeners[event].forEach((listener) => listener(...args));
    }
  };

  function spawn(command, args, options) {
    if (typeof args === "undefined") {
      args = [];
    } else if (!(args instanceof Array)) {
        // allow for (command, options) signature
        options = args;
        args = [];
    }

    if (typeof options === "undefined") {
      options = {};
    }

    const child = new ChildProcess();
    const childCallbackName = getUniqueCallbackName("spawn");
    window[childCallbackName] = child;

    function cleanup(name) {
      delete window[name];
    }

    child.on("exit", code => {
        cleanup(childCallbackName);
    });

    try {
      ksu.spawn(
        command,
        JSON.stringify(args),
        JSON.stringify(options),
        childCallbackName
      );
    } catch (error) {
      child.emit("error", error);
      cleanup(childCallbackName);
    }
    return child;
  }

function fullScreen(isFullScreen) {
  if (typeof ksu === "undefined" || typeof ksu.fullScreen !== "function") return false;
  return ksu.fullScreen(isFullScreen);
}

function enableEdgeToEdge(enable) {
  if (typeof ksu === "undefined" || typeof ksu.enableEdgeToEdge !== "function") return;
  ksu.enableEdgeToEdge(enable);
}

function toast(message) {
  try {
    if (typeof ksu !== "undefined" && typeof ksu.toast === "function") {
      ksu.toast(String(message));
      return;
    }
  } catch (e) { /* manager aneh: lanjut ke fallback */ }
  console.log("[toast]", message); /* fallback bila bridge toast tak ada */
}

function moduleInfo() {
  try {
    if (typeof ksu !== "undefined" && typeof ksu.moduleInfo === "function") {
      return ksu.moduleInfo();
    }
  } catch (e) {}
  return null;
}

function listPackages(type) {
  try {
    return JSON.parse(ksu.listPackages(type));
  } catch (error) {
    return [];
  }
}

function getPackagesInfo(packages) {
  try {
    if (typeof packages !== "string") {
      packages = JSON.stringify(packages);
    }
    return JSON.parse(ksu.getPackagesInfo(packages));
  } catch (error) {
    return [];
  }
}

/* [HARDENING-3] probe bridge pm/io dengan aman: beberapa manager fork
   (KOWSU dkk.) menyediakan ksu.pm() tetapi objek kembaliannya TIDAK punya
   version() sebagai fungsi — panggilan langsung (gaya upstream) membuat
   seluruh file gagal dimuat. Di sini: try/catch + typeof per metode. */
function probeBridge(factory) {
  try {
    if (typeof ksu === "undefined" || typeof factory !== "function") return null;
    const bridge = factory();
    return bridge && typeof bridge === "object" ? bridge : null;
  } catch (e) {
    return null;
  }
}

function bridgeVersion(bridge) {
  try {
    if (bridge && typeof bridge.version === "function") {
      return Number(bridge.version()) || 0;
    }
  } catch (e) {}
  return 0;
}

const pmBridge = probeBridge(() => ksu.pm());
const pmSupported = !!(pmBridge && (
  typeof pmBridge.version === "function" ||
  typeof pmBridge.listPackages === "function" ||
  typeof pmBridge.getPackagesInfo === "function"
));

const pm = {
  support: pmSupported,
  version: bridgeVersion(pmBridge),
  listPackages(type) {
    try {
      return JSON.parse(ksu.pm().listPackages(type));
    } catch (error) {
      return [];
    }
  },
  getPackagesInfo(packages) {
    try {
      if (typeof packages !== "string") {
        packages = JSON.stringify(packages);
      }
      return JSON.parse(ksu.pm().getPackagesInfo(packages));
    } catch (error) {
      return [];
    }
  },
};

function exit() {
  if (typeof ksu !== "undefined" && typeof ksu.exit === "function") {
    ksu.exit();
  }
}

const ioBridge = probeBridge(() => ksu.io());
const ioSupported = !!(ioBridge && (
  typeof ioBridge.version === "function" ||
  typeof ioBridge.File === "function" ||
  typeof ioBridge.FileInputStream === "function" ||
  typeof ioBridge.FileOutputStream === "function" ||
  typeof ioBridge.RandomAccessFile === "function"
));

const io = {
  support: ioSupported,
  version: bridgeVersion(ioBridge),

  File(path) {
    const impl = ksu.io().File(path);
    return {
      exists() { return impl.exists(); },
      isFile() { return impl.isFile(); },
      isDirectory() { return impl.isDirectory(); },
      canRead() { return impl.canRead(); },
      canWrite() { return impl.canWrite(); },
      canExecute() { return impl.canExecute(); },
      createNewFile() { return impl.createNewFile(); },
      delete() { return impl.delete(); },
      deleteRecursive() { return impl.deleteRecursive(); },
      mkdir() { return impl.mkdir(); },
      mkdirs() { return impl.mkdirs(); },
      renameTo(destPath) { return impl.renameTo(destPath); },
      list() {
        try {
          return JSON.parse(impl.list() || '[]');
        } catch (error) {
          return [];
        }
      },
      listFiles() {
        try {
          return JSON.parse(impl.listFiles() || '[]');
        } catch (error) {
          return [];
        }
      },
      length() { return impl.length(); },
      lastModified() { return impl.lastModified(); },
      setLastModified(time) { return impl.setLastModified(time); },
      getAbsolutePath() { return impl.getAbsolutePath(); },
      getCanonicalPath() { return impl.getCanonicalPath(); },
      getParent() { return impl.getParent(); },
      getPath() { return impl.getPath(); },
      getName() { return impl.getName(); },
      isHidden() { return impl.isHidden(); },
      isBlock() { return impl.isBlock(); },
      isCharacter() { return impl.isCharacter(); },
      isSymlink() { return impl.isSymlink(); },
      createNewSymlink(target) { return impl.createNewSymlink(target); },
      createNewLink(existing) { return impl.createNewLink(existing); },
      clear() { return impl.clear(); },
      setReadOnly() { return impl.setReadOnly(); },
      setReadable(readable, ownerOnly) { return impl.setReadable(readable, ownerOnly); },
      setWritable(writable, ownerOnly) { return impl.setWritable(writable, ownerOnly); },
      setExecutable(executable, ownerOnly) { return impl.setExecutable(executable, ownerOnly); },
      getFreeSpace() { return impl.getFreeSpace(); },
      getTotalSpace() { return impl.getTotalSpace(); },
      getUsableSpace() { return impl.getUsableSpace(); },
      newInputStream() { return impl.newInputStream(); },
      newOutputStream(append) { return append !== undefined ? impl.newOutputStream(append) : impl.newOutputStream(); },
      toString() { return impl.toString(); },
    };
  },

  FileInputStream() {
    const impl = ksu.io().FileInputStream();
    return {
      open(path) { return impl.open(path); },
      read(id, maxBytes) { return maxBytes !== undefined ? impl.read(id, maxBytes) : impl.read(id); },
      available(id) { return impl.available(id); },
      close(id) { return impl.close(id); },
    };
  },

  FileOutputStream() {
    const impl = ksu.io().FileOutputStream();
    return {
      open(path, append) { return append !== undefined ? impl.open(path, append) : impl.open(path); },
      write(id, data) { return impl.write(id, data); },
      writeByte(id, b) { return impl.writeByte(id, b); },
      flush(id) { return impl.flush(id); },
      close(id) { return impl.close(id); },
    };
  },

  RandomAccessFile() {
    const impl = ksu.io().RandomAccessFile();
    return {
      open(path, mode) { return impl.open(path, mode); },
      read(id) { return impl.read(id); },
      readBytes(id, len) { return impl.readBytes(id, len); },
      readBoolean(id) { return impl.readBoolean(id); },
      readByte(id) { return impl.readByte(id); },
      readInt(id) { return impl.readInt(id); },
      readLong(id) { return impl.readLong(id); },
      readShort(id) { return impl.readShort(id); },
      readFloat(id) { return impl.readFloat(id); },
      readDouble(id) { return impl.readDouble(id); },
      readUTF(id) { return impl.readUTF(id); },
      readLine(id) { return impl.readLine(id); },
      write(id, b) { impl.write(id, b); },
      writeBase64(id, data) { impl.writeBase64(id, data); },
      writeBoolean(id, v) { impl.writeBoolean(id, v); },
      writeByte(id, v) { impl.writeByte(id, v); },
      writeInt(id, v) { impl.writeInt(id, v); },
      writeLong(id, v) { impl.writeLong(id, v); },
      writeShort(id, v) { impl.writeShort(id, v); },
      writeFloat(id, v) { impl.writeFloat(id, v); },
      writeDouble(id, v) { impl.writeDouble(id, v); },
      writeUTF(id, str) { impl.writeUTF(id, str); },
      seek(id, pos) { return impl.seek(id, pos); },
      getFilePointer(id) { return impl.getFilePointer(id); },
      length(id) { return impl.length(id); },
      setLength(id, newLength) { return impl.setLength(id, newLength); },
      close(id) { return impl.close(id); },
    };
  },
};
/* ================== AKHIR LIBRARY KERNELSU (BUNDLED) ================== */

const CONFIG_FILE_PATH = "/data/adb/modules/LickingT/thermal.conf";
const PORN_ARCHIVE_PATH = "/data/adb/modules/LickingT/PornArchive/PornCategories.txt";
const APP_CONFIGS_PATH = "/data/adb/modules/LickingT/AppConfigs.txt";
const STATUS_FILE_PATH = "/data/adb/modules/LickingT/CurrentState";
const SERVICE_FILE_PATH = "/data/adb/modules/LickingT/service.sh";

/* === I18N (TRANSLATION) === */
let currentTranslations = {};

/* helper teks i18n dengan fallback Inggris */
const tt = (key, fallback) => currentTranslations[key] || fallback;

const LANG_NAMES = { en: 'English', id: 'Bahasa Indonesia', ja: '日本語', jv: 'Basa Jawa' };

/* === JUDUL HEADER PER TAB === */
const HOME_TITLE = 'Licking Thermal';
let currentNav = null;
function setHeaderTitle(text) {
  const small = document.getElementById('bar-title-small');
  const large = document.getElementById('bar-title-large');
  if (small) small.textContent = text;
  if (large) large.textContent = text;
}

const infoContentFallback = {
  aggressive: { title: "Aggressive Mode", text: "Highly recommended for a performance boost." },
  modeOptions: { title: "Operation Mode", text: "Auto: Selected apps only.\nStatic: Always on." },
  zonePolicy: { title: "Thermal Policy", text: "Sets how the system reacts to temps." },
  thermalZone: { title: "Thermal Zone", text: "Disable: Disable thermal zone spoofing.\nSpoof to 30°C: Spoof thermal zone temperature to 30°C." },
  kernelPanic: { title: "Disable Kernel Panic", text: "Prevents random reboots by ignoring minor system crashes. Useful for fixing stability issues." },
  fastCharge: { title: "Fast Charge", text: "Turns off some temperature sensors to force maximum charging speed." },
  disableHal: { title: "Disable Thermal HAL", text: "Stops hardware thermal services. Only available when Aggressive Mode is ON. Uses bind mounts (AvaAddams)." }
};

async function loadLanguage(lang) {
  try {
    const response = await fetch(`assets/lang/${lang}.json`);
    if (!response.ok) throw new Error("Translation not found");
    currentTranslations = await response.json();
    localStorage.setItem('licking_lang', lang);
    applyTranslations();
    updateLanguageUI(lang);
  } catch(e) {
    console.warn("Translation load failed, using fallback:", e.message);
  }
}

function applyTranslations() {
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (currentTranslations[key]) {
      if (el.tagName === 'INPUT' && el.type === 'text') {
        el.placeholder = currentTranslations[key];
      } else {
        el.innerHTML = currentTranslations[key];
      }
    }
  });
}

function updateLanguageUI(lang) {
  /* sinkronkan nilai dropdown bahasa (dropdown dibuat saat init) */
  const dd = dropdowns['lang-select'];
  if (dd) dd.setValue(lang, false);
  /* judul header mengikuti bahasa aktif (kecuali Home yang tetap nama module) */
  if (currentNav) setHeaderTitle(currentNav.title());
}

window.showInfo = function(key) {
  const content = currentTranslations.infoModals && currentTranslations.infoModals[key]
                  ? currentTranslations.infoModals[key]
                  : infoContentFallback[key];
  if(content) {
    document.getElementById('modal-title').innerText = content.title;
    renderInfoText(document.getElementById('modal-text'), content.text);
    document.getElementById('info-modal').classList.add('show');
  }
};

function renderInfoText(el, text) {
  if (!el) return;
  el.innerHTML = '';
  const lines = String(text).split('\n').map(s => s.trim()).filter(Boolean);
  const rows = lines.map(line => {
    const i = line.indexOf(':');
    return (i > 0 && i <= 24 && line.slice(i + 1).trim())
      ? { label: line.slice(0, i).trim(), desc: line.slice(i + 1).trim() }
      : { label: null, desc: line };
  });
  if (rows.some(r => r.label)) {
    const box = document.createElement('div');
    box.className = 'm-modal-rows';
    rows.forEach(r => {
      const row = document.createElement('div');
      row.className = 'm-modal-row' + (r.label ? '' : ' plain');
      const desc = document.createElement('span');
      desc.className = 'm-modal-desc';
      desc.textContent = r.desc;
      if (r.label) {
        const label = document.createElement('span');
        label.className = 'm-modal-label';
        label.textContent = r.label;
        row.append(label, desc);
      } else {
        row.appendChild(desc);
      }
      box.appendChild(row);
    });
    el.appendChild(box);
  } else {
    lines.forEach(line => {
      const p = document.createElement('p');
      p.className = 'm-modal-p';
      p.textContent = line;
      el.appendChild(p);
    });
  }
}

window.closeModal = function() {
  document.getElementById('info-modal')?.classList.remove('show');
};

window.openExternalLink = async function(uri, event) {
  event.preventDefault();
  try { await ksuExec(`am start -a android.intent.action.VIEW -d '${uri}' || true`); }
  catch (e) { toast(`Error: ${e.message}`); }
};

/* === KERNELSU API CORE === */
async function exec(command) {
  const { errno, stdout, stderr } = await ksuExec(command);
  if (errno !== 0) throw new Error(stderr || `Exit ${errno}`);
  return stdout.trim();
}

async function updateBannerIndicators() {
  const statusEl = document.getElementById("status-indicator");
  const pidEl = document.getElementById("pid-indicator");
  try {
    const state = await exec(`cat ${STATUS_FILE_PATH} || echo "Unknown"`);
    if (state.trim() === "Horny") {
      statusEl.innerText = currentTranslations.statusActive || "Working ✨";
      statusEl.style.color = "var(--m-primary)";
    } else if (state.trim() === "NotHorny") {
      statusEl.innerText = currentTranslations.statusBalanced || "Balanced 😴";
      statusEl.style.color = "var(--m-on-surface)";
    } else {
      statusEl.innerText = currentTranslations.statusDisabled || "Disabled ❌";
      statusEl.style.color = "var(--m-error)";
    }
  } catch(e) {}

  try {
    const pid = await exec(`pgrep -f ${SERVICE_FILE_PATH} || echo ""`);
    pidEl.innerText = pid.trim() ? `PID: ${pid.trim()}` : "PID: NULL";
  } catch(e) {}
}

async function loadDeviceInfo() {
  try {
    const v = await exec("grep '^version=' /data/adb/modules/LickingT/module.prop 2>/dev/null || echo 'version=Unknown'");
    document.getElementById("info-version").textContent = v.replace('version=', '').trim();
  } catch(e) { document.getElementById("info-version").textContent = "Unknown"; }

  try {
    const d = await exec("getprop ro.product.model || echo 'Unknown'");
    document.getElementById("info-device").textContent = d.trim();
  } catch(e) { document.getElementById("info-device").textContent = "Unknown"; }

  try {
    const a = await exec("getprop ro.build.version.release || echo 'Unknown'");
    document.getElementById("info-android").textContent = a.trim();
  } catch(e) { document.getElementById("info-android").textContent = "Unknown"; }

  try {
    const c = await exec("getprop ro.board.platform || echo 'Unknown'");
    document.getElementById("info-chipset").textContent = c.trim();
  } catch(e) { document.getElementById("info-chipset").textContent = "Unknown"; }

  try {
    const k = await exec("uname -r || echo 'Unknown'");
    document.getElementById("info-kernel").textContent = k.trim();
  } catch(e) { document.getElementById("info-kernel").textContent = "Unknown"; }
}

async function setConfigValue(key, value) {
  try {
    const cmd = `
      if [ ! -f "${CONFIG_FILE_PATH}" ]; then touch "${CONFIG_FILE_PATH}"; fi;
      if grep -q "^${key}=" "${CONFIG_FILE_PATH}"; then
        sed -i "s/^${key}=.*/${key}=${value}/" "${CONFIG_FILE_PATH}"
      else
        echo "${key}=${value}" >> "${CONFIG_FILE_PATH}"
      fi
    `;
    await exec(cmd);
    toast(currentTranslations.toastSaved || `Saved successfully`);
  } catch(e) {
    toast(`Failed: ${e.message}`);
  }
}

/* tampilkan/sembunyikan baris policy (gaya card miuix: tanpa divider) */
function setRowVisible(rowId, visible) {
  const row = document.getElementById(rowId);
  if (row) row.style.display = visible ? '' : 'none';
}


function updateFastChargeVisibility(modeVal) {
  const chargeRow = document.getElementById("charge-row");
  if (!chargeRow) return;
  const isSupported = localStorage.getItem("licking_fastcharge_support") === "true";
  const isAuto = modeVal === "automatic" || modeVal === "auto";
  if (isSupported && isAuto) {
    chargeRow.style.display = "";
  } else {
    chargeRow.style.display = "none";
  }
}

async function updateExtraCard() {
  try {
    const out = await exec(`cat ${CONFIG_FILE_PATH} || true`);
    let mode = "automatic", hal = "0", aggHal = "0", disablePanic = "0", zone = "1", charge = "0";

    out.split("\n").forEach(l => {
      const t = l.trim();
      if(t.startsWith("MODE=")) mode = t.replace("MODE=","").trim().toLowerCase() === "auto" ? "automatic" : "static";
      if(t.startsWith("HAL=")) hal = t.replace("HAL=","").trim();
      if(t.startsWith("AggHal=")) aggHal = t.replace("AggHal=","").trim();
      if(t.startsWith("DISABLE_PANIC=")) disablePanic = t.replace("DISABLE_PANIC=","").trim();
      if(t.startsWith("ZONE=")) zone = t.replace("ZONE=","").trim();
      if(t.startsWith("Charge=")) charge = t.replace("Charge=","").trim();
    });

    const modeDd = dropdowns['mode-select'];
    const halSwitch = document.getElementById("hal-switch");
    const panicSwitch = document.getElementById("panic-switch");
    const zoneDd = dropdowns['zone-select'];
    const chargeSwitch = document.getElementById("charge-switch");
    const disableHalSwitch = document.getElementById("disable-hal-switch");
    const disableHalRow = document.getElementById("disable-hal-row");

    if(modeDd) modeDd.setValue(mode);
    if(halSwitch) halSwitch.checked = (hal === "1");
    if(panicSwitch) panicSwitch.checked = (disablePanic === "1");
    if(chargeSwitch) chargeSwitch.checked = (charge === "1");
    if(disableHalSwitch) disableHalSwitch.checked = (aggHal === "1");
    if(disableHalRow) disableHalRow.style.display = (hal === "1") ? "" : "none";

    updateFastChargeVisibility(mode);

    if(zoneDd) {
      zoneDd.setValue(zone);
      setRowVisible('policy-row-wrapper', zone !== "1");
    }
  } catch(e) {}
}

/* === THERMAL POLICIES === */
let globalPolicies = ["stepwise"];

async function fetchThermalPolicies() {
  try {
    const avail = await exec("cat /sys/class/thermal/thermal_zone0/available_policies");
    globalPolicies = avail.split(/\s+/).filter(p => p);
  } catch(e) {
    globalPolicies = ["stepwise", "userspace", "power_allocator"];
  }
}

async function updateThermalPoliciesUI() {
  const policyDd = dropdowns['policy-select'];
  if (!policyDd) return;
  try {
    const curr = await exec("cat /sys/class/thermal/thermal_zone0/policy");
    policyDd.setOptions(globalPolicies.map(p => ({ value: p, label: p })));
    policyDd.setValue(curr.trim());
  } catch(e) {
    policyDd.setOptions([{ value: '', label: 'Not supported' }]);
    policyDd.setValue('');
  }
}

/* === MIUIX DROPDOWN (OverlayDropdownPreference port) === */
const dropdowns = {};
let _allDd = [];

function closeAllDropdowns() { _allDd.forEach(d => d.close()); }

class MiuixDropdown {
  constructor(id, onChange) {
    this.id = id;
    this.root = document.getElementById(id);
    this.onChange = onChange || (() => {});
    this.value = null;
    this.options = [];
    this.menu = document.createElement('div');
    this.menu.className = 'm-dd-menu';
    this.scrim = document.createElement('div');
    this.scrim.className = 'm-dd-scrim';
    document.body.appendChild(this.scrim);
    document.body.appendChild(this.menu);
    this.scrim.addEventListener('click', (e) => {
      this.close();
      /* bila tap jatuh pada tombol dropdown lain, buka dropdown itu
         langsung — tanpa ini user harus mengetuk dua kali untuk berpindah */
      const hit = document.elementsFromPoint(e.clientX, e.clientY)
        .find(el => el !== this.scrim && !(el.closest && el.closest('.m-dd-menu')));
      const btn = hit && hit.closest ? hit.closest('.m-dd') : null;
      if (btn) {
        const other = _allDd.find(d => d.root === btn);
        if (other && other !== this) other.open();
      }
    });
    this.root.addEventListener('click', (e) => { e.stopPropagation(); this.open(); });
    _allDd.push(this);
  }

  setOptions(options) {
    this.options = options;
    this.menu.innerHTML = '';
    options.forEach(opt => {
      const item = document.createElement('div');
      item.className = 'm-dd-item';
      const label = document.createElement('span');
      label.textContent = opt.label;
      const check = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
      check.setAttribute('class', 'm-icon');
      const use = document.createElementNS('http://www.w3.org/2000/svg', 'use');
      use.setAttribute('href', '#i-check');
      check.appendChild(use);
      item.append(label, check);
      item.addEventListener('click', () => {
        this.setValue(opt.value, true);
        this.close();
      });
      this.menu.appendChild(item);
    });
    this._refresh();
    this._updateLabel();
  }

  setValue(value, fire) {
    this.value = value;
    this._updateLabel();
    this._refresh();
    if (fire) this.onChange(value);
  }

  _updateLabel() {
    const opt = this.options.find(o => o.value === this.value);
    const valEl = this.root.querySelector('.m-dd-val');
    if (valEl) valEl.textContent = opt ? opt.label : '';
  }

  _refresh() {
    this.menu.querySelectorAll('.m-dd-item').forEach((el, i) => {
      el.classList.toggle('selected', !!this.options[i] && this.options[i].value === this.value);
    });
  }

  open() {
    closeAllDropdowns();
    /* aktifkan scrim: tap di area mana pun di luar menu menutup dropdown,
       meskipun tidak memilih opsi apa pun */
    this.scrim.classList.add('open');
    // ukur dulu (tanpa animasi) lalu posisikan
    this.menu.style.visibility = 'hidden';
    this.menu.style.left = '0px';
    this.menu.style.top = '0px';
    this.menu.classList.add('open');
    const r = this.root.getBoundingClientRect();
    const mw = this.menu.offsetWidth, mh = this.menu.offsetHeight;
    const vw = window.innerWidth, vh = window.innerHeight;
    let left = r.right - mw;
    if (left < 8) left = 8;
    if (left + mw > vw - 8) left = Math.max(8, vw - 8 - mw);
    let top = r.bottom + 6, upward = false;
    if (top + mh > vh - 12) { top = Math.max(12, r.top - mh - 6); upward = true; }
    this.menu.classList.toggle('upward', upward);
    this.menu.style.left = left + 'px';
    this.menu.style.top = top + 'px';
    this.menu.style.visibility = '';
  }

  close() {
    this.menu.classList.remove('open');
    this.scrim.classList.remove('open');
  }
}

/* === APP LIST & PER-APP CONFIG === */
let cachedApps = [];
let activePackages = new Set();
let appConfigs = {};
let currentEditingPkg = null;

async function saveAppConfigs() {
  let customLines = [];
  for (const pkg of activePackages) {
    const conf = appConfigs[pkg];
    if (conf && conf.isCustomized) {
      customLines.push(`${pkg}:${conf.agg ? '1' : '0'}:${conf.policy}:${conf.zone || '1'}:${conf.aggHal ? '1' : '0'}`);
    }
  }

  const cleanCustomWrite = customLines.join('\n');
  const cleanPornWrite = Array.from(activePackages).join('\n');

  try {
    await exec(`printf %s '${cleanCustomWrite.replace(/'/g,"'\\''")}' > ${APP_CONFIGS_PATH}`);
    await exec(`printf %s '${cleanPornWrite.replace(/'/g,"'\\''")}' > ${PORN_ARCHIVE_PATH}`);
  } catch (err) {
    toast(`Failed to save config: ${err.message}`);
  }
}

async function loadAppsData() {
  try {
    const content = await exec(`cat ${PORN_ARCHIVE_PATH} || true`);
    activePackages = new Set(content.split('\n').map(l => l.trim()).filter(Boolean));

    const configContent = await exec(`cat ${APP_CONFIGS_PATH} || true`);
    configContent.split('\n').forEach(line => {
      const parts = line.trim().split(':');
      if (parts.length === 3) {
        appConfigs[parts[0]] = {
          agg: parts[1] === '1',
          policy: parts[2],
          zone: '1',
          isCustomized: true
        };
      } else if (parts.length >= 4) {
        appConfigs[parts[0]] = {
          agg: parts[1] === '1',
          policy: parts[2],
          zone: parts[3],
          aggHal: parts.length > 4 ? (parts[4] === '1') : false,
          isCustomized: true
        };
      }
    });

    const t = await exec("pm list packages -3");
    let thirdPartyPkgs = new Set();
    if (t) {
        t.split("\n").forEach(e => {
            const pkg = e.replace("package:", "").trim();
            if (pkg) thirdPartyPkgs.add(pkg);
        });
    }

    const allPkgsOut = await exec("pm list packages -U");
    let rawPackages = [];

    if (allPkgsOut) {
        allPkgsOut.split("\n").forEach(line => {
            const match = line.match(/^package:(.+)\s+uid:(\d+)$/);
            if (match) {
                rawPackages.push({
                    packageName: match[1],
                    uid: match[2],
                    appLabel: match[1]
                });
            }
        });
    }

    await Promise.all(rawPackages.map(async (pkgObj) => {
        try {
            const query = JSON.stringify([pkgObj.packageName]);
            let info = await getPackagesInfo(query);
            if (typeof info === 'string') info = JSON.parse(info);
            if (Array.isArray(info) && info.length > 0) {
                const appData = info[0];
                const label = appData.appLabel || appData.label || appData.appName;
                if (label) pkgObj.appLabel = label;
            }
        } catch (err) {}
    }));

    cachedApps = [];
    rawPackages.forEach(pkg => {
        if (thirdPartyPkgs.has(pkg.packageName)) cachedApps.push(pkg);
    });

    renderAppList();
  } catch(e) {
    const container = document.getElementById("appList");
    if(container) container.innerHTML = `<div class="m-state error">Error loading apps: ${e.message}</div>`;
  }
}

function makeMiuixIcon(ref, cls) {
  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  svg.setAttribute('class', 'm-icon' + (cls ? ' ' + cls : ''));
  const use = document.createElementNS('http://www.w3.org/2000/svg', 'use');
  use.setAttribute('href', ref);
  svg.appendChild(use);
  return svg;
}

function renderAppList() {
  const container = document.getElementById("appList");
  const searchInput = document.getElementById("app-search");
  if (!container || !searchInput) return;

  const query = searchInput.value.toLowerCase().trim();

  let filtered = cachedApps.filter(pkg => {
    const name = (pkg.appLabel || pkg.packageName).toLowerCase();
    const id = pkg.packageName.toLowerCase();
    return name.includes(query) || id.includes(query);
  });

  filtered.sort((a, b) => {
    const aActive = activePackages.has(a.packageName);
    const bActive = activePackages.has(b.packageName);
    if (aActive && !bActive) return -1;
    if (!aActive && bActive) return 1;
    return (a.appLabel || a.packageName).localeCompare(b.appLabel || b.packageName);
  });

  container.innerHTML = "";
  if (filtered.length === 0) {
    container.innerHTML = `<div class="m-state">${currentTranslations.noApps || "No apps found."}</div>`;
    return;
  }

  const fragment = document.createDocumentFragment();

  filtered.forEach((pkg) => {
    const isChecked = activePackages.has(pkg.packageName);
    const labelText = pkg.appLabel || pkg.packageName;

    if (!appConfigs[pkg.packageName]) {
      appConfigs[pkg.packageName] = { agg: false, policy: globalPolicies[0] || 'stepwise', zone: '1', aggHal: false, isCustomized: false };
    }

    /* baris aplikasi gaya preference miuix */
    const item = document.createElement('div');
    item.className = 'm-pref m-app-row';

    const img = document.createElement('img');
    img.className = 'm-app-icon';
    img.src = `ksu://icon/${pkg.packageName}`;
    img.alt = 'icon';

    img.onerror = async () => {
        if (img.dataset.fallbackAttempted) return;
        img.dataset.fallbackAttempted = "true";
        try {
            if (window.ksu && typeof window.ksu.getPackagesIcons === 'function') {
                let result = window.ksu.getPackagesIcons(JSON.stringify([pkg.packageName]));
                if (result instanceof Promise) result = await result;
                if (result) {
                    const icons = typeof result === 'string' ? JSON.parse(result) : result;
                    if (icons && icons[pkg.packageName]) {
                       img.src = "data:image/png;base64," + icons[pkg.packageName];
                       return;
                    }
                }
            }
        } catch(e) {}
        img.src = "data:image/svg+xml;charset=UTF-8,%3csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22%2379747E%22 stroke-width=%221.5%22%3e%3cpath d=%22M4 6a2 2 0 012-2h12a2 2 0 012 2v12a2 2 0 01-2 2H6a2 2 0 01-2-2V6z%22/%3e%3ccircle cx=%2212%22 cy=%2212%22 r=%223%22/%3e%3c/svg%3e";
    };

    const textGroup = document.createElement('div');
    textGroup.className = 'm-pref-text';

    const labelEl = document.createElement('span');
    labelEl.className = 'm-app-label';
    const labelTextEl = document.createElement('span');
    labelTextEl.className = 'label-text';
    labelTextEl.textContent = labelText;
    labelEl.appendChild(labelTextEl);

    if (isChecked) {
      const badge = document.createElement('span');
      badge.className = 'm-badge';
      badge.textContent = 'ENABLED';
      labelEl.appendChild(badge);
    }

    const pkgEl = document.createElement('span');
    pkgEl.className = 'm-app-pkg';
    pkgEl.textContent = pkg.packageName;

    textGroup.append(labelEl, pkgEl);

    const chevron = makeMiuixIcon('#i-arrowright', 'm-arrow');

    item.append(img, textGroup, chevron);

    item.addEventListener('click', () => {
      openGameSettings(pkg, isChecked, img.src);
    });

    fragment.appendChild(item);
  });

  container.appendChild(fragment);
}

function openGameSettings(pkg, isChecked, iconSrc) {
  currentEditingPkg = pkg.packageName;
  const conf = appConfigs[pkg.packageName];

  document.getElementById('as-app-name').textContent = pkg.appLabel || pkg.packageName;
  document.getElementById('as-app-pkg').textContent = pkg.packageName;
  document.getElementById('as-app-icon').src = iconSrc;

  document.getElementById('as-main-switch').checked = isChecked;
  document.getElementById('as-agg-switch').checked = conf.agg;
  
  const asDisableHalSwitch = document.getElementById('as-disable-hal-switch');
  const asDisableHalRow = document.getElementById('as-disable-hal-row');
  if (asDisableHalSwitch) asDisableHalSwitch.checked = !!conf.aggHal;
  if (asDisableHalRow) asDisableHalRow.style.display = conf.agg ? "" : "none";

  const customSwitch = document.getElementById('as-custom-switch');
  customSwitch.checked = conf.isCustomized;

  const group = document.getElementById('custom-config-group');
  if (conf.isCustomized) group.classList.remove('disabled');
  else group.classList.add('disabled');

  const asPolicyDd = dropdowns['as-policy-select'];
  if (asPolicyDd) {
    asPolicyDd.setOptions(globalPolicies.map(p => ({ value: p, label: p })));
    asPolicyDd.setValue(conf.policy);
  }

  const asZoneDd = dropdowns['as-zone-select'];
  if (asZoneDd) {
    const currentZoneVal = conf.zone || '1';
    asZoneDd.setValue(currentZoneVal);
    setRowVisible('as-policy-row-wrapper', currentZoneVal !== "1");
  }

  document.getElementById('appSettingsOverlay').classList.add('active');
}

async function checkFastChargeSupport() {
  const chargeSwitch = document.getElementById("charge-switch");
  if (!chargeSwitch) return;

  const chargeRow = chargeSwitch.closest('.m-pref');
  if (!chargeRow) return;

  const cachedSupport = localStorage.getItem("licking_fastcharge_support");

  if (cachedSupport === "true" || cachedSupport === "false") {
    updateFastChargeVisibility(dropdowns['mode-select']?.value || 'automatic');
    return;
  }

  try {
    // Mengecek dukungan fast charge dengan path spesifik
    const result = await exec("ls /sys/class/power_supply/*/constant_charge_current_max /sys/class/power_supply/*/input_current_limit /sys/class/power_supply/*/input_voltage_limit /sys/class/power_supply/*/siop_level /sys/class/power_supply/*/temp_warm /sys/class/power_supply/*/charge_control_limit 2>/dev/null || true");

    if (result.trim() !== "") {
      localStorage.setItem("licking_fastcharge_support", "true");
      updateFastChargeVisibility(dropdowns['mode-select']?.value || 'automatic');
    } else {
      localStorage.setItem("licking_fastcharge_support", "false");
      updateFastChargeVisibility(dropdowns['mode-select']?.value || 'automatic');
    }
  } catch (err) {
    localStorage.setItem("licking_fastcharge_support", "false");
    updateFastChargeVisibility(dropdowns['mode-select']?.value || 'automatic');
    console.warn("Gagal mengecek dukungan fast charge:", err);
  }
}

/* === SETTINGS: CUSTOM BANNER === */
const MODULE_DIR = "/data/adb/modules/LickingT";
const BANNER_BACKUP_GLOB = "/data/adb/licking_banner.*";
const MAX_BANNER_SIZE = 5 * 1024 * 1024;   // 5 MB
const DEFAULT_BANNER_SRC = "assets/banner.jpg";
let bannerIsCustom = false;
let bannerDirCache = null;

/* Deteksi folder webroot yang benar-benar di-serve manager (KernelSU/APatch:
   webroot; sebagian module: webui). Hint dari URL halaman diverifikasi dengan
   keberadaan index.html — memperbaiki bug banner kembali ke default karena
   file tertulis ke folder yang tidak di-serve. */
async function detectBannerDir() {
  if (bannerDirCache) return bannerDirCache;
  const hint = (decodeURIComponent(location.pathname).match(/\/(webroot|webui)\//) || [])[1];
  const order = hint === 'webui'
    ? [`${MODULE_DIR}/webui`, `${MODULE_DIR}/webroot`]
    : [`${MODULE_DIR}/webroot`, `${MODULE_DIR}/webui`];
  try {
    const out = await exec(
      `for d in ${order.join(' ')}; do if [ -f "$d/index.html" ]; then echo "$d"; break; fi; done`
    );
    if (out.trim()) { bannerDirCache = out.trim(); return bannerDirCache; }
  } catch (e) { /* exec gagal -> fallback */ }
  bannerDirCache = `${MODULE_DIR}/webui`;
  return bannerDirCache;
}

function setBannerSrc(src, isCustom) {
  bannerIsCustom = !!isCustom;
  const home = document.getElementById('home-banner-img');
  if (home) home.src = src;
  const resetRow = document.getElementById('banner-reset-row');
  if (resetRow) resetRow.style.display = isCustom ? '' : 'none';
}

/* banner custom gagal dimuat (mis. folder ternyata tidak di-serve) ->
   coba cache dataURL lokal, lalu balik ke default */
function attachBannerFallback(el) {
  el?.addEventListener('error', () => {
    if (!bannerIsCustom) return;
    let cached = null;
    try { cached = localStorage.getItem('licking_banner_data'); } catch (e) {}
    if (cached && el.src !== cached) {
      setBannerSrc(cached, true);
    } else {
      try { localStorage.removeItem('licking_banner_custom'); } catch (e) {}
      setBannerSrc(DEFAULT_BANNER_SRC, false);
    }
  });
}

/* ekstensi file dari tipe/nama file yang diunggah */
function bannerExt(file) {
  const m = (file.name || '').toLowerCase().match(/\.(png|jpe?g|gif|webp|bmp|avif|ico)$/);
  if (m) return m[1] === 'jpeg' ? 'jpg' : m[1];
  if (file.type === 'image/png') return 'png';
  if (file.type === 'image/gif') return 'gif';
  if (file.type === 'image/webp') return 'webp';
  if (file.type === 'image/bmp') return 'bmp';
  if (file.type === 'image/avif') return 'avif';
  if (file.type === 'image/x-icon' || file.type === 'image/vnd.microsoft.icon') return 'ico';
  return 'png';
}

/* tulis base64 ke file via root shell, per-chunk agar aman dari batas ARG_MAX shell */
async function writeBannerFile(b64, ext) {
  const CH = 90000;   // < 128 KB MAX_ARG_STRLEN per argumen
  const decodedBytes = Math.floor(b64.length / 4) * 3
    - (b64.endsWith('==') ? 2 : b64.endsWith('=') ? 1 : 0);
  const dir = await detectBannerDir();
  const targets = [
    `${dir}/banner_custom.${ext}`,               // dipakai langsung oleh WebUI (folder ter-serve)
    `/data/adb/licking_banner.${ext}`            // backup persisten (selamat dari update modul)
  ];
  try {
    await exec(`mkdir -p ${dir}`);
    for (const target of targets) {
      await exec(`: > ${target}.b64`);
      for (let i = 0; i < b64.length; i += CH) {
        await exec(`printf '%s' '${b64.slice(i, i + CH)}' >> ${target}.b64`);
      }
      await exec(`base64 -d ${target}.b64 > ${target} && rm -f ${target}.b64`);
    }
    const size = await exec(`wc -c < ${targets[0]}`);
    return parseInt(size.trim(), 10) === decodedBytes;
  } catch (e) {
    console.warn('writeBannerFile failed:', e.message);
    return false;
  }
}

/* Inisialisasi banner — FILE DULU (sumber kebenaran), bukan localStorage:
   storage WebView bisa dibersihkan manager antar sesi sehingga gerbang
   localStorage membuat banner selalu kembali ke default. File di folder module
   persisten; cache dataURL lokal hanya fallback terakhir. */
async function initCustomBanner() {
  const home = document.getElementById('home-banner-img');
  attachBannerFallback(home);

  try {
    const dir = await detectBannerDir();
    let f = (await exec(`ls ${dir}/banner_custom.* 2>/dev/null | head -n1`)).trim();
    if (!f) {
      /* pulihkan dari backup persisten (kasus modul baru saja diupdate) */
      await exec(`b=$(ls ${BANNER_BACKUP_GLOB} 2>/dev/null | head -n1); if [ -n "$b" ]; then cp "$b" "${dir}/banner_custom.\${b##*.}"; fi`);
      f = (await exec(`ls ${dir}/banner_custom.* 2>/dev/null | head -n1`)).trim();
    }
    if (f) {
      setBannerSrc(f.split('/').pop() + '?t=' + Date.now(), true);
      return;
    }
  } catch (e) { /* exec tidak tersedia / gagal -> fallback cache lokal */ }

  let cached = null;
  try { cached = localStorage.getItem('licking_banner_data'); } catch (e) {}
  if (cached) { setBannerSrc(cached, true); return; }

  setBannerSrc(DEFAULT_BANNER_SRC, false);
}

async function handleBannerUpload(file) {
  if (!file) return;
  const typeOk = /^image\//.test(file.type) || /\.(png|jpe?g|gif|webp|bmp|avif|ico)$/i.test(file.name || '');
  if (!typeOk) { toast(tt('bannerBadType', 'Unsupported image format')); return; }
  if (file.size > MAX_BANNER_SIZE) { toast(tt('bannerTooBig', 'Image must be 5 MB or smaller')); return; }

  const dataUrl = await new Promise(res => {
    const r = new FileReader();
    r.onload = () => res(r.result);
    r.onerror = () => res(null);
    r.readAsDataURL(file);
  });
  if (!dataUrl) { toast(tt('bannerReadFailed', 'Failed to read file')); return; }

  setBannerSrc(dataUrl, true);   // pratinjau instan
  toast(tt('bannerSaving', 'Saving banner...'));

  /* simpan salinan lokal (dataURL) agar banner tetap tampil walau file tidak ter-serve */
  try { localStorage.setItem('licking_banner_data', dataUrl); } catch (e) {}

  const b64 = dataUrl.slice(dataUrl.indexOf(',') + 1);
  const ok = await writeBannerFile(b64, bannerExt(file));
  if (ok) {
    try { localStorage.setItem('licking_banner_custom', '1'); } catch (e) {}
    toast(tt('bannerSaved', 'Banner updated'));
  } else {
    toast(tt('bannerSaveFailed', 'Failed to save banner'));
  }
}

async function resetCustomBanner() {
  try {
    const dir = await detectBannerDir();
    await exec(`rm -f ${dir}/banner_custom.* ${MODULE_DIR}/webroot/banner_custom.* ${MODULE_DIR}/webui/banner_custom.* ${BANNER_BACKUP_GLOB} 2>/dev/null`);
  } catch (e) {}
  try {
    localStorage.removeItem('licking_banner_custom');
    localStorage.removeItem('licking_banner_data');
  } catch (e) {}
  setBannerSrc(DEFAULT_BANNER_SRC, false);
  toast(tt('bannerReset', 'Banner reset to default'));
}

/* === SETTINGS: MONET / DYNAMIC COLOR (logika KernelSU, ala pingpimp) ===
   Toggle cukup menyuntik attribute html[data-monet]; pemetaan warnanya di style.css:
   ON  -> --m-primary dsb. = var(--primary) dsb. dari colors.css host (Material You
          dari wallpaper sistem), fallback biru miuix bila host tidak menyuntik.
   OFF -> aksen biru miuix (#277AF7). */
function applyMonetState(on) {
  document.documentElement.setAttribute('data-monet', on ? 'on' : 'off');
  try { localStorage.setItem('licking_monet', on ? '1' : '0'); } catch (e) {}
}

/* === SETTINGS: BLUR (Gaussian / Progressive) === */
function applyBlurState(enabled, mode) {
  const m = mode === 'progressive' ? 'progressive' : 'gaussian';
  document.body.classList.toggle('blur-on', !!enabled);
  document.body.classList.toggle('blur-gaussian', !!enabled && m === 'gaussian');
  document.body.classList.toggle('blur-progressive', !!enabled && m === 'progressive');
  const modeGroup = document.getElementById('blur-mode-group');
  if (modeGroup) modeGroup.style.display = enabled ? '' : 'none';
  localStorage.setItem('licking_blur', enabled ? m : 'off');
}

/* === INIT === */
async function init() {
  const savedLang = localStorage.getItem('licking_lang') || 'en';
  loadLanguage(savedLang);

  /* --- komponen dropdown miuix --- */
  dropdowns['mode-select'] = new MiuixDropdown('mode-select', async (value) => {
    await setConfigValue("MODE", value === "automatic" ? "auto" : "static");
    updateFastChargeVisibility(value);
  });
  dropdowns['mode-select'].setOptions([
    { value: "automatic", label: "Auto (By App)" },
    { value: "static", label: "Static (Always On)" }
  ]);

  dropdowns['zone-select'] = new MiuixDropdown('zone-select', async (value) => {
    if(!value) return;
    try {
      await setConfigValue("ZONE", value);
      setRowVisible('policy-row-wrapper', value !== "1");
    } catch(err) {
      toast(`Failed: ${err.message}`);
    }
  });
  dropdowns['zone-select'].setOptions([
    { value: "1", label: "Kill Thermal Zone" },
    { value: "0", label: "Spoof to 30°C" }
  ]);

  dropdowns['policy-select'] = new MiuixDropdown('policy-select', async (value) => {
    if(!value) return;
    try {
      await exec(`for z in /sys/class/thermal/thermal_zone*; do chmod 644 "$z/policy"; echo "${value}" > "$z/policy"; done`);
      await exec(`echo "${value}" > /data/adb/modules/LickingT/zpolicy`);
      toast(currentTranslations.toastSaved || `Policy saved and updated`);
    } catch(err) {
      toast(`Failed: ${err.message}`);
    }
  });

  dropdowns['as-zone-select'] = new MiuixDropdown('as-zone-select', async (value) => {
    if(!currentEditingPkg) return;
    appConfigs[currentEditingPkg].zone = value;
    appConfigs[currentEditingPkg].isCustomized = true;
    await saveAppConfigs();
    const zoneText = value === '1' ? 'Disable' : 'Spoof to 30°C';
    toast(`Thermal Zone: ${zoneText}`);
    setRowVisible('as-policy-row-wrapper', value !== "1");
  });
  dropdowns['as-zone-select'].setOptions([
    { value: "1", label: "Kill Thermal Zone" },
    { value: "0", label: "Spoof to 30°C" }
  ]);

  dropdowns['as-policy-select'] = new MiuixDropdown('as-policy-select', async (value) => {
    if(!currentEditingPkg) return;
    appConfigs[currentEditingPkg].policy = value;
    appConfigs[currentEditingPkg].isCustomized = true;
    await saveAppConfigs();
    toast(`${currentTranslations.toastPolicyUpdated || 'Policy updated to'} ${value}`);
  });

  dropdowns['blur-mode-select'] = new MiuixDropdown('blur-mode-select', (value) => {
    const blurSwitch = document.getElementById('blur-switch');
    if (blurSwitch && blurSwitch.checked) applyBlurState(true, value);
  });
  dropdowns['blur-mode-select'].setOptions([
    { value: 'gaussian', label: tt('blurGaussian', 'Gaussian') },
    { value: 'progressive', label: tt('blurProgressive', 'Progressive') }
  ]);

  /* --- dropdown bahasa (miuix dropdown, seperti opsi lain — bukan popup card) --- */
  dropdowns['lang-select'] = new MiuixDropdown('lang-select', (value) => {
    if (value) loadLanguage(value);
  });
  dropdowns['lang-select'].setOptions(
    Object.keys(LANG_NAMES).map(code => ({ value: code, label: LANG_NAMES[code] }))
  );
  if (LANG_NAMES[savedLang]) dropdowns['lang-select'].setValue(savedLang, false);

  /* --- modal info --- */
  document.getElementById('close-info-modal')?.addEventListener('click', window.closeModal);

  document.querySelectorAll('.m-scrim').forEach(el => {
    el.addEventListener('click', (e) => { if(e.target === el) window.closeModal(); });
  });

  /* --- navigasi antar halaman (Home / Apps / Settings) ---
     judul header mengikuti tab aktif; Home tetap nama module */
  const navTabs = [
    { btn: 'openMain', view: 'mainMenu', title: () => HOME_TITLE },
    { btn: 'openGameList', view: 'gameListMenu', title: () => tt('navApps', 'Apps') },
    { btn: 'openSettings', view: 'settingsMenu', title: () => tt('navSettings', 'Settings') }
  ];
  const switchTab = (active) => {
    currentNav = active;
    navTabs.forEach(t => {
      document.getElementById(t.btn)?.classList.toggle('active', t === active);
      document.getElementById(t.view)?.classList.toggle('hidden', t !== active);
    });
    setHeaderTitle(active.title());
    window.scrollTo({ top: 0, behavior: 'smooth' });
    window.updateBarFade?.();
  };
  navTabs.forEach(t => {
    document.getElementById(t.btn)?.addEventListener('click', () => switchTab(t));
  });

  /* --- topappbar: judul besar tergelincir saat scroll + crossfade judul kecil
         di tengah bar (perilaku miuix TopAppBar). Tinggi header konstan ->
         tidak ada umpan balik layout, bebas glitch saat scroll lambat /
         berhenti di posisi tengah. --- */
  const smallTitle = document.getElementById('bar-title-small');
  const FADE_START = 4;    // px scroll sebelum judul kecil mulai muncul
  const FADE_SPAN = 44;    // px hingga muncul penuh (selaras tinggi judul besar)
  let fadePending = false;
  window.updateBarFade = () => {
    fadePending = false;
    if (!smallTitle) return;
    const p = Math.max(0, Math.min(1, (window.scrollY - FADE_START) / FADE_SPAN));
    smallTitle.style.opacity = p.toFixed(3);
  };
  window.addEventListener('scroll', () => {
    if (!fadePending) { fadePending = true; requestAnimationFrame(window.updateBarFade); }
  }, { passive: true });
  window.updateBarFade();

  /* --- switch konfigurasi global --- */
  document.getElementById("panic-switch")?.addEventListener('change', async (e) => {
    const isDisablePanic = e.target.checked;
    const val = isDisablePanic ? "0" : "1";
    const printkVal = isDisablePanic ? "0 0 0 0" : "1 1 1 1";
    const devkmsgVal = isDisablePanic ? "off" : "on";

    const panicScript = `
      (
      write_val() {
          [ -f "$1" ] && { chmod +w "$1" 2>/dev/null; echo "$2" > "$1" 2>/dev/null; }
      }

      IONICE=""; command -v ionice >/dev/null 2>&1 && IONICE="ionice -c3"
      nice -n 19 $IONICE find /proc/sys/ /sys/ \\( -name '*panic*' -o -name 'exception-trace' -o -name 'sched_schedstats' -o -name 'tracing_on' -o -name 'log_ecn_error' -o -name 'snapshot_crashdumper' -o -name 'use_spi_crc' \\) 2>/dev/null | while read -r path; do
          write_val "$path" "${val}"
      done

      write_val "/proc/sys/kernel/printk" "${printkVal}"
      write_val "/proc/sys/kernel/printk_devkmsg" "${devkmsgVal}"
      ) >/dev/null 2>&1 &
    `;

    try {
      await exec(panicScript);
      await setConfigValue("DISABLE_PANIC", isDisablePanic ? "1" : "0");
    } catch (err) {
      toast(`Failed: ${err.message}`);
      e.target.checked = !isDisablePanic;
    }
  });

  document.getElementById('btn-support')?.addEventListener('click', (e) => window.openExternalLink('https://t.me/EverythingAboutArchive/221', e));
  document.getElementById('dev-btn-github')?.addEventListener('click', (e) => window.openExternalLink('https://github.com/fuckyoustan', e));
  document.getElementById('dev-btn-telegram')?.addEventListener('click', (e) => window.openExternalLink('tg://resolve?domain=EverythingAboutArchive', e));

  /* --- Home: Save Log — salin LickT.log dari folder module ke penyimpanan internal
     (folder Download). File dicek dulu agar toast error lebih jelas. --- */
  document.getElementById('btn-savelog')?.addEventListener('click', async (e) => {
    e.preventDefault();
    const src = `${MODULE_DIR}/LickT.log`;
    const dest = '/sdcard/Download/LickT.log';
    try {
      const ada = await exec(`[ -f '${src}' ] && echo 1 || echo 0`);
      if (ada.trim() !== '1') { toast(tt('toastLogNotFound', 'Log file not found')); return; }
      await exec(`mkdir -p /sdcard/Download && cp '${src}' '${dest}'`);
      toast(tt('toastLogSaved', 'Log saved to Download'));
    } catch (err) {
      toast(tt('toastLogSaveFailed', 'Failed to save log') + `: ${err.message}`);
    }
  });

  document.getElementById("hal-switch")?.addEventListener('change', (e) => {
    setConfigValue("HAL", e.target.checked ? "1" : "0");
    const row = document.getElementById("disable-hal-row");
    if (row) row.style.display = e.target.checked ? "" : "none";
  });
  document.getElementById("disable-hal-switch")?.addEventListener('change', (e) => setConfigValue("AggHal", e.target.checked ? "1" : "0"));
  document.getElementById("charge-switch")?.addEventListener('change', (e) => setConfigValue("Charge", e.target.checked ? "1" : "0"));

  /* --- search bar miuix --- */
  const searchInput = document.getElementById("app-search");
  const searchClear = document.getElementById("app-search-clear");
  searchInput?.addEventListener("input", () => {
    if (searchClear) searchClear.hidden = !searchInput.value;
    renderAppList();
  });
  searchClear?.addEventListener("click", () => {
    if (searchInput) searchInput.value = "";
    searchClear.hidden = true;
    renderAppList();
    searchInput?.focus();
  });

  /* --- SETTINGS: custom banner --- */
  const bannerFileInput = document.getElementById('banner-file');
  document.getElementById('banner-change-row')?.addEventListener('click', () => bannerFileInput?.click());
  document.getElementById('banner-reset-row')?.addEventListener('click', resetCustomBanner);
  bannerFileInput?.addEventListener('change', async () => {
    const f = bannerFileInput.files && bannerFileInput.files[0];
    bannerFileInput.value = '';   // agar file yang sama bisa dipilih ulang
    await handleBannerUpload(f);
  });

  /* --- SETTINGS: monet / dynamic color (logika KernelSU: html[data-monet]) --- */
  const monetSwitch = document.getElementById('monet-switch');
  monetSwitch?.addEventListener('change', () => {
    applyMonetState(monetSwitch.checked);
    toast(monetSwitch.checked
      ? tt('toastMonetOn', 'Monet colors enabled')
      : tt('toastMonetOff', 'Monet colors disabled'));
  });
  monetSwitch.checked = localStorage.getItem('licking_monet') === '1';
  applyMonetState(monetSwitch.checked);

  /* --- SETTINGS: blur header & nav --- */
  const blurSwitch = document.getElementById('blur-switch');
  const savedBlur = localStorage.getItem('licking_blur') || 'off';
  const savedBlurMode = savedBlur === 'progressive' ? 'progressive' : 'gaussian';
  blurSwitch?.addEventListener('change', () => {
    applyBlurState(blurSwitch.checked, dropdowns['blur-mode-select']?.value || 'gaussian');
  });
  blurSwitch.checked = savedBlur !== 'off';
  dropdowns['blur-mode-select']?.setValue(savedBlurMode);
  applyBlurState(savedBlur !== 'off', savedBlurMode);

  /* --- SETTINGS: full screen (immersive via ksu.fullScreen) --- */
  const fullscreenSwitch = document.getElementById('fullscreen-switch');
  const applyFullScreen = (on) => {
    try {
      if (typeof ksu === 'undefined' || typeof ksu.fullScreen !== 'function') throw new Error('unsupported');
      fullScreen(!!on);   /* wrapper library kernelsu (bundled) */
    } catch (e) {
      if (fullscreenSwitch) fullscreenSwitch.checked = !on;
      toast(tt('toastFullscreenUnsupported', 'Full screen is not supported by this manager'));
      return;
    }
    try { localStorage.setItem('licking_fullscreen', on ? '1' : '0'); } catch (e) {}
  };
  fullscreenSwitch?.addEventListener('change', () => applyFullScreen(fullscreenSwitch.checked));
  fullscreenSwitch.checked = localStorage.getItem('licking_fullscreen') === '1';
  if (fullscreenSwitch.checked) applyFullScreen(true);

  /* --- overlay settings per aplikasi --- */
  document.getElementById('btn-close-settings')?.addEventListener('click', () => {
    document.getElementById('appSettingsOverlay').classList.remove('active');
    currentEditingPkg = null;
    renderAppList();
  });

  document.getElementById('as-main-switch')?.addEventListener('change', async (e) => {
    if(!currentEditingPkg) return;
    try {
      if (e.target.checked) activePackages.add(currentEditingPkg);
      else activePackages.delete(currentEditingPkg);

      await saveAppConfigs();
      toast(e.target.checked ? (currentTranslations.toastAppEnabled || `Enabled for this app`) : (currentTranslations.toastAppDisabled || `Disabled for this app`));
    } catch (err) {
      toast((currentTranslations.toastFailed || `Failed`) + `: ${err.message}`);
      e.target.checked = !e.target.checked;
    }
  });

  document.getElementById('as-custom-switch')?.addEventListener('change', async (e) => {
    if(!currentEditingPkg) return;
    const isCustom = e.target.checked;
    appConfigs[currentEditingPkg].isCustomized = isCustom;

    const group = document.getElementById('custom-config-group');
    if (isCustom) group.classList.remove('disabled');
    else group.classList.add('disabled');

    await saveAppConfigs();
    toast(isCustom ? (currentTranslations.toastCustomUnlocked || `Custom settings unlocked`) : (currentTranslations.toastGlobalSettings || `Using global settings`));
  });

  document.getElementById('as-agg-switch')?.addEventListener('change', async (e) => {
    if(!currentEditingPkg) return;
    const isOn = e.target.checked;
    appConfigs[currentEditingPkg].agg = isOn;
    appConfigs[currentEditingPkg].isCustomized = true;
    
    const row = document.getElementById('as-disable-hal-row');
    if (row) row.style.display = isOn ? "" : "none";
    
    await saveAppConfigs();
    const modeText = currentTranslations.aggMode || "Aggressive Mode";
    toast(`${modeText} ${isOn ? 'ON' : 'OFF'}`);
  });

  document.getElementById('as-disable-hal-switch')?.addEventListener('change', async (e) => {
    if(!currentEditingPkg) return;
    appConfigs[currentEditingPkg].aggHal = e.target.checked;
    appConfigs[currentEditingPkg].isCustomized = true;
    await saveAppConfigs();
  });

  /* tutup dropdown saat overlay discroll */
  document.querySelector('.m-overlay-scroll')?.addEventListener('scroll', closeAllDropdowns, { passive: true });
  /* tutup juga saat halaman utama discroll — menu berposisi fixed akan
     terlepas dari tombolnya bila konten bergulir */
  window.addEventListener('scroll', closeAllDropdowns, { passive: true });

  await checkFastChargeSupport();
  updateExtraCard();
  await fetchThermalPolicies();
  updateThermalPoliciesUI();

  await initCustomBanner();
  
  // Call loadDeviceInfo here
  await loadDeviceInfo();

  loadAppsData();
  updateBannerIndicators();

  setInterval(updateBannerIndicators, 5000);

  /* UI siap -> tutup splash loading */
  hideSplash();
}

/* === SPLASH LOADING ===
   Ditampilkan sejak HTML pertama kali dirender; disembunyikan di akhir init()
   (atau oleh timer pengaman di bawah bila init terhambat). */
let splashHidden = false;
function hideSplash() {
  if (splashHidden) return;
  splashHidden = true;
  document.getElementById('m-splash')?.classList.add('hide');
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}

/* pengaman: init berat/berulir -> splash tetap hilang */
setTimeout(hideSplash, 5000);
