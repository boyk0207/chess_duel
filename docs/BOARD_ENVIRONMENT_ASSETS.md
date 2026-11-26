# Шатрын хөлгийн гаднах шинэ scene asset

`scenes/board_environment.tscn` нь `scripts/board_environment.gd`-ээр тогтмол seed-тэй 3D mesh үүсгэдэг. Таван stage бүр хөлгийн эргэн тойронд 10 жижиг аралтай; хөлгийн нүд, дарах хүрээ, тулааны collision-д оролцохгүй. Floating Island-д 2026-11-26-нд хэрэглэгчийн өгсөн nature FBX-ийн сонгосон mesh болон Issum texture ашигласан tower нэмсэн. Эдгээр гаднын asset-ийн эх сурвалж, credit нь `docs/FLOATING_ISLAND_ASSETS.md`-д бий. Бусад дөрвөн stage-ийн геометр project-д original procedural хэвээр.

| Stage | Орчны чимэглэл |
|---|---|
| Floating Island | Imported stylized мод/хад/цэцэг, Issum palette-тай жижиг цамхаг, чулуун нуман хаалга, усан хүрхрээ, cyan туг |
| Hell Gate | Базальт, лаавын агааржуулалт ба улбар гэрэл |
| Dark Desert | Элсэн чулуун үлдэгдэл, обелиск, сүмийн элемент |
| Sanctuary | Цайвар багана, ногоон мод, хүрхрээ |
| Frozen Peak | Мөсөн талст ба хөх гэрэл |

Хоёр хаант улсын cyan/red туг нь бүх stage-д харагдана. Өнгө нь `scripts/data.gd`-ийн тухайн stage palette-тай холбогддог. Scene-ийн чимэглэл нь Hell Gate/Frozen Peak/Dark Desert/Sanctuary тулааны map механик хийгдсэн гэсэн үг биш.

`scripts/tests/board_environment_smoke.gd` таван theme-ийн тус бүр 10 арал, board-оос зай, өвөрмөц mesh, Floating Island-ийн imported props, main scene холболт ба камерын frustum-д үзэгдэх хэсгийг шалгана. График харагдах байдал, texture detail, кадр секунд, GPU хэрэглээг Ubuntu дээр гар QA хийх шаардлагатай. Тестийн бүтцийн PASS нь урлагийн чанарыг батлахгүй.
