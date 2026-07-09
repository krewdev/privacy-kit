#!/usr/bin/env bash
# Install privacy-kit to ~/.local/share/privacy-kit and symlink pk → ~/bin/pk
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PREFIX="${PK_PREFIX:-$HOME/.local/share/privacy-kit}"
BIN_DIR="${HS_INSTALL_DIR:-$HOME/bin}"

echo "Installing privacy-kit → $PREFIX"
mkdir -p "$PREFIX"
# copy tree (exclude .git)
rsync -a --delete --exclude '.git' --exclude '.DS_Store' "$ROOT/" "$PREFIX/" 2>/dev/null || {
  rm -rf "$PREFIX"
  mkdir -p "$PREFIX"
  cp -R "$ROOT/bin" "$ROOT/lib" "$ROOT/docs" "$PREFIX/" 2>/dev/null || true
  cp "$ROOT/README.md" "$ROOT/LICENSE" "$ROOT/install.sh" "$PREFIX/" 2>/dev/null || true
  # ensure lib+bin exist
  cp -R "$ROOT/bin" "$PREFIX/"
  cp -R "$ROOT/lib" "$PREFIX/"
}

chmod +x "$PREFIX/bin/pk"
mkdir -p "$BIN_DIR"
ln -sfn "$PREFIX/bin/pk" "$BIN_DIR/pk"
echo "Linked: $BIN_DIR/pk → $PREFIX/bin/pk"

path_line='export PATH="$HOME/bin:$PATH"'
add_path_to() {
  local rc="$1"
  [[ -f "$rc" ]] || touch "$rc"
  if grep -qE '\$HOME/bin|~/bin' "$rc" 2>/dev/null; then
    echo "PATH already references bin in $rc"
  else
    printf '\n# privacy-kit\n%s\n' "$path_line" >>"$rc"
    echo "Added ~/bin to PATH in $rc"
  fi
}

case "${SHELL:-}" in
  */zsh) add_path_to "$HOME/.zshrc" ;;
  */bash)
    if [[ -f "$HOME/.bashrc" ]]; then add_path_to "$HOME/.bashrc"
    else add_path_to "$HOME/.bash_profile"; fi
    ;;
  *)
    [[ -f "$HOME/.zshrc" ]] && add_path_to "$HOME/.zshrc"
    ;;
esac

echo
echo "Next:"
echo "  source ~/.zshrc"
echo "  pk audit"
echo
"$BIN_DIR/pk" version
