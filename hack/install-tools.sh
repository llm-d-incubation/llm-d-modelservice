#!/bin/bash

set -euo pipefail

# Tool versions

# https://github.com/helm/chart-testing
CT_VERSION="v3.13.0"
# https://github.com/helm/helm
HELM_VERSION="v3.18.5"
# https://pypi.org/project/yamale/
YAMALE_VERSION="6.0.0"
# https://pypi.org/project/yamllint/
YAMLLINT_VERSION="1.37.1"
# https://pypi.org/project/pre-commit/
PRECOMMIT_VERSION="4.3.0"

# Global variables
FORCE_INSTALL="${FORCE_INSTALL:-false}"

# Detect OS and Architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case $ARCH in
  x86_64) ARCH="amd64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

# Check if a tool is already installed
is_tool_installed() {
  local tool_path="$1"
  [ -f "$tool_path" ] && [ -x "$tool_path" ]
}

# Check if tool should be installed (returns 0 if should skip, 1 if should install)
should_skip_install() {
  local tool_name="$1"
  local tool_binary="$2"

  if [[ "$FORCE_INSTALL" != "true" ]] && is_tool_installed "$tool_binary"; then
    echo "$tool_name is already installed. Skipping installation."
    echo "Set FORCE_INSTALL=true to reinstall."
    return 0
  fi
  return 1
}


install_tar_binary() {
  local install_path="$1"
  local download_url="$2"
  local binary_path="$3"
  local binary_name="${4:-$(basename "$binary_path")}"

  mkdir -p "$install_path"

  echo "Installing $binary_name..."
  local temp_dir=$(mktemp -d)
  curl -fsSL "$download_url" | tar -zx -C "$temp_dir"
  mv "$temp_dir/$binary_path" "$install_path/$binary_name"
  rm -rf "$temp_dir"
  chmod +x "$install_path/$binary_name"
}

install_ct() {
  local install_path="$1"
  local ct_binary="$install_path/ct"

  # Check if ct should be skipped
  if should_skip_install "ct" "$ct_binary"; then
    return 0
  fi

  echo "Installing Python dependencies..."
  pip3 install "yamale==$YAMALE_VERSION" "yamllint==$YAMLLINT_VERSION"
  install_tar_binary "$install_path" \
    "https://github.com/helm/chart-testing/releases/download/$CT_VERSION/chart-testing_${CT_VERSION:1}_${OS}_${ARCH}.tar.gz" \
    "ct"
}

install_helm() {
  local install_path="$1"
  local helm_binary="$install_path/helm"

  # Check if helm should be skipped
  if should_skip_install "helm" "$helm_binary"; then
    return 0
  fi

  install_tar_binary "$install_path" \
    "https://get.helm.sh/helm-$HELM_VERSION-$OS-$ARCH.tar.gz" \
    "$OS-$ARCH/helm" \
    "helm"
}

install_precommit() {
  local install_path="$1"
  local precommit_binary="$install_path/pre-commit"

  # Check if pre-commit should be skipped
  if should_skip_install "pre-commit" "$precommit_binary"; then
    return 0
  fi

  pip3 install "pre-commit==$PRECOMMIT_VERSION"

  # Create a wrapper script in the bin directory
  cat > "$precommit_binary" << 'EOF'
#!/bin/bash
# Wrapper script to use the system-installed pre-commit
exec python3 -m pre_commit "$@"
EOF
  chmod +x "$precommit_binary"
}


# Main execution
install_tool() {
  local install_path="$1"
  local tool="$2"
  "install_$tool" "$install_path"
  echo "'$tool' has been installed successfully. Location: $install_path"
}

# Set default TOOLS_PATH if not provided
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_PATH="${TOOLS_PATH:-$PROJECT_DIR/bin}"

if [ $# -eq 0 ]; then
  install_tool "$TOOLS_PATH" "ct"
  install_tool "$TOOLS_PATH" "helm"
  install_tool "$TOOLS_PATH" "precommit"
else
  install_tool "$TOOLS_PATH" "${1}"
fi
