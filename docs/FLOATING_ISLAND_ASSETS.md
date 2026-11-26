# Floating Island — хэрэглэгчийн өгсөн asset-ууд

2026-11-26-нд хэрэглэгч хоёр ZIP өгч, эхлээд зөвхөн Floating Island-ийг шинэчлэхийг хүссэн. Эх ZIP-үүдийг зөвхөн уншиж, хэрэгтэй файлыг project-д сонгон хуулсан. Өөрчлөлтийн backup: `backups/pre_floating_island_import_2026-11-26.tar.gz`.

## Хэрэглэсэн материал ба credit

| Asset | Эх, зохиогч, эрх | Энэ project-д хэрэглэсэн зүйл |
|---|---|---|
| [Low poly Stylized Nature Pack](https://sketchfab.com/3d-models/low-poly-stylized-nature-pack-9c773e846c6e4448b26b2cdecb2b91bf) | Satendra Saraswat, Sketchfab дээр **CC Attribution** гэж тэмдэглэсэн. Тайлбарт нь Imphenzia-ийн gradient image-ийг өөрчилсөн гэж бичсэн. | `LP_PACK_SS.fbx`, `GradientSS.png`-ийн мод, хад, цэцгийн сонгосон mesh. Board ба 3D duel-д хэмжээ/байрлалыг өөрчилж чимэглэл болгон байрлуулсан. |
| [Issum, The town on Capital Isle](https://sketchfab.com/3d-models/issum-the-town-on-capital-isle-e433923a64d549fabb2d30635d643ab6) | Olee. [Бусад төслийн asset credits](https://github.com/mqnc/propwash)-д **CC BY 4.0** гэж бүртгэсэн; эх Sketchfab хуудсыг энэ орчноос нээхэд 403 буцаасан тул release-ээс өмнө эрхийн хуудсыг шууд нягтал. | `Main_Pallete.png`-ийн цонхны хэсгийг project-д шинээр хийсэн жижиг цамхгийн фасадад ашигласан. ZIP-ийн `.blend` геометрийг Blender байхгүй тул импортлоогүй. |

**Тоглоомын credits-д оруулах бичвэр:** “Low poly Stylized Nature Pack” by Satendra Saraswat (Sketchfab, CC Attribution); “Issum, The town on Capital Isle” by Olee (Sketchfab, CC BY 4.0). Both adapted for Chess Duel – Voxel Snakes & Lizards. Links are above. Release хийхдээ Sketchfab эх хуудсын эрхийн хувилбар болон attribution шаардлагыг дахин нягтал.

Nature ZIP SHA-256: `4f462aa538fa1dd746bd3fa7a2ec10a74865112334456535216a9bb1db3d1269`. Issum ZIP SHA-256: `dbd66574fc245ff93298ed424d67c6822ea91ffe6fb393ef9a3d3d7e4b5a6b1f`.

## Хэрэгжүүлэлт

`scripts/floating_asset_library.gd` нь FBX-ийн 67 mesh-ээс нэрээр нь сонгож, өндөрт нь тааруулан байрлуулна. FBX-ийн original `GradientSS.png` material хадгалагдана. Issum-ийн palette-г `AtlasTexture`-ээр жижиг цамхгийн цонхонд хэрэглэнэ. Board-ийн stage 0 арван арлын хоёрт цамхаг, бусдад nature props; 3D duel-ийн дөрвөн арал, төвийн зах, алсын backdrop-д nature props ба хоёр жижиг цамхаг нэмсэн. Цамхаг, импортын мод/хад/цэцэг **collision, damage, зам хаалтгүй**; өмнөх гүүр, collapsing island, tornado, lightning, shard механик хэвээр.

`scripts/tests/floating_asset_import_smoke.gd`, `board_environment_smoke.gd`, `combat_smoke.gd` нь импорт, texture, байрлал, дөрвөн 3D арал/гүүр ба камераас үзэгдэх props-ийг шалгана. Headless structural test нь текстурын өнгө, silhouette, FPS-ийг нүдээр батлахгүй. Ubuntu график session-д F5 board болон Floating Island-ийн AI 3D дуэлийг 1280×720 дээр үзэж, frame rate ба collision/flicker-ийг шалга.
