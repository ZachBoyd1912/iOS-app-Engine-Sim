"""Rename attachments exported by `xcresulttool export attachments` to their test-given names.

`python3 name_attachments.py DIR`. The exporter writes files with generated names plus a
manifest.json; the manifest's exact shape on Xcode 26 is unverified, so this walks it loosely
and leaves files alone if it cannot match them.
"""
import json
import os
import re
import sys

folder = sys.argv[1]
manifest_path = os.path.join(folder, "manifest.json")
if not os.path.exists(manifest_path):
    print("no manifest.json; keeping exported names")
    sys.exit(0)


def walk(node):
    if isinstance(node, dict):
        if "exportedFileName" in node and "suggestedHumanReadableName" in node:
            yield node["exportedFileName"], node["suggestedHumanReadableName"]
        for value in node.values():
            yield from walk(value)
    elif isinstance(node, list):
        for value in node:
            yield from walk(value)


with open(manifest_path) as handle:
    manifest = json.load(handle)
for exported, human in walk(manifest):
    source = os.path.join(folder, exported)
    if not os.path.exists(source):
        continue
    stem, ext = os.path.splitext(exported)
    name = re.sub(r"[^A-Za-z0-9._-]+", "_", human)
    if not os.path.splitext(name)[1]:
        name += ext
    os.replace(source, os.path.join(folder, name))
    print(f"{exported} -> {name}")
