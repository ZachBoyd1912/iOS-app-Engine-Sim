#!/bin/sh
# Host-side CPU sampler for the UI test step. Simulator apps are ordinary macOS processes on
# the runner, so `top`, `ps` and `sample` see their threads directly.
#
# Why it exists: on 25/11/2026 the iPhone UI tests wedged after tapping Start (engine-sim reported
# 235-280% of a frame on the CI simulator) and the app could not even be terminated. This records
# which threads actually hold the CPU, so the fix is chosen from evidence, not a guess.
#
# Lessons from the first two attempts (runs 45735387185, 45737490966):
#  - `top -l 1` prints 0.0% for everything (it needs two samples for a delta): use -l 2, keep the 2nd.
#  - upload-artifact rejects colons in file names.
#  - `sample` failed silently with its output thrown away: its errors are now kept, and
#    `ps -M` (per-thread CPU) is recorded as well so one tool failing does not lose the evidence.
#
# Usage: cpu_sampler.sh <out-dir> &   ...   touch <out-dir>/stop
out="$1"
mkdir -p "$out"
echo "cores: $(sysctl -n hw.ncpu)  model: $(sysctl -n hw.model)" > "$out/host.txt"
samples=0
while [ ! -f "$out/stop" ]; do
  {
    echo "=== $(date -u +%H:%M:%S) UTC"
    top -l 2 -s 2 -o cpu -n 12 -stats pid,command,cpu,threads 2>&1 | awk '/^PID/{n++} n==2'
  } >> "$out/top.txt"
  pid=$(pgrep -x PistonForge | head -n 1)
  if [ -n "$pid" ]; then
    {
      echo "=== $(date -u +%H:%M:%S) UTC pid $pid"
      ps -M -p "$pid" 2>&1 | sort -k4 -rn | head -n 15
    } >> "$out/threads.txt"
    # A full stack sample of the app, at most 4 per run (each is a few MB).
    if [ "$samples" -lt 4 ]; then
      samples=$((samples + 1))
      sample "$pid" 3 -mayDie -file "$out/sample-$samples-$(date -u +%H%M%S).txt" >> "$out/sample-errors.txt" 2>&1 &
    fi
  fi
  sleep 15
done
