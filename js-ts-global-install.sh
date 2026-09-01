#!/usr/bin/env bash

set -e  # Exit on error

GLOBAL_PACKAGE_JSON="$HOME/.config/pnpm/global-package.json"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Installing global JS/TS packages via pnpm"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -f "$GLOBAL_PACKAGE_JSON" ]; then
  echo "❌ Error: global-package.json not found at $GLOBAL_PACKAGE_JSON"
  echo "   Make sure you've run stow on the js-ts-global package first."
  exit 1
fi

# Clean up npm-installed prettierd if it exists
echo "🧹 Cleaning up old npm-installed packages..."
npm uninstall -g @fsouza/prettierd 2>/dev/null || true

echo "📦 Installing packages from global-package.json..."
echo ""

# Extract dependencies from package.json and install them globally
# Using node to parse JSON properly
node -e "
const pkg = require('$GLOBAL_PACKAGE_JSON');
const deps = pkg.dependencies || {};
for (const [name, version] of Object.entries(deps)) {
  const packageSpec = version === 'latest' ? name : \`\${name}@\${version}\`;
  console.log(packageSpec);
}
" | while read -r package; do
  if [ -n "$package" ]; then
    echo "  Installing: $package"
    pnpm add -g "$package" --ignore-scripts=false
  fi
done

echo ""
echo "✅ Global JS/TS packages installed successfully!"
echo ""
echo "Installed packages:"
pnpm list -g --depth 0
