# Ton: Entstehung

Alle Klänge und Musikstücke sind **CC0** (Public Domain, D-082: Musik dauerhaft frei).
Namensnennung ist nicht nötig; sie steht hier trotzdem, aus Respekt und zur Nachvollziehbarkeit.
Maßgeblich ist [`klaenge.json`](klaenge.json); diese Seite fasst sie lesbar zusammen.
Abgerufen am 01.11.2026 von OpenGameArt. Bearbeitung mit [`tools/ton/ton_bauen.py`](../../tools/ton/ton_bauen.py):
Stille am Anfang entfernt, bei Bedarf gekürzt und ausgeblendet, Klänge auf Mono 44,1 kHz mit Spitze −1 dBFS (CAF),
Musik auf −16 LUFS (AAC 128 kbit/s). Die Lautstärke im Spiel steht in `App/Audio/AudioStyle.swift`.

## Quellen

| Kürzel | Titel | Autor | Lizenz | Seite |
|---|---|---|---|---|
| `rpg80` | 80 CC0 RPG SFX | rubberduck | CC0 | https://opengameart.org/content/80-cc0-rpg-sfx |
| `sfx100` | 100 CC0 SFX | rubberduck | CC0 | https://opengameart.org/content/100-cc0-sfx |
| `brechen` | 75 CC0 breaking/falling/hit sfx | rubberduck | CC0 | https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx |
| `schleim` | 40 CC0 water/splash/slime SFX | rubberduck | CC0 | https://opengameart.org/content/40-cc0-water-splash-slime-sfx |
| `oberflaeche` | Interface Sounds | Kenney | CC0 | https://opengameart.org/content/interface-sounds |
| `zischen` | Swishes Sound Pack | artisticdude | CC0 | https://opengameart.org/content/swishes-sound-pack |
| `plopp` | 3 Pop Sounds | wubitog | CC0 | https://opengameart.org/content/3-pop-sounds |
| `funke` | Electricity Sound Effects (spark) | BMacZero | CC0 | https://opengameart.org/content/electricity-sound-effects-0 |
| `strom` | Electricity Game Sound Pack (shieldhit) | faxcorp | CC0 | https://opengameart.org/content/electricity-game-sound-pack |
| `markttag` | Medieval: Market Day (Loop) | RandomMind | CC0 | https://opengameart.org/content/medieval-market-day |
| `schlacht` | Medieval: Battle | RandomMind | CC0 | https://opengameart.org/content/medieval-battle |
| `verfolgung` | Determined Pursuit (epic orchestra loop) | Emma_MA | CC0 | https://opengameart.org/content/determined-pursuit-epic-orchestra-loop |
| `sieg` | Medieval: Victory Theme | RandomMind | CC0 | https://opengameart.org/content/medieval-victory-theme |
| `niederlage` | Medieval: Defeat Theme | RandomMind | CC0 | https://opengameart.org/content/medieval-defeat-theme |

## Klänge

| Datei | Quelle | Datei in der Quelle | Bearbeitung |
|---|---|---|---|
| `ui_tap_1.caf` | `oberflaeche` | Audio/select_001.ogg | – |
| `ui_tap_2.caf` | `oberflaeche` | Audio/select_002.ogg | – |
| `ui_confirm_1.caf` | `oberflaeche` | Audio/confirmation_001.ogg | – |
| `ui_deny_1.caf` | `oberflaeche` | Audio/error_004.ogg | – |
| `build_1.caf` | `rpg80` | item_stone_02.ogg | – |
| `build_2.caf` | `rpg80` | item_stone_01.ogg | gekürzt auf 0.45 s |
| `sell_1.caf` | `rpg80` | item_coins_03.ogg | – |
| `watch_shot_1.caf` | `zischen` | swishes/swish-1.wav | – |
| `watch_shot_2.caf` | `zischen` | swishes/swish-2.wav | – |
| `watch_shot_3.caf` | `zischen` | swishes/swish-4.wav | – |
| `bolt_shot_1.caf` | `funke` | (Einzeldatei) | – |
| `bolt_shot_2.caf` | `strom` | (Einzeldatei) | gekürzt auf 0.45 s |
| `spore_puff_1.caf` | `schleim` | slime_03.ogg | – |
| `spore_puff_2.caf` | `schleim` | slime_05.ogg | – |
| `hit_1.caf` | `brechen` | bfh1_wood_hit_01.ogg | – |
| `hit_2.caf` | `sfx100` | hit_01.ogg | – |
| `slowed_1.caf` | `schleim` | bubble_02.ogg | – |
| `combo_1.caf` | `oberflaeche` | Audio/glass_003.ogg | – |
| `enemy_pop_1.caf` | `plopp` | 3pops/pop1.ogg | – |
| `enemy_pop_2.caf` | `plopp` | 3pops/pop3.ogg | – |
| `enemy_pop_3.caf` | `sfx100` | plop_01.ogg | – |
| `coin_1.caf` | `rpg80` | item_coins_01.ogg | gekürzt auf 0.35 s |
| `leak_1.caf` | `sfx100` | slam_01.ogg | – |
| `wave_1.caf` | `sfx100` | gong_01.ogg | – |
| `ability_cast_1.caf` | `rpg80` | spell_02.ogg | – |
| `stone_impact_1.caf` | `brechen` | bfh1_rock_falling_01.ogg | – |
| `stone_impact_2.caf` | `brechen` | bfh1_rock_breaking_02.ogg | – |
| `moon_impact_1.caf` | `rpg80` | spell_01.ogg | – |
| `wall_up_1.caf` | `rpg80` | stones_02.ogg | – |
| `wall_down_1.caf` | `brechen` | bfh1_rock_breaking_01.ogg | – |

## Musik

| Datei | Lage | Quelle | Schleife |
|---|---|---|---|
| `music_menu.m4a` | Hauptmenü, Karte, Avatar | `markttag` (Medieval: Market Day (Loop), RandomMind) | ja |
| `music_battle.m4a` | Kampf, Vorführung | `schlacht` (Medieval: Battle, RandomMind) | ja |
| `music_final_wave.m4a` | letzte Welle | `verfolgung` (Determined Pursuit (epic orchestra loop), Emma_MA) | ja |
| `music_victory.m4a` | Sieg | `sieg` (Medieval: Victory Theme, RandomMind) | nein |
| `music_defeat.m4a` | Niederlage, Aufgeben | `niederlage` (Medieval: Defeat Theme, RandomMind) | nein |

## Klang tauschen

1. Neue Quelle auf OpenGameArt suchen. Die Lizenz steht im Feld „License(s)“ der Seite;
   der Suchfilter allein liefert auch CC-BY-SA (01.11.2026 gesehen). Nur CC0 nehmen.
2. Eintrag in `klaenge.json` ändern (Quelle mit SHA-256 des Downloads, Pfad im Archiv).
3. `python3 tools/ton/ton_bauen.py <datei>`, Ergebnis anhören, diese Seite nachziehen.
4. `python3 tools/ton/ton_pruefen.py` muss grün sein (läuft auch in der CI).
