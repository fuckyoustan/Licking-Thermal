import { exec as ksuExec, toast } from 'https://esm.run/kernelsu';

const CONFIG_FILE_PATH="/data/adb/modules/LickingT/thermal.conf";
const PORN_ARCHIVE_PATH="/data/adb/modules/LickingT/PornArchive/PornCategories.txt";
const STATUS_FILE_PATH="/data/adb/modules/LickingT/CurrentState";
const SERVICE_FILE_PATH="/data/adb/modules/LickingT/service.sh";
const SPOOF_STATE_PATH="/data/adb/modules/LickingT/battery_spoof_state";

const infoContent = {
  aggressive: {
    title: "Aggressive Mode",
    text: "Highly recommended for boosting performance. However, if a game you are playing uses anti-cheat that detects thermal modification, disable this feature immediately to avoid issues."
  },
  modeOptions: {
    title: "Mode Options",
    text: "Choose the operation mode that fits your needs:\n\n• Automatic: Only disables thermal throttling when you launch specific applications defined in your 'List Package'.\n\n• Static: Keeps thermal throttling disabled continuously, regardless of which app is currently running."
  },
  zonePolicy: {
    title: "Zone Policy",
    text: "Zone Policy dictates the logic determines how the system responds when thermal zones hit specific temperature thresholds. It goes beyond just reading temperatures; it decides the countermeasure actions. (For deep-dive details, it's best to ask an AI!)."
  },
  batterySpoof: {
    title: "Battery Spoofing",
    text: "⚠️ STRONG WARNING ⚠️\nUse at your own risk! This feature fakes battery temperature reports to prevent throttling under heavy loads. It significantly impacts long-term battery health. Only use this while gaming and RESET it immediately after you finish.\n\nKnown bug: It may cause inaccurate battery percentage readings."
  }
};

async function exec(command) {
  const { errno, stdout, stderr } = await ksuExec(command);
  if (errno !== 0) {
    throw new Error(stderr || `Exit ${errno}`);
  }
  return stdout.trim();
}

async function updateBannerIndicators() {
  const statusEl = document.getElementById("status-indicator");
  const pidEl = document.getElementById("pid-indicator");
  try {
    const currentState = await exec(`cat ${STATUS_FILE_PATH} || echo "Unknown"`);
    if (currentState.trim() === "Horny") {
      statusEl.innerText = "✨ Working";
      statusEl.classList.add("status-working");
    } else if (currentState.trim() === "NotHorny") {
      statusEl.innerText = "😴 Balance Mode";
      statusEl.classList.remove("status-working");
    } else {
      statusEl.innerText = "❌ Not Working";
      statusEl.classList.remove("status-working");
    }
  } catch (e) {
    statusEl.innerText = "😴 Balance Mode";
  }
  try {
    const pid = await exec(`pgrep -f ${SERVICE_FILE_PATH} || echo ""`);
    if (pid.trim()) {
      pidEl.innerText = `Service PID: ${pid.trim()}`;
    } else {
      pidEl.innerText = "Service PID: NULL";
    }
  } catch (e) {
    pidEl.innerText = "Service PID: NULL";
  }
}

async function openExternalLink(uri,event){
  event.preventDefault();
  const command=`am start -a android.intent.action.VIEW -d '${uri}'`;
  try{
    await exec(`${command}||true`)
  }catch(e){
    console.error(`Failed to open link ${uri}:`,e);
    toast(`Error opening link: ${e.message}. URI: ${uri}`);
  }
}

async function updateDeviceInfo(){
  try{
    const model=await exec("getprop ro.product.model || true");
    const android=await exec("getprop ro.build.version.release || true");
    const kernel=await exec("uname -r || true");
    const chipset=await exec("getprop ro.board.platform || getprop ro.hardware.chipname || true");
    const abis=await exec("getprop ro.product.cpu.abilist || getprop ro.product.cpu.abi || true");
    document.getElementById("device-model").innerText=model||"Unknown";
    document.getElementById("device-android").innerText=android||"Unknown";
    document.getElementById("device-kernel").innerText=kernel||"Unknown";
    document.getElementById("device-chipset").innerText=chipset||"Unknown";
    document.getElementById("device-abis").innerText=abis||"Unknown"
  }catch(e){
    document.getElementById("device-model").innerText="Error";
    document.getElementById("device-android").innerText="Error";
    console.error("Failed to execute commands for device info:",e)
  }
}

async function setConfigValue(key,value,type){
  try{
    const tempFile=`/data/local/tmp/${key}_temp.conf`;
    const removeOldCommand=`grep -v '^${key}=' ${CONFIG_FILE_PATH} | tee ${tempFile} > /dev/null && mv ${tempFile} ${CONFIG_FILE_PATH} || true`;
    const addNewCommand=`echo '${key}=${value}' >> ${CONFIG_FILE_PATH}`;
    await exec(removeOldCommand);
    await exec(addNewCommand);
    toast(`${type} setting changed to: ${value}`);
  }catch(e){
    toast(`Error setting ${type} config: ${e.message}`);
    updateExtraCard()
  }
}

async function updateExtraCard(){
  try{
    const out=await exec(`cat ${CONFIG_FILE_PATH} || true`);
    const lines=out.split("\n");
    let MODE="automatic";
    let HAL="0";
    lines.forEach(line=>{
      const lineTrimmed=line.trim();
      if(lineTrimmed.startsWith("MODE=")){
        const fileMode=lineTrimmed.replace("MODE=","").trim().toLowerCase();
        MODE=(fileMode==="auto")?"automatic":"static"
      }
      if(lineTrimmed.startsWith("HAL=")){
        HAL=lineTrimmed.replace("HAL=","").trim()
      }
    });
    document.getElementById("mode-select").value=MODE;
    document.getElementById("hal-switch").checked=(HAL==="1")
  }catch(e){
    console.error(`Failed to read config:`,e);
  }
}

async function updateThermalPolicies() {
  const policySelect = document.getElementById("policy-select");
  try {
    const available = await exec("cat /sys/class/thermal/thermal_zone0/available_policies");
    const current = await exec("cat /sys/class/thermal/thermal_zone0/policy");
    const policies = available.split(/\s+/).filter(p => p.trim().length > 0);
    policySelect.innerHTML = "";
    policies.forEach(policy => {
      const option = document.createElement("option");
      option.value = policy;
      option.text = policy;
      if (policy === current.trim()) {
        option.selected = true;
      }
      policySelect.appendChild(option);
    });
  } catch (e) {
    policySelect.innerHTML = "<option value=''>Not Supported</option>";
    console.error("Failed to fetch thermal policies:", e);
  }
}

async function handlePolicyChange(selectedPolicy) {
  if (!selectedPolicy) return;  
  try {
    const command = `for zone in /sys/class/thermal/thermal_zone*; do chmod 644 "$zone/policy"; echo "${selectedPolicy}" > "$zone/policy"; done`;
    await exec(command);
    toast(`Thermal Policy changed to: ${selectedPolicy}`);
  } catch (e) {
    toast(`Error setting policy: ${e.message}`);
    updateThermalPolicies();
  }
}

function handleModeChange(selectedMode){
  const newFileMode=(selectedMode==="automatic")?"auto":"static";
  setConfigValue("MODE",newFileMode,"Mode")
}

function handleHalChange(isChecked){
  const newHalValue=isChecked?"1":"0";
  setConfigValue("HAL",newHalValue,"Kill HAL")
}

async function updatePornArchive(){
  const textarea=document.getElementById("porn-archive-textarea");
  textarea.value="Loading file contents...";
  try{
    const content=await exec(`cat ${PORN_ARCHIVE_PATH} || true`);
    textarea.value=content.trim()+(content.trim().length>0?"\n":"")
  }catch(e){
    textarea.value=`Error reading file: ${e.message}`;
  }
}

async function savePornArchive(){
  const textarea=document.getElementById("porn-archive-textarea");
  const content=textarea.value.trim();
  try{
    const cleanContent=content.split('\n').map(line=>line.trim()).filter(line=>line.length>0).join('\n');
    const writeCommand=`printf %s '${cleanContent.replace(/'/g,"'\\''")}' > ${PORN_ARCHIVE_PATH}`;
    await exec(writeCommand);
    toast("List Package saved!");
    await updatePornArchive()
  }catch(e){
    toast(`Error: ${e.message}`);
  }
}

// Fitur Load Status Battery Spoofing dari File
async function initBatterySpoof() {
  try {
    // Membaca file state, jika tidak ada/error maka default "1"
    const savedVal = await exec(`cat ${SPOOF_STATE_PATH} 2>/dev/null || echo "1"`);
    const val = parseInt(savedVal.trim());
    
    // Validasi apakah angkanya masuk akal (antara 1 dan 45)
    if (!isNaN(val) && val >= 1 && val <= 45) {
      document.getElementById("battery-spoof-slider").value = val;
      document.getElementById("battery-spoof-val").innerText = val;
    } else {
      document.getElementById("battery-spoof-slider").value = 1;
      document.getElementById("battery-spoof-val").innerText = "1";
    }
  } catch (e) {
    console.error("Gagal memuat status spoofing baterai:", e);
  }
}

// Fitur Apply Battery Spoofing (Menyimpan Status)
async function applyBatterySpoof() {
  const sliderVal = document.getElementById("battery-spoof-slider").value;
  const appliedVal = parseInt(sliderVal) * 10; 
  const command = `cmd battery set -f temp ${appliedVal} 2>/dev/null`;
  
  try {
    await exec(command);
    // Menyimpan posisi slider terakhir ke file
    await exec(`echo "${sliderVal}" > ${SPOOF_STATE_PATH}`);
    toast(`Spoofed: Battery set to ${sliderVal}°C`);
  } catch (e) {
    toast(`Error battery spoofing: ${e.message}`);
  }
}

// Fitur Reset Battery Spoofing (Menghapus Status dan reset ke 1)
async function resetBatterySpoof() {
  try {
    await exec("cmd battery reset");
    // Menghapus file status
    await exec(`rm -f ${SPOOF_STATE_PATH} 2>/dev/null`);
    // Mengembalikan UI slider ke angka 1
    document.getElementById("battery-spoof-slider").value = 1;
    document.getElementById("battery-spoof-val").innerText = "1";
    toast("Reset: Battery temperature returns to normal");
  } catch (e) {
    toast(`Error mereset baterai: ${e.message}`);
  }
}

function showInfo(contentKey) {
  const content = infoContent[contentKey];
  if (content) {
    document.getElementById('modal-title').innerText = content.title;
    document.getElementById('modal-text').innerText = content.text;
    document.getElementById('info-modal').classList.add('active');
  }
}

function closeModal() {
  document.getElementById('info-modal').classList.remove('active');
}

function closeModalOnClickOutside(event) {
  if (event.target.id === 'info-modal') {
    closeModal();
  }
}

window.openExternalLink=openExternalLink;
window.handleModeChange=handleModeChange;
window.handleHalChange=handleHalChange;
window.handlePolicyChange = handlePolicyChange;
window.updatePornArchive=updatePornArchive;
window.savePornArchive=savePornArchive;
window.applyBatterySpoof = applyBatterySpoof;
window.resetBatterySpoof = resetBatterySpoof;
window.showInfo = showInfo;
window.closeModal = closeModal;
window.closeModalOnClickOutside = closeModalOnClickOutside;

document.addEventListener('DOMContentLoaded',()=>{
  updateDeviceInfo();
  updateExtraCard();
  updateThermalPolicies();
  updatePornArchive();
  initBatterySpoof(); // Memuat status slider saat UI di-refresh
  updateBannerIndicators();
  setInterval(updateBannerIndicators, 5000);
});
