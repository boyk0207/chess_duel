# Chess Duel – Voxel Snakes & Lizards хөгжүүлэлтийн замын зураг

**Одоогийн үе шат: Phase 4 — Chess Board Overhaul.** Хэрэглэгч 2026-11-26-нд Phase 3-ын сонсголыг "бүгд OK" гэж баталж, Phase 4-ийг зөвшөөрсөн. Дараагийн phase руу зөвхөн хэрэглэгчийн зөвшөөрлөөр шилжинэ.

`[x]` = код/asset байгаа, тухайн хэсгийн статик эсвэл автомат шалгалт хийсэн. Энэ тэмдэг **бодит тоглолт, speaker, хоёр компьютерийн QA-г батлахгүй**. `[ ]` = хийгдээгүй эсвэл шаардлагын нэг хэсэг дутуу. `хийсэн/нийт` тоонд зөвхөн `[x]` орно. Эргэлзээтэй ажлыг дууссанд тооцоогүй.

## I. Үндсэн тоглоом ба тулаан

### Phase 1 — Core Game System · 6/6

- [x] Үндсэн Chess Duel-д хууль ёсны P/N/B/R/Q/K нүүдэл, check/checkmate, castling, en passant, N/B/R/Q/W promotion, Warlord-ийн kinglike нүүдэл ба тест бий. Идэлт тулаанаар шийдэгддэг тул FIDE-ийн цэвэр шатар биш; LAN capture/promotion хоёр-process тест PASS.
- [x] 7 төрлийн дүр: Pawn, Knight, Bishop, Rook, Queen, King, Warlord (`scripts/data.gd`, rig manifest).
- [x] Шатрын capture-оос тулаанд шилжих урсгал (`scripts/main.gd`).
- [x] Pawn promotion код ба сонголтын dialog (`scripts/main.gd`).
- [x] Checkmate/stalemate болон тулаанд King ялагдах хоёр төгсгөл; хоёуланг нь тестэлсэн.
- [x] Үндсэн тоглоомын цэс ба local mode сонголт.

### Phase 2 — Combat System & Polish · 8/8

- [x] 7 rig, нийт 57 bone, 140 skeletal animation; manifest, GLB болон combat smoke шалгасан.
- [x] Attack, Heavy Attack, Combo код.
- [x] Block, Perfect Block, Counter код; combat smoke-ийн сонгосон нөхцөл PASS.
- [x] Dodge, Special Attack код.
- [x] Weapon болон Projectile код.
- [x] Hit Stop, Hit Flash, Weapon Trail код.
- [x] Victory Cinematic-ийн camera/animation урсгал.
- [x] Floating Island-ийн үндсэн 3D map, нурдаг гүүр, салхи, аянга, shard, хөдөлгөөнт тавцан. Бүх интерактив хувилбарын гар QA үлдсэн.

### Phase 3 — Sound Design · 11/11 · **ХЭРЭГЛЭГЧИЙН СОНСГОЛЫН БАТАЛГААГААР ХААСАН**

- [x] Main Menu-ийн хоёр хөгжим: хоёр take нэг OGG-д crossfade-тай нийлсэн, 236 секунд; headless playback ба loop PASS. Тусдаа файл ээлжлүүлдэг код биш; сонсголын QA болон track тус бүрийн эрхийн баримтыг project-д хадгалах ажил үлдсэн.
- [x] Chess Board BGM: `board.ogg`, menu/board шилжилт audio smoke-д PASS.
- [x] Floating Island-д зориулсан `island_battle.ogg` ба `island_battle_intense.ogg`: 32 секундийн хоёр original давхарга, stage 0 сонголт, intensity ба loop-ийг headless шалгасан. Сонсголын QA үлдсэн.
- [x] P/N/B/R/Q/K/W-д ялгаатай богино weapon swing ба contact attack WAV: 7+7 тусдаа stream. Swing довтолгоо эхлэхэд, attack байнд хүрэхэд дуугарна; хоёр duel хувилбарт автомат шалгасан. Сонсголын QA үлдсэн.
- [x] Hit, Block, Perfect Block, Counter, Dodge event ба SFX холбоос; N/B/R/Q/K/W-ийн Hit-д 6 ялгаатай богино WAV, Bomber-ийн contact attack-д хүнд мөргөлтийн cue нэмсэн. Croc Soldier-ийн Special/Hit-г хадгалсан. Resource ба combat smoke шалгасан; speaker QA үлдсэн.
- [x] 7 дүрийн Special Attack SFX resource ба event холбоос; N/B/R/Q/K/W-д эхлэх үеийн 6, хүрэх үеийн 6 ялгаатай WAV. Bomber дэлбэрэлт, Wizard гал, King quake зэрэг event-ийг тусад нь холбосон; audio/combat smoke шалгасан, speaker QA үлдсэн.
- [x] Wind, waterfall, thunder зэрэг ambient/event sound холбоос; audio smoke шалгасан.
- [x] Victory & Defeat audio resource ба duel hook.
- [x] Music, SFX, UI, Ambience volume settings: тусдаа bus, slider, хадгалалт ба reset; UI ба SFX-ийн тусгаарлалтыг audio smoke шалгасан. Speaker QA үлдсэн.
- [x] Дөрвөн идэвхтэй BGM-ийг OGG болгосон, эх WAV-уудыг хадгалсан; хэмжээ ба Godot loop шалгасан. Export package-ийн хэмжээ шалгаагүй.
- [x] Sound Test ба бодит тоглолтын QA: headless smoke PASS; хэрэглэгч 2026-11-26-нд өмнө өгсөн сонсголын checklist-ийг "бүгд OK" гэж баталсан. Агент өөрөө speaker дээр сонсоогүй; төхөөрөмж/нарийвчилсан тэмдэглэл ирээгүй. Track тус бүрийн эрхийн баримтыг release материалд хавсаргах ажил тусдаа үлдсэн.

Хэрэглэгчийн тусгай хүсэлтээр Bomber-ийн 2.5D/3D дэлбэрэлтийн damage ба харагдах хүрээг 2.4 нэгж болгож нэгтгэсэн. Радиусын дотор/гаднах автомат тест PASS; бодит дүрслэл ба сонсголын QA үлдсэн. Мөн F5 **SETTINGS → Controls**-д keybind тохиргоог эрт хэрэгжүүлсэн; үүнийг Phase 12 руу албан ёсоор шилжсэн гэж үзэхгүй.

**3D-only чиглэл (хэрэглэгчийн шинэ хүсэлт):** 2.5D дуэлийг эцсийн хувилбараас бүрэн хасна. Одоогоор AI + Floating Island л `Duel3D`; бусад stage ба Human vs Human `Duel` ашигладаг, 3D-ийн хоёр дахь fighter AI-д hardcode хийгдсэн. Тиймээс 3D local бүх горим/stage-ийг орлуулж шалгахаас өмнө `duel.gd`-г устгахгүй. Cloud server энэ шилжилтийн урьдчилсан шаардлага биш. Алхам ба шалгалтын gate: `docs/3D_ONLY_MIGRATION.md`.

## II. Тулааны ертөнц — Battle Maps

**Map 01 — Floating Island:** үндсэн 3D map ба таван арал, нурдаг гүүр, салхи, аянга, Power Shard, хөдөлгөөнт тавцангийн код, өвөрмөц хоёр давхаргат BGM байгаа. Хэрэглэгчийн өгсөн stylized nature FBX-ийн мод/хад/цэцэг, Issum-ийн palette texture-тай жижиг цамхаг board stage 0 ба 3D duel-ийн чимэглэлд нэмсэн; source/credit `docs/FLOATING_ISLAND_ASSETS.md`-д бий. График чанар, FPS, бүх hazard-ийн интерактив QA болон хөгжим/ambience-ийн нарийвчилсан сонсгол хүлээгдэж байна. Одоогоор `Duel3D` зөвхөн AI + Floating Island үед сонгогдоно; бусад stage `Duel` ашигладаг. Хэрэглэгч map-уудыг нэг нэгээр нь шинэчлэх хүсэлттэй; дараагийн map-ийн asset pass эхлээгүй.

### Phase 4 — Chess Board Overhaul · 10/10 · **КОД/АВТОМАТ ШАЛГАЛТ ХИЙСЭН; ГРАФИК QA ҮЛДСЭН**

- [x] Шатрын хөлгийн шинэ 3D frame, trim, crest, corner tower, kingdom terrace; structural smoke PASS, график QA үлдсэн.
- [x] Хоёр талын хаант улсын cyan/red crest, stripe ба fill light; structural smoke PASS.
- [x] Дүр сонгоход багийн өнгөт 3D ring; structural smoke PASS.
- [x] Боломжит сул нүдэнд тусдаа ногоон disc; structural smoke PASS.
- [x] Attack хийх нүдэнд улаан ring; structural smoke PASS.
- [x] Сүүлийн нүүдлийн эхлэл/төгсгөлийн хоёр persistent marker; шинэ тоглолтод арилна, smoke PASS.
- [x] Үндсэн Chess Duel-д check-ийн нэг улаан, checkmate-ийн хоёр анхааруулах хүрээ; rule ба main smoke PASS. King тулаанд ялагдах хувилбар дүрэм хэвээр, график QA үлдсэн.
- [x] Capture дээр 2.1 секундийн board camera close-up, хоёр нүдний highlight, 49 ordered дүрийн хослолд strike/reaction/counter/guard → Walk → Idle arena entrance scene; дараа нь duel ба буцах flow smoke PASS. График QA үлдсэн.
- [x] N/B/R/Q/W таван сонголттой шинэ Pawn promotion overlay; choice/turn smoke PASS. LAN-ийн энгийн болон capture promotion хоёр-process smoke PASS.
- [x] Камерын өндөр/өнцөг, shadow-той sun ба хоёр талын stage-д тохирох fill light; structural smoke PASS, график QA үлдсэн.

**Хэрэглэгчийн сүүлчийн шийдвэр:** Тусдаа Classic Chess болон цагийн UI-г авсан. Өгсөн 2009 оны FIDE PDF-ээс нүүдэл, check/checkmate, рокировка, en passant-ийг үндсэн Chess Duel-д шингээсэн; capture → тулаан ба Warlord хэвээр. Яг хамарсан болон хувилбар дүрмийн зөрүү `docs/CHESS_DUEL_RULES.md`-д бий. Хөлгийн гадна таван stage тус бүрт арван original voxel арлын scene asset нэмсэн; theme ялгаа, хүрээ ба камерын харагдах хэсгийг автомат шалгасан. Бодит график session-д өнгө, scale, хөдөлгөөн ба кадр секундийг шалгах шаардлагатай (`docs/PHASE4_BOARD_QA.md`). Phase 5 эхлээгүй.

### Phase 5 — Hell Gate · 0/6

- [ ] Лаавын урсгал ба hazard.
- [ ] Газраас оргилох гал.
- [ ] Нурдаг чулуун тавцан.
- [ ] Галт бөмбөгийн map hazard.
- [ ] Халууны visual effect.
- [ ] Өвөрмөц soundtrack ба интерактив QA.

### Phase 6 — Frozen Peak · 0/6

- [ ] Хальтирдаг мөсөн талбай.
- [ ] Цасан шуурга.
- [ ] Нурдаг мөсөн гүүр.
- [ ] Дээрээс унах мөс.
- [ ] Харагдах орчны хязгаарлалт.
- [ ] Хүйтэн ambient sound ба интерактив QA.

### Phase 7 — Dark Desert · 0/6

- [ ] Элсэн шуурга.
- [ ] Живдэг элс.
- [ ] Эртний сүмийн урхи.
- [ ] Хөдөлгөөнт чулуун багана.
- [ ] Нууц Power Shard.
- [ ] Цөлийн soundtrack ба интерактив QA.

### Phase 8 — Sanctuary · 0/6

- [ ] Эдгээх бүс.
- [ ] Ид шидийн хамгаалалт.
- [ ] Teleport portal.
- [ ] Хөдөлгөөнт гэрлийн тавцан.
- [ ] Energy boost.
- [ ] Тайван ид шидийн soundtrack ба интерактив QA.

Hell Gate, Frozen Peak, Dark Desert, Sanctuary-ийн **өнгө, гэрэл, board theme** `scripts/data.gd`-д бий. Дээрх map механик нь концепц санал бөгөөд эцсийн дизайн биш.

## III. AI ба тоглоомын баланс

### Phase 9 — Advanced AI · 0/9

- [ ] Easy, Normal, Hard, Expert difficulty.
- [ ] Шатрын нүүдэл тооцоолох ахисан AI (энгийн сонголтын AI байгаа).
- [ ] 3D тулааны ахисан AI (суурь arena AI байгаа).
- [ ] Дайсны довтолгооноос ухамсартай бултах.
- [ ] Block ба Counter-г нөхцөлд нь ашиглах.
- [ ] Special Attack-ийг зөв үед ашиглах.
- [ ] Map-ийн аюулаас тогтвортой зайлсхийх.
- [ ] Дүр тус бүрийн өөр тулааны хэв маяг.
- [ ] AI vs AI автомат тест.

### Phase 10 — Game Balance · 0/9

- [ ] Дүр бүрийн HP тохируулах.
- [ ] Attack damage тохируулах.
- [ ] Attack speed тохируулах.
- [ ] Movement speed тохируулах.
- [ ] Special Attack cooldown тохируулах.
- [ ] Block ба Dodge баланс.
- [ ] Warlord-ийн хүчний баланс.
- [ ] Map hazard damage баланс.
- [ ] Дүр бүрийг бусад бүх дүртэй тоглуулж тестлэх.

Дүрийн зорилтот хэв маяг: Pawn — тэнцвэртэй; Knight — хурдан; Bishop — холын ид шид; Rook — хүнд цохилт; Queen — олон төрлийн довтолгоо; King — хамгаалалт; Warlord — хүчтэй, хөдөлгөөнтэй. Давуу тал бүрд бодит сул тал тогтоох шаардлагатай.

## IV. Online Multiplayer

### Phase 11 — Online Multiplayer · 8/18 · **LAN PvP-г хэрэглэгчийн тусгай хүсэлтээр эрт хэрэгжүүлсэн; албан Phase 4 хэвээр**

- [x] Host / Join Game: Host тоглоом дотроо LAN WebSocket server асаана; Join нь Host IP:8080-д холбогдоно. Loopback ба хоёр тусдаа Godot process smoke PASS, хоёр өөр компьютерийн QA үлдсэн.
- [x] Join хүлээлтийн хамгаалалт: холболт/өрөөний хариунд 20 секундын timeout, харагдах countdown, BACK/CANCEL ба retry; lobby smoke PASS. Бодит удаан Wi-Fi QA үлдсэн.
- [x] Private Room Code: 6 тэмдэгт кодоор Join; буруу кодыг Host татгалзана. Loopback smoke PASS.
- [x] Player Lobby: хоёр client, Ready, Start, Leave урсгал loopback smoke PASS.
- [x] Map Selection sync: Host-ийн сонгосон stage Start мессежээр Join талд хүрч, main scene-д хэрэглэгдсэнийг smoke тестээр шалгасан.
- [ ] Character / Team Selection sync.
- [x] Chess Move Synchronization: Host legal validation, энгийн/capture нүүдэл, en passant, энгийн ба capture promotion, довтлогч/хамгаалагчийн ялалт хоёр process-т PASS. Хоёр өөр компьютерийн QA үлдсэн.
- [x] Combat Synchronization: Join input Host fighter-ийг хөдөлгөж, Host-ийн duel snapshot/үр дүн Join-д хүрснийг stage 0 3D ба stage 1 2.5D хоёр-process smoke баталсан. Stage 0-д 30 Hz snapshot, Join prediction/interpolation ба хуучин state coalescing нэмсэн; хоёр компьютерийн latency QA дутуу.
- [x] Server-authoritative Damage & HP: Host процесс damage/HP/ялагчийг дангаар бодож, Join state replica авна. Scene smoke HP/position, харын attack/block/special PASS; тусдаа төхөөрөмжийн QA үлдсэн.
- [ ] Special Attack Synchronization: Host special-ийг бодож, 3D projectile snapshot дамжуулна; stage 0/1 хоёр-process-т Join Pawn Special cooldown, scene smoke-д Black Rook bomb PASS. Бүх 7 дүрийн хоёр компьютерийн visual/SFX QA дутуу.
- [ ] Map Hazard Synchronization: Floating Island-ийн Host snapshot-д island/bridge, ferry, crystal, lightning, storm төлөв орсон. Бүрэн hazard timeline ба хоёр компьютерийн QA дутуу.
- [ ] Ping ба latency handling: stage 0-д эхний prediction/interpolation нэмсэн; RTT хэмжүүр, packet loss/jitter, хоёр компьютерийн latency QA дутуу.
- [ ] Disconnect & Reconnect.
- [ ] Anti-cheat хамгаалалт.
- [ ] Online Matchmaking.
- [ ] Ranked & Casual Mode.
- [ ] Steam Multiplayer Integration.
- [ ] Хоёр өөр компьютер дээр бодит тест.

Хэрэглэгчийн 2026-11-25-ны хүсэлтээр зөвхөн LAN prototype-ийг эрт хэрэгжүүлсэн. Бүрэн multiplayer-ийн дараагийн ажлууд, cloud hosting нь тусдаа зөвшөөрөл ба 3D-only local parity-ийн дараах ажил. LAN prototype-ийн гар туршилт `docs/LAN_TEST.md`-д бий.

3D-only local тулаан баталгаажсаны дараа localhost/хоёр client-аар network prototype хийж, сервер authoritative damage/HP, chess move, hazard-ийн дүрмийг тогтооно. Cloud hosting ба Steam/itch.io public release нь prototype, хоёр компьютерийн QA, pre-release playtest-ийн дараах алхам; platform-д build upload хийх нь өөрөө тоглолтын сервер ажиллуулахгүй.

## V. UI, Optimization, Testing, Release

### Phase 12 — UI & Player Experience · 1/12 · **PHASE ЭХЛЭЭГҮЙ, ХҮСЭЛТЭЭР НЭГ АЖИЛ ЭРТ ХИЙСЭН**

- [ ] Main Menu шинэ дизайн (одоогийн ажилладаг menu бий).
- [ ] Settings Menu бүрэн болгох (audio ба controls tab бий; бусад UI/UX, гар QA үлдсэн).
- [ ] Pause Menu.
- [ ] HP, Stamina, Special Attack HUD нэгтгэх (duel HUD суурь бий).
- [ ] Character Selection UI.
- [ ] Map Selection UI-г бүрэн болгох (menu stage selector бий).
- [ ] Loading Screen.
- [x] Keyboard / Mouse тохиргоо: 3D arena ба 2.5D P1/P2-ийн 22 action, key/mouse rebind, conflict swap, хадгалалт ба reset; `controls_bomb_smoke.gd` PASS. График/input төхөөрөмжийн гар QA үлдсэн.
- [ ] Controller Support.
- [ ] Tutorial Mode.
- [ ] English ба Монгол хэлний сонголт.
- [ ] Player Profile.

### Phase 13 — Optimization · 1/10

- [x] Зургаан идэвхтэй BGM-ийг OGG болгосон; эх WAV project-д үлдсэн, export size шалгаагүй.
- [ ] Давхардсан asset-уудыг ашиглалттай нь тулгаж шалгах.
- [ ] 3D model ба texture optimization.
- [ ] LOD систем.
- [ ] Particle optimization.
- [ ] RAM ба VRAM хэрэглээ хэмжих.
- [ ] Low / Medium / High график тохиргоо.
- [ ] Target hardware дээр тогтвортой 60 FPS шалгах.
- [ ] Loading time багасгах.
- [ ] Windows ба Linux export (одоогийн баталгаажсан орчин Ubuntu; Windows дэмжлэгийг тусад нь шийднэ).

### Phase 14 — Testing & Bug Fixing · 0/10

- [ ] Бүх дүрийн animation-ийг интерактив шалгах (140 clip-ийн автомат smoke PASS).
- [ ] Бүх дүрийн тулааны механикийг гар аргаар шалгах.
- [ ] Бүх map-ийн collision шалгах.
- [ ] Chess rules бүрэн шалгах.
- [ ] Audio ба volume-ийг speaker дээр шалгах (headless smoke PASS).
- [ ] Multiplayer stress test.
- [ ] Удаан хугацааны тоглолтын тест.
- [ ] Settings save/load-ийг session хооронд шалгах.
- [ ] Найзуудаар тоглуулж feedback авах.
- [ ] Beta хувилбар гаргах.

### Phase 15 — Steam & itch.io Release · 0/13

- [ ] Тоглоомын эцсийн нэр батлах.
- [ ] Game Logo.
- [ ] Steam Capsule Artwork.
- [ ] Game Trailer.
- [ ] Gameplay Screenshot.
- [ ] Store Description.
- [ ] Asset ба audio лиценз шалгах; menu-ийн хоёр take-д commercial эрхтэй гэж хэрэглэгч мэдэгдсэн, тухайн output-ийн баримтыг project/release материалд хавсаргах ажил үлдсэн.
- [ ] itch.io Demo Release.
- [ ] Steamworks тохируулах.
- [ ] Steam Store Page.
- [ ] Steam Demo.
- [ ] Full Release.
- [ ] Update ба Patch систем.

## Одоогийн дараагийн алхам

2026-11-26: Төслийн 602 source/asset/doc файлын анхны Git commit `main` branch-д `boyk0207/chess_duel` руу push хийгдсэн. `backups/`, `.godot/`, `.audit_runtime/` нь локал хэвээр; энэ нь хөгжүүлэлтийн phase-ийг өөрчлөхгүй.

Phase 4-ийн график QA-г `docs/PHASE4_BOARD_QA.md`-ийн дагуу F5 дээр хийж, 5 stage-ийн хөлөг, орчны шинэ asset, check/checkmate хүрээ, promotion overlay, capture cinematic-ийг харж үнэлнэ. Үндсэн Chess Duel-д check/checkmate rule logic холбогдсон; King тулаанд ялагдах хувилбар үр дүн хэвээр. Хэрэглэгч зөвшөөрөх хүртэл Phase 5 руу шилжихгүй. LAN PvP-ийн хоёр өөр компьютерийн график, latency, input, hazard QA `docs/LAN_TEST.md`-д үлдсэн. Menu-ийн хоёр Stable Audio take-ийн тухайн output-ийн эрхийн баримт release материалд хавсаргагдаагүй.
