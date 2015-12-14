#! /bin/sh
# Update Info.plist in the app bundlebased on current build configuration.
# This script should only be at the end of a build to ensure:
#   - The .app folder exists
#   - the plist has been preprocessed
# Processing is done inside the .app to prevent changes to repository status

declare -r INFO_PLIST="${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/Info.plist"

# Fail if any subsequent commands fail
set -e

if [[ "${CONFIGURATION}" != "Release" || $WMF_FORCE_ITUNES_FILE_SHARING == "1" ]]; then
  echo "Enabling iTunes File Sharing for ${CONFIGURATION} build."
  defaults write "${INFO_PLIST}" UIFileSharingEnabled true
fi

if [[ "${CONFIGURATION}" != "Release" || $WMF_FORCE_DEBUG_MENU == "1" ]]; then
  echo "Showing debug menu for ${CONFIGURATION} build."
  defaults write "${INFO_PLIST}" WMFShowDebugMenu true
fi

