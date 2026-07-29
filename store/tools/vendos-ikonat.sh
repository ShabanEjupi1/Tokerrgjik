#!/bin/sh
# Shpërndan ikonat e vizatuara te vendet ku i pret Android-i, Flutter Web-i dhe
# Play Console-i. Ekzekutohet pas `vizato.mjs`.
#
#   sh vendos-ikonat.sh <dosja-me-png-të-vizatuara>
set -eu

G="${1:?jep dosjen me PNG-të}"
R="$(cd "$(dirname "$0")/../.." && pwd)"        # rrënja e repos
A="$R/tokerrgjik_mobile/android/app/src/main/res"
W="$R/tokerrgjik_mobile/web"
S="$R/store/assets"

# --- Android: ikona e nisjes, e vjetra dhe ajo adaptive -------------------
cp "$G/ic_launcher-mdpi-48.png"     "$A/mipmap-mdpi/ic_launcher.png"
cp "$G/ic_launcher-hdpi-72.png"     "$A/mipmap-hdpi/ic_launcher.png"
cp "$G/ic_launcher-xhdpi-96.png"    "$A/mipmap-xhdpi/ic_launcher.png"
cp "$G/ic_launcher-xxhdpi-144.png"  "$A/mipmap-xxhdpi/ic_launcher.png"
cp "$G/ic_launcher-xxxhdpi-192.png" "$A/mipmap-xxxhdpi/ic_launcher.png"

cp "$G/ic_launcher_foreground-mdpi-108.png"    "$A/drawable-mdpi/ic_launcher_foreground.png"
cp "$G/ic_launcher_foreground-hdpi-162.png"    "$A/drawable-hdpi/ic_launcher_foreground.png"
cp "$G/ic_launcher_foreground-xhdpi-216.png"   "$A/drawable-xhdpi/ic_launcher_foreground.png"
cp "$G/ic_launcher_foreground-xxhdpi-324.png"  "$A/drawable-xxhdpi/ic_launcher_foreground.png"
cp "$G/ic_launcher_foreground-xxxhdpi-432.png" "$A/drawable-xxxhdpi/ic_launcher_foreground.png"

# --- Flutter Web / PWA ---------------------------------------------------
cp "$G/web-Icon-192.png"          "$W/icons/Icon-192.png"
cp "$G/web-Icon-512.png"          "$W/icons/Icon-512.png"
cp "$G/ic_launcher-xhdpi-96.png"  "$W/icons/Icon-96.png"
cp "$G/web-favicon-32.png"        "$W/icons/Icon-32.png"
cp "$G/web-favicon-16.png"        "$W/icons/Icon-16.png"
cp "$G/web-favicon-16.png"        "$W/icons/favicon-16x16.png"
cp "$G/web-Icon-maskable-192.png" "$W/icons/Icon-maskable-192.png"
cp "$G/web-Icon-maskable-512.png" "$W/icons/Icon-maskable-512.png"

cp "$G/web-favicon-32.png"        "$W/favicon.png"
cp "$G/web-favicon-32.png"        "$W/favicon-32x32.png"
cp "$G/web-favicon-16.png"        "$W/favicon-16x16.png"
cp "$G/web-apple-touch-180.png"   "$W/apple-touch-icon.png"
cp "$G/web-Icon-192.png"          "$W/android-chrome-192x192.png"
cp "$G/web-Icon-512.png"          "$W/android-chrome-512x512.png"

# --- Play Console --------------------------------------------------------
mkdir -p "$S"
cp "$G/play-ikona-512.png"        "$S/play-ikona-512.png"
cp "$G/play-grafika-1024x500.png" "$S/play-grafika-1024x500.png"

echo "✓ ikonat u vendosën"
