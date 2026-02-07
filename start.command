#!/bin/bash
cd "$(dirname "$0")"
echo "🎮 Iniciando servidor PLAYBOX en http://localhost:8080/PLAYBOX.html"
echo ""
echo "Presiona Ctrl+C para detener el servidor"
echo ""
open "http://localhost:8080/PLAYBOX.html" &
python3 -m http.server 8080
