"""Print the UDID of the simulator to test on: `python3 pick_sim.py iphone|ipad`.

Reads `xcrun simctl list devices available -j` from stdin. Picks the newest iOS runtime, then
the preferred device name in it (iPhone 17-class, or iPad Pro 13-inch), falling back to any
iPhone or iPad so a runner image change does not break the job.
"""
import json
import re
import sys

kind = sys.argv[1]
devices = json.load(sys.stdin)["devices"]
preferred = [r"^iPhone 17 Pro$", r"^iPhone 17", r"^iPhone"] if kind == "iphone" else [r"^iPad Pro 13-inch", r"^iPad Pro", r"^iPad"]


def version(runtime: str) -> tuple:
    match = re.search(r"iOS-(\d+)-(\d+)", runtime)
    return (int(match.group(1)), int(match.group(2))) if match else (0, 0)


runtimes = sorted((r for r in devices if "iOS" in r), key=version, reverse=True)
for pattern in preferred:
    for runtime in runtimes:
        for device in devices[runtime]:
            if re.search(pattern, device["name"]):
                print(device["udid"])
                print(f"{kind}: {device['name']} on {runtime}", file=sys.stderr)
                sys.exit(0)
sys.exit(f"no {kind} simulator available")
