# LAN PvP — хоёр компьютерийн шалгалт

## Одоогийн хэрэгжилт

Host-ийн тоглоомын process TCP `8080` дээр WebSocket server-ээ автоматаар асаана. Host ба Join ижил LAN/Wi-Fi-д байж, Host IP + зургаан тэмдэгт өрөөний кодоор холбогдоно. Host цагаан, Join хар тал. Host board-ийн хууль ёсны нүүдлийг шалгаж, capture эхлүүлэх, тулааны хөдөлгөөн/HP/ялагчийг шийднэ. Join өөрийн дүрийн input-ийг Host руу илгээж, Host-ийн тулааны төлөвийг үзнэ. Capture, en passant, N/B/R/Q/W promotion-ийн сонголт хоёр board-д дамжина. Тулаанд довтлогч ялагдвал дүр нь хасагдах Chess Duel дүрэм хэвээр.

Floating Island (stage 0) нь 3D тулаантай. Бусад дөрвөн stage одоогийн 2.5D тулаантай хэвээр; эдгээр map-ийн 3D-only шилжилтийг энэ LAN ажил хийгээгүй. Join дээр 3D projectile, HP, байрлал, гүүр/арлын нуралт, crystal, ferry, lightning анхааруулгын төлөв Host-оос ирнэ. Host тулааны damage, hazard, ялагчийг цорын ганц эх сурвалж болгон бодно. Stage 0-д 30 Hz snapshot, Join талын хөдөлгөөний prediction/interpolation ба хуучирсан state-ийг алгасах арга нэмсэн; бодит хоёр компьютерийн үр дүнг давтан шалгах хэрэгтэй. 2.5D stage-уудын latency polish, ping хэмжүүр, reconnect, интернет matchmaking байхгүй.

## Гар QA

1. Хоёр компьютер дээр яг ижил project/build-ийг Godot 4.7.2-оор ажиллуулж F5 дар. Host хүссэн stage-аа сонгоод **PLAY LAN (2 PCs) → HOST LAN ROOM** дар. Join нь Host IP ба зургаан тэмдэгт кодоор орно. Host/Join хоёулаа **READY**, Host **START GAME** дарна. Тусдаа server process асаах шаардлагагүй.
2. Нүүдэл ба capture: Host e2–e4, Join d7–d5, Host e4×d5 хий. Хоёр компьютерт duel нээгдэх ёстой. Floating Island-д 3D; бусад stage-д тухайн 2.5D arena. Join өөрийн дүрийг хөдөлгөх, Attack, Block, Special ашиглахад Host дээр мөн харагдах эсэхийг шалга. 3D-д Jump, Sprint, Dodge, Perfect Block, combo болон bomb зэрэг Special-ийг турш.
3. Хоёр талд HP буурах, projectile/hazard харагдах, ялагчийн дараа ижил board, ижил ээлж, ижил дүрийн байрлал байгааг шалга. Довтлогч ялагдах хувилбарыг тусад нь турш. Pawn promotion сонголтыг зөвхөн нүүдэл хийсэн компьютер гаргаж, сонгосон дүр хоёр board-д ижил болох ёстой. En passant capture-г мөн шалга.
4. Floating Island-ийн гүүр нурах, crystal авах, tornado/wind, lightning, moving platform ба 45 секундийн sudden death үеэр хоёр талын дүрслэл/HP-ийг ажигла. 1280×720 ба өөр нягтаршилд FPS, input саатал, snapshot тасрах/flicker, speaker SFX-ийг тэмдэглэ.
   2026-11-26-нд Host-д 21.8 секунд орчим `Trying to assign invalid previously freed instance` алдаа, Join дээр хүчтэй саатал/үсрэлт гарсан. Шинэ build-ээр **дор хаяж 50 секунд** амьд тулаан үргэлжлүүлж, 20/24/28/32 секундын арлууд бүрэн нурж дуусахад Host debugger алдаагүй, Join талд дүр ба арал огцом үсрэхгүй, нурсан арал дээр үл үзэгдэх collision байхгүй эсэхийг үз. Мөн Join-ийн W/A/S/D, sprint, jump, dodge-г туршиж, input ба дэлгэцийн хөдөлгөөний зөрүүг тэмдэглэ.
5. Тулааны дундуур Join тоглоомоос гарвал Host lobby/menu рүү буцах, Host гарахад Join мэдэгдэл авах эсэхийг шалга. Дараа нь өрөөг шинээр үүсгээд дахин холбогдоно.

Холбогдохгүй бол хоёр төхөөрөмж нэг сүлжээнд байгаа эсэх, Host-ийн зөв LAN IP, өрөөний код, Ubuntu firewall-д TCP `8080` inbound нээлттэй эсэхийг шалга. LAN IP нь интернет matchmaking хаяг биш.
Join-д 20 секундын countdown харагдана. Хариу ирэхгүй бол timeout алдаа гарч дахин JOIN дарж болно; **BACK / CANCEL** нь идэвхтэй оролдлогыг цуцална. Удаан Wi-Fi дээр Host IP, код, firewall-аас гадна Host тоглоомын lobby нээлттэй эсэхийг шалга. Timeout нь тулааны үеийн ping/packet loss-ийг засахгүй.

## Автомат баталгаа

- `scripts/tests/lan_lobby_smoke.gd`: room code, Ready/Start, ээлж, энгийн нүүдэл, Leave, буруу кодын дараах retry, Join timeout/cancel.
- `scripts/tests/lan_board_smoke.gd` ба `lan_two_process_smoke.gd`: Host/Join board-ийн энгийн нүүдэл ба map сонголт.
- `scripts/tests/lan_duel_scene_smoke.gd`: 3D/2.5D Host input, HP/position snapshot, black attack/block/special, projectile replica, packet хэмжээ; нурсан арлын freed-node snapshot, Join collision removal ба хөдөлгөөний prediction/interpolation.
- `scripts/tests/lan_pvp_two_process_smoke.gd -- host|guest 0..4`: бүх таван stage-ийг хоёр тусдаа Godot process-т шалгана: stage 0 3D, бусад 2.5D capture; Join input-ийн Host хөдөлгөөн; stage 0/1-д Join Attack-ийн damage, Special cooldown; довтлогч/хамгаалагчийн ялалт; энгийн болон capture promotion; en passant; тулааны дундах disconnect.

Headless localhost тест нь хоёр өөр компьютер, бодит keyboard/mouse, latency, speaker болон график QA-г орлохгүй. Үр дүн ба үлдсэн хязгаарлалтыг `DEVELOPMENT_LOG.md`-д тэмдэглэ.
