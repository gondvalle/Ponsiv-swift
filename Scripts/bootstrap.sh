#!/usr/bin/env bash
set -euo pipefail

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "Instalando XcodeGen con Homebrew…"
  brew install xcodegen
fi

echo "Generando Ponsiv.xcodeproj con XcodeGen…"
xcodegen

echo "Resolviendo dependencias SPM…"
xcodebuild -resolvePackageDependencies -project Ponsiv.xcodeproj

echo "Listo. Abre Ponsiv.xcodeproj, selecciona el esquema 'Ponsiv' y pulsa ⌘B y luego ⌘R."
