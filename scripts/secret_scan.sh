#!/usr/bin/env bash
# Scans staged files (or all tracked files with --all) for secrets. Exit 1 on a hit.
set -u
if [ "${1:-}" = "--all" ]; then files="$(git ls-files)"; else files="$(git diff --cached --name-only --diff-filter=ACM)"; fi
pat='ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}|figd_[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}'
hit=0
for f in $files; do
  [ -f "$f" ] || continue
  case "$f" in *.p12|*.mobileprovision|*.cer|.env|.env.*) echo "secret_scan: forbidden file type staged: $f"; hit=1; continue;; esac
  if grep -nE "$pat" "$f" >/dev/null 2>&1; then echo "secret_scan: possible secret in $f:"; grep -nE "$pat" "$f" | sed -E 's/([A-Za-z0-9_-]{8})[A-Za-z0-9_-]+/\1…/g' | head -5; hit=1; fi
done
exit $hit
