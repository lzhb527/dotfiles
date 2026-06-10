#!/bin/bash

# Create sample directory for testing
DEMO_DIR="$HOME/QuickFind2Demo"

echo "Creating demo directory at $DEMO_DIR..."

# Remove if exists
rm -rf "$DEMO_DIR"

# Create main directory
mkdir -p "$DEMO_DIR"

# Create project structure
mkdir -p "$DEMO_DIR/Projects/WebApp"
mkdir -p "$DEMO_DIR/Projects/MobileApp"
mkdir -p "$DEMO_DIR/Projects/DataScience"

# Web project files with content
cat > "$DEMO_DIR/Projects/WebApp/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Demo</title></head>
<body><h1>Hello World</h1></body>
</html>
EOF

cat > "$DEMO_DIR/Projects/WebApp/styles.css" << 'EOF'
body { margin: 0; padding: 20px; }
h1 { color: #333; }
EOF

cat > "$DEMO_DIR/Projects/WebApp/script.js" << 'EOF'
console.log('Hello World');
document.addEventListener('DOMContentLoaded', () => {
  console.log('Ready');
});
EOF

cat > "$DEMO_DIR/Projects/WebApp/package.json" << 'EOF'
{
  "name": "webapp",
  "version": "1.0.0",
  "main": "index.js"
}
EOF

echo "# WebApp Project" > "$DEMO_DIR/Projects/WebApp/README.md"

# Mobile project files
cat > "$DEMO_DIR/Projects/MobileApp/MainActivity.java" << 'EOF'
public class MainActivity {
    public static void main(String[] args) {
        System.out.println("Hello World");
    }
}
EOF

cat > "$DEMO_DIR/Projects/MobileApp/app.kt" << 'EOF'
fun main() {
    println("Hello Kotlin")
}
EOF

echo '<?xml version="1.0"?><config></config>' > "$DEMO_DIR/Projects/MobileApp/config.xml"
echo 'apply plugin: "com.android.application"' > "$DEMO_DIR/Projects/MobileApp/build.gradle"

# Data science files
cat > "$DEMO_DIR/Projects/DataScience/analysis.py" << 'EOF'
import pandas as pd
import numpy as np

def analyze_data():
    print("Analysis started")
EOF

echo "name,value,date" > "$DEMO_DIR/Projects/DataScience/data.csv"
echo "item1,100,2024-01-01" >> "$DEMO_DIR/Projects/DataScience/data.csv"

echo "# Notebook" > "$DEMO_DIR/Projects/DataScience/notebook.ipynb"
echo "pandas>=2.0.0" > "$DEMO_DIR/Projects/DataScience/requirements.txt"
dd if=/dev/urandom of="$DEMO_DIR/Projects/DataScience/model.pkl" bs=1024 count=1 2>/dev/null

# Documents
mkdir -p "$DEMO_DIR/Documents/Reports"
mkdir -p "$DEMO_DIR/Documents/Presentations"
mkdir -p "$DEMO_DIR/Documents/Spreadsheets"

# Create actual PDF
cat > "$DEMO_DIR/Documents/Reports/Q4_Report.pdf" << 'EOF'
%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Count 1/Kids[3 0 R]>>endobj
3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R/Resources<<>>>>endobj
xref
0 4
trailer<</Size 4/Root 1 0 R>>
%%EOF
EOF

echo "Q4 Report Content" > "$DEMO_DIR/Documents/Reports/Annual_Summary.docx"
echo "Meeting Notes - January 2024" > "$DEMO_DIR/Documents/Reports/Meeting_Notes.txt"
echo "# Technical Documentation" > "$DEMO_DIR/Documents/Reports/Technical_Documentation.md"

# Create dummy office files
echo "PK" > "$DEMO_DIR/Documents/Presentations/Product_Launch.pptx"
echo "PK" > "$DEMO_DIR/Documents/Spreadsheets/Budget_2024.xlsx"

# Media files - create minimal valid files
mkdir -p "$DEMO_DIR/Media/Images"
mkdir -p "$DEMO_DIR/Media/Videos"
mkdir -p "$DEMO_DIR/Media/Music"

# Create a 1x1 PNG
printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82' > "$DEMO_DIR/Media/Images/screenshot.png"

# Create a minimal JPEG
printf '\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xff\xdb\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t\x08\n\x0c\x14\r\x0c\x0b\x0b\x0c\x19\x12\x13\x0f\x14\x1d\x1a\x1f\x1e\x1d\x1a\x1c\x1c $.\x27 $\x1c\x1c(7),01444\x1f\x27'\''9=82<.342\xff\xc0\x00\x0b\x08\x00\x01\x00\x01\x01\x01\x11\x00\xff\xc4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\t\xff\xda\x00\x08\x01\x01\x00\x00?\x00\xd2\xcf \xff\xd9' > "$DEMO_DIR/Media/Images/vacation_photo.jpg"

# Create minimal SVG
cat > "$DEMO_DIR/Media/Images/logo.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
  <circle cx="50" cy="50" r="40" fill="blue"/>
</svg>
EOF

# Create minimal GIF
printf 'GIF89a\x01\x00\x01\x00\x80\x00\x00\xff\xff\xff\x00\x00\x00!\xf9\x04\x01\x00\x00\x00\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02D\x01\x00;' > "$DEMO_DIR/Media/Images/diagram.gif"

# Audio/Video - just headers
printf 'ID3' > "$DEMO_DIR/Media/Music/song1.mp3"
printf 'fLaC' > "$DEMO_DIR/Media/Music/track2.flac"
printf 'RIFF\x24\x00\x00\x00WAVEfmt ' > "$DEMO_DIR/Media/Music/audio.wav"
printf 'OggS' > "$DEMO_DIR/Media/Music/podcast.ogg"

# Video headers
printf '\x00\x00\x00\x20ftypmp42' > "$DEMO_DIR/Media/Videos/tutorial.mp4"
printf 'RIFF\x00\x00\x00\x00AVI ' > "$DEMO_DIR/Media/Videos/presentation.avi"
printf '\x1aE\xdf\xa3' > "$DEMO_DIR/Media/Videos/demo.mkv"

# Archives
mkdir -p "$DEMO_DIR/Archives"
printf 'PK\x03\x04' > "$DEMO_DIR/Archives/backup.zip"
printf '\x1f\x8b' > "$DEMO_DIR/Archives/project.tar.gz"
printf '7z\xbc\xaf\x27\x1c' > "$DEMO_DIR/Archives/data.7z"
printf 'Rar!' > "$DEMO_DIR/Archives/old_files.rar"

# Scripts and configs
mkdir -p "$DEMO_DIR/Scripts"
cat > "$DEMO_DIR/Scripts/deploy.sh" << 'EOF'
#!/bin/bash
echo "Deploying application..."
EOF
chmod +x "$DEMO_DIR/Scripts/deploy.sh"

cat > "$DEMO_DIR/Scripts/automation.py" << 'EOF'
#!/usr/bin/env python3
print("Automation script")
EOF

cat > "$DEMO_DIR/Scripts/config.ini" << 'EOF'
[settings]
debug=true
EOF

echo '{"version": "1.0"}' > "$DEMO_DIR/Scripts/settings.json"
echo 'SELECT * FROM users;' > "$DEMO_DIR/Scripts/database.sql"

# Development tools
mkdir -p "$DEMO_DIR/Development"
echo '#include <stdio.h>' > "$DEMO_DIR/Development/main.c"
echo '#include <iostream>' > "$DEMO_DIR/Development/utils.cpp"
echo 'package main' > "$DEMO_DIR/Development/server.go"
echo 'fn main() {}' > "$DEMO_DIR/Development/app.rs"
echo 'export default function() {}' > "$DEMO_DIR/Development/component.jsx"
echo '$color: blue;' > "$DEMO_DIR/Development/style.scss"

# Books
mkdir -p "$DEMO_DIR/Books"
printf 'PK\x03\x04' > "$DEMO_DIR/Books/Programming_Guide.epub"
echo 'MOBI' > "$DEMO_DIR/Books/Novel.mobi"

# Fonts
mkdir -p "$DEMO_DIR/Fonts"
printf '\x00\x01\x00\x00' > "$DEMO_DIR/Fonts/custom_font.ttf"
printf 'OTTO' > "$DEMO_DIR/Fonts/icons.otf"
printf 'wOFF' > "$DEMO_DIR/Fonts/web_font.woff2"

# Hidden files
echo 'node_modules/' > "$DEMO_DIR/.gitignore"
echo 'SECRET_KEY=xyz' > "$DEMO_DIR/.env"

echo "✓ Demo directory created successfully!"
echo "Location: $DEMO_DIR"
echo ""
echo "Files now have proper headers/content for icon detection!"
