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

### 🔴 HOCH: Perspektive / Rendering
**Das größte ungelöste Problem.**
- Aktuelle Formel: `z^1.8` — funktioniert technisch, aber:
  - Hindernisse werden beim Näherkommen **flacher/niedriger** statt größer
  - Visuelle Geschwindigkeit: Objekte **zu schnell in der Ferne, zu langsam am Spieler**
- Ziel: echte `1/z`-Projektion (Pseudo-3D-Racer Stil)
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
➡️ Stückweise Gameplay-Treue erhöhen: zuerst Flow, Tempo, Spawn-Rhythmus und Lenkgefühl feinjustieren

## Aktuelle Iteration
- Erste kleine Gameplay-Pass-Änderung auf Flow/Pacing
- Etwas schnellerer Vorwärtsfluss
- Kürzerer, knackigerer Sprung
- Leicht trägeres, kontrollierteres Steering
- Coins etwas ruhiger zwischen Hindernisphasen
- Zweite Gameplay-Pass-Änderung auf Hindernis-Rhythmus
- Weniger zufällige Spawnfolge, mehr wiedererkennbare Druck-/Ruhephasen
- Coins stärker entlang sinnvoller Fahrlinien
- Dritte Gameplay-Pass-Änderung: Ruhephasen mit geführten Coin-Routen durch größere Tunnelbewegungen
- Danach vereinfacht: Coin-Spiral-Phasen sollen klar lesbar sein, ohne konkurrierende Coin-Linien oder harte Hindernisse
- Coin-Collection wurde enger gezogen, um Fehl-Einsammeln rund um Sprünge zu reduzieren

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
