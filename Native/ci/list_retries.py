"""List tests that failed and then passed on Xcode's retry (-retry-tests-on-failure).

`python3 list_retries.py LOG KIND`. Prints a GitHub warning per retried test so a flake is
visible in the run summary instead of hidden by the pass. Never fails the step.
"""
import re
import sys

log_path, kind = sys.argv[1], sys.argv[2]
pattern = re.compile(r"Test Case '-\[(\S+) (\S+)\]' (passed|failed)")
results = {}
try:
    with open(log_path, errors="replace") as handle:
        for line in handle:
            match = pattern.search(line)
            if match:
                name = f"{match.group(1)}.{match.group(2)}"
                results.setdefault(name, []).append(match.group(3))
except OSError as error:
    print(f"could not read {log_path}: {error}")
    sys.exit(0)

retried = [name for name, outcomes in results.items() if "failed" in outcomes and outcomes[-1] == "passed"]
for name in retried:
    print(f"::warning title=UI test passed only on retry ({kind})::{name}")
print(f"{kind}: {len(retried)} test(s) passed only on retry")
