# Phase 3 audio sources and licenses

## Kenney Impact Sounds 1.0

- Creator/distributor: Kenney.
- Source: https://kenney.nl/assets/impact-sounds
- Download: https://kenney.nl/media/pages/assets/impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip
- License: Creative Commons Zero 1.0 (CC0), including commercial use; original text is at `assets/audio/kenney/License.txt`.
- Files: the selected `footstep_*.ogg` and `impact*.ogg` files in `assets/audio/kenney/`. These form seven distinct character attack, special, footstep, and hit sets, plus wood, plank, and stone destruction cues.

## Original procedural audio

- Source: `tools/generate_audio.py` in this project, written for Phase 3.
- Files: `assets/audio/generated/*.wav`.
- License: original project work; no external samples. The menu, board, and two battle layers are composed by code. Wind, waterfall, and thunder are synthesized noise and tones.

The game routes music to `Music`, spatial and gameplay effects to `SFX`, menu clicks and board selection to `UI`, and environmental loops to `Ambience`. All four buses send to `Master`; mixer values are saved to `user://audio_settings.cfg`.

## Phase 3 UI volume revision (2026-11-25)

The `UI` bus now has its own persisted slider in the main audio settings and the F6 sound test scene. Existing `ui_click` and `board_select` cues use that bus; board movement and combat effects stay on `SFX`. No audio media or licenses changed in this revision.

## OpenGameArt 80 CC0 RPG SFX

- Creator: rubberduck. Source: https://opengameart.org/content/80-cc0-rpg-sfx
- Download: https://opengameart.org/sites/default/files/80-CC0-RPG-SFX_0.zip
- License: CC0 1.0, including commercial use. License text is at `assets/audio/opengameart_rpg/LICENSE.txt`.
- Selected OGG files in `assets/audio/opengameart_rpg/` supply character attack, special, and hit cues. Character footsteps and scenery impacts continue to use Kenney sounds.

## Sound fix / polish revision

`tools/polish_audio.py` generates new original 44.1 kHz stereo menu, board and battle music (the two battle tracks have equal duration), and original swing, dodge, cast, magic-impact, shard, victory and defeat cues. Some spatial cues are mono by design. Existing Kenney/OpenGameArt license files remain unchanged. No new external media was added. Old audio is retained in `backups/pre_sound_fix.tar.gz`.

## Menu playlist revision

`assets/audio/generated/menu.wav` now contains user-provided Stable Audio files `take-4-take-4.wav` and `take-3-take-3.wav` in that order, with two-second equal-power crossfades at both transitions, including the loop boundary. The older procedural menu is backed up in `backups/pre_menu_playlist.tar.gz`. Commercial usage rights for the supplied takes have not been independently verified; confirm before release. Do not regenerate the procedural menu with `tools/generate_audio.py` or `tools/polish_audio.py` unless intentionally replacing this playlist. Other audio and scripts are unchanged.

## Phase 3 BGM OGG revision (2026-11-25)

The four active BGM streams (`menu`, `board`, `battle`, `battle_intense`) are Vorbis OGG files at 44.1 kHz stereo, encoded from the retained PCM WAV originals using GStreamer's `vorbisenc quality=0.7`. `scripts/audio_manager.gd` loads the OGG files and enables looping at runtime. The menu OGG preserves the existing combined two-take playlist and its crossfades; the individual supplied takes were not modified. Total size of the four active streams changed from 50,662,256 bytes (WAV) to 6,542,214 bytes (OGG), an 87.09% reduction in active BGM asset size. The WAV originals remain in the project, so this does not itself establish a smaller exported game. New backup: `backups/pre_phase3_bgm_ogg_2026-11-25.tar.gz`. The supplied takes' commercial rights remain unverified.

## Floating Island and weapon audio revision (2026-11-25)

`tools/generate_phase3_sound.py` deterministically synthesizes `island_battle.wav`, `island_battle_intense.wav`, and seven `weapon_swing_<kind>.wav` files using only Python standard-library oscillators and seeded noise; no external audio samples were used. The two 32-second stereo BGM sources were encoded as `island_battle.ogg` and `island_battle_intense.ogg` with GStreamer Vorbis quality 0.7. The seven short mono weapon swings remain WAV. Existing music and licensed attack/Special cues were retained. Source backup: `backups/pre_phase3_completion_2026-11-25.tar.gz`.

The user confirmed that they hold commercial-use rights for the two Stable Audio menu takes and provided their [Stable Audio workspace](https://stableaudio.com/workspace-next/apps/generate?project=drafts&mode=music). The [current Stable Audio FAQ](https://stableaudio.com/) says plans include commercial licensing. That workspace URL does not identify the two specific outputs or their generation dates, so a per-track export/license record should still be kept with release materials. No license document or account credentials were copied into this project.

## Six character Special/Hit pairs (2026-11-25)

Browser review identified [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds), [Kenney Sci-fi Sounds](https://kenney.nl/assets/sci-fi-sounds), [OpenGameArt 80 CC0 RPG SFX](https://opengameart.org/content/80-cc0-rpg-sfx), and [OpenGameArt 50 CC0 Sci-Fi SFX](https://opengameart.org/content/50-cc0-sci-fi-sfx) as potentially useful CC0 sources. This revision **does not include new downloads**: the environment could not resolve the external download host. It uses only already stored Kenney Impact and OpenGameArt RPG OGG files, whose source and license text are recorded above. The Sci-fi packs are research candidates, not project dependencies.

`tools/generate_character_sfx.py` decodes the selected source OGG files to temporary 44.1 kHz mono PCM with GStreamer, layers deterministic synthesized tones, noise and bass, then writes 12 short mono WAV files to `assets/audio/generated/`. The originals and old cue arrays remain in place. Mapping:

| Character | Special | Hit | Main source layer |
| --- | --- | --- | --- |
| Monitor Knight (N) | armour charge | metal impact | Kenney `impactMetal_medium_004`, `impactMetal_heavy_002` |
| Snake Wizard (B) | rising fire cast | glass/magic fracture | OpenGameArt `spell_fire_06`; Kenney `impactGlass_medium_001` |
| Lizard Bomber (R) | fuse and bass explosion | heavy wooden shell | Kenney `impactPunch_heavy_001`, `impactWood_heavy_003` |
| Snake God (Q) | celestial bell/smite | falling divine resonance | Kenney `impactBell_heavy_000`, `impactBell_heavy_003` |
| Snake King (K) | stone quake | mining/stone impact | OpenGameArt `stones_03`; Kenney `impactMining_003` |
| Warlord (W) | war bass and iron | heavy plate impact | Kenney `impactMetal_heavy_002`, `impactPlate_heavy_001` |

Croc Soldier (P) keeps the original `spell_01.ogg` Special and `item_wood_01.ogg` Hit. Godot routes both flat F6 test playback and spatial combat playback through the same character mapping. The new WAV files are derived from CC0 assets and original project synthesis; no new license category was added. Backup: `backups/pre_phase3_character_sfx_2026-11-25.tar.gz`.

## Character contact attacks and Special impacts (2026-11-25)

After `backups/pre_phase3_attack_impact_2026-11-25.tar.gz`, the same generator gained seven `attack_<kind>.wav` files and six `special_impact_<kind>.wav` files. All are short mono WAVs derived from the **same already stored CC0 packs** plus deterministic synthesis; no external downloads or new license category. Existing source OGGs, the older cue arrays, Croc Soldier's Special/Hit files, and combat mechanics remain.

| Character | Contact Attack | Special Impact | Source layers |
| --- | --- | --- | --- |
| Croc Soldier (P) | spear stab | original generic spear impact | OpenGameArt `blade_01` |
| Monitor Knight (N) | fast armoured strike | charging metal impact | OpenGameArt `metal_02`; Kenney `impactMetal_heavy_002` |
| Snake Wizard (B) | light magical strike | crackling fire impact | OpenGameArt `spell_02`, `spell_fire_07` |
| Lizard Bomber (R) | heavy blunt collision | bass explosion | Kenney `impactPunch_heavy_001` |
| Snake God (Q) | bright bell strike | divine resonance | Kenney `impactBell_heavy_000/003` |
| Snake King (K) | royal metal strike | stone quake | OpenGameArt `metal_03`, `stones_04` |
| Warlord (W) | heavy plate/hammer strike | iron war impact | Kenney `impactPlate_heavy_001` |

`attack` is triggered on contact in both duel scripts, while the existing `weapon_swing_*.wav` plays at wind-up. `special` stays at cast/start; `special_impact` plays on charge contact, bomb detonation, spell/projectile impact, or smite strike. For hit projectiles, the impact cue is played once rather than repeated inside damage handling. F6 exposes a separate Special Impact button for the six changed characters. This routing still needs speaker and input-driven QA.
