#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>
#include <glob.h>
#include <ftw.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <dirent.h>

/* ─────────────────────────────────────────────
 * MODE CONSTANTS
 * ───────────────────────────────────────────── */
#define MODE_AMATURE 0
#define MODE_MILF    1
#define MODE_ANAL    2

/* ─────────────────────────────────────────────
 * GLOBAL: mode saat ini (dipakai callback ftw)
 * ───────────────────────────────────────────── */
static int g_mode = -1;

/* ─────────────────────────────────────────────
 * HELPER: Jalankan perintah shell sederhana
 * ───────────────────────────────────────────── */
static void sh(const char *cmd) {
    int r = system(cmd);
    (void)r;
}

/* ─────────────────────────────────────────────
 * HELPER: Tulis val ke satu path (ekuivalen Miyabi)
 *   do_chmod : jika 1, chmod 644 dulu sebelum tulis
 * ───────────────────────────────────────────── */
static void miyabi(const char *val, const char *path, int do_chmod) {
    if (!val || !path) return;
    struct stat st;
    if (stat(path, &st) != 0 || !S_ISREG(st.st_mode)) return;
    if (do_chmod) chmod(path, 0644);
    int fd = open(path, O_WRONLY | O_TRUNC | O_CLOEXEC);
    if (fd < 0) return;
    write(fd, val, strlen(val));
    close(fd);
}

/* ─────────────────────────────────────────────
 * HELPER: Tulis val ke semua path yang cocok glob
 * ───────────────────────────────────────────── */
static void miyabi_glob(const char *val, const char *pattern, int do_chmod) {
    glob_t g;
    if (glob(pattern, GLOB_NOSORT | GLOB_NOESCAPE, NULL, &g) == 0) {
        for (size_t i = 0; i < g.gl_pathc; i++) {
            miyabi(val, g.gl_pathv[i], do_chmod);
        }
        globfree(&g);
    }
}

/* ─────────────────────────────────────────────
 * HELPER: chmod seluruh file yang cocok glob
 * ───────────────────────────────────────────── */
static void chmod_glob(const char *pattern, mode_t mode) {
    glob_t g;
    if (glob(pattern, GLOB_NOSORT | GLOB_NOESCAPE, NULL, &g) == 0) {
        for (size_t i = 0; i < g.gl_pathc; i++) {
            chmod(g.gl_pathv[i], mode);
        }
        globfree(&g);
    }
}

/* ─────────────────────────────────────────────
 * HELPER: chmod satu path jika ada
 * ───────────────────────────────────────────── */
static void chmod_if_exists(const char *path, mode_t mode) {
    struct stat st;
    if (stat(path, &st) == 0) chmod(path, mode);
}

/* ─────────────────────────────────────────────
 * HELPER: jalankan perintah dan baca output baris-per-baris,
 *         panggil callback(line, userdata) tiap baris
 * ───────────────────────────────────────────── */
typedef void (*line_cb)(const char *line, void *ud);

static void pipe_each_line(const char *cmd, line_cb cb, void *ud) {
    FILE *fp = popen(cmd, "r");
    if (!fp) return;
    char buf[512];
    while (fgets(buf, sizeof(buf), fp)) {
        size_t len = strlen(buf);
        while (len > 0 && (buf[len-1] == '\n' || buf[len-1] == '\r'))
            buf[--len] = '\0';
        if (len > 0) cb(buf, ud);
    }
    pclose(fp);
}

/* =========================================================
 * ==================  FUNGSI-FUNGSI BERSAMA  ==============
 * ========================================================= */

static void comatozze(int mode) {
    const char *val = (mode == MODE_ANAL) ? "1" : "0";
    int do_chmod    = (mode != MODE_ANAL);

    miyabi_glob(val, "/sys/block/*/queue/iostats",   do_chmod);
    miyabi_glob(val, "/sys/block/*/queue/rotational", do_chmod);
    miyabi_glob(val, "/sys/block/*/queue/add_random", do_chmod);
}

/* ─────────────────────────────────────────────
 * INTERNAL: tulis satu entry ke MTK thermal zone
 * ───────────────────────────────────────────── */
static void write_tz(const char *zone, const char *actor,
                     int t_limit, const char *cooler_chain,
                     int interval, int do_chmod) {
    char entry[1024], zone_path[128];
    snprintf(zone_path, sizeof(zone_path), "/proc/driver/thermal/%s", zone);
    snprintf(entry, sizeof(entry), "1 %d000 0 %s %s %d",
             t_limit, actor, cooler_chain, interval);
    miyabi(entry, zone_path, do_chmod);
}

static void EmmaStone(int mode) {
    const char *tzcpu = "/proc/driver/thermal/tzcpu";
    struct stat st;
    if (stat(tzcpu, &st) != 0) return;

    int t_limit;
    const char *cooler;
    int do_chmod = (mode != MODE_ANAL);

    if (mode == MODE_AMATURE) {
        t_limit = 120;
        cooler  = "no-cooler";
    } else if (mode == MODE_MILF) {
        t_limit = 125;
        cooler  = "no-cooler";
    } else { /* ANAL */
        t_limit = 117;
        cooler  = "cpu_heavy";
    }

    char cooler_chain[512];
    cooler_chain[0] = '\0';
    for (int i = 0; i < 9; i++) {
        char part[64];
        snprintf(part, sizeof(part), "0 0 %s ", cooler);
        strncat(cooler_chain, part, sizeof(cooler_chain) - strlen(cooler_chain) - 1);
    }
    
    size_t clen = strlen(cooler_chain);
    if (clen > 0 && cooler_chain[clen-1] == ' ') cooler_chain[clen-1] = '\0';

    write_tz("tzcpu",     "mtktscpu-sysrst",     t_limit, cooler_chain, 200,  do_chmod);
    write_tz("tzpmic",    "mtktspmic-sysrst",    t_limit, cooler_chain, 1000, do_chmod);
    write_tz("tzbattery", "mtktsbattery-sysrst", t_limit, cooler_chain, 1000, do_chmod);
    write_tz("tzpa",      "mtk-cl-kshutdown00",  t_limit, cooler_chain, 2000, do_chmod);
    write_tz("tzcharger", "mtktscharger-sysrst", t_limit, cooler_chain, 2000, do_chmod);
    write_tz("tzwmt",     "mtktswmt-sysrst",     t_limit, cooler_chain, 1000, do_chmod);
    write_tz("tzbts",     "mtktsAP-sysrst",      t_limit, cooler_chain, 1000, do_chmod);
    write_tz("tzbtsnrpa", "mtk-cl-kshutdown01",  t_limit, cooler_chain, 1000, do_chmod);
    write_tz("tzbtspa",   "mtk-cl-kshutdown02",  t_limit, cooler_chain, 1000, do_chmod);
}

static void SweetyFox(int mode) {
    mode_t perm = (mode == MODE_ANAL) ? 0644 : 0000;

    char cmd[512];
    const char *perm_str = (mode == MODE_ANAL) ? "644" : "000";
    snprintf(cmd, sizeof(cmd),
        "find /sys/devices/virtual/thermal/thermal_zone*/ "
             "/sys/firmware/devicetree/base/soc/*/ "
             "/sys/devices/virtual/hwmon/hwmon*/ "
             "-type f \\( -iname '*temp*' -o -iname '*trip_point_*' "
             "-o -iname '*type*' -o -iname '*limit_info*' \\) "
             "-exec chmod %s {} + 2>/dev/null", perm_str);
    sh(cmd);
    (void)perm;
}

static void thermal_zone_mode(int mode) {

    const char *zone_mode = (mode == MODE_ANAL) ? "enabled" : "disabled";
    const char *thm_val   = (mode == MODE_ANAL) ? "1" : "0";

    miyabi_glob(zone_mode, "/sys/devices/virtual/thermal/thermal_zone*/mode",       1);
    miyabi_glob(thm_val,   "/sys/devices/virtual/thermal/thermal_zone*/thm_enable", 1);
}

static void msm_thermal(int mode) {

    int enable = (mode == MODE_ANAL);
    DIR *d = opendir("/sys");
    if (!d) return;
    closedir(d);

    sh(enable
       ? "find /sys -name enabled 2>/dev/null | grep 'msm_thermal' | "
         "while read p; do v=$(cat \"$p\" 2>/dev/null); "
         "[ \"$v\" = \"N\" ] && printf 'Y' > \"$p\" 2>/dev/null; "
         "[ \"$v\" = \"0\" ] && printf '1' > \"$p\" 2>/dev/null; done"
       : "find /sys -name enabled 2>/dev/null | grep 'msm_thermal' | "
         "while read p; do v=$(cat \"$p\" 2>/dev/null); "
         "[ \"$v\" = \"Y\" ] && printf 'N' > \"$p\" 2>/dev/null; "
         "[ \"$v\" = \"1\" ] && printf '0' > \"$p\" 2>/dev/null; done");
}

static void mali_thermal_chmod(int mode) {
    mode_t perm    = (mode == MODE_ANAL) ? 0644 : 0000;
    const char *ps = (mode == MODE_ANAL) ? "644" : "000";
    char cmd[256];

    snprintf(cmd, sizeof(cmd),
        "for p in /sys/devices/*.mali; do "
        "  [ -e \"$p/tmu\" ]          && chmod %s \"$p/tmu\" 2>/dev/null; "
        "  [ -e \"$p/tripping\" ]     && chmod %s \"$p/throttling\"* 2>/dev/null; "
        "  [ -e \"$p/tripping\" ]     && chmod %s \"$p/tripping\" 2>/dev/null; "
        "done", ps, ps, ps);
    sh(cmd);
    (void)perm;
}

static void kgsl_temp_chmod(int mode) {

    const char *ps = (mode == MODE_ANAL) ? "644" : "000";
    char cmd[256];
    snprintf(cmd, sizeof(cmd),
        "find /sys/devices/soc/*/kgsl/kgsl-3d0/ -name '*temp*' 2>/dev/null "
        "| while read p; do chmod %s \"$p\"; done", ps);
    sh(cmd);
}

static void thermal_props(int mode) {
    if (mode == MODE_ANAL) {

        sh("getprop 2>/dev/null | grep -iE 'thermal|temp|throttl' | "
           "awk -F'[][]' '{print $2}' | while read p; do "
           "  [ -z \"$p\" ] && continue; "
           "  resetprop -n \"$p\" \"running\" 2>/dev/null; "
           "  setprop \"$p\" \"running\" 2>/dev/null; "
           "done");
    } else {

        sh("getprop 2>/dev/null | grep -iE 'thermal|temp|throttl' | "
           "awk -F'[][]' '{print $2}' | while read p; do "
           "  [ -z \"$p\" ] && continue; "
           "  case $((RANDOM % 4)) in "
           "    0) v=\"YESDADDY\";; 1) v=\"FUCK\";; "
           "    2) v=\"AHHH\";;    3) v=\"LICKIT\";; "
           "  esac; "
           "  resetprop -n \"$p\" \"$v\" 2>/dev/null; "
           "  setprop \"$p\" \"$v\" 2>/dev/null; "
           "done");
    }
}

static void vicca(int mode) {

    const char *sig = (mode == MODE_MILF) ? "-9" : "-SIGCONT";
    char cmd[256];
    snprintf(cmd, sizeof(cmd),
        "ps -e 2>/dev/null | awk '/[Tt]hermal/ {print $2}' | "
        "while read pid; do [ -n \"$pid\" ] && kill %s \"$pid\" 2>/dev/null; done",
        sig);
    sh(cmd);
}

static void msbrewc(int mode) {

    const char *sig = (mode == MODE_MILF) ? "-SIGSTOP" : "-SIGCONT";
    char cmd[256];
    snprintf(cmd, sizeof(cmd),
        "for pid in $(pgrep -f thermal 2>/dev/null); do "
        "  kill %s \"$pid\" 2>/dev/null; "
        "done", sig);
    sh(cmd);
}

/* =========================================================
 * ==================  FUNGSI PER-MODE  ====================
 * ========================================================= */

static void MariaOzawa(int mode) {

    const char *hot  = (mode == MODE_MILF) ? "570" : "480";
    const char *warm = (mode == MODE_MILF) ? "500" : "460";

    miyabi_glob("150", "/sys/class/power_supply/*/temp_cool", 1);
    miyabi_glob(hot,   "/sys/class/power_supply/*/temp_hot",  1);
    miyabi_glob(warm,  "/sys/class/power_supply/*/temp_warm", 1);
}

static void SaoriHara(void) {
    miyabi_glob("150", "/sys/class/power_supply/*/temp_cool", 0);
    miyabi_glob("400", "/sys/class/power_supply/*/temp_hot",  0);
    miyabi_glob("380", "/sys/class/power_supply/*/temp_warm", 0);
}

static void Honoka_bypass(int do_chmod) {
    miyabi("N", "/sys/module/workqueue/parameters/power_efficient", do_chmod);
    miyabi("N", "/sys/module/workqueue/parameters/disable_numa",    do_chmod);
}

static void Honoka_restore(void) {
    miyabi("Y", "/sys/module/workqueue/parameters/power_efficient", 0);
    miyabi("Y", "/sys/module/workqueue/parameters/disable_numa",    0);
}

static void AsamiSugiura_bypass(int do_chmod) {
    const char *base = "/sys/class/kgsl/kgsl-3d0";
    char p[128];
    #define KW(sub, val) do { snprintf(p, sizeof(p), "%s/%s", base, sub); miyabi(val, p, do_chmod); } while(0)
    KW("throttling",        "0");
    KW("bus_split",         "0");
    KW("max_gpuclk",        "0");
    KW("adreno_idler_active","0");
    KW("thermal_pwrlevel",  "0");
    KW("force_no_nap",      "1");
    KW("force_rail_on",     "1");
    KW("force_bus_on",      "1");
    KW("force_clk_on",      "1");
    #undef KW
}

static void AsamiSugiura_restore(void) {
    const char *base = "/sys/class/kgsl/kgsl-3d0";
    char p[128];
    #define KW(sub, val) do { snprintf(p, sizeof(p), "%s/%s", base, sub); miyabi(val, p, 0); } while(0)
    KW("throttling",         "1");
    KW("bus_split",          "1");
    KW("max_gpuclk",         "1");
    KW("adreno_idler_active","1");
    KW("thermal_pwrlevel",   "1");
    KW("force_no_nap",       "0");
    KW("force_rail_on",      "0");
    KW("force_bus_on",       "0");
    KW("force_clk_on",       "0");
    #undef KW
}

static void ValentinaNappi(int do_chmod) {
    miyabi("0", "/proc/ppm/enabled", do_chmod);
    int idx[] = {2, 3, 4, 6, 7};
    for (int i = 0; i < 5; i++) {
        char val[8];
        snprintf(val, sizeof(val), "%d 0", idx[i]);
        miyabi(val, "/proc/ppm/policy_status", do_chmod);
    }
}

static void mysaaat(void) {
    miyabi("1", "/proc/ppm/enabled", 0);
    int idx[] = {2, 3, 4, 6, 7};
    for (int i = 0; i < 5; i++) {
        char val[8];
        snprintf(val, sizeof(val), "%d 1", idx[i]);
        miyabi(val, "/proc/ppm/policy_status", 0);
    }
}

static void AngelaWhite_bypass(int mode) {
    const char *base = "/proc/cpufreq";
    char p[128];
    const char *imax = (mode == MODE_MILF) ? "2" : "1";
    const char *pmode = (mode == MODE_MILF) ? "3" : "0";
    int do_chmod = 1;

    #define CW(sub, val) do { snprintf(p, sizeof(p), "%s/%s", base, sub); miyabi(val, p, do_chmod); } while(0)
    CW("cpufreq_imax_thermal_protect", "0");
    CW("cpufreq_sched_disable",        "1");
    CW("cpufreq_imax_enable",          imax);
    CW("cpufreq_power_mode",           pmode);
    #undef CW
}

static void TeraPatrick(void) {
    const char *base = "/proc/cpufreq";
    char p[128];
    #define CW(sub, val) do { snprintf(p, sizeof(p), "%s/%s", base, sub); miyabi(val, p, 0); } while(0)
    CW("cpufreq_imax_thermal_protect", "1");
    CW("cpufreq_sched_disable",        "0");
    CW("cpufreq_imax_enable",          "0");
    CW("cpufreq_power_mode",           "1");
    #undef CW
}

static void Siskaeee(int do_chmod) {
    miyabi("0", "/proc/sys/kernel/sched_boost",   do_chmod);
    miyabi("0", "/sys/kernel/eara_thermal/enable", do_chmod);
    sh("cmd thermalservice override-status 0 2>/dev/null");
}

static void LanaRhoades(void) {
    miyabi("1", "/proc/sys/kernel/sched_boost",   0);
    miyabi("1", "/sys/kernel/eara_thermal/enable", 0);
    sh("cmd thermalservice reset 2>/dev/null");
}

static void SashaGrey(int do_chmod) {
    const char *path  = "/proc/gpufreq/gpufreq_power_limited";
    const char *items[] = {
        "ignore_batt_oc 1", "ignore_batt_percent 1",
        "ignore_low_batt 1", "ignore_thermal_protect 1",
        "ignore_pbm_limited 1", NULL
    };
    for (int i = 0; items[i]; i++) miyabi(items[i], path, do_chmod);
}

static void NikkiBenz(void) {
    const char *path  = "/proc/gpufreq/gpufreq_power_limited";
    const char *items[] = {
        "ignore_batt_oc 0", "ignore_batt_percent 0",
        "ignore_low_batt 0", "ignore_thermal_protect 0",
        "ignore_pbm_limited 0", NULL
    };
    for (int i = 0; items[i]; i++) miyabi(items[i], path, 0);
}

static void AvaAddams(void) {
    const char *shit_path = "/data/adb/modules/LickingT/FuckingThermal";
    int fd = open(shit_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd >= 0) close(fd);

    sh("find /system /vendor -type f "
       "\\( -iname '*thermal*' -o -iname '*throttl*' \\) "
       "! -iname '*.rc' 2>/dev/null | "
       "while IFS= read -r f; do "
       "  mount --bind /data/adb/modules/LickingT/FuckingThermal \"$f\" 2>/dev/null; "
       "done");
}

static void AiUehara(void) {
    sh("find /system/etc/init /vendor/etc/init /odm/etc/init -type f 2>/dev/null "
       "| xargs grep -h '^service' 2>/dev/null | awk '{print $2}' "
       "| grep -i thermal | while read s; do stop \"$s\" 2>/dev/null; done");
}

static void EvaAngelina(void) {
    sh("find /system /vendor -type f "
       "\\( -iname '*thermal*' -o -iname '*throttl*' \\) "
       "! -iname '*.rc' 2>/dev/null | "
       "while IFS= read -r f; do umount \"$f\" 2>/dev/null; done");
}

static void MelenaTara(void) {
    sh("find /system/etc/init /vendor/etc/init /odm/etc/init -type f 2>/dev/null "
       "| xargs grep -h '^service' 2>/dev/null | awk '{print $2}' "
       "| grep -i thermal | while read s; do start \"$s\" 2>/dev/null; done");
}

static int read_hal_config(void) {
    const char *cfg = "/data/adb/modules/LickingT/thermal.conf";
    FILE *fp = fopen(cfg, "r");
    if (!fp) return 0;
    char line[256];
    int hal = 0;
    while (fgets(line, sizeof(line), fp)) {
        if (strncasecmp(line, "HAL=", 4) == 0) {
            hal = atoi(line + 4);
            break;
        }
    }
    fclose(fp);
    return hal;
}

/* =========================================================
 * ==================  MAIN EXECUTION FLOWS  ===============
 * ========================================================= */

static void run_amature(void) {

    MariaOzawa(MODE_AMATURE);
    Honoka_bypass(1);
    comatozze(MODE_AMATURE);
    kgsl_temp_chmod(MODE_AMATURE);
    AngelaWhite_bypass(MODE_AMATURE);
    EmmaStone(MODE_AMATURE);

    usleep(500000);

    Siskaeee(1);
    AsamiSugiura_bypass(1);
    ValentinaNappi(1);
    msm_thermal(MODE_AMATURE);
    SashaGrey(1);
    mali_thermal_chmod(MODE_AMATURE);

    usleep(500000);

    SweetyFox(MODE_AMATURE);
    thermal_zone_mode(MODE_AMATURE);
    thermal_props(MODE_AMATURE);

    usleep(500000);
}

static void run_milf(void) {

    MariaOzawa(MODE_MILF);
    Honoka_bypass(1);
    comatozze(MODE_MILF);
    AsamiSugiura_bypass(1);
    ValentinaNappi(1);
    AngelaWhite_bypass(MODE_MILF);
    Siskaeee(1);

    usleep(500000);

    vicca(MODE_MILF);
    EmmaStone(MODE_MILF);
    kgsl_temp_chmod(MODE_MILF);
    msm_thermal(MODE_MILF);
    SashaGrey(1);
    mali_thermal_chmod(MODE_MILF);

    usleep(500000);

    SweetyFox(MODE_MILF);
    thermal_zone_mode(MODE_MILF);
    AvaAddams();
    AiUehara();
    thermal_props(MODE_MILF);
    msbrewc(MODE_MILF);

    usleep(500000);
}

static void run_anal_main1(void) {
    Honoka_restore();
    SaoriHara();
    comatozze(MODE_ANAL);
    NikkiBenz();
    TeraPatrick();
    LanaRhoades();

    usleep(500000);

    AsamiSugiura_restore();
    EmmaStone(MODE_ANAL);
    kgsl_temp_chmod(MODE_ANAL);        
    msm_thermal(MODE_ANAL);             
    SweetyFox(MODE_ANAL);               

    usleep(500000);

    thermal_zone_mode(MODE_ANAL);      
    mysaaat();
    mali_thermal_chmod(MODE_ANAL);   
    thermal_props(MODE_ANAL);         

    usleep(500000);
}

static void run_anal_main2(void) {
    EvaAngelina();
    MelenaTara();
    vicca(MODE_ANAL);             
    msbrewc(MODE_ANAL);              
}

static void run_anal(void) {
    run_anal_main1();

    if (read_hal_config() == 1) {
        run_anal_main2();
    }
}

/* =========================================================
 * ==================  ENTRY POINT  ========================
 * ========================================================= */

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr,
            "LickingT Thermal Manager\n"
            "Usage: %s <mode>\n"
            "  0 | amature  - Non-aggressive thermal bypass\n"
            "  1 | milf     - Aggressive thermal bypass\n"
            "  2 | anal     - Restore defaults\n",
            argv[0]);
        return 1;
    }

    const char *arg = argv[1];
    if (strcmp(arg, "0") == 0 || strcasecmp(arg, "amature") == 0) {
        g_mode = MODE_AMATURE;
    } else if (strcmp(arg, "1") == 0 || strcasecmp(arg, "milf") == 0) {
        g_mode = MODE_MILF;
    } else if (strcmp(arg, "2") == 0 || strcasecmp(arg, "anal") == 0) {
        g_mode = MODE_ANAL;
    } else {
        fprintf(stderr, "Error: mode tidak dikenal '%s'\n", arg);
        return 1;
    }

    switch (g_mode) {
        case MODE_AMATURE: run_amature(); break;
        case MODE_MILF:    run_milf();    break;
        case MODE_ANAL:    run_anal();    break;
    }

    return 0;
}
