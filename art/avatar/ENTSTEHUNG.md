# Avatar-Porträts — Entstehung

Für die Avatarwahl (0.11.0, [r-5-avatar.md](../../docs/konzepte/r-5-avatar.md)): drei Zwerge,
drei Elfen. Die App zeigt sie rund, `scaledToFill`, 40 bis 64 pt. Werkzeug wie in
[art/spielfeld/ENTSTEHUNG.md](../spielfeld/ENTSTEHUNG.md): FLUX.1-schnell GGUF Q4_0
(Apache 2.0) über stable-diffusion.cpp, 4 Schritte, 512 × 512, ohne Freistellen.

Dateien: `<name>-rohbild.png` (wie gemalt). Im Katalog (`App/Assets.xcassets/Avatar/`) liegt
ein quadratischer Ausschnitt mit dem Gesicht in der Mitte, auf 512 × 512 gebracht, damit der
Kreis Augen und Mund nicht anschneidet.

| Name | Seed | Prompt |
|---|---|---|
| `portrait_dwarf-1` | 41 | a proud dwarf warrior with a long braided red beard, a horned iron helmet and riveted bronze shoulder armor, mobile strategy game character portrait, stylized 3D cartoon render, hand-painted textures, chunky proportions, bold dark outlines, vibrant saturated colors, warm rim light, light from top left, highly detailed, head and shoulders bust portrait, centered, facing the viewer at a slight three-quarter angle, on a plain flat light grey background, no text, no letters |
| `portrait_dwarf-2` | 41 | a cheerful dwarf blacksmith woman with thick auburn braids, freckles, a leather apron and brass goggles on her forehead, mobile strategy game character portrait, stylized 3D cartoon render, hand-painted textures, chunky proportions, bold dark outlines, vibrant saturated colors, warm rim light, light from top left, highly detailed, head and shoulders bust portrait, centered, facing the viewer at a slight three-quarter angle, on a plain flat light grey background, no text, no letters |
| `portrait_dwarf-3` | 41 | a wise old dwarf runekeeper with a long white beard bound with gold rings, a fur hood and glowing blue runes on his collar, mobile strategy game character portrait, stylized 3D cartoon render, hand-painted textures, chunky proportions, bold dark outlines, vibrant saturated colors, warm rim light, light from top left, highly detailed, head and shoulders bust portrait, centered, facing the viewer at a slight three-quarter angle, on a plain flat light grey background, no text, no letters |
| `portrait_elf-1` | 41 | a graceful elf ranger woman with long silver hair, pointed ears, a green hooded cloak and a leaf-shaped silver brooch, mobile strategy game character portrait, stylized 3D cartoon render, hand-painted textures, chunky proportions, bold dark outlines, vibrant saturated colors, warm rim light, light from top left, highly detailed, head and shoulders bust portrait, centered, facing the viewer at a slight three-quarter angle, on a plain flat light grey background, no text, no letters |
| `portrait_elf-2` | 41 | a young elf archer man with braided golden hair, pointed ears, a forest green tunic and a carved wooden bow over his shoulder, mobile strategy game character portrait, stylized 3D cartoon render, hand-painted textures, chunky proportions, bold dark outlines, vibrant saturated colors, warm rim light, light from top left, highly detailed, head and shoulders bust portrait, centered, facing the viewer at a slight three-quarter angle, on a plain flat light grey background, no text, no letters |
| `portrait_elf-3` | 41 | a mystical elf moon priestess with dark blue hair, pointed ears, a silver crescent moon circlet and softly glowing eyes, mobile strategy game character portrait, stylized 3D cartoon render, hand-painted textures, chunky proportions, bold dark outlines, vibrant saturated colors, warm rim light, light from top left, highly detailed, head and shoulders bust portrait, centered, facing the viewer at a slight three-quarter angle, on a plain flat light grey background, no text, no letters |
