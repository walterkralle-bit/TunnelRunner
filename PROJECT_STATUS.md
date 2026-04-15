# Projekt Status — Tunnel Runner

## Aktueller Stand
- Basis-Gameplay funktioniert
- 8-Sektoren-Kollision implementiert
- Sprung-Mechanik fertig
- Münzen-System (Spiral + Gap-Spawn) fertig
- Combo-Hindernisse (braun + cyan gemischt) fertig
- Mobile-Steuerung (Steuerrad 280px, Sprungknopf) fertig
- Score, Record, Münzzähler, Milestone-Feedback fertig
- Tunnel-Farbwechsel über Zeit fertig
- Funken-Trail beim Fahren fertig

## Offene Probleme (Priorität)

### 🟠 IN ARBEIT: Perspektive / Rendering
- Alte Formel `z^1.8` wurde als Hauptproblem identifiziert
- Erste Umstellung auf eine echte `1/z`-artige Weltdepth-Projektion ist jetzt eingebaut
- Nächster Schritt: im Browser feinjustieren, bis
  - Hindernisse beim Näherkommen ihre Proportionen behalten
  - Objekte näher am Spieler visuell schneller wirken
  - Tunnel nicht leer oder zu stark gestaucht aussieht
- Referenz: https://gabrielgambetta.com/computer-graphics-from-scratch/09-perspective-projection.html
- Referenz: https://jakesgordon.com/writing/javascript-racer-v1-straight/

### 🟡 MITTEL: Sound
- Noch nicht implementiert
- Gewünscht: Sprung-Sound, Münzen-Ping, Crash-Boom, Tunnel-Rauschen

### 🟡 MITTEL: Highscore
- `localStorage`-Persistenz fehlt noch

### 🟡 MITTEL: Screen Shake bei Crash
- Noch nicht implementiert

### 🟢 NIEDRIG: App Store / PWA
- Capacitor-Integration als letzter Schritt
- Erst wenn Web-Version stabil und getestet

## Nächster Schritt
➡️ Neue Projektion im laufenden Spiel testen und die Parameter `near`, `far`, `tunnelDepth` fein abstimmen

## Wichtige Design-Entscheidungen
- **NICHT** "Dodge!"/"Jump!"-Hinweistexte im Spiel
- **KEIN** Lives/Hearts-System (durch Münzzähler ersetzt)
- **KEIN** blinkender Player-Positions-Ring
- Visueller Stil: realistisch/3D, **nicht** Retro/Pixel
- Kommunikation mit Felix: Deutsch, kurz und direkt

## Roadmap
1. ✅ Core-Gameplay
2. 🔴 Perspektive lösen
3. 🔲 Sound
4. 🔲 Highscore (localStorage)
5. 🔲 Screen Shake
6. 🔲 Web-Version deployen (GitHub Pages / Netlify)
7. 🔲 Tester via itch.io
8. 🔲 App Store (Capacitor / PWA)
