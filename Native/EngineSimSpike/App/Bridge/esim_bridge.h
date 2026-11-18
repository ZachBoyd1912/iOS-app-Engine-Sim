// Plain C interface to engine-sim's sound core, for the phone test app (spike, throwaway).
#ifndef ESIM_BRIDGE_H
#define ESIM_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    double rpm;           // engine speed right now
    double load_percent;  // physics time per 1/60 s frame as a percent of the frame budget (100 = full)
    double frame_ms;      // average physics time per frame
    long   underruns;     // audio callbacks that got less audio than they asked for
    long   frames;        // frames simulated since start
    double dyno_torque;   // dyno torque (N m), only meaningful in hold mode
    int    cylinders;
    int    running;
} esim_stats;

// Load an engine script (relative to assetsDir, e.g. "main_08_ferrari_f136_v8.mr") and start the
// simulation thread. Returns 0 on success, otherwise fills err.
int  esim_start(const char *assetsDir, const char *mainScript, char *err, int errLen);
void esim_stop(void);

// throttle 0...1. holdMode 1 = the dyno holds holdRpm (like the Linux/Mac tests); 0 = free-running.
void esim_set(double throttle, int holdMode, double holdRpm);
void esim_crank(void);                 // run the starter motor until the engine fires
void esim_read(float *out, int frames); // audio render callback; never blocks long
void esim_stats_get(esim_stats *out);

#ifdef __cplusplus
}
#endif
#endif
