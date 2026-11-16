# Gemalte Ringe — Entstehung (A-5, D-171)

Konzept: [a-5-spezialisierungen-und-ringe.md](../../docs/konzepte/a-5-spezialisierungen-und-ringe.md).
Werkzeug wie in [art/spielfeld/ENTSTEHUNG.md](../spielfeld/ENTSTEHUNG.md): FLUX.1-schnell GGUF Q4_0
(Apache 2.0) über stable-diffusion.cpp, 4 Schritte, 512 × 512.

| Name | Seed | Prompt |
|---|---|---|
| `mark_ring` | 23 | mobile strategy game asset, stylized 3D cartoon render, hand-painted textures, bold dark outlines, vibrant saturated colors, warm rim light, highly detailed, a single perfectly round thin ring of polished warm gold with a braided rope pattern and small engraved leaf ornaments, softly glowing golden light, seen from directly above, centered in frame, filling most of the image, on a plain flat black background, nothing inside the ring, no text, no letters |

Danach `ringstreifen.py mark_ring-rohbild.png mark_ring-streifen.png 1536 96`: je Winkel der
hellste Radius (geglättet über 61 von 720 Winkeln), äußere drei Viertel des Bandes abgewickelt,
Alpha aus der Helligkeit, Kontur #22160F, Enden über ein Achtel überblendet. In den Atlas als
@3x 1536 × 96 und @2x 1024 × 64 (PNG mit Alpha). Die App wickelt den Streifen zurück um den Kreis
(`App/Battle/GroundMarks.swift`).

Dateien: `mark_ring-rohbild.png` (wie gemalt), `mark_ring-streifen.png` (abgewickelt).

**Verworfen:** Seed 11 malte den Ring schräg von der Seite (Ellipse mit Innenwand); abgewickelt
wäre der Streifen auf einer Seite doppelt so breit gewesen.
