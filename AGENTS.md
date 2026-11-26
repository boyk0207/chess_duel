# Chess Duel – Voxel Snakes & Lizards: төслийн дүрэм

## Хамтын ажиллагаа

- Хэрэглэгчтэй Монгол хэлээр харилц; латин үсгээр бичсэн Монгол хүсэлтийг мөн ойлгож ажилла.
- Шинэ санааны хэрэгжих боломжийг одоогийн системтэй тулгаж судалж, asset/animation/mechanic эвдэхгүйгээр хөгжүүл. Алдааны шалтгааныг тогтоож зас; бодит тестийн үр дүнг тэмдэглэ.
- `AGENTS.md`, `DEVELOPMENT_LOG.md`, `ROADMAP.md`-д шаардлага, хийсэн өөрчлөлт, тест, үлдсэн ажлыг тогтмол шинэчил.
- Хэрэглэгчийн зөвшөөрөлгүйгээр хөгжүүлэлтийн дараагийн phase руу шилжихгүй. Хэрэглэгч 2026-11-26-нд Phase 3-ын сонсголыг "бүгд OK" гэж батлаад Phase 4-ийг эхлүүлэхийг зөвшөөрсөн. Одоогийн phase: **Phase 4 — Chess Board Overhaul**.
- Хэрэглэгчийн 2026-11-26-ны сүүлчийн шийдвэр: **тусдаа Classic Chess горим, цаг хэрэггүй**. Нүүдлийн хууль ёсны дүрэм, check/checkmate, рокировка, en passant-г үндсэн Chess Duel хөлөгт шингээ. Capture → тулаан, Warlord promotion, довтлогч тулаанд ялагдвал дүр нь хасагдах урсгалыг хадгал. Өгсөн `LawsOfChess.pdf` нь 2009 оны дүрэм; Chess Duel-ийн тулааны үр дүн FIDE-ийн шууд идэлтээс ялгаатай. `docs/CHESS_DUEL_RULES.md`-ийг хар.
- Хэрэглэгчийн шинэ зорилго: эцсийн тоглоомд 2.5D duel хэрэгжүүлэлтийг бүрэн хасаж, 3D тулаанд шилжих. Одоогоор `Duel3D` Floating Island-ийн AI болон LAN PvP-д, бусад stage ба local Human vs Human `Duel`-д тулгуурлаж байгаа тул 3D орлуулалт ба regression баталгаажихаас өмнө `scripts/duel.gd`-ийг устгахгүй. Шилжилтийн дараалал `docs/3D_ONLY_MIGRATION.md`-д бий. Хэрэглэгч 2026-11-25-нд хоёр компьютерийн LAN, тоглоомын Host дотроо server-ээ автоматаар асаах prototype-ийг тусгайлан зөвшөөрсөн. Энэ нь Phase 11-ийг бүхэлд нь дуусгах, cloud server эхлүүлэх, 2.5D-г устгах зөвшөөрөл биш.
- Хэрэглэгч 2026-11-26-нд LAN-ийн хоёр компьютер хооронд capture тулаан болон PvP-г ажиллуулахыг тусгайлан хүссэн. Host authority-тай LAN PvP код нэмсэн: stage 0-д 3D, бусад stage-д одоогийн 2.5D дуэль. Нүүдэл, HP/position, ялалт, promotion хоёр тусдаа Godot process-т синхрон болохыг автомат тестэлсэн. Энэ нь Phase 4-өөс Phase 11 рүү албан ёсоор шилжсэн гэсэн үг биш; хоёр өөр компьютерийн гар QA, latency polish, reconnect, интернет matchmaking үлдсэн. `docs/LAN_TEST.md`-ийг хар.
- `ROADMAP.md`-ийг хэрэглэгчийн хүссэн `хийсэн/нийт` ба `- [x]` / `- [ ]` checklist хэлбэрээр хөтөл. Баталгаажсан код/asset ба автомат тесттэй ажлыг л чагтал; бодит тоглолт, speaker, хоёр компьютерийн QA-г тусад нь тэмдэглэ. Баталгаагүй өмнөх тэмдэглэгээг шууд хуулж болохгүй.

## Хөгжүүлэлтийн дараалал

1. Core Game System
2. Combat System & Polish
3. Sound Design — хэрэглэгчийн сонсголын баталгаагаар хаасан
4. Chess Board Overhaul — одоогийн phase
5. Hell Gate
6. Frozen Peak
7. Dark Desert
8. Sanctuary
9. Advanced AI
10. Game Balance
11. Online Multiplayer
12. UI & Player Experience
13. Optimization
14. Testing & Bug Fixing
15. Steam & itch.io Release

Network compatibility-г эртнээс тооц; хэрэглэгч LAN PvP-г тусгайлан зөвшөөрсөн. Cloud/internet multiplayer болон албан Phase 11 шилжилт тусдаа зөвшөөрөлтэй.

## Ажиллах хүрээ

- Godot 4.7 төсөл; 2026-11-25-нд 4.7.2 дээр шалгасан. Зорилтот OS Ubuntu 24.04 LTS, платформ Steam ба itch.io; export хараахан баталгаажаагүй.
- `project.godot` entry point. F5 зөвхөн `scenes/main.tscn`-ийг нээнэ. F6-д `scenes/tests/`-ийн хэрэгтэй scene-ийг нээгээд ажиллуул.
- Зөвхөн энэ project хавтас дотор ажилла. 2026-11-26-нд энэ хавтсыг тусдаа Git repository болгож, `main`-ийг `github.com/boyk0207/chess_duel`-д push хийсэн; гаднах `/home/buyna` Git root-д commit хийхгүй. Өөрчлөлтийн өмнө Git checkpoint эсвэл `backups/`-д snapshot ав. `.gitignore` нь `backups/`, `.godot/`, `.audit_runtime/`-ийг хасна; эх код, scene, rig, audio, asset, лиценз/credit, баримт бичгийг commit-д хадгал.
- 7 rig, 57 bone, 140 animation, animation нэр, asset, map, mechanic-уудыг хадгал. Шаардлагагүй файл устгахгүй. Үндсэн код засахаас өмнө ажлын хүрээ ба буцах хувилбарыг тогтоо.

## Зураглал

- `scripts/main.gd`: menu, stage, chess board, duel launch. `scenes/board_visual.tscn` ба `scripts/board_visual.gd`: board дүрслэл.
- Phase 4 board: `board_visual.gd` нь 3D kingdom frame, хоёр талын crest, selected/legal/capture marker, сүүлийн нүүдлийн persistent тэмдэглэгээ үүсгэнэ. Үндсэн Chess Duel-д check-ийн нэг, checkmate-ийн хоёр анхааруулах хүрээ бий. `main.gd`-д хоёр талын fill light, шинэ camera offset бий. Capture үед `scenes/capture_intro.tscn`-ийн 2.1 сек шилжилт: 7×7 ordered хослолд дүрийн онцлогт тохирсон strike/reaction/counter/guard, Walk→Idle; board/HP үр дүнг өөрчлөхгүй. `scenes/tests/capture_intro_preview.tscn`-ийг F6-аар нээж 49 хувилбарыг үз; `scripts/tests/capture_intro_matrix_smoke.gd`-г шалга. `scripts/promotion_picker.gd` нь N/B/R/Q/W сонгоно. LAN capture ба promotion Host authority-тай дамжина. `scripts/tests/board_overhaul_smoke.gd`, `chess_main_smoke.gd`, `docs/PHASE4_BOARD_QA.md`-г хар.
- `scripts/chess_rules.gd`: үндсэн Chess Duel-ийн хууль ёсны нүүдэл, check/checkmate, рокировка, en passant, Warlord promotion ба тулаанд довтлогч ялагдах үеийн хувилбар дүрэм. Үндсэн горимд clock UI байхгүй. `scripts/tests/chess_rules_smoke.gd` нь 20/400/8902 perft болон тусгай дүрмийг шалгана. LAN-д зөвхөн capture-гүй, promotion-гүй нүүдлийн prototype бий.
- `scenes/board_environment.tscn` ба `scripts/board_environment.gd`: таван stage-д хөлгийн гадуур тус бүр арван procedural арал, stage-д тохирсон архитектур/байгалийн элемент. Floating Island-д импортын nature/town props, бусад дөрөвт original procedural props бий. Энэ нь board-ийн чимэглэл бөгөөд Hell Gate зэрэг map hazard механик биш. `scripts/tests/board_environment_smoke.gd` нь хүрээ, stage ялгаа ба камерын frustum-ийг шалгана.
- Хэрэглэгч 2026-11-26-нд таван map-ийг нэг нэгээр нь засахаар шийдэж, эхлээд Floating Island-д өгсөн хоёр ZIP-ээс asset хэрэглэхийг хүссэн. `assets/arena/floating_island/nature/`-ийн FBX+gradient, `issum/Main_Pallete.png`-ийг `scripts/floating_asset_library.gd`-ээр board stage 0 ба `scripts/floating_visuals.gd`-ийн 3D duel backdrop-д чимэглэлээр хэрэглэнэ. Issum `.blend`-ийг Blender байхгүй тул импортлоогүй. Гаднын asset-ийн author, CC attribution ба release шалгах зүйл `docs/FLOATING_ISLAND_ASSETS.md`-д бий; credit-ийг хадгал. Шинэ props-д collision нэмэхгүй, өмнөх arena hazard/animation-г хадгал. `scripts/tests/floating_asset_import_smoke.gd`-г ажиллуул. Hell Gate зэрэг дараагийн map-ийн asset pass-ийг хэрэглэгч зөвшөөрөх хүртэл эхлүүлэхгүй.
- `scripts/data.gd`: P/N/B/R/Q/K/W дүр, stat, 5 stage theme. `scripts/duel_3d.gd`: Floating Island 3D combat, bridge, tornado/wind, lightning, shard, moving platform, hit stop, combo, dodge, counter, trail, victory camera. `scripts/duel.gd`: өөр duel хэрэгжүүлэлт.
- `scripts/rig_factory.gd`, `assets/rigs/manifest.json`: skeletal rigs. `scripts/network/lan_host.gd` нь Host тоглоомын process-д TCP/WebSocket listener (0.0.0.0:8080) асаана; `multiplayer.gd` ба `lobby.gd` нь Host IP + 6 тэмдэгт кодоор Join, Ready/Start, Host map сонголт, chess нүүдэл, capture, promotion, duel input/state/result дамжуулна. Host board нь нүүдлийн зөв эсэхийг шалгаж, Host-ийн duel scene damage/HP/hazard/ялагчийг шийднэ. Join нь snapshot replica. 2026-11-26-нд хэрэглэгчийн бодит LAN туршилтаар 3D тулаанд нурсан арлын freed-node crash, Join талд саатал/үсрэлт илэрсэн. Crash guard, 30 Hz snapshot, snapshot coalescing, Join-ийн өөрийн хөдөлгөөний prediction ба нөгөө дүрийн interpolation нэмсэн; хоёр компьютер дээр давтан баталгаажуулах шаардлагатай. Reconnect, интернэт matchmaking байхгүй. `docs/LAN_TEST.md`-д заавар бий.
- 2026-11-26-нд LAN Join-д 20 секундын connection/room-state timeout, countdown, BACK/CANCEL цуцлалт ба retry нэмсэн. Хариу ирээгүй үед UI үүрд "Joining room..." дээр үлдэхгүй. `scripts/tests/lan_lobby_smoke.gd` timeout/cancel, wrong-code cleanup болон энгийн урсгалыг шалгана. Бодит удаан Wi-Fi-ийн latency/packet-loss QA тусдаа үлдэнэ.
- 2026-11-26-нд Floating Island LAN PvP-ийн Power Shard pickup-ийг хоёр дүр зэрэг ойр байх үед хамгийн ойр амьд дүрт оноодог болгосон. Host-ийн popup эзэн/төрөл/хугацааг snapshot-д оруулж, Join дээр цагаан=0, хар=1 ижил индексийн дүрийн толгой дээр харуулна; давтагдсан state popup-ийг дахин эхлүүлэхгүй. `lan_duel_scene_smoke.gd`, `lan_pvp_two_process_smoke.gd` stage 0-г хар. Хоёр бодит компьютерийн харагдах QA үлдсэн.
- 2026-11-26-нд Join 3D тулааны HUD-д render FPS, секундэд хэрэглэсэн snapshot, сүүлийн snapshot ирснээс хойших хугацааг нэмсэн. 30 Hz Host snapshot нь дэлгэцийн FPS биш; snapshot-ийн нас нь RTT биш. Хоёр компьютерт хурдан чиглэл солих тулаанд хэмжиж байж latency-г тааруул.
- `scripts/audio_manager.gd` нь `Sound` autoload; `ChessNetwork` мөн autoload. Music, SFX, UI, Ambience bus нь Master руу холбогдоно. Menu click ба board select UI bus-д, board move ба combat cue SFX bus-д орно. Mixer `user://audio_settings.cfg`-д хадгалагдана. Audio-ийн provenance, лицензийг `docs/AUDIO_SOURCES.md`-ээс хар.
- `scripts/control_bindings.gd` нь `Controls` autoload. F5 цэсний **SETTINGS → Controls** табаас 3D arena, 2.5D Player 1/2-ийн 22 keyboard/mouse binding-ийг сольж, `user://controls.cfg`-д хадгална. Ижил тоглох горимд key давхцвал хоёр action-ийн товч солигдоно; Esc нь rebind cancel/суллахад зориулагдсан. Өмнөх үндсэн товчнууд default хэвээр. `scripts/tests/controls_bomb_smoke.gd` нь хадгалалт, swap, reset болон bomb радиусыг шалгана.
- Bomber-ийн 2.5D ба 3D Special дэлбэрэлтийн damage болон харагдах хүрээ `BOMB_RADIUS = 2.4` нэгжээр таарна. Радиусын дотор/гадна damage-г автомат шалгасан; график session-д ring ба particle-ийн харагдах байдлыг тусад нь шалга.
- Идэвхтэй 6 BGM нь `assets/audio/generated/*.ogg`; эх PCM WAV-уудыг хадгалсан. Floating Island-д `island_battle` ба `island_battle_intense`, бусад stage-д ерөнхий `battle` ба `battle_intense` ашиглана. OGG-ийн loop-ийг `Sound` runtime дээр асаадаг. Менюгийн хоёр take нэг 236 секундын OGG-д crossfade-тай; тусдаа track playlist биш.
- `tools/generate_phase3_sound.py` нь зөвхөн Floating Island-ийн хоёр original BGM эх WAV ба P/N/B/R/Q/K/W-ийн долоон weapon swing WAV-г үүсгэнэ. Богино SFX WAV, BGM OGG зарчмыг баримтал; бусад audio-г санамсаргүй дахин үүсгэхгүй.
- `tools/generate_character_sfx.py` нь project-д хадгалсан Kenney/OpenGameArt CC0 OGG-үүдээс GStreamer-ээр decode хийж, синтез давхарга нэмэн P/N/B/R/Q/K/W-ийн `attack_*.wav` (7), N/B/R/Q/K/W-ийн `special_*.wav`, `hit_*.wav`, `special_impact_*.wav` (18) үүсгэнэ. Croc Soldier (P)-ийн хуучин Special/Hit cue-г хадгал. Өмнөх эх OGG, лиценз, fallback mapping-ийг устгахгүй. Эх сурвалж `docs/AUDIO_SOURCES.md`-д бий.
- `assets/arena/`, `assets/rigs/`, `assets/audio/`, `addons/pyrolux_fx/`, `shaders/`, `tools/`, `docs/`-ийг хадгал.

## Тест ба audio

Өөрчлөлтөд хамаарах Godot 4.7 headless import, main, sound test, audio/main audio/combat smoke-ийг ажиллуул. Exit code **болон** log дахь warning/error-ийг тэмдэглэ. Жишээ:

```bash
godot --headless --path . --editor --import
godot --headless --path . --script res://scripts/tests/audio_smoke.gd
godot --headless --path . --script res://scripts/tests/main_audio_smoke.gd
godot --headless --path . --script res://scripts/tests/sound_scene_smoke.gd
godot --headless --path . --script res://scripts/tests/stage_audio_smoke.gd
godot --headless --path . --script res://scripts/tests/combat_smoke.gd
godot --headless --path . --script res://scripts/tests/controls_bomb_smoke.gd
godot --headless --path . --script res://scripts/tests/board_overhaul_smoke.gd
godot --headless --path . --script res://scripts/tests/chess_rules_smoke.gd
godot --headless --path . --script res://scripts/tests/chess_main_smoke.gd
godot --headless --path . --script res://scripts/tests/board_environment_smoke.gd
godot --headless --path . --script res://scripts/tests/floating_asset_import_smoke.gd
godot --headless --path . --script res://scripts/tests/lan_lobby_smoke.gd
godot --headless --path . --script res://scripts/tests/lan_board_smoke.gd
godot --headless --path . --script res://scripts/tests/lan_duel_scene_smoke.gd
godot --headless --path . --script res://scripts/tests/lan_pvp_two_process_smoke.gd -- host 0 # тусдаа process-д -- guest 0; stage 1..4 мөн адил
godot --headless --path . --script res://scripts/tests/lan_two_process_smoke.gd -- host # тусдаа terminal-д -- guest
godot --headless --path . --quit-after 120 res://scenes/main.tscn
godot --headless --path . --quit-after 120 res://scenes/tests/sound_test.tscn
```

Headless тест speaker output, хоёр menu аялгууны шилжилт, бүтэн loop, input-driven combat, online end-to-end-ийг батлахгүй. Тест хийгээгүй бол амжилттай гэж тайлагнахгүй. BGM-д OGG, богино SFX-д WAV ашиглахыг зорь; формат солихдоо playback, loop, лицензийг шалга. `tools/generate_audio.py` болон `tools/polish_audio.py`-ийг санамсаргүй ажиллуулахгүй: menu playlist солигдож болзошгүй.

LAN smoke тест TCP socket нээнэ; sandbox дотор `ERR_CANT_CREATE` гарч болно. Network эрхтэй орчинд localhost-оор ажиллуулж, дараа нь `docs/LAN_TEST.md`-ийн дагуу хоёр тусдаа компьютер дээр гар QA хий. Loopback нь хоёр компьютерийн туршилтыг орлохгүй.

Phase 3-ын гар сонсголыг хэрэглэгч 2026-11-26-нд "бүгд OK" гэж баталсан; `docs/PHASE3_AUDIO_QA.md`-д хэрэглэгчийн баталгааг тусад нь бүртгэсэн. Энэ нь агент өөрөө төхөөрөмж дээр сонссон гэсэн үг биш. Menu-ийн хоёр Stable Audio take-ийн эрхтэй гэж хэрэглэгч мэдэгдсэн; тухайн output-ийн баримт release материалд хавсаргагдаагүй хэвээр.

N/B/R/Q/K/W-ийн шинэ Special ба Hit cue-үүдийг F6 sound test-д тус бүр сонсож, чанга/сул эсэх, дүрийн чадварт тохирч байгаа эсэх, Croc Soldier-ийн дуу хэвээр эсэхийг тэмдэглэ. Headless resource test нь сонсголын үнэлгээ биш.

`attack` cue одоо зөвхөн байнд хүрсэн энгийн цохилт дээр дуугарна; swing нь довтолгоо эхлэхэд хэвээр. N/B/R/Q/K/W-ийн `special_impact` нь чадвар байнд/орчинд хүрэхэд дуугарна; Bomber-ийн bomb газар хүрээд дэлбэрэхэд ч дуугарах ёстой. F6-д зургаан дүрийн Special Impact товч бий.

Godot headless process-ийг audio тоглуулж байх үед `--quit-after`-аар шууд хаахад shutdown resource warning гарч болно. `sound_scene_smoke.gd` болон `main_audio_smoke.gd` нь player-ийг зогсоож, audio thread сулрахыг хүлээдэг; warning/error-ийг нууж тайлагнахгүй.

Одоогийн бодит төлөв `DEVELOPMENT_LOG.md`, дараагийн ажил `ROADMAP.md`-д байна.
