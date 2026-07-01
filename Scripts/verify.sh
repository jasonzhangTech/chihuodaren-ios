#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ -d /Applications/Xcode.app/Contents/Developer ]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

echo "== Plist and project format =="
plutil -lint ChiHuoDaRen.xcodeproj/project.pbxproj ChiHuoDaRen/Info.plist

echo "== Asset JSON =="
node -e "for (const f of ['ChiHuoDaRen/Assets.xcassets/Contents.json','ChiHuoDaRen/Assets.xcassets/AccentColor.colorset/Contents.json','ChiHuoDaRen/Assets.xcassets/AppIcon.appiconset/Contents.json']) { JSON.parse(require('fs').readFileSync(f,'utf8')); console.log(f + ': OK') }"

echo "== Swift syntax parse =="
swiftc -parse \
  ChiHuoDaRen/App.swift \
  ChiHuoDaRen/Models/FoodModels.swift \
  ChiHuoDaRen/Services/LogSaveValidation.swift \
  ChiHuoDaRen/Services/MapInitialLocationPolicy.swift \
  ChiHuoDaRen/Services/RecommendationService.swift \
  ChiHuoDaRen/Services/UserLocationProvider.swift \
  ChiHuoDaRen/Views/ContentView.swift \
  ChiHuoDaRen/Views/LogListView.swift \
  ChiHuoDaRen/Views/FoodLogCard.swift \
  ChiHuoDaRen/Views/PhotoMosaicView.swift \
  ChiHuoDaRen/Views/LogEditorView.swift \
  ChiHuoDaRen/Views/CameraCaptureView.swift \
  ChiHuoDaRen/Views/MapLocationPickerView.swift \
  ChiHuoDaRen/Views/LogDetailView.swift \
  ChiHuoDaRen/Views/EatDecisionView.swift

echo "== Core PRD flow =="
swift Verification/CoreLogicVerification.swift

echo "== Form validation =="
swiftc ChiHuoDaRen/Services/LogSaveValidation.swift Verification/FormValidationVerification.swift -o /tmp/chihuodaren-form-validation
/tmp/chihuodaren-form-validation

echo "== Location selection =="
swiftc ChiHuoDaRen/Services/MapInitialLocationPolicy.swift Verification/LocationSelectionVerification.swift -o /tmp/chihuodaren-location-selection
/tmp/chihuodaren-location-selection

if xcrun --sdk iphonesimulator --show-sdk-path >/dev/null 2>&1; then
  echo "== iOS simulator build =="
  rm -rf /tmp/ChiHuoDaRenDerivedData
  xcodebuild \
    -project ChiHuoDaRen.xcodeproj \
    -scheme ChiHuoDaRen \
    -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
    -derivedDataPath /tmp/ChiHuoDaRenDerivedData \
    build
else
  echo "SKIP: iOS simulator SDK not installed. Install full Xcode, then rerun Scripts/verify.sh."
fi
