#!/usr/bin/env bash
# Planning phase: no Swift/Xcode artefacts outside /poc. Exit 1 on violation.
bad="$(find . -type f \( -name '*.swift' -o -name 'Package.swift' \) -not -path './poc/*' -not -path './app/*' -not -path './.git/*' -not -path './.build/*' 2>/dev/null; find . -type d \( -name '*.xcodeproj' -o -name '*.xcworkspace' \) -not -path './poc/*' -not -path './app/*' -not -path './.git/*' 2>/dev/null)"
[ -z "$bad" ] && { echo "check_scope: OK"; exit 0; }
echo "check_scope: production code artefacts outside /poc:"; echo "$bad"; exit 1
