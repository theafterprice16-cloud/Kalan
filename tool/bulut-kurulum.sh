#!/bin/bash
# Kalan · claude.ai/code bulut ortamı kurulum betiği: Flutter SDK
# Ortam ayarlarındaki "Setup script" kutusuna bu dosyanın tamamını yapıştır.
# Projen belirli bir Flutter sürümüne bağlıysa aşağıya yaz (örnek: FLUTTER_SURUM="3.38.1").
# Boş bırakırsan en son stable sürüm kurulur.
FLUTTER_SURUM=""

HEDEF=/opt/flutter
KAYNAK=https://storage.googleapis.com/flutter_infra_release/releases

if [ ! -x "$HEDEF/bin/flutter" ]; then
  LISTE=$(curl -fsSL "$KAYNAK/releases_linux.json") || { echo "Kalan: Flutter sürüm listesi alınamadı"; exit 0; }
  if [ -n "$FLUTTER_SURUM" ]; then
    ARSIV=$(echo "$LISTE" | jq -r --arg v "$FLUTTER_SURUM" '[.releases[] | select(.version==$v and .channel=="stable")][0].archive')
  else
    ARSIV=$(echo "$LISTE" | jq -r '.current_release.stable as $h | [.releases[] | select(.hash==$h)][0].archive')
  fi
  if [ -z "$ARSIV" ] || [ "$ARSIV" = "null" ]; then echo "Kalan: Flutter arşivi bulunamadı"; exit 0; fi
  curl -fsSL "$KAYNAK/$ARSIV" | tar -xJ -C /opt || { echo "Kalan: Flutter indirilemedi"; exit 0; }
fi

git config --system --add safe.directory "$HEDEF" || true
ln -sf "$HEDEF/bin/flutter" /usr/local/bin/flutter
ln -sf "$HEDEF/bin/dart" /usr/local/bin/dart
flutter config --no-analytics >/dev/null 2>&1 || true
dart --disable-analytics >/dev/null 2>&1 || true
flutter precache --no-android --no-ios >/dev/null 2>&1 || true
flutter --version || true
chmod -R a+rwX "$HEDEF" || true
exit 0
