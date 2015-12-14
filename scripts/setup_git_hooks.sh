# Install the git pre-commit hook
if [[ -z "./.git" ]]; then
  echo "No git directory detected."
  exit 2
fi

echo "Installing the git hook"
GIT_HOOK_INSTALL_PATH="./.git/hooks/pre-push"
GIT_HOOK_SCRIPT_PATH="./scripts/git-uncrustify-all-pre-flight-check.sh"
GIT_HOOK_SCRIPT_PATH_REL_HOOKS="../../$GIT_HOOK_SCRIPT_PATH"

if [[ -L "$GIT_HOOK_INSTALL_PATH" ]]; then
  echo "Backed up previous commit-hook"
  mv -f "$GIT_HOOK_INSTALL_PATH" "${GIT_HOOK_INSTALL_PATH}.bak"
fi

ln -s "$GIT_HOOK_SCRIPT_PATH_REL_HOOKS" "$GIT_HOOK_INSTALL_PATH"
echo "Installed git hook at $GIT_HOOK_INSTALL_PATH"
