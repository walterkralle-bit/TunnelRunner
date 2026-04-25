# Projekt Status — Tunnel Runner

## Aktueller Stand
- Basis-Gameplay funktioniert
- Pause-Feature mit Button + ESC eingebaut
- Pause-Button aus dem Spielfeld in eine obere Leiste verschoben
- Tunnel-Framing oben etwas entschärft, damit der Rand nicht abgeschnitten wirkt
- 8-Sektoren-Kollision implementiert
- Sprung-Mechanik fertig
- Münzen-System (Spiral + Gap-Spawn) fertig
- Combo-Hindernisse (braun + cyan gemischt) fertig
- Mobile-Steuerung (Steuerrad 280px, Sprungknopf) fertig
- Score, Record, Münzzähler, Milestone-Feedback fertig
- Tunnel-Farbwechsel über Zeit fertig
- Funken-Trail beim Fahren fertig

## Offene Probleme (Priorität)

### 🟡 MITTEL: Highscore
- `localStorage`-Persistenz fehlt noch

### 🟡 MITTEL: Screen Shake bei Crash
- Noch nicht implementiert

### 🟡 MITTEL: Gameplay-Feintuning
- Spawn-Rhythmus weiter testen
- Lenkgefühl und Flow feinjustieren
- Fairness in längeren Runs beobachten

### 🟢 NIEDRIG: App Store / PWA
- Capacitor-Integration als letzter Schritt
- Erst wenn Web-Version stabil und getestet

## Nächster Schritt
➡️ Highscore (`localStorage`) und Screen Shake als nächstes Polishing umsetzen

## Zuletzt erledigt
- Perspektive in `index-perspective-exp.html` auf deutlich glaubwürdigere Pseudo-3D-Projektion umgestellt
- Hindernis-Austritt am Bildschirmrand über harte Tunnel-Vorderkante entschärft
- Unfaire, vollständig blockierende Hinderniskombinationen im Experimental-Build abgesichert
- Sound-System testweise eingebaut; Thema vorerst geparkt und nicht mehr als aktiver Fokus behandeln
- Separates Godot-Projekt unter `godot/TunnelRunnerGodot/` als neuer Port-Startpunkt angelegt, ohne den HTML-Build zu ersetzen

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
- Coin-Spiralen wurden flacher und länger gemacht, damit sie klarer lesbar und besser fahrbar sind
- Coin-Collect-Logik wurde weiter verschärft, damit Spiral-Münzen nicht kettenartig falsch eingesammelt werden
- Brown-Block-Gruppen werden jetzt konsequenter als zusammenhängende Wandsegmente gespawnt, auch in Combo-Situationen
- Coin-Spiral-Phasen werden stärker von Hindernisdruck freigehalten
- Spiral-Phasen sollen exklusiver sein, ohne konkurrierende Coin-Sequenzen mitten in der Route
- Brown/Blue-Combo-Geometrie wird schrittweise bündiger gemacht, damit zwischen Segmenten keine sichtbaren Lücken entstehen
- Coin-Spiralen werden stärker an sichere Fahrbahnen gebunden statt frei durch problematische Hindernisgeometrie zu laufen
- Blue Jump-Segmente sollen über gleiche Unterkante statt gleiche Oberkante mit Brown-Walls lesbarer werden, damit sie niedriger und überspringbar wirken
- Sichtbare Nähte zwischen zusammenhängenden Brown-Segmenten werden weiter reduziert
- Screenshot-getriebenes Feintuning an Combo-Geometrie und Segmenthöhen läuft
- Blue-Segmente werden radial nach außen gesetzt, ohne ihre eigene Dicke zu verlieren

## Wichtige Design-Entscheidungen
- **NICHT** "Dodge!"/"Jump!"-Hinweistexte im Spiel
- **KEIN** Lives/Hearts-System (durch Münzzähler ersetzt)
- **KEIN** blinkender Player-Positions-Ring
- Visueller Stil: realistisch/3D, **nicht** Retro/Pixel
- Kommunikation mit Felix: Deutsch, kurz und direkt

## Roadmap
1. ✅ Core-Gameplay
2. ✅ Perspektive lösen
3. ⏸️ Sound vorerst geparkt
4. 🔲 Highscore (localStorage)
5. 🔲 Screen Shake
6. 🔲 Web-Version deployen (GitHub Pages / Netlify)
7. 🔲 Tester via itch.io
8. 🔲 App Store (Capacitor / PWA)
