import { exec as ksuExec, toast, getPackagesInfo } from 'kernelsu';

const CONFIG_FILE_PATH = "/data/adb/modules/LickingT/thermal.conf";
const PORN_ARCHIVE_PATH = "/data/adb/modules/LickingT/PornArchive/PornCategories.txt";
const STATUS_FILE_PATH = "/data/adb/modules/LickingT/CurrentState";
const SERVICE_FILE_PATH = "/data/adb/modules/LickingT/service.sh";
const SPOOF_STATE_PATH = "/data/adb/modules/LickingT/battery_spoof_state";

/* === I18N (TRANSLATION) === */
let currentTranslations = {};

const infoContentFallback = {
  aggressive: { title: "Aggressive Mode", text: "Highly recommended for a performance boost." },
  modeOptions: { title: "Operation Mode", text: "Auto: Selected apps only.\nStatic: Always on." },
  zonePolicy: { title: "Thermal Policy", text: "Sets how the system reacts to temps." },
  batterySpoof: { title: "Battery Spoofing", text: "⚠️ Fakes battery temp. Use while gaming only!" }
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
  document.querySelectorAll('.language-option').forEach(opt => {
    if (opt.getAttribute('data-lang') === lang) opt.classList.add('selected');
    else opt.classList.remove('selected');
  });
}

window.showInfo = function(key) {
  const content = currentTranslations.infoModals && currentTranslations.infoModals[key] 
                  ? currentTranslations.infoModals[key] 
                  : infoContentFallback[key];
  if(content) {
    document.getElementById('modal-title').innerText = content.title;
    document.getElementById('modal-text').innerText = content.text;
    document.getElementById('info-modal').classList.add('active');
  }
};

window.closeModal = function() {
  document.getElementById('info-modal').classList.remove('active');
  document.getElementById('languageDialog').classList.remove('active');
  document.getElementById('devModal').classList.remove('active');
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
      statusEl.style.color = "var(--primary, #D0BCFF)";
    } else if (state.trim() === "NotHorny") {
      statusEl.innerText = currentTranslations.statusBalanced || "Balanced 😴";
      statusEl.style.color = "white";
    } else {
      statusEl.innerText = currentTranslations.statusDisabled || "Disabled ❌";
      statusEl.style.color = "#ff6b6b";
    }
  } catch(e) {}
  
  try {
    const pid = await exec(`pgrep -f ${SERVICE_FILE_PATH} || echo ""`);
    pidEl.innerText = pid.trim() ? `PID: ${pid.trim()}` : "PID: NULL";
  } catch(e) {}
}

async function updateDeviceInfo() {
  try {
    const ver = await exec("grep '^version=' /data/adb/modules/LickingT/module.prop 2>/dev/null || echo 'version=Unknown'");
    document.getElementById("module-version").innerText = ver.replace("version=", "").trim();
    document.getElementById("device-model").innerText = await exec("getprop ro.product.model || true") || "Unknown";
    document.getElementById("device-android").innerText = await exec("getprop ro.build.version.release || true") || "Unknown";
    document.getElementById("device-kernel").innerText = await exec("uname -r || true");
    document.getElementById("device-chipset").innerText = await exec("getprop ro.board.platform || getprop ro.hardware.chipname || true");
  } catch(e) {}
}

async function setConfigValue(key, value) {
  try {
    const tmp = `/data/local/tmp/${key}_temp.conf`;
    await exec(`grep -v '^${key}=' ${CONFIG_FILE_PATH} > ${tmp} && mv ${tmp} ${CONFIG_FILE_PATH} || true`);
    await exec(`echo '${key}=${value}' >> ${CONFIG_FILE_PATH}`);
    toast(currentTranslations.toastSaved || `Saved successfully`);
  } catch(e) { toast(`Failed: ${e.message}`); }
}

async function updateExtraCard() {
  try {
    const out = await exec(`cat ${CONFIG_FILE_PATH} || true`);
    let mode = "automatic", hal = "0";
    out.split("\n").forEach(l => {
      const t = l.trim();
      if(t.startsWith("MODE=")) mode = t.replace("MODE=","").trim().toLowerCase() === "auto" ? "automatic" : "static";
      if(t.startsWith("HAL=")) hal = t.replace("HAL=","").trim();
    });
    
    const modeSelect = document.getElementById("mode-select");
    const halSwitch = document.getElementById("hal-switch");
    if(modeSelect) modeSelect.value = mode;
    if(halSwitch) halSwitch.checked = (hal === "1");
  } catch(e) {}
}

async function updateThermalPolicies() {
  const select = document.getElementById("policy-select");
  if (!select) return;
  try {
    const avail = await exec("cat /sys/class/thermal/thermal_zone0/available_policies");
    const curr = await exec("cat /sys/class/thermal/thermal_zone0/policy");
    const policies = avail.split(/\s+/).filter(p => p);
    select.innerHTML = "";
    policies.forEach(p => {
      const opt = document.createElement("option");
      opt.value = p; opt.text = p;
      if(p === curr.trim()) opt.selected = true;
      select.appendChild(opt);
    });
  } catch(e) { select.innerHTML = "<option value=''>Not supported</option>"; }
}

/* === APP LIST === */
let cachedApps = [];
let activePackages = new Set();

async function loadAppsData() {
  try {
    const content = await exec(`cat ${PORN_ARCHIVE_PATH} || true`);
    activePackages = new Set(content.split('\n').map(l => l.trim()).filter(Boolean));

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

            if (typeof info === 'string') {
                info = JSON.parse(info);
            }

            if (Array.isArray(info) && info.length > 0) {
                const appData = info[0];
                const label = appData.appLabel || appData.label || appData.appName;
                if (label) {
                    pkgObj.appLabel = label;
                }
            }
        } catch (err) {}
    }));

    cachedApps = [];
    rawPackages.forEach(pkg => {
        if (thirdPartyPkgs.has(pkg.packageName)) {
            cachedApps.push(pkg);
        }
    });

    renderAppList();
  } catch(e) {
    const container = document.getElementById("appList");
    if(container) container.innerHTML = `<div style="color:#ff6b6b; padding:1rem; text-align:center;">Error loading apps: ${e.message}</div>`;
  }
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
    container.innerHTML = `<div style='text-align:center; padding: 2rem; color: var(--onSurfaceVariant, #CAC4D0); font-size: 0.85rem;'>${currentTranslations.noApps || "No apps found."}</div>`;
    return;
  }

  const fragment = document.createDocumentFragment();

  filtered.forEach(pkg => {
    const isChecked = activePackages.has(pkg.packageName);
    const labelText = pkg.appLabel || pkg.packageName;
    
    const item = document.createElement('div');
    item.className = 'isolate-app-item';
    
    const wrapper = document.createElement('div');
    wrapper.className = 'isolate-content-wrapper';
    
    const img = document.createElement('img');
    img.className = 'isolate-app-icon';
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
    textGroup.className = 'isolate-text-group';

    const labelEl = document.createElement('span');
    labelEl.className = 'isolate-app-label';
    labelEl.textContent = labelText;
    if (isChecked) labelEl.style.color = "var(--primary, #D0BCFF)";

    const pkgEl = document.createElement('span');
    pkgEl.className = 'isolate-app-pkg';
    pkgEl.textContent = pkg.packageName;

    textGroup.appendChild(labelEl);
    textGroup.appendChild(pkgEl);

    wrapper.appendChild(img);
    wrapper.appendChild(textGroup);

    const switchLabel = document.createElement('label');
    switchLabel.className = 'custom-switch';

    const input = document.createElement('input');
    input.type = 'checkbox';
    input.className = 'app-switch';
    input.checked = isChecked;

    const slider = document.createElement('span');
    slider.className = 'switch-slider';

    switchLabel.appendChild(input);
    switchLabel.appendChild(slider);

    input.addEventListener('change', async () => {
        try {
            if (input.checked) {
                activePackages.add(pkg.packageName);
            } else {
                activePackages.delete(pkg.packageName);
            }
            
            const cleanWrite = Array.from(activePackages).join('\n');
            await exec(`printf %s '${cleanWrite.replace(/'/g,"'\\''")}' > ${PORN_ARCHIVE_PATH}`);
            toast(input.checked ? `➕ ${labelText}` : `➖ ${labelText}`);
            renderAppList();
        } catch (err) {
            toast(`Failed to save: ${err.message}`);
            input.checked = !input.checked;
        }
    });

    item.appendChild(wrapper);
    item.appendChild(switchLabel);
    fragment.appendChild(item);
  });

  container.appendChild(fragment);
}

/* === BATTERY SPOOFING SLIDER === */
function updateSliderProgress(slider) {
  if(!slider) return;
  const value = parseFloat(slider.value);
  const min = parseFloat(slider.min) || 1;
  const max = parseFloat(slider.max) || 45;
  const percentage = ((value - min) / (max - min)) * 100;
  
  slider.style.background = `linear-gradient(to right, var(--primaryContainer, #4F378B) ${percentage}%, var(--surfaceContainerHighest, #36343B) ${percentage}%)`;
}

async function initBatterySpoof() {
  try {
    const savedVal = await exec(`cat ${SPOOF_STATE_PATH} 2>/dev/null || echo "1"`);
    const val = parseInt(savedVal.trim());
    const slider = document.getElementById("battery-spoof-slider");
    const valDisplay = document.getElementById("battery-spoof-val");
    if (!isNaN(val) && val >= 1 && val <= 45 && slider && valDisplay) { 
      slider.value = val; 
      valDisplay.innerText = val + "°C"; 
      updateSliderProgress(slider);
    } else if (slider) {
      updateSliderProgress(slider);
    }
  } catch(e) {}
}


/* =========================================
   INISIALISASI AMAN
========================================= */
function init() {
  const savedLang = localStorage.getItem('licking_lang') || 'en';
  loadLanguage(savedLang);

  document.getElementById('btn-language')?.addEventListener('click', () => document.getElementById('languageDialog').classList.add('active'));
  document.getElementById('dev-profile-btn')?.addEventListener('click', () => document.getElementById('devModal').classList.add('active'));
  document.getElementById('closeLangDialog')?.addEventListener('click', window.closeModal);
  document.getElementById('close-info-modal')?.addEventListener('click', window.closeModal);
  
  document.querySelectorAll('.modal-overlay').forEach(el => {
    el.addEventListener('click', (e) => { if(e.target === el) window.closeModal(); });
  });
  
  document.querySelectorAll('.language-option').forEach(opt => {
    opt.addEventListener('click', () => {
      loadLanguage(opt.getAttribute('data-lang'));
      window.closeModal();
    });
  });

  const btnMain = document.getElementById('openMain');
  const btnApps = document.getElementById('openGameList');
  const viewMain = document.getElementById('mainMenu');
  const viewApps = document.getElementById('gameListMenu');

  btnMain?.addEventListener('click', () => {
    btnMain.classList.add('active');
    btnApps?.classList.remove('active');
    viewMain?.classList.remove('kanjud');
    viewApps?.classList.add('kanjud');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });

  btnApps?.addEventListener('click', () => {
    btnApps.classList.add('active');
    btnMain?.classList.remove('active');
    viewApps?.classList.remove('kanjud');
    viewMain?.classList.add('kanjud');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });

  document.getElementById('btn-support')?.addEventListener('click', (e) => window.openExternalLink('https://t.me/EverythingAboutArchive/221', e));
  document.getElementById('modal-btn-github')?.addEventListener('click', (e) => window.openExternalLink('https://github.com/fuckyoustan', e));
  document.getElementById('modal-btn-telegram')?.addEventListener('click', (e) => window.openExternalLink('tg://resolve?domain=EverythingAboutArchive', e));

  document.getElementById("hal-switch")?.addEventListener('change', (e) => setConfigValue("HAL", e.target.checked ? "1" : "0"));
  document.getElementById("mode-select")?.addEventListener('change', (e) => setConfigValue("MODE", e.target.value === "automatic" ? "auto" : "static"));
  document.getElementById("policy-select")?.addEventListener('change', async (e) => {
    if(!e.target.value) return;
    try {
      await exec(`for z in /sys/class/thermal/thermal_zone*; do chmod 644 "$z/policy"; echo "${e.target.value}" > "$z/policy"; done`);
      toast(currentTranslations.toastSaved || `Policy updated`);
    } catch(err) { toast(`Failed: ${err.message}`); }
  });

  const batterySlider = document.getElementById("battery-spoof-slider");
  const valDisplay = document.getElementById('battery-spoof-val');
  
  batterySlider?.addEventListener("input", (e) => {
    if(valDisplay) valDisplay.innerText = e.target.value + '°C';
    updateSliderProgress(e.target);
  });

  document.getElementById("btn-apply")?.addEventListener("click", async () => {
    if(!batterySlider) return;
    const val = batterySlider.value;
    try {
      await exec(`cmd battery set -f temp ${parseInt(val) * 10} 2>/dev/null`);
      await exec(`echo "${val}" > ${SPOOF_STATE_PATH}`);
      toast(currentTranslations.toastSpoofed ? currentTranslations.toastSpoofed.replace("{val}", val) : `Battery locked at ${val}°C`);
    } catch(e) { toast(`Spoof error: ${e.message}`); }
  });

  document.getElementById("btn-reset")?.addEventListener("click", async () => {
    try {
      await exec("cmd battery reset");
      await exec(`rm -f ${SPOOF_STATE_PATH} 2>/dev/null`);
      if(batterySlider) {
        batterySlider.value = 1;
        updateSliderProgress(batterySlider);
      }
      if(valDisplay) valDisplay.innerText = "1°C";
      toast(currentTranslations.toastReset || "Battery temp is back to normal");
    } catch(e) { toast("Reset error"); }
  });

  document.getElementById("app-search")?.addEventListener("input", renderAppList);

  updateExtraCard();
  updateThermalPolicies();
  loadAppsData();
  initBatterySpoof();
  updateBannerIndicators();
  
  setInterval(updateBannerIndicators, 5000);
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
