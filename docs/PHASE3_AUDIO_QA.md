# Phase 3 — гар сонсголын QA

**Төлөв: хэрэглэгч 2026-11-26-нд "бүгд OK" гэж баталсан.** Автомат/headless тестүүд audio файлыг ачаалж, cue сонголт, bus routing, loop ба stage switch-ийг шалгасан. Speaker/headphone дээрх чанарыг агент өөрөө шалгаагүй; доорх бүртгэл нь хэрэглэгчийн өгсөн ерөнхий баталгаа бөгөөд төхөөрөмж, тус бүрийн хэмжилт ирээгүй.

## Ubuntu 24.04 / Godot 4.7.2 дээр

1. `project.godot`-ийг Godot-д нээгээд F5 дар. **SETTINGS → Audio** таб дотор Master, Music, SFX, UI, Ambience slider бүгд байгаа эсэхийг хар. UI-г 0 болгоход menu товчны click ба board select дуугүй, SFX тулаан/board move хэвээр байх ёстой. **RESET AUDIO** дарж дахин сонс; тохиргоог өөрчлөөд тоглоомыг дахин нээж хадгалагдсаныг шалга.
2. Main Menu-г **236 секундээс урт** тоглуул. Хоёр аялгууны шилжилт болон төгсгөлөөс эхлэл рүү буцах үед click/pop, гэнэт чангарах/намсах, нам гүм тасралт байгаа эсэхийг тэмдэглэ. Menu-ийн хоёр take нэг OGG-д crossfade-тай нийлсэн.
3. **PLAY LOCAL → HUMAN VS AI → Floating Island** сонгоод capture хий. Board BGM-ээс Floating Island-ийн өвөрмөц BGM рүү шилжих, тулаанд HP буурахад intensity layer нэмэгдэх, буцахад board BGM сэргэхийг сонс. Өөр stage сонговол ерөнхий battle BGM сонсогдох ёстой.
4. `scenes/tests/sound_test.tscn`-ийг editor-т нээгээд F6 дар. P/N/B/R/Q/K/W-ийн **Swing, Attack, Special, Step, Hit**, мөн N/B/R/Q/K/W-ийн **Special Impact** товч бүрийг сонс. Bomber-ийн Attack нь хүнд мөргөлт, Special Impact нь тэсрэлт мэт ялгарч байгаа эсэхийг эхэлж шалга. Бусад дүрийн Attack/Impact нь чадварт нь таарч, хэт чанга/сул биш эсэхийг тэмдэглэ. Croc Soldier-ийн өмнөх Special/Hit өөрчлөгдөөгүй байх ёстой. Victory, Defeat, Dodge, Block, Counter, UI click, wind, waterfall, thunder-ийг мөн сонс.
5. Бодит тулаанд swing нь нүүдэл эхлэхэд, contact Attack нь зөвхөн байнд хүрэхэд дуугарч байгаа эсэхийг шалга. Bomber-ийн bomb газарт дэлбэрэхэд Special Impact сонсогдох ёстой; бусад дүрийн special impact, Perfect Block, Counter, Dodge, bridge collapse, shard pickup, victory/defeat-ийг мөн шалга. Godot Debugger-ийн script/runtime алдааг тэмдэглэ. Headless-д мэдэгдсэн abrupt shutdown warning нь гар gameplay-ийн дууны чанарыг батлахгүй.

## Бүртгэл

- Шалгасан хүн, огноо, төхөөрөмж: **хэрэглэгч, 2026-11-26; төхөөрөмжийг тодруулаагүй**
- Menu 236 секунд ба loop seam: **хэрэглэгч өмнөх checklist-ийн бүх зүйлийг OK гэж баталсан; тусгай тэмдэглэлгүй**
- Floating Island/бусад stage BGM, intensity: **мөн адил**
- 7 Swing, 7 contact Attack, 7 Special, 6 Special Impact, 7 Hit: **мөн адил**
- Mixer, ambience, Victory/Defeat, бодит тулаан: **мөн адил**
- Илэрсэн асуудал / тайлбар: **хэрэглэгч асуудал мэдээлээгүй**
