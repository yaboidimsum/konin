
1. Konin/Models/Chapter.swift
Add ChapterVisuals to centralize per-chapter config:
- background image name
- sky/ground/rail colors
- weather type (.none, .rain, .fog, .ash)
- environment object pools
- flags for searchlights / horizon fire glow
2. Konin/SpriteKit/GameScene.swift
- Rails: three-layer track (ballast → sleeper → rail) with joints and perspective scaling.
- Backgrounds: load Polish bg-<chapter>.png; remove Soviet imagery.
- Chapter styling: muted palette per chapter.
- Station: fully rebuilt station with building, platform, benches, lamps, clock, “ŻÓŁKIEW” sign, passenger silhouettes.
- Weather/overlays: rain in Koźmin, smoke/ash + searchlights in Jarocin, tunnel brick walls + headlight dust, Konin floating particles, Żółkiew mist.
- Tunnel → Konin transition: white explosion flash + shake, then fade into dream.
3. Konin/SpriteKit/EnvironmentNode.swift
- Replace colored-rectangle builders with texture-based pixel-art sprites.
- Add new object types and richer chapter pools.
- Add shadows and random variation (flip, tint, slight rotation).
- Remove blocky vector look.
4. Konin/SpriteKit/HazardManager.swift (minor)
- Ensure mines read clearly against new ballast/ground.
- Optional: add broken-rail hazard variant for visual variety.
Per-Chapter Visual Identity
Chapter    Mood    Key Visuals
Krotoszyn    Last peaceful morning    Birches, Polish cottages, haystacks, horse carts, church spire, telegraph poles.
Koźmin    Storm front    Rain, fog, broken poles, damaged cottages, bare trees, churned mud.
Jarocin    War zone    Craters, barbed wire, sandbags, wrecked tanks, smoke columns, searchlights, AA fire.
Tunnel    Into darkness    Brick walls, support beams, headlight beam, dust particles, water reflections, ends with explosion flash.
Konin    Unreal afterlife    Muted golden haze, floating particles, three rails merging to one, soft clouds.
Żółkiew    Final arrival    Misty Polish station, brick building, platform details, passenger silhouettes, train slows to stop.
Color Palette (Muted/Drab)
Chapter    Sky    Ground
Krotoszyn    #7a8a99 → #c4b8a3    #4a5238
Koźmin    #4a4f52 → #6e7068    #3a3834
Jarocin    #524a45 → #7a5a45    #4a4238
Tunnel    #0a0a0a    #151515
Konin    #9a9688 → #b8a88a    #6e7a5a
Żółkiew    #b8b8b8 → #d8d4c8    #8a8a82
Implementation Order
1. Generate placeholder PNG assets.
2. Update Chapter.swift with visual metadata.
3. Refactor rails and track bed in GameScene.swift.
4. Replace backgrounds and chapter styling.
5. Rewrite EnvironmentNode.swift with texture-based objects.
6. Revamp final station.
7. Add weather/atmosphere effects.
8. Build and playtest every chapter.
Ready to proceed? Say “go” and I’ll start with asset creation and then move through the code changes.

Go
