#!/usr/bin/env bash
# Checkers déterministes du portfolio public — point d'entrée unique (docs/agentic/NOTIONS.md §5).
#   scripts/agent-check.sh --quick | (complet)
# Site statique public : aucun secret, HTML bien formé, liens locaux existants.
source "$(dirname "$0")/agent-check-common.sh" "$@"

[ "$MODE" = "full" ] && CHANGED="$(git ls-files)"$'\n'"$(git ls-files --others --exclude-standard)"

step "secrets" secret_scan
step "JSON valides" json_check
step "scripts shell valides" shell_check

html_check() {
  python3 - <<'PY'
import sys, pathlib, re
from html.parser import HTMLParser
from urllib.parse import urlparse, unquote
VOID = {"area","base","br","col","embed","hr","img","input","link","meta","source","track","wbr"}
OPTIONAL = {"p","li","dt","dd","tr","td","th","option","thead","tbody","tfoot","colgroup","rt","rp","optgroup"}
problems = []
for page in sorted(pathlib.Path(".").glob("**/*.html")):
    if ".git" in page.parts or "node_modules" in page.parts: continue
    stack, links = [], []
    class P(HTMLParser):
        def handle_starttag(self, tag, attrs):
            a = dict(attrs)
            for k in ("href", "src"):
                if a.get(k): links.append(a[k])
            if tag not in VOID: stack.append((tag, self.getpos()[0]))
        def handle_endtag(self, tag):
            if tag in VOID: return
            while stack and stack[-1][0] != tag and stack[-1][0] in OPTIONAL: stack.pop()
            if stack and stack[-1][0] == tag: stack.pop()
            else: problems.append(f"{page}:{self.getpos()[0]} </{tag}> sans ouverture")
    P().feed(page.read_text(encoding="utf-8"))
    for tag, line in stack:
        if tag not in OPTIONAL and tag not in ("html","head","body"):
            problems.append(f"{page}:{line} <{tag}> non fermé")
    for l in links:
        u = urlparse(l)
        if u.scheme or l.startswith(("#", "//", "mailto:", "tel:", "data:", "javascript:")): continue
        target = (page.parent / unquote(u.path)).resolve()
        if u.path and not target.exists():
            problems.append(f"{page}: lien local cassé → {l}")
if problems:
    print("\n".join("    " + p for p in problems)); sys.exit(1)
PY
}
step "HTML bien formé + liens locaux" html_check

finish
