#!/bin/zsh
# Archive a Release build and upload it to App Store Connect.
#
#   AppStore/upload.sh <build-number>
#
# Signs with an App Store Connect API key when ASC_KEY_ID and ASC_ISSUER_ID are set (key file at
# ~/.appstoreconnect/private_keys/AuthKey_$ASC_KEY_ID.p8), otherwise with the Apple account signed
# in to Xcode. The app record must already exist in App Store Connect.
set -euo pipefail
cd "${0:A:h}/.."

BUILD=${1:?usage: AppStore/upload.sh <build-number>}
ARCHIVE=build/archive/Countdown-$BUILD.xcarchive

auth=()
if [[ -n ${ASC_KEY_ID:-} && -n ${ASC_ISSUER_ID:-} ]]; then
  auth=(-authenticationKeyPath "$HOME/.appstoreconnect/private_keys/AuthKey_$ASC_KEY_ID.p8"
        -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
fi

xcodegen generate >/dev/null
xcodebuild archive -project Countdown.xcodeproj -scheme Countdown -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$ARCHIVE" \
  CURRENT_PROJECT_VERSION="$BUILD" -allowProvisioningUpdates "${auth[@]}"

xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportOptionsPlist AppStore/ExportOptions.plist \
  -exportPath build/export -allowProvisioningUpdates "${auth[@]}"

echo "Uploaded build $BUILD. It appears in App Store Connect → TestFlight once processing finishes (5-30 min)."
