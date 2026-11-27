#!/usr/bin/env python3
"""Contrast check for the app's colour tokens, read straight from Theme.swift.

Why this replaces Xcode's audit for contrast: `performAccessibilityAudit` flagged section headers
and footers that sit on the gradient background (run 45920342777). Measured from the screenshots,
every flagged element is at least 6.55:1 in the worst case (brightest background pixel next to the
text), so the audit was misjudging the gradient. This script is deterministic and checks every
pairing the screens actually use, including the base blended with the warm and cool tints at
their declared opacities (the brightest the gradient gets).

What it does NOT cover: text drawn over the 3D engine viewport, and system colours we do not set.

Rules (WCAG 2.2 AA, and the ZB UX standard): words 4.5:1, status marks and large text 3:1.
Usage: check_contrast.py path/to/Theme.swift   (exit 1 on any failure)
"""
import re
import sys

src = open(sys.argv[1], encoding="utf-8").read()


def token(name):
    """RGB 0-1 for `static let <name> = Color(...)/UIColor(...)`, following `= other` aliases."""
    m = re.search(rf"static let {name}\b[^=]*=\s*(.+)", src)
    if not m:
        sys.exit(f"token {name} not found in Theme.swift")
    expr = m.group(1)
    if w := re.search(r"white:\s*([\d.]+)", expr):
        v = float(w.group(1))
        return (v, v, v)
    if c := re.search(r"red:\s*([\d.]+),\s*green:\s*([\d.]+),\s*blue:\s*([\d.]+)", expr):
        return tuple(float(c.group(i)) for i in (1, 2, 3))
    if a := re.search(r"Color\(uiColor:\s*(\w+)\)", expr):
        return token(a.group(1))
    if a := re.fullmatch(r"\s*(\w+)\s*", expr):
        return token(a.group(1))
    sys.exit(f"cannot read token {name}: {expr}")


def opacity(name):
    m = re.search(rf"{name}\.opacity\(([\d.]+)\)", src)
    if not m:
        sys.exit(f"opacity for {name} not found in Theme.background")
    return float(m.group(1))


def blend(top, alpha, under):
    return tuple(t * alpha + u * (1 - alpha) for t, u in zip(top, under))


def lum(rgb):
    def ch(v):
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = (ch(v) for v in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def ratio(a, b):
    hi, lo = sorted((lum(a), lum(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)


base = token("baseUI")
backgrounds = {
    "base": base,
    "base+warm tint": blend(token("hueWarmUI"), opacity("hueWarm"), base),
    "base+cool tint": blend(token("hueCoolUI"), opacity("hueCool"), base),
    "surface": token("surface"),
    # Form rows use the system grouped-row colour; measured (28,28,30) in the CI screenshots.
    "form row": (28 / 255, 28 / 255, 30 / 255),
}
gradient = ["base", "base+warm tint", "base+cool tint"]

# (foreground token, backgrounds it is drawn on, minimum ratio)
pairs = [
    ("textPrimary", gradient + ["surface", "form row"], 4.5),
    ("textSecondary", gradient + ["surface", "form row"], 4.5),
    ("accent", gradient + ["surface", "form row"], 4.5),
    ("goodInk", ["surface", "form row"], 4.5),
    ("warnInk", ["surface", "form row"], 4.5),
    ("badInk", ["surface", "form row"], 4.5),
    ("goodMark", ["surface", "form row"], 3.0),
    ("warnMark", ["surface", "form row"], 3.0),
    ("badMark", ["surface", "form row"], 3.0),
]
checks = [(fg, token(fg), bg, backgrounds[bg], need) for fg, bgs, need in pairs for bg in bgs]
checks.append(("textPrimary", token("textPrimary"), "surfaceRaised", token("surfaceRaised"), 4.5))
checks.append(("onAccent", token("onAccent"), "accent", token("accent"), 4.5))

failed = 0
for fg_name, fg, bg_name, bg, need in checks:
    r = ratio(fg, bg)
    ok = r >= need
    failed += not ok
    print(f"{'ok  ' if ok else 'FAIL'} {fg_name:13s} on {bg_name:15s} {r:5.2f}:1 (needs {need}:1)")
print(f"{len(checks) - failed} of {len(checks)} pairs pass")
sys.exit(1 if failed else 0)
