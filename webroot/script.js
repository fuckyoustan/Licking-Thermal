// Path File
const THERMAL_SCRIPT_PATH = "/system/bin/LickT";
const CONFIG_FILE_PATH = "/data/adb/modules/LickingT/thermal.conf";
const PORN_ARCHIVE_PATH = "/data/adb/modules/LickingT/PornArchive/PornCategories.txt";

// --- KSU/Magisk Exec Function ---
function exec(command) {
  return new Promise((resolve, reject) => {
    const cbName = `exec_cb_${Date.now()}`;
    window[cbName] = (errno, stdout, stderr) => {
      delete window[cbName];
      if (errno !== 0) {
        reject(new Error(stderr || `Exit ${errno}`));
        return;
      }
      resolve(stdout.trim());
    };
    try {
      if (typeof ksu === 'undefined' || !ksu.exec) {
          reject(new Error("KSU/Magisk execution object (ksu.exec) not found."));
          return;
      }
      ksu.exec(command, "{}", cbName);
    } catch (err) {
      delete window[cbName];
      reject(err);
    }
  });
}

/* ---------------- Link Handler Baru ---------------- */
async function openExternalLink(uri, event) {
    event.preventDefault(); 
    const command = `am start -a android.intent.action.VIEW -d '${uri}'`;
    
    try {
        await exec(`${command} || true`); 
    } catch (e) {
        console.error(`Failed to open link ${uri}:`, e);
        alert(`Error opening link: ${e.message}. URI: ${uri}`);
    }
}

/* ---------------- Device Info (Real-Time) ---------------- */
async function updateDeviceInfo() {
  try {
    const model   = await exec("getprop ro.product.model || true");
    const android = await exec("getprop ro.build.version.release || true");
    const kernel  = await exec("uname -r || true");
    const chipset = await exec("getprop ro.board.platform || getprop ro.hardware.chipname || true");
    const abis    = await exec("getprop ro.product.cpu.abilist || getprop ro.product.cpu.abi || true");

    document.getElementById("device-model").innerText = model || "Unknown";
    document.getElementById("device-android").innerText = android || "Unknown";
    document.getElementById("device-kernel").innerText = kernel || "Unknown";
    document.getElementById("device-chipset").innerText = chipset || "Unknown";
    document.getElementById("device-abis").innerText = abis || "Unknown";

  } catch (e) {
    document.getElementById("device-model").innerText = "Error: Cannot get info";
    document.getElementById("device-android").innerText = "Error: Cannot get info";
    document.getElementById("device-kernel").innerText = "Error: Cannot get info";
    document.getElementById("device-chipset").innerText = "Error: Cannot get info";
    document.getElementById("device-abis").innerText = "Error: Cannot get info";
    console.error("Failed to execute commands for device info:", e);
  }
}

/* ---------------- Real-time Thermal Monitoring ---------------- */
async function updateThermalMonitoring() {
  const monitoringElement = document.getElementById("thermal-monitoring");
  monitoringElement.innerHTML = ''; 

  try {
    const output = await exec(`${THERMAL_SCRIPT_PATH}`);
    
    const lines = output.split('\n').filter(line => line.trim() !== '');

    if (lines.length === 0) {
      monitoringElement.innerHTML = `<div style="text-align: center; padding: 12px 0;"><p class="info-label thermal-high">No thermal data received</p></div>`;
      return;
    }

    lines.forEach((line) => {
      const parts = line.split(':');
      if (parts.length < 2) return;

      const label = parts[0].trim().replace(/\s+/g, ' '); 
      const valueText = parts[1].trim(); 
      
      const tempValueMatch = valueText.match(/(\d+)/);
      const tempValue = tempValueMatch ? parseInt(tempValueMatch[0], 10) : 0;
      
      let tempClass = '';
      if (tempValue >= 60) { 
        tempClass = 'thermal-high';
      }

      const item = document.createElement('div');
      item.className = 'info-item'; 
      item.innerHTML = `
        <span class="info-label">${label}</span>
        <span class="info-value ${tempClass}">${valueText}</span>
      `;

      monitoringElement.appendChild(item);
    });
    
  } catch (e) {
    monitoringElement.innerHTML = `<div style="text-align: center; padding: 12px 0;"><p class="info-label thermal-high">Error executing script at ${THERMAL_SCRIPT_PATH}: ${e.message}</p></div>`;
    console.error("Failed to execute thermal script:", e);
  }
}

/* ---------------- Extra Controls (MODE & HAL) ---------------- */

async function setConfigValue(key, value, type) {
    try {
        const tempFile = `/data/local/tmp/${key}_temp.conf`;
        const removeOldCommand = `grep -v '^${key}=' ${CONFIG_FILE_PATH} | tee ${tempFile} > /dev/null && mv ${tempFile} ${CONFIG_FILE_PATH} || true`;
        const addNewCommand = `echo '${key}=${value}' >> ${CONFIG_FILE_PATH}`;
        
        await exec(removeOldCommand);
        await exec(addNewCommand);
        
        alert(`${type} setting changed to: ${value}`);

    } catch (e) {
        console.error(`Failed to set ${key} config:`, e);
        alert(`Error setting ${type} config: ${e.message}`);
        updateExtraCard(); 
    }
}

async function updateExtraCard() {
    try {
        const out = await exec(`cat ${CONFIG_FILE_PATH} || true`);
        const lines = out.split("\n");
        let MODE = "automatic"; 
        let HAL = "0"; 

        lines.forEach(line => {
            const lineTrimmed = line.trim();
            if (lineTrimmed.startsWith("MODE=")) {
                const fileMode = lineTrimmed.replace("MODE=", "").trim().toLowerCase();
                MODE = (fileMode === "auto") ? "automatic" : "static"; 
            }
            if (lineTrimmed.startsWith("HAL=")) {
                HAL = lineTrimmed.replace("HAL=", "").trim();
            }
        });

        const modeSelect = document.getElementById("mode-select");
        modeSelect.value = MODE;
        
        const halSwitch = document.getElementById("hal-switch");
        halSwitch.checked = (HAL === "1");

    } catch (e) {
        console.error(`Failed to read config file ${CONFIG_FILE_PATH}:`, e);
        document.getElementById("mode-select").disabled = true;
        document.getElementById("hal-switch").disabled = true;
        alert(`Error reading module config. Please check KSU/Magisk/File permissions. Details: ${e.message}`);
    }
}

function handleModeChange(selectedMode) {
    const newFileMode = (selectedMode === "automatic") ? "auto" : "static";
    setConfigValue("MODE", newFileMode, "Mode");
}

function handleHalChange(isChecked) {
    const newHalValue = isChecked ? "1" : "0"; 
    setConfigValue("HAL", newHalValue, "Kill HAL");
}

/* ---------------- List Package Control ---------------- */

async function updatePornArchive() {
    const textarea = document.getElementById("porn-archive-textarea");
    textarea.value = "Loading file contents...";
    
    try {
        const content = await exec(`cat ${PORN_ARCHIVE_PATH} || true`);
        textarea.value = content.trim() + (content.trim().length > 0 ? "\n" : "");
        
    } catch (e) {
        textarea.value = `Error reading file: ${e.message}\n(File path: ${PORN_ARCHIVE_PATH})`;
        console.error("Failed to read List Package file:", e);
    }
}

async function savePornArchive() {
    const textarea = document.getElementById("porn-archive-textarea");
    const content = textarea.value.trim();
    
    try {
        const cleanContent = content.split('\n')
            .map(line => line.trim())
            .filter(line => line.length > 0)
            .join('\n');

        const writeCommand = `printf %s '${cleanContent.replace(/'/g, "'\\''")}' > ${PORN_ARCHIVE_PATH}`;

        await exec(writeCommand);
        
        alert("List Package saved successfully!");
        await updatePornArchive(); 
        
    } catch (e) {
        alert(`Error saving List Package: ${e.message}`);
        console.error("Failed to save List Package file:", e);
    }
}

// Global functions exposed to HTML for events (onchange, onclick)
window.openExternalLink = openExternalLink;
window.handleModeChange = handleModeChange;
window.handleHalChange = handleHalChange;
window.updatePornArchive = updatePornArchive;
window.savePornArchive = savePornArchive;


// Initialize
document.addEventListener('DOMContentLoaded', () => {
  updateDeviceInfo(); 
  updateExtraCard();
  updatePornArchive();
  updateThermalMonitoring();
  setInterval(updateThermalMonitoring, 15000); 
});