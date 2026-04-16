#!/bin/bash
set -e

# ============================================================
#  Mobile Forensic Setup
#  Installs: UFADE, ALEX, iLEAPP, ALEAPP
#  Tested on: Arch Linux / CachyOS
# ============================================================

TOOLS_DIR="$HOME/Tools"
REPOS=(
    "UFADE|https://github.com/prosch88/UFADE.git|ufade.py"
    "ALEX|https://github.com/prosch88/ALEX.git|alex.py"
    "iLEAPP|https://github.com/prosch88/iLEAPP.git|ileappGUI.py"
    "ALEAPP|https://github.com/prosch88/ALEAPP.git|aleappGUI.py"
)

ICONS=(
    "UFADE|assets/ufade.png"
    "ALEX|assets/alex.png"
    "iLEAPP|assets/iLEAPP_logo.png"
    "ALEAPP|assets/ALEAPP_logo.png"
)

COMMENTS=(
    "UFADE|Universal Forensic Apple Device Extractor"
    "ALEX|Android Logical Extraction"
    "iLEAPP|iOS Logs Events And Plists Parser"
    "ALEAPP|Android Logs Events And Plists Parser"
)

# ── helpers ──────────────────────────────────────────────────

info()    { echo -e "\e[1;34m==>\e[0m $*"; }
success() { echo -e "\e[1;32m  ✓\e[0m $*"; }
warn()    { echo -e "\e[1;33m  !\e[0m $*"; }
die()     { echo -e "\e[1;31mERROR:\e[0m $*" >&2; exit 1; }

get_field() {
    local name="$1" field="$2" list=("${@:3}")
    for entry in "${list[@]}"; do
        IFS='|' read -r n v <<< "$entry"
        [[ "$n" == "$name" ]] && echo "$v" && return
    done
}

get_field3() {
    local name="$1" field="$2" list=("${@:3}")
    for entry in "${list[@]}"; do
        IFS='|' read -r n f1 f2 <<< "$entry"
        [[ "$n" == "$name" ]] && { [[ "$field" == "1" ]] && echo "$f1" || echo "$f2"; } && return
    done
}

# ── 1. system packages ────────────────────────────────────────

info "Installing system packages..."
sudo pacman -S --needed --noconfirm python311 tk 2>/dev/null || die "pacman failed"
success "python311 + tk installed"

# ── 2. directories ───────────────────────────────────────────

info "Creating directories..."
mkdir -p \
    "$TOOLS_DIR" \
    "$HOME/.local/share/applications" \
    "$HOME/.local/share/desktop-directories" \
    "$HOME/.config/menus/applications-merged"
success "Directories ready"

# ── 3. clone & setup each tool ───────────────────────────────

for entry in "${REPOS[@]}"; do
    IFS='|' read -r name url main_script <<< "$entry"
    dir="$TOOLS_DIR/$name"

    info "[$name] Cloning..."
    if [[ -d "$dir/.git" ]]; then
        warn "$name already exists — pulling instead"
        git -C "$dir" pull
    else
        git clone "$url" "$dir"
    fi

    info "[$name] Creating Python 3.11 venv..."
    python3.11 -m venv "$dir/.venv"

    info "[$name] Installing requirements..."
    "$dir/.venv/bin/pip" install -q --upgrade pip
    "$dir/.venv/bin/pip" install -q -r "$dir/requirements.txt"

    info "[$name] Creating start script..."
    cat > "$dir/start.sh" <<EOF
#!/bin/bash
cd "\$(dirname "\$0")"
.venv/bin/python $main_script
EOF
    chmod +x "$dir/start.sh"

    success "$name done"
    echo
done

# ── 4. desktop entries ───────────────────────────────────────

info "Creating desktop entries..."

for entry in "${REPOS[@]}"; do
    IFS='|' read -r name url main_script <<< "$entry"
    dir="$TOOLS_DIR/$name"

    icon_rel=$(get_field "$name" "" "${ICONS[@]}")
    comment=$(get_field "$name" "" "${COMMENTS[@]}")
    icon_path="$dir/$icon_rel"

    # fallback icon if file not found
    [[ -f "$icon_path" ]] || icon_path="applications-science"

    cat > "$HOME/.local/share/applications/${name,,}.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$name
Comment=$comment
Exec=$dir/start.sh
Icon=$icon_path
Terminal=false
Categories=MobileForensic;
EOF
    success "$name.desktop created"
done

# ── 5. updater script ────────────────────────────────────────

info "Creating update script..."
cat > "$TOOLS_DIR/update-mobile-forensic.sh" <<'EOF'
#!/bin/bash
set -e

TOOLS=(UFADE ALEX iLEAPP ALEAPP)
BASE="$HOME/Tools"

for tool in "${TOOLS[@]}"; do
    dir="$BASE/$tool"
    echo "==> Updating $tool..."
    git -C "$dir" pull
    echo "    Installing requirements..."
    "$dir/.venv/bin/pip" install -q --upgrade -r "$dir/requirements.txt"
    echo "    $tool done."
    echo
done

echo "All tools updated."
EOF
chmod +x "$TOOLS_DIR/update-mobile-forensic.sh"
success "update-mobile-forensic.sh created"

# ── 6. updater desktop entry ─────────────────────────────────

cat > "$HOME/.local/share/applications/mobile-forensic-update.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Mobile Forensic Updater
Comment=Updates UFADE, ALEX, iLEAPP and ALEAPP
Exec=bash -c '$TOOLS_DIR/update-mobile-forensic.sh 2>&1 | tee /tmp/mobile-forensic-update.log; echo "--- Done. Press Enter to close ---"; read'
Icon=system-software-update
Terminal=true
Categories=MobileForensic;
EOF
success "Updater desktop entry created"

# ── 7. menu folder ───────────────────────────────────────────

info "Creating start menu folder..."

cat > "$HOME/.local/share/desktop-directories/mobile-forensic.directory" <<EOF
[Desktop Entry]
Type=Directory
Name=Mobile Forensic
Icon=phone
EOF

cat > "$HOME/.config/menus/applications-merged/mobile-forensic.menu" <<EOF
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
  "http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
<Menu>
  <Name>Applications</Name>
  <Menu>
    <Name>MobileForensic</Name>
    <Directory>mobile-forensic.directory</Directory>
    <Include>
      <Category>MobileForensic</Category>
    </Include>
  </Menu>
</Menu>
EOF

update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
success "Menu folder created"

# ── done ─────────────────────────────────────────────────────

echo
echo -e "\e[1;32m============================================================\e[0m"
echo -e "\e[1;32m  Setup complete!\e[0m"
echo -e "\e[1;32m============================================================\e[0m"
echo
echo "  Tools installed in: $TOOLS_DIR"
echo
echo "  Start commands:"
echo "    ~/Tools/UFADE/start.sh"
echo "    ~/Tools/ALEX/start.sh"
echo "    ~/Tools/iLEAPP/start.sh"
echo "    ~/Tools/ALEAPP/start.sh"
echo
echo "  Update all: ~/Tools/update-mobile-forensic.sh"
echo
echo "  If the menu folder doesn't appear yet, run:"
echo "    kbuildsycoca6"
echo
