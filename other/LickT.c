#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/mount.h>
#include <dirent.h>
#include <glob.h>
#include <signal.h>
#include <errno.h>
#include <ftw.h>

/* ─────────────────────────────────────────────
 *  Tipe mode
 * ───────────────────────────────────────────── */
#define MODE_NON_AGGRESSIVE 0
#define MODE_AGGRESSIVE     1
#define MODE_RESTORE        2

static int g_mode = -1;

/* ─────────────────────────────────────────────
 *  Helper: tulis nilai ke satu path file
 * ───────────────────────────────────────────── */
static void write_val(const char *val, const char *path)
{
    if (!path || !val) return;
    struct stat st;
    if (stat(path, &st) != 0 || !S_ISREG(st.st_mode)) return;
    chmod(path, 0644);
    int fd = open(path, O_WRONLY | O_TRUNC | O_CLOEXEC);
    if (fd < 0) return;
    write(fd, val, strlen(val));
    close(fd);
}

/* ─────────────────────────────────────────────
 *  Helper: tulis nilai ke semua path yang cocok pola glob
 * ───────────────────────────────────────────── */
static void write_glob(const char *val, const char *pattern)
{
    glob_t g;
    memset(&g, 0, sizeof(g));
    if (glob(pattern, GLOB_NOSORT | GLOB_NOESCAPE, NULL, &g) == 0) {
        for (size_t i = 0; i < g.gl_pathc; i++)
            write_val(val, g.gl_pathv[i]);
    }
    globfree(&g);
}

/* ─────────────────────────────────────────────
 *  Helper: chmod semua path yang cocok pola glob
 * ───────────────────────────────────────────── */
static void chmod_glob(mode_t mode, const char *pattern)
{
    glob_t g;
    memset(&g, 0, sizeof(g));
    if (glob(pattern, GLOB_NOSORT | GLOB_NOESCAPE, NULL, &g) == 0) {
        for (size_t i = 0; i < g.gl_pathc; i++)
            chmod(g.gl_pathv[i], mode);
    }
    globfree(&g);
}

/* ─────────────────────────────────────────────
 *  Helper: jalankan perintah shell sederhana
 * ───────────────────────────────────────────── */
static void run_cmd(const char *cmd)
{
    system(cmd);
}

/* ─────────────────────────────────────────────
 *  Helper: rekursif chmod dengan nftw
 * ───────────────────────────────────────────── */
static mode_t g_nftw_mode;
static const char **g_nftw_names;
static int g_nftw_name_count;

static int nftw_chmod_cb(const char *path, const struct stat *sb,
                          int typeflag, struct FTW *ftwbuf)
{
    (void)ftwbuf;
    if (typeflag != FTW_F) return 0;
    const char *base = path + ftwbuf->base;
    for (int i = 0; i < g_nftw_name_count; i++) {
        char lower_base[256], lower_pat[256];
        int j;
        for (j = 0; base[j] && j < 255; j++)
            lower_base[j] = (base[j] >= 'A' && base[j] <= 'Z')
                             ? base[j] + 32 : base[j];
        lower_base[j] = '\0';
        for (j = 0; g_nftw_names[i][j] && j < 255; j++)
            lower_pat[j] = (g_nftw_names[i][j] >= 'A' && g_nftw_names[i][j] <= 'Z')
                            ? g_nftw_names[i][j] + 32 : g_nftw_names[i][j];
        lower_pat[j] = '\0';
        if (strstr(lower_base, lower_pat)) {
            chmod(path, g_nftw_mode);
            break;
        }
    }
    return 0;
}

static void find_chmod(mode_t mode, const char **bases, int nb,
                       const char **dirs, int nd)
{
    g_nftw_mode       = mode;
    g_nftw_names      = bases;
    g_nftw_name_count = nb;
    for (int i = 0; i < nd; i++)
        nftw(dirs[i], nftw_chmod_cb, 16, FTW_PHYS);
}

/* ═══════════════════════════════════════════════════
 *  ── FUNGSI BERSAMA (dipakai lebih dari 1 mode) ──
 * ═══════════════════════════════════════════════════ */

static void configure_io_queue(const char *iostats,
                                const char *rotational,
                                const char *add_random)
{
    glob_t g;
    memset(&g, 0, sizeof(g));
    if (glob("/sys/block/*/queue", GLOB_NOSORT, NULL, &g) == 0) {
        for (size_t i = 0; i < g.gl_pathc; i++) {
            char p[512];
            snprintf(p, sizeof(p), "%s/iostats",    g.gl_pathv[i]);
            write_val(iostats, p);
            snprintf(p, sizeof(p), "%s/rotational", g.gl_pathv[i]);
            write_val(rotational, p);
            snprintf(p, sizeof(p), "%s/add_random", g.gl_pathv[i]);
            write_val(add_random, p);
        }
    }
    globfree(&g);
}

static void set_battery_temp(const char *cool, const char *hot, const char *warm)
{
    glob_t g;
    memset(&g, 0, sizeof(g));
    if (glob("/sys/class/power_supply/*", GLOB_NOSORT, NULL, &g) == 0) {
        for (size_t i = 0; i < g.gl_pathc; i++) {
            char p[512];
            snprintf(p, sizeof(p), "%s/temp_cool", g.gl_pathv[i]);
            write_val(cool, p);
            snprintf(p, sizeof(p), "%s/temp_hot",  g.gl_pathv[i]);
            write_val(hot,  p);
            snprintf(p, sizeof(p), "%s/temp_warm", g.gl_pathv[i]);
            write_val(warm, p);
        }
    }
    globfree(&g);
}

static void set_workqueue(const char *power_efficient, const char *disable_numa)
{
    write_val(power_efficient, "/sys/module/workqueue/parameters/power_efficient");
    write_val(disable_numa,    "/sys/module/workqueue/parameters/disable_numa");
}

static void configure_mtk_thermal(int t_limit_c, const char *cooler_str)
{
    if (access("/proc/driver/thermal/tzcpu", F_OK) != 0) return;

    char buf[1024];
    int  lim = t_limit_c * 1000;

    snprintf(buf, sizeof(buf),
             "1 %d 0 mtktscpu-sysrst %s 200", lim, cooler_str);
    write_val(buf, "/proc/driver/thermal/tzcpu");

    snprintf(buf, sizeof(buf),
             "1 %d 0 mtktspmic-sysrst %s 1000", lim, cooler_str);
    write_val(buf, "/proc/driver/thermal/tzpmic");

    snprintf(buf, sizeof(buf),
             "1 %d 0 mtktsbattery-sysrst %s 1000", lim, cooler_str);
    write_val(buf, "/proc/driver/thermal/tzbattery");

    snprintf(buf, sizeof(buf),
             "1 %d 0 mtk-cl-kshutdown00 %s 2000", lim, cooler_str);
    write_val(buf, "/proc/driver/thermal/tzpa");

    snprintf(buf, sizeof(buf),
             "1 %d 0 mtktscharger-sysrst %s 2000", lim, cooler_str);
    write_val(buf, "/proc/driver/thermal/tzcharger");

    snprintf(buf, sizeof(buf),
             "1 %d 0 mtktswmt-sysrst %s 1000", lim, cooler_str);
    write_val(buf, "/proc/driver/thermal/tzwmt");

    snprintf(buf, sizeof(buf),
             "1 %d 0 mtktsAP-sysrst %s 1000", lim, cooler_str);
    write_val(buf, "/proc/driver/thermal/tzbts");

    snprintf(buf, sizeof(buf),
             "1 %d 0 mtk-cl-kshutdown01 %s 1000", lim, cooler_str);
    write_val(buf, "/proc/driver/thermal/tzbtsnrpa");

    snprintf(buf, sizeof(buf),
             "1 %d 0 mtk-cl-kshutdown02 %s 1000", lim, cooler_str);
    write_val(buf, "/proc/driver/thermal/tzbtspa");
}

static void configure_kgsl(int throttle, int bus_split, int max_gpuclk,
                             int idler, int thermal_pwrlevel,
                             int no_nap, int rail_on,
                             int bus_on, int clk_on)
{
    const char *base = "/sys/class/kgsl/kgsl-3d0";
    char p[512], v[8];

#define KW(name, val) \
    snprintf(p, sizeof(p), "%s/%s", base, name); \
    snprintf(v, sizeof(v), "%d", val); \
    write_val(v, p)

    KW("throttling",         throttle);
    KW("bus_split",          bus_split);
    KW("max_gpuclk",         max_gpuclk);
    KW("adreno_idler_active",idler);
    KW("thermal_pwrlevel",   thermal_pwrlevel);
    KW("force_no_nap",       no_nap);
    KW("force_rail_on",      rail_on);
    KW("force_bus_on",       bus_on);
    KW("force_clk_on",       clk_on);
#undef KW
}

static void set_msm_thermal(int enable)
{
    glob_t g;
    memset(&g, 0, sizeof(g));
    if (glob("/sys/*/enabled", GLOB_NOSORT, NULL, &g) == 0) {
        for (size_t i = 0; i < g.gl_pathc; i++) {
            if (!strstr(g.gl_pathv[i], "msm_thermal")) continue;
            char buf[8];
            int fd = open(g.gl_pathv[i], O_RDONLY | O_CLOEXEC);
            if (fd < 0) continue;
            ssize_t n = read(fd, buf, sizeof(buf) - 1);
            close(fd);
            if (n <= 0) continue;
            buf[n] = '\0';

            if (enable) {
                if (buf[0] == 'N') write_val("Y", g.gl_pathv[i]);
                if (buf[0] == '0') write_val("1", g.gl_pathv[i]);
            } else {
                if (buf[0] == 'Y') write_val("N", g.gl_pathv[i]);
                if (buf[0] == '1') write_val("0", g.gl_pathv[i]);
            }
        }
    }
    globfree(&g);
}

static void configure_ppm(int enabled)
{
    char v[4];
    snprintf(v, sizeof(v), "%d", enabled);
    write_val(v, "/proc/ppm/enabled");

    int policies[] = {2, 3, 4, 6, 7};
    for (int i = 0; i < 5; i++) {
        char buf[16];
        snprintf(buf, sizeof(buf), "%d %d", policies[i], enabled);
        write_val(buf, "/proc/ppm/policy_status");
    }
}

static void chmod_kgsl_temp(mode_t mode)
{
    glob_t g;
    memset(&g, 0, sizeof(g));
    if (glob("/sys/devices/soc/*/kgsl/kgsl-3d0/*temp*",
             GLOB_NOSORT, NULL, &g) == 0) {
        for (size_t i = 0; i < g.gl_pathc; i++)
            chmod(g.gl_pathv[i], mode);
    }
    globfree(&g);
}

static void chmod_mali_thermal(mode_t mode)
{
    glob_t g;
    memset(&g, 0, sizeof(g));
    if (glob("/sys/devices/*.mali", GLOB_NOSORT, NULL, &g) == 0) {
        for (size_t i = 0; i < g.gl_pathc; i++) {
            char p[512];
            snprintf(p, sizeof(p), "%s/tmu", g.gl_pathv[i]);
            if (access(p, F_OK) == 0) chmod(p, mode);

            snprintf(p, sizeof(p), "%s/throttling", g.gl_pathv[i]);
            if (access(p, F_OK) == 0) chmod(p, mode);

            snprintf(p, sizeof(p), "%s/tripping", g.gl_pathv[i]);
            if (access(p, F_OK) == 0) chmod(p, mode);
        }
    }
    globfree(&g);
}

static void set_thermal_zones(const char *mode_val, const char *thm_val)
{
    glob_t g;
    memset(&g, 0, sizeof(g));
    if (glob("/sys/devices/virtual/thermal/thermal_zone*",
             GLOB_NOSORT, NULL, &g) == 0) {
        for (size_t i = 0; i < g.gl_pathc; i++) {
            char p[512];
            snprintf(p, sizeof(p), "%s/mode",       g.gl_pathv[i]);
            write_val(mode_val, p);
            snprintf(p, sizeof(p), "%s/thm_enable",  g.gl_pathv[i]);
            write_val(thm_val, p);
        }
    }
    globfree(&g);
}

static void chmod_sensor_files(mode_t mode)
{
    const char *patterns[] = {
        "/sys/devices/virtual/thermal/thermal_zone*/*temp*",
        "/sys/devices/virtual/thermal/thermal_zone*/*trip_point_*",
        "/sys/devices/virtual/thermal/thermal_zone*/*type*",
        "/sys/devices/virtual/thermal/thermal_zone*/*limit_info*",
        "/sys/firmware/devicetree/base/soc/*/*temp*",
        "/sys/firmware/devicetree/base/soc/*/*trip_point_*",
        "/sys/firmware/devicetree/base/soc/*/*type*",
        "/sys/firmware/devicetree/base/soc/*/*limit_info*",
        "/sys/devices/virtual/hwmon/hwmon*/*temp*",
        "/sys/devices/virtual/hwmon/hwmon*/*trip_point_*",
        "/sys/devices/virtual/hwmon/hwmon*/*type*",
        "/sys/devices/virtual/hwmon/hwmon*/*limit_info*",
    };
    for (int i = 0; i < (int)(sizeof(patterns)/sizeof(patterns[0])); i++)
        chmod_glob(mode, patterns[i]);
}

static void set_gpufreq_power_limit(int ignore)
{
    const char *entries[] = {
        "ignore_batt_oc",
        "ignore_batt_percent",
        "ignore_low_batt",
        "ignore_thermal_protect",
        "ignore_pbm_limited",
    };
    const char *path = "/proc/gpufreq/gpufreq_power_limited";
    struct stat st;
    if (stat(path, &st) != 0) return;

    for (int i = 0; i < 5; i++) {
        char buf[64];
        snprintf(buf, sizeof(buf), "%s %d", entries[i], ignore);
        int fd = open(path, O_WRONLY | O_CLOEXEC);
        if (fd < 0) continue;
        write(fd, buf, strlen(buf));
        close(fd);
    }
}

static void configure_cpufreq_mtk(int protect, int sched_dis,
                                    int imax_en, int power_mode)
{
    const char *base = "/proc/cpufreq";
    char p[256], v[8];

#define CW(name, val) \
    snprintf(p, sizeof(p), "%s/%s", base, name); \
    snprintf(v, sizeof(v), "%d", val); \
    write_val(v, p)

    CW("cpufreq_imax_thermal_protect", protect);
    CW("cpufreq_sched_disable",        sched_dis);
    CW("cpufreq_imax_enable",          imax_en);
    CW("cpufreq_power_mode",           power_mode);
#undef CW
}

/* ═══════════════════════════════════════════════════
 *  ── FUNGSI EKSKLUSIF MODE 1 & 2 (Aggressive / Restore) ──
 * ═══════════════════════════════════════════════════ */

static void bind_thermal_files(void)
{
    const char *EMPTY = "/data/adb/modules/LickingT/FuckingThermal";
    int fd = open(EMPTY, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
    if (fd >= 0) close(fd);

    run_cmd(
        "find /system /vendor -type f "
        "\\( -iname '*thermal*' -o -iname '*throttl*' \\) "
        "! -iname '*.rc' 2>/dev/null | while IFS= read -r f; do "
        "  mount --bind /data/adb/modules/LickingT/FuckingThermal \"$f\"; "
        "done"
    );
}

static void umount_thermal_files(void)
{
    run_cmd(
        "find /system /vendor -type f "
        "\\( -iname '*thermal*' -o -iname '*throttl*' \\) "
        "! -iname '*.rc' 2>/dev/null | while IFS= read -r f; do "
        "  umount \"$f\" 2>/dev/null; "
        "done"
    );
}

static void control_thermal_services(int do_start)
{
    const char *action = do_start ? "start" : "stop";
    char cmd[512];
    snprintf(cmd, sizeof(cmd),
        "find /system/etc/init /vendor/etc/init /odm/etc/init "
        "-type f 2>/dev/null | xargs grep -h '^service' 2>/dev/null | "
        "awk '{print $2}' | grep -i thermal | while read -r svc; do "
        "  %s \"$svc\"; "
        "done",
        action);
    run_cmd(cmd);
}

static void signal_thermal_procs(int sig)
{
    char cmd[256];
    snprintf(cmd, sizeof(cmd),
        "for pid in $(pgrep -f thermal 2>/dev/null); do "
        "  kill -%d \"$pid\" 2>/dev/null; "
        "done",
        sig);
    run_cmd(cmd);

    snprintf(cmd, sizeof(cmd),
        "ps -e 2>/dev/null | awk '/[Tt]hermal/ {print $2}' | "
        "while read -r pid; do [ -n \"$pid\" ] && kill -%d \"$pid\" 2>/dev/null; done",
        sig);
    run_cmd(cmd);
}

static void reset_thermal_props_running(void)
{
    run_cmd(
        "getprop | grep -iE 'thermal|temp|throttl' | "
        "awk -F'[][]' '{print $2}' | while read -r prop; do "
        "  [ -z \"$prop\" ] && continue; "
        "  resetprop -n \"$prop\" running 2>/dev/null; "
        "  setprop \"$prop\" running 2>/dev/null; "
        "done"
    );
}

static void spoof_thermal_props(void)
{
    run_cmd(
        "getprop | grep -iE 'thermal|temp|throttl' | "
        "awk -F'[][]' '{print $2}' | while read -r prop; do "
        "  [ -z \"$prop\" ] && continue; "
        "  idx=$(( $(date +%N) % 4 )); "
        "  case $idx in "
        "    0) val=YESDADDY ;; "
        "    1) val=FUCK ;; "
        "    2) val=AHHH ;; "
        "    3) val=LICKIT ;; "
        "  esac; "
        "  resetprop -n \"$prop\" \"$val\" 2>/dev/null; "
        "  setprop \"$prop\" \"$val\" 2>/dev/null; "
        "done"
    );
}

static void control_thermalservice(int restore)
{
    if (restore)
        run_cmd("cmd thermalservice reset 2>/dev/null");
    else
        run_cmd("cmd thermalservice override-status 0 2>/dev/null");
}

static void set_eara_sched(int enable)
{
    char v[4];
    snprintf(v, sizeof(v), "%d", enable);
    write_val(v, "/proc/sys/kernel/sched_boost");
    write_val(v, "/sys/kernel/eara_thermal/enable");
}

/* ═══════════════════════════════════════════════════
 *  ── IMPLEMENTASI TIAP MODE ──
 * ═══════════════════════════════════════════════════ */

static void run_mode_non_aggressive(void)
{
    printf("[LickingT] Mode: Non-Aggressive\n");

    set_battery_temp("150", "480", "460");
    set_workqueue("N", "N");
    configure_io_queue("0", "0", "0");
    chmod_kgsl_temp(0000);
    configure_cpufreq_mtk(0, 1, 1, 0);
    configure_mtk_thermal(120,
        "0 0 no-cooler 0 0 no-cooler 0 0 no-cooler "
        "0 0 no-cooler 0 0 no-cooler 0 0 no-cooler "
        "0 0 no-cooler 0 0 no-cooler 0 0 no-cooler");
    usleep(500000);

    set_eara_sched(0);
    control_thermalservice(0);
    configure_kgsl(0, 0, 0, 0, 0, 1, 1, 1, 1);
    configure_ppm(0);
    set_msm_thermal(0);
    set_gpufreq_power_limit(1);
    chmod_mali_thermal(0000);
    usleep(500000);

    chmod_sensor_files(0000);
    set_thermal_zones("disabled", "0");
    spoof_thermal_props();
    usleep(500000);

    printf("[LickingT] Non-Aggressive selesai.\n");
}

static void run_mode_aggressive(void)
{
    printf("[LickingT] Mode: Aggressive\n");

    set_battery_temp("150", "570", "500");
    set_workqueue("N", "N");
    configure_io_queue("0", "0", "0");
    configure_kgsl(0, 0, 0, 0, 0, 1, 1, 1, 1);
    configure_ppm(0);
    configure_cpufreq_mtk(0, 1, 2, 3);
    set_eara_sched(0);
    control_thermalservice(0);
    usleep(500000);

    signal_thermal_procs(SIGKILL);
    configure_mtk_thermal(125,
        "0 0 no-cooler 0 0 no-cooler 0 0 no-cooler "
        "0 0 no-cooler 0 0 no-cooler 0 0 no-cooler "
        "0 0 no-cooler 0 0 no-cooler 0 0 no-cooler");
    chmod_kgsl_temp(0000);
    set_msm_thermal(0);
    set_gpufreq_power_limit(1);
    chmod_mali_thermal(0000);
    usleep(500000);

    chmod_sensor_files(0000);
    set_thermal_zones("disabled", "0");
    bind_thermal_files();
    control_thermal_services(0);
    spoof_thermal_props();
    signal_thermal_procs(SIGSTOP);
    usleep(500000);

    printf("[LickingT] Aggressive selesai.\n");
}

static void run_mode_restore(void)
{
    printf("[LickingT] Mode: Restore (Default)\n");

    set_workqueue("Y", "Y");
    set_battery_temp("150", "400", "380");
    configure_io_queue("1", "1", "1");
    set_gpufreq_power_limit(0);
    configure_cpufreq_mtk(1, 0, 0, 1);
    set_eara_sched(1);
    control_thermalservice(1);
    usleep(500000);

    configure_kgsl(1, 1, 1, 1, 1, 0, 0, 0, 0);
    configure_mtk_thermal(117,
        "0 0 cpu_heavy 0 0 cpu_heavy 0 0 cpu_heavy "
        "0 0 cpu_heavy 0 0 cpu_heavy 0 0 cpu_heavy "
        "0 0 cpu_heavy 0 0 cpu_heavy 0 0 cpu_heavy");
    chmod_kgsl_temp(0644);
    set_msm_thermal(1);
    chmod_sensor_files(0644);
    usleep(500000);

    set_thermal_zones("enabled", "1");
    configure_ppm(1);
    chmod_mali_thermal(0644);
    reset_thermal_props_running();
    usleep(500000);

    umount_thermal_files();
    control_thermal_services(1);
    signal_thermal_procs(SIGCONT);

    printf("[LickingT] Restore selesai.\n");
}

/* ─────────────────────────────────────────────
 *  Baca konfigurasi HAL dari thermal.conf
 * ───────────────────────────────────────────── */
static int read_hal_config(void)
{
    const char *cfg = "/data/adb/modules/LickingT/thermal.conf";
    FILE *f = fopen(cfg, "r");
    if (!f) return 0;

    char line[256];
    while (fgets(line, sizeof(line), f)) {
        if (strncasecmp(line, "HAL=", 4) == 0) {
            int v = atoi(line + 4);
            fclose(f);
            return v;
        }
    }
    fclose(f);
    return 0;
}

/* ─────────────────────────────────────────────
 *  main
 * ───────────────────────────────────────────── */
int main(int argc, char *argv[])
{
    if (argc < 2) {
        fprintf(stderr,
            "LickingT Thermal Controller\n"
            "Penggunaan: %s <mode>\n\n"
            "  0 | non-aggressive  - Mode hemat / non-agresif\n"
            "  1 | aggressive      - Mode performa / agresif\n"
            "  2 | restore         - Kembalikan ke pengaturan default\n",
            argv[0]);
        return 1;
    }

    if (strcmp(argv[1], "0") == 0 ||
        strcasecmp(argv[1], "non-aggressive") == 0 ||
        strcasecmp(argv[1], "amature") == 0)
        g_mode = MODE_NON_AGGRESSIVE;
    else if (strcmp(argv[1], "1") == 0 ||
             strcasecmp(argv[1], "aggressive") == 0 ||
             strcasecmp(argv[1], "milf") == 0)
        g_mode = MODE_AGGRESSIVE;
    else if (strcmp(argv[1], "2") == 0 ||
             strcasecmp(argv[1], "restore") == 0 ||
             strcasecmp(argv[1], "anal") == 0)
        g_mode = MODE_RESTORE;
    else {
        fprintf(stderr, "Mode tidak dikenal: %s\n", argv[1]);
        return 1;
    }

    if (geteuid() != 0) {
        fprintf(stderr, "Harus dijalankan sebagai root!\n");
        return 1;
    }

    switch (g_mode) {
    case MODE_NON_AGGRESSIVE:
        run_mode_non_aggressive();
        break;
    case MODE_AGGRESSIVE: {
        int hal = read_hal_config();
        run_mode_aggressive();
        if (hal) {
            umount_thermal_files();
            control_thermal_services(0);
        }
        break;
    }
    case MODE_RESTORE:
        run_mode_restore();
        break;
    }

    return 0;
}
