# Tasarım tokenları: Gece & Nane

Uygulamadaki tek renk kaynağı. Kod karşılığı: `lib/core/theme/kalan_colors.dart` (`KalanColors`, açık ve koyu iki örnek). Material `ColorScheme` ve bileşen temaları `lib/core/theme/kalan_theme.dart` içinde bu tokenlardan türetilir. Yeni renk, ton ya da degrade eklemek için önce ürün sahibinden onay alınır.

## Palet

| Token | Koyu tema | Açık tema | Kullanım |
|---|---|---|---|
| `bg` | #0B0F14 | #F7F8FA | Ekran zemini |
| `surface` | #151B23 | #FFFFFF | Kartlar, listeler, alt sayfalar |
| `surfaceRaised` | #1E2630 | #EEF1F4 | Seçili satır, giriş alanı zemini, harf rozeti |
| `border` | #2A3441 | #DDE2E8 | İnce ayraç ve kart çizgileri (yalnızca dekor) |
| `text` | #F2F5F7 | #0B0F14 | Ana metin |
| `textMuted` | #9AA5B1 | #5B6673 | İkincil metin, tarih, açıklama; alan çerçevesi |
| `mint` | #3DDC97 | #3DDC97 | Kalan vurgusu, dolgu, ana düğme zemini |
| `onMint` | #0B0F14 | #0B0F14 | Nane dolgu üstündeki metin ve ikon |
| `mintText` | #3DDC97 | #0E7A53 | Metin olarak nane: büyük "kalan" sayısı, bağlantılar, metin düğmeleri, odak çerçevesi |
| `amber` | #FFB547 | #FFB547 | Kalan eksiye düşünce çubuk dolgusu, uyarı noktası |
| `amberText` | #FFB547 | #A15C00 | Metin olarak kehribar: eksi kalan, uyarı ikonu ve metni |
| `coral` | #FF5C5C | #C62F2F | Yalnızca gecikme ("Gecikti"), hata ve geri alınamaz silme |
| `chartCommitted` | #6B7684 | #5B6673 | Grafikte "söz verilmiş" kısım |

Türetilen tek değer: pencere arkası karartma `scrim` = `bg` %60 opaklık (yeni ton değil). Gölge ve yüzey tonu şeffaftır.

## Kurallar

1. **Tema:** Varsayılan sisteme uyar (`ThemeMode.system`). Ayarlar → Tema: Sistem / Açık / Koyu. Seçim cihazda `shared_preferences` ile saklanır.
2. **Durum renkleri:**
   - Kalan sıfır ya da artıda: büyük sayı `mintText`.
   - Kalan eksiye düşünce: büyük sayı `amberText`; altında `textMuted` renginde sakin açıklama ve `amberText` ikon. Kırmızı kullanılmaz.
   - Sıkışık dönem ve "Bugün/Yarın": `amberText` ikon ya da `amber` nokta, yanında metin.
   - `coral` yalnızca gecikmiş ödeme (ikon + "Gecikti" metni), form hataları ve silme onayı.
3. **Biçim dili:** Düz renkler, bol boşluk, ince çizgiler. Degrade ve ağır gölge yok. Koyu temada derinlik `bg` → `surface` → `surfaceRaised` ton farkıyla verilir.
4. **Renk tek başına anlam taşımaz:** Her durum metin ya da ikonla da belli olur ("Ödendi", "Gecikti", sıkışık dönem notu).
5. **Grafik:** Dönem başına tek çubuk; söz verilmiş `chartCommitted`, kalan `mint`, eksi dönemde aşan kısım `amber`. Pasta ve 3B yok. Çubuğun ekran okuyucu etiketi vardır.
6. **Harf rozetleri:** `surfaceRaised` zemin, `textMuted` harf; marka renkleri yok.
7. **Açık temada nane:** `mint` açık zeminde metin olarak kullanılmaz (1,77:1); yalnızca `onMint` yazılı dolgu olarak. Metin için `mintText`.
8. **Sistem çubukları:** Durum çubuğu şeffaf, ikonları temaya göre; gezinme çubuğu `surface`.

## Ölçülen kontrastlar (WCAG 2.x)

`test/core/theme/contrast_test.dart` her çifti hesaplar: normal metin en az 4,5; büyük metin ve ikon en az 3,0.

| Çift | Koyu | Açık |
|---|---|---|
| text / bg | 17,55 | 18,09 |
| text / surface | 15,81 | 19,22 |
| textMuted / bg | 7,68 | 5,50 |
| textMuted / surface | 6,92 | 5,84 |
| textMuted / surfaceRaised | 6,10 | 5,16 |
| mintText / bg | 10,87 | 5,03 |
| mintText / surface | 9,80 | 5,35 |
| amberText / surface | 9,85 | 5,19 |
| coral / surface | 5,72 | 5,46 |
| onMint / mint | 10,87 | 10,87 |
| chartCommitted / surface | 3,75 | 5,84 |
| mint / chartCommitted (çubukta yan yana) | 2,61 | 3,31 |
| mint / surface (yalnızca dolgu) | 9,80 | 1,77 |

Koyu temada çubukta `mint` ve `amber` yüzeye karşı 9,8 verir; açık temada yüzeye karşı düşük kaldıkları için `chartCommitted` komşuluğu (3,3) ve ekran okuyucu etiketiyle anlaşılır.

## Marka

- İkon: K harfi, alt bacak üç nane parça. Zemin #0B0F14, gövde #F2F5F7, parçalar #3DDC97. Kaynak `assets/brand/kalan_icon.svg` (ve zeminsiz `kalan_mark.svg`), üretici `tool/generate_icons.py`.
- Platform ikonları: `dart run flutter_launcher_icons` (iOS saydamsız; Android adaptif ön katman + #0B0F14 arka katman).
- Açılış ekranı zemini #0B0F14 (iki temada da), ortada işaret.

## Doğrulama

- `test/core/theme/contrast_test.dart`: kontrast.
- `test/app/color_guard_test.dart`: `lib/core/theme` dışında `Color(0x…)`, `Colors.*`, onaltılık renk kodu ya da opaklık türetme varsa kırılır.
- `test/golden/screens_golden_test.dart`: her ana ekran açık ve koyu temada; ana ekran ayrıca kalan artıda ve eksi. Görüntüler `screenshots/`. Güncelleme: `flutter test test/golden --update-goldens`.
