# 2.5D-ээс бүрэн 3D тулаан руу шилжих төлөвлөгөө

**Төлөв: зөвхөн шийдвэр ба дараалал. 2.5D код/scene/asset устгаагүй.** Хэрэглэгчийн зорилго: эцсийн тоглоомд 2.5D тулаан үлдээхгүй. Одоогийн албан ёсны үе шат Phase 4; дараагийн phase-г зөвшөөрөлгүй эхлүүлэхгүй.

## Одоогийн саад

- `scripts/main.gd::_start_duel()` нь Floating Island-д AI эсвэл LAN PvP үед `Duel3D`, бусад тохиолдолд `Duel` үүсгэдэг. Local Human vs Human 3D болоогүй.
- `scripts/duel_3d.gd::setup(..., _ai, ...)`-ийн `_ai` параметр local горимд ашиглагдахгүй; LAN үед Join нь хоёр дахь fighter-ийг сүлжээгээр удирддаг. Энэ нь local нэг компьютерийн Human vs Human 3D горимыг орлохгүй.
- Floating Island-д 3D arena бий. Hell Gate, Dark Desert, Sanctuary, Frozen Peak-ийн stage theme байгаа ч 3D arena механик/гар QA дуусаагүй. Шууд 3D-г бүх stage-д асаах нь эдгээр map-ийг бүрэн хийсэн гэсэн үг биш.
- 2026-11-26-нд хэрэглэгч LAN PvP-г одоо ажиллуулахыг хүссэн. Host authority-тай capture/тулааны input, HP, position, ялагч, promotion sync нэмсэн; Floating Island-д 3D, бусад stage-д одоогийн 2.5D тулаан ажиллана. `docs/LAN_TEST.md`-д автомат ба гар QA бий. Энэ нь бүх stage/local горимын 3D-only шилжилтийг орлохгүй; latency prediction/interpolation, reconnect, хоёр өөр компьютерийн гар QA үлдсэн.

## Ажлын дараалал

1. Одоогийн 2.5D-ийг backup-д хадгалж, 3D Floating Island local AI-ийн input, 7 дүр, Special/Hit, радиус, sound, victory урсгалыг бодит тоглолтоор шалгах.
2. 3D Human vs Human local удирдлага, камерын шийдлийг хэрэгжүүлж хоёр хүнээр турших. Хоёр тоглогчийн харах өнцөгт split-screen нь боломжит хувилбар; UI/гүйцэтгэлийн туршилтаар батална. AI горим хэвээр ажиллах ёстой.
3. Сонгох боломжтой stage бүрт 3D arena орлуулалт болон тухайн stage-ийн бодит mechanic, collision, BGM/hazard QA хийх. Бэлэн биш stage-ийг бүрэн гэж тэмдэглэхгүй.
4. `main.gd`-ийн бүх local capture-ийг баталгаажсан 3D дуэльд холбож, Human vs AI/Human vs Human, ялалт/ялагдал, promotion, буцах board урсгал, F5/F6 ба combat smoke-ийг шалгах.
5. Зөвхөн дээрх parity/QA амжилттай болсны дараа 2.5D script/reference/test-ийг төслөөс салгаж, backup-аас буцаах боломжийг хадгалан хэрэггүй файлыг цэвэрлэх. Godot cold import, headless ба график runtime regression ажиллуулах.
6. 3D local дүрэм тогтворжмогц network model ба message/state-ийн хил заагийг тогтоож, localhost болон хоёр client prototype турших. Competitive combat/chess-ийн damage, HP, move, timer, hazard-ийг серверээр баталгаажуулах архитектур сонгох. Эхний prototype-д cloud сервер түрээслэх шаардлагагүй.
7. Multiplayer prototype-ийг хоёр өөр компьютер/сүлжээнд шалгаж, дараа нь cloud/dedicated hosting, export, restricted playtest, эцэст нь Steam/itch.io public release хийх. Release хүртэл platform дээр хаалттай тест хийж болно.

## Эх сурвалж

- Godot-ийн [high-level multiplayer баримт](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html) нь gameplay-critical шийдвэрт server authority, client input-ийг шалгахыг зөвлөдөг.
- Godot 4-ийн [dedicated server export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html) нь headless server ажиллуулах боломжийг тайлбарласан.
- [Steam Playtest/closed beta](https://partner.steamgames.com/doc/store/testing), [itch.io restricted access](https://itch.io/docs/creators/access-control) нь public release-ээс өмнөх тестийн сувгууд.
