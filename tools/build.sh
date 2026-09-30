#!/bin/zsh
U=1B8F9C0A-B61B-4975-8BE7-62443178E70D
S=/tmp/focus-build
cd "/Users/deveshramanan/ADHD Slayer/app/FocusApp" || exit 1
xcodebuild -project FocusApp.xcodeproj -scheme FocusApp -destination "platform=iOS Simulator,id=$U" -derivedDataPath $S/dd CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | sed 's|/Users/deveshramanan/ADHD Slayer/app/FocusApp/FocusApp/||' | sort -u | head -80
