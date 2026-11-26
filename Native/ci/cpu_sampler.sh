#!/bin/sh
# Host-side CPU sampler for the UI test step. Simulator apps are ordinary macOS processes on
# the runner, so `top` and `sample` see their threads directly.
#
# Why it exists: on 25/11/2026 the iPhone UI tests wedged after tapping Start (engine-sim reported
# 235-280% of a frame on the CI simulator) and the app could not even be terminated. This records
# which threads actually hold the CPU, so the fix is chosen from evidence, not a guess.
#
# Usage: cpu_sampler.sh <out-dir> &   ...   touch <out-dir>/stop
out="$1"
mkdir -p "$out"
samples=0
while [ ! -f "$out/stop" ]; do
  stamp=$(date -u +%H:%M:%S)
  {
    echo "=== $stamp UTC"
    top -l 1 -o cpu -n 15 -stats pid,command,cpu,threads,mem 2>/dev/null | tail -n 17
  } >> "$out/top.txt"
  pid=$(pgrep -x PistonForge | head -n 1)
  # A thread-level stack sample of the app itself, at most 6 per run (each is a few MB).
  if [ -n "$pid" ] && [ "$samples" -lt 6 ]; then
    samples=$((samples + 1))
    sample "$pid" 3 -mayDie -file "$out/sample-$samples-$stamp.txt" >/dev/null 2>&1 &
  fi
  sleep 20
done
