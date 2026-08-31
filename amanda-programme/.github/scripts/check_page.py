#!/usr/bin/env python3
"""Sanity-check the page before it is copied to the server.

Catches the mistakes that would otherwise ship a broken page: an empty or
truncated file, an unclosed tag, or a stray editor conflict marker.
"""
import sys
import re

REQUIRED = ["<!doctype html>", "<html", "<head>", "</head>", "<body>", "</body>", "</html>"]
PAIRED = ["html", "head", "body", "style", "script", "section", "article"]


def check(path):
    with open(path, encoding="utf-8") as fh:
        html = fh.read()

    errors = []

    if len(html) < 1000:
        errors.append(f"file is only {len(html)} bytes; it looks truncated")

    lowered = html.lower()
    for token in REQUIRED:
        if token not in lowered:
            errors.append(f"missing {token}")

    for tag in PAIRED:
        opens = len(re.findall(rf"<{tag}\b", lowered))
        closes = len(re.findall(rf"</{tag}\s*>", lowered))
        if opens != closes:
            errors.append(f"<{tag}> opened {opens} times but closed {closes} times")

    for marker in ("<<<<<<<", ">>>>>>>", "=======\n<<<"):
        if marker in html:
            errors.append(f"leftover merge conflict marker {marker!r}")

    if errors:
        for err in errors:
            print(f"error: {err}", file=sys.stderr)
        return 1

    stubs = len(re.findall(r'class="stub"', html))
    print(f"{path} looks fine: {len(html)} bytes, {stubs} retrospective stubs")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: check_page.py PATH", file=sys.stderr)
        sys.exit(2)
    sys.exit(check(sys.argv[1]))
