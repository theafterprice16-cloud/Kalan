# Tasarım tokenları: Mürekkep ve Safran

Uygulamadaki tek renk kaynağı. Kod karşılığı: `lib/core/theme/kalan_colors.dart` (`KalanColors`, açık ve koyu iki örnek). Material `ColorScheme` ve bileşen temaları `lib/core/theme/kalan_theme.dart` içinde bu tokenlardan türetilir; `ColorScheme.fromSeed` ve dinamik renk kullanılmaz. Yeni renk, ton ya da degrade eklemek için önce ürün sahibinden onay alınır.

Fikir: Zemin kâğıt sıcaklığında, yazı mürekkep renginde. "Kalan" lacivert, "söz verilmiş" para safran. Kalan eksiye düşünce koyu safran kullanılır; bu alarm değil, sakin bir nottur. Vişne yalnızca gecikme, hata ve silme içindir. Yeşil-kırmızı "kazanç/kayıp" ikilisi bilerek yoktur.

## Palet

| Token | Açık | Koyu | Kullanım |
|---|---|---|---|
| `bg` | #F5F0E6 | #11161D | Ekran zemini (kâğıt) |
| `surface` | #FCF9F2 | #19212B | Kart ve liste zemini |
| `surfaceRaised` | #FFFFFF | #222C38 | Açılır pencere, alt sayfa, yükseltilmiş kart, giriş alanı, harf rozeti |
| `border` | #8E8576 | #6B7888 | Ayraç, giriş kutusu ve kart kenarı |
| `text` | #1A2330 | #EFE9DD | Ana metin (mürekkep) |
| `textMuted` | #566070 | #A8B0BB | İkincil metin, açıklama, tarih |
| `accent` | #1D4E89 | #8FB8F2 | "Kalan" vurgusu: büyük sayı, birincil düğme dolgusu, grafikte kalan kısım |
| `onAccent` | #FCF9F2 | #0D1B2E | `accent` dolgusu üstündeki metin ve ikon |
| `accentText` | #1D4E89 | #9CC1F5 | Metin olarak vurgu: bağlantı, ikincil düğme yazısı |
| `negative` | #8A5A00 | #EEC56E | Kalan eksiye düştüğünde büyük sayı ve dönem işareti (sakin, koyu safran) |
| `negativeText` | #7D5200 | #EEC56E | Eksi durumun açıklama metni |
| `late` | #A3193F | #F7668C | Yalnızca gecikme, hata ve silme (vişne) |
| `chartCommitted` | #B87A0A | #C98F24 | Grafikte "söz verilmiş" kısım (safran); üstüne metin yazılmaz |
| `focus` | #2D6CC8 | #BCD6FB | Klavye odak halkası (2 px, 2 px boşlukla) |

Türetilen ton yoktur: saydamlıkla ara ton üretilmez. Pencere arkasında karartma yerine `surfaceRaised` zemin ve ince `border` kullanılır.

### Material eşlemesi

`primary` = accent, `onPrimary` = onAccent, `surface` = surface, `onSurface` = text, `onSurfaceVariant` = textMuted, `outline` = border, `error` = late, `onError` = açık temada surfaceRaised (#FFFFFF, late üstünde 7,59:1), koyu temada bg (#11161D, late üstünde 6,26:1), `scaffoldBackgroundColor` = bg. Gölge, yüzey tonu (`surfaceTint`) ve karartma (`scrim`) saydamdır. Diğer tokenlar `KalanColors` ThemeExtension'ı üzerinden okunur (`context.colors.negative` gibi).

## Kurallar

1. **Tek kaynak:** Renkler yalnızca `lib/core/theme` içinde tanımlanır. Başka hiçbir Dart dosyasında renk kodu geçmez (`test/app/color_guard_test.dart`).
2. **Tema:** Varsayılan telefonun ayarıdır (`ThemeMode.system`). Ayarlar → Tema: Sistem / Açık / Koyu. Seçim cihazda `shared_preferences` ile saklanır.
3. **accent yalnızca "kalan" içindir:** büyük sayı (kalan sıfır ya da artıda), birincil düğme ve FAB dolgusu, grafikte kalan kısım. Anahtar, onay kutusu, tarih ve saat seçici gibi seçim kontrolleri mürekkep (`text` dolgu, `bg` yazı) kullanır.
4. **chartCommitted** yalnızca grafikte "söz verilmiş" kısımdır; üstüne metin yazılmaz.
5. **negative / negativeText** yalnızca kalan eksiye düştüğünde kullanılır. Büyük sayı `negative` renginde ve başında eksi işareti vardır; altında `negativeText` renginde açıklama ("Bu dönem ₺5.200 eksik kalıyor.") ve `negative` ikon bulunur. `late` kullanılmaz.
6. **late** yalnızca gecikme ("Gecikti" ikonu ve metni), form hataları ve silme düğmeleri içindir; yanında her zaman ikon ya da kelime olur.
7. **Renk tek başına anlam taşımaz:** "Ödendi", "Gecikti", sıkışık dönem notu, "Bugün/Yarın" hep metinle birlikte gösterilir. Sıkışık dönem eksi değildir; notu mürekkep ikonla gösterilir.
8. **Derinlik:** Degrade ve gölge yok, elevation 0, `surfaceTintColor` saydam. Derinlik bg → surface → surfaceRaised ve ince `border` ile verilir.
9. **Odak halkası:** Düğmelerde `focus` renginde, 2 px kalınlıkta ve kontrolden 2 px uzakta (`KalanTheme.focusRing`). Giriş alanında odak kenarı `focus` renginde 2 px'tir.
10. **Grafik:** Dönem başına tek çubuk; söz verilmiş `chartCommitted`, kalan `accent`, eksi dönemde aşan kısım `negative`. Pasta ve 3B yok. Çubuğun ekran okuyucu etiketi vardır. İstisna, "İleriki dönemler" grafiği (12; ürün sahibi brifi, 19 Kasım 2026): eksi dönemde çubuğun tamamı `chartCommitted`, gelir seviyesinde ince `negative` çizgi ve altında eksi işaretli "eksik" yazısı (`negativeText`). Ana ekrandaki dönem çubuğu değişmedi.
11. **Harf rozetleri:** `surfaceRaised` zemin, `textMuted` harf; marka renkleri yok.
12. **Sistem çubukları:** Durum çubuğu şeffaf, ikonları temaya göre; gezinme çubuğu `surface`.

## Kontrast (WCAG 2.2)

Normal metin en az 4,5; büyük metin, dolgu, grafik, kenar ve odak en az 3,0. `test/core/theme/contrast_test.dart` her çifti iki tema için hesaplar ve aşağıdaki değerlerle karşılaştırır.

| Çift (ön / zemin) | Açık | Koyu | Eşik |
|---|---|---|---|
| text / bg | 13,93 | 15,02 | 4,5 |
| text / surface | 15,05 | 13,43 | 4,5 |
| text / surfaceRaised | 15,82 | 11,69 | 4,5 |
| textMuted / bg | 5,60 | 8,30 | 4,5 |
| textMuted / surface | 6,05 | 7,41 | 4,5 |
| textMuted / surfaceRaised | 6,36 | 6,46 | 4,5 |
| accentText / bg | 7,39 | 9,82 | 4,5 |
| accentText / surface | 7,98 | 8,78 | 4,5 |
| accentText / surfaceRaised | 8,39 | 7,65 | 4,5 |
| negativeText / bg | 6,01 | 11,11 | 4,5 |
| negativeText / surface | 6,49 | 9,93 | 4,5 |
| negativeText / surfaceRaised | 6,82 | 8,65 | 4,5 |
| late / bg | 6,68 | 6,26 | 4,5 |
| late / surface | 7,21 | 5,59 | 4,5 |
| late / surfaceRaised | 7,59 | 4,87 | 4,5 |
| onAccent / accent | 7,98 | 8,49 | 4,5 |
| accent / bg | 7,39 | 8,91 | 3,0 |
| accent / surface | 7,98 | 7,97 | 3,0 |
| accent / surfaceRaised | 8,39 | 6,94 | 3,0 |
| negative / bg | 5,22 | 11,11 | 3,0 |
| negative / surface | 5,64 | 9,93 | 3,0 |
| negative / surfaceRaised | 5,93 | 8,65 | 3,0 |
| chartCommitted / bg | 3,17 | 6,43 | 3,0 |
| chartCommitted / surface | 3,43 | 5,75 | 3,0 |
| chartCommitted / surfaceRaised | 3,60 | 5,01 | 3,0 |
| border / bg | 3,21 | 4,04 | 3,0 |
| border / surface | 3,46 | 3,61 | 3,0 |
| border / surfaceRaised | 3,64 | 3,14 | 3,0 |
| focus / bg | 4,52 | 12,24 | 3,0 |
| focus / surface | 4,88 | 10,94 | 3,0 |
| focus / surfaceRaised | 5,13 | 9,53 | 3,0 |

Tabloda olmayan ama temanın kullandığı çiftler de test edilir: `bg` / `text` (snackbar, seçili anahtar ve tarih) ve `onError` / `error`.

## Eski → Yeni

Gece & Nane (12 Kasım 2026) tokenlarının Mürekkep ve Safran karşılıkları:

| Eski token | Yeni token | Not |
|---|---|---|
| `bg` | `bg` | Aynı rol |
| `surface` | `surface` | Aynı rol |
| `surfaceRaised` | `surfaceRaised` | Artık açılır pencere ve alt sayfa zemini de |
| `border` | `border` | Artık giriş kutusu kenarı da (3,0 eşiğini geçiyor); eskiden yalnızca dekordu |
| `text` | `text` | Aynı rol; seçim kontrollerinin dolgusu da |
| `textMuted` | `textMuted` | Giriş kutusu kenarı görevi `border`'a geçti |
| `mint` | `accent` | Dolgular: birincil düğme, FAB, grafikte kalan kısım |
| `onMint` | `onAccent` | Aynı rol |
| `mintText` (büyük sayı) | `accent` | Büyük "kalan" sayısı kurala göre `accent` |
| `mintText` (bağlantı, metin düğmesi, "Ödendi" ikonu) | `accentText` | Metin olarak vurgu |
| `mintText` (anahtar, sekme, imleç, odak kenarı) | `text` / `focus` | Karşılığı yok: `accent` yalnızca "kalan" için. Seçim kontrolleri mürekkep, odak `focus` |
| `amber` (eksi çubuk dolgusu) | `negative` | Aynı rol |
| `amber` ("Bugün/Yarın" noktası) | `text` | Karşılığı yok: yaklaşan ödeme eksi durum değil; metinle birlikte mürekkep nokta |
| `amberText` (eksi büyük sayı, eksi ikon) | `negative` | Kurala göre büyük sayı `negative` |
| `amberText` (eksi açıklama) | `negativeText` | Açıklama metni artık `textMuted` değil `negativeText` |
| `amberText` (sıkışık dönem ikonu, izin uyarısı ikonu) | `text` | Karşılığı yok: ikisi de eksi durum değil; en yakın nötr token |
| `coral` | `late` | Aynı rol (gecikme, hata, silme) |
| `chartCommitted` | `chartCommitted` | Gri yerine safran |
| `scrim` (`bg` %60) | yok | Saydamlıkla ton üretilmiyor; pencere `surfaceRaised` + `border` ile ayrılır |
| yok | `focus` | Yeni: klavye odak halkası |

## Marka

- İkon: K harfi; alt bacak üç taksit parçası. İlk iki parça "söz verilmiş" safran, en uçtaki parça "kalan" lacivert. Şekil, oran ve boşluklar değişmedi; yalnızca renkler değişti.
  - Açık: zemin #F5F0E6, K #1A2330, ilk iki parça #B87A0A, son parça #1D4E89.
  - Koyu: zemin #11161D, K #EFE9DD, ilk iki parça #C98F24, son parça #8FB8F2.
- Kaynaklar `assets/brand/kalan_icon.svg` ve `kalan_icon_dark.svg` (zeminsiz: `kalan_mark*.svg`); üretici `tool/generate_icons.py`, sonra `dart run flutter_launcher_icons`.
- iOS: açık ikon ve iOS 18 koyu görünüm ikonu (`Icon-App-Dark-*`). Tonlu (tinted) ikon eklenmedi.
- Android: uyarlanabilir ikon; ön katman K ve parçalar (açık renkler), arka katman düz #F5F0E6. Tek renkli (monochrome) katman yok.
- Açılış ekranı iki temada: zemin `bg`, ortada işaret (iOS: `LaunchBackground` renk kümesi ve `LaunchImageDark`; Android: `values-night` ve `drawable-night-nodpi`).
- 60 piksel okunabilirlik: `docs/kimlik/ikon-60px-acik.png` ve `ikon-60px-koyu.png`. K ve üç parça ayrı ayrı seçiliyor (her temada 4 ayrı şekil).

## Doğrulama

- `test/core/theme/contrast_test.dart`: kontrast, iki tema.
- `test/core/theme/theme_scheme_test.dart`: ColorScheme eşlemesi, düz tema, odak halkası, temadaki her rengin bir token olması.
- `test/app/color_guard_test.dart`: `lib/core/theme` dışında `Color(0x…)`, `Color.fromARGB`, `Color.fromRGBO`, `Colors.<ad>` (`Colors.transparent` hariç), tırnak içinde ya da yorumda onaltılık renk kodu ya da opaklık türetme varsa kırılır. İstisna listesi boş.
- `test/app/assets_test.dart`: ikon SVG'lerinin renkleri, iki temada aynı şekil, açılış zeminleri, iOS koyu ikon.
- `test/golden/screens_golden_test.dart`: her ana ekran açık ve koyu temada; ana ekran kalan artıda ve eksi. Görüntüler `screenshots/`. Güncelleme: `flutter test test/golden --update-goldens`.
