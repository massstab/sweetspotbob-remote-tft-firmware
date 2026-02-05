#!/bin/bash

# Basisverzeichnisse
ESPHOME_DIR=~/esphome
FIRMWARE_DEST=~/SynologyDrive/Projekte/SweetSpotBob/sweetspotbob-remote-tft-firmware/firmware

# Array mit den Projekt-Nummern
PROJECTS=(1 2)

# Aktivieren der ESPHome Python-Umgebung
echo "Aktiviere ESPHome Python-Umgebung..."
source "$ESPHOME_DIR/venv/bin/activate"
mkdir -p $FIRMWARE_DEST


# Schleife über alle Projekte
for x in "${PROJECTS[@]}"; do
    echo "==============================="
    echo "Kompiliere Projekt esp32-s3-tft-$x.yaml ..."
    
    # Projekt-Datei
    YAML_FILE="$ESPHOME_DIR/esp32-s3-tft-$x.yaml"

    # Eigene Ordner pro Gerät
    mkdir -p $FIRMWARE_DEST/esp32-s3-tft-$x
    
    # Kompilieren mit ESPHome
    esphome --quiet compile "$YAML_FILE"
    if [ $? -ne 0 ]; then
        echo "Fehler beim Kompilieren von $YAML_FILE"
        exit 1
    fi
    
    # Pfad zur kompilierten Firmware
    BUILD_DIR="$ESPHOME_DIR/.esphome/build/esp32-s3-tft-$x/.pioenvs/esp32-s3-tft-$x"
    FIRMWARE_FILE="$BUILD_DIR/firmware.ota.bin"
    
    if [ ! -f "$FIRMWARE_FILE" ]; then
        echo "Firmware-Datei nicht gefunden: $FIRMWARE_FILE"
        exit 1
    fi
    
    # Ziel-Datei in SynologyDrive kopieren
    DEST_FILE="$FIRMWARE_DEST/esp32-s3-tft-$x/firmware-esp32-s3-tft-${x}.ota.bin"
    echo "Kopiere Firmware nach $DEST_FILE ..."
    cp "$FIRMWARE_FILE" "$DEST_FILE"
    
    # MD5 Checksumme berechnen
    MD5_FILE="$FIRMWARE_DEST/esp32-s3-tft-$x/firmware-esp32-s3-tft-${x}.md5"
    echo "Berechne MD5-Checksumme ..."
    md5sum "$DEST_FILE" > "$MD5_FILE"
    
    echo "Projekt esp32-s3-tft-$x fertig."
done

echo "==============================="
echo "Alle Projekte wurden kompiliert und Checksummen erstellt."

# Git Commit und Push
cd ~/SynologyDrive/Projekte/SweetSpotBob/sweetspotbob-remote-tft-firmware || exit 1

echo "Füge neue Firmware-Dateien zum Git hinzu..."
git add firmware/*

# Commit mit automatischem Timestamp
COMMIT_MSG="Update Firmware $(date +'%Y-%m-%d %H:%M:%S')"
git commit -m "$COMMIT_MSG"

echo "Pushe Änderungen zu GitHub..."
git push origin main

echo "Fertig! Alle Änderungen sind auf GitHub."
