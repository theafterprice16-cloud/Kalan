---
name: kalan-palet
description: Kalan uygulamasında renk, tema, ikon, grafik ya da herhangi bir görsel/arayüz işi yapılırken Mürekkep ve Safran paletini ve kullanım kurallarını uygular.
---

# Kalan paleti: Mürekkep ve Safran

Kalan'ın tek geçerli paleti budur. Eski belgelerde (kimlik dosyası, eski logo prompt'ları) geçen yeşil/lacivert/kehribar/mercan paleti (#23B58E, #14213D, #F2A541, #E4572E vb.) GEÇERSİZDİR; görürsen kullanma, bu paletle değiştir.

## Fikir

Kâğıt sıcaklığında zemin, mürekkep rengi yazı. "Kalan" lacivert mürekkep, "söz verilmiş" para safran. Kalan eksiye düşünce koyu safran (alarm değil, sakin not). Vişne yalnızca gecikme, hata ve silme için. Yeşil-kırmızı "kazanç/kayıp" ikilisi bilerek yok; palette yeşil yok.

## Tokenlar (aynen kullan, yaklaşık değer üretme)

| Token | Açık | Koyu | Kullanım |
|---|---|---|---|
| bg | #F5F0E6 | #11161D | Ekran zemini (kâğıt) |
| surface | #FCF9F2 | #19212B | Kart ve liste zemini |
| surfaceRaised | #FFFFFF | #222C38 | Açılır pencere, alt sayfa, yükseltilmiş kart |
| border | #8E8576 | #6B7888 | Ayraç, giriş kutusu ve kart kenarı |
| text | #1A2330 | #EFE9DD | Ana metin (mürekkep) |
| textMuted | #566070 | #A8B0BB | İkincil metin, açıklama, tarih |
| accent | #1D4E89 | #8FB8F2 | "Kalan" vurgusu: büyük sayı, birincil düğme dolgusu, grafikte kalan kısım |
| onAccent | #FCF9F2 | #0D1B2E | accent dolgusu üstündeki metin ve ikon |
| accentText | #1D4E89 | #9CC1F5 | Metin olarak vurgu: bağlantı, ikincil düğme yazısı |
| negative | #8A5A00 | #EEC56E | Kalan eksiye düştüğünde büyük sayı ve dönem işareti |
| negativeText | #7D5200 | #EEC56E | Eksi durumun açıklama metni |
| late | #A3193F | #F7668C | Yalnızca gecikme, hata ve silme (vişne) |
| chartCommitted | #B87A0A | #C98F24 | Grafikte "söz verilmiş" kısım; üstüne metin yazılmaz |
| focus | #2D6CC8 | #BCD6FB | Klavye odak halkası (2 px, 2 px boşlukla) |

## Kullanım kuralları

1. Açık ve koyu tema eşit özenle uygulanır; varsayılan cihaz ayarına uyar (ThemeMode.system). Bir temanın rengi öbür temada kullanılmaz.
2. `accent` yalnızca "kalan" içindir: büyük kalan sayısı, birincil düğme, grafikte kalan kısım, logodaki son parça. Süsleme için kullanılmaz.
3. `chartCommitted` yalnızca "söz verilmiş" kısmı gösterir. Üstüne metin yazılmaz; etiket yanına ya da altına konur.
4. `negative` / `negativeText` yalnızca kalan eksiye düştüğünde; yanında her zaman eksi işareti ve "eksik" gibi bir kelime olur. Eksi kalan hata değildir, vişne kullanılmaz.
5. `late` yalnızca üç durumda: günü geçmiş ödeme, hata mesajı, silme eylemi. Yanında her zaman ikon ya da kelime olur.
6. Renk tek başına anlam taşımaz: her durum renkle birlikte kelime, işaret ya da ikonla anlatılır.
7. Kontrast: normal metin en az 4,5:1; büyük metin, ikon, kenar, grafik ve odak halkası en az 3:1. Tablodaki standart çiftler bu eşikleri geçer; tabloda olmayan bir çift kullanmadan önce WCAG kontrastını hesapla.
8. Yüzeyler düzdür. Derinlik bg → surface → surfaceRaised sırası ve ince border ile verilir.
9. Odak halkası `focus` rengiyle, 2 px kalınlık ve 2 px boşlukla.

## Yasaklar

- Degrade, parlama, neon, cam efekti, ağır gölge.
- Yeşil "iyi", kırmızı "kötü" anlamı; mor, pembe, nane yeşili, turkuaz, camgöbeği.
- Saf beyaz ekran zemini ve saf siyah (#000000). #FFFFFF yalnızca açık temada surfaceRaised.
- Tabloda olmayan hex kodu, saydamlıkla türetilmiş ara ton, "biraz daha açık" lacivert.
- `accent` ile `late` aynı öğede yan yana.
- Korkutan görseller: ünlem dolu uyarılar, kırmızı zeminler, düşen oklar.

Paletin dışında bir renge ihtiyaç duyarsan kullanma; neden gerektiğini yaz ve ürün sahibinden onay iste.

## Flutter'da uygulama

- Renkler tek kaynakta toplanır (ör. `lib/theme/kalan_tokens.dart` ya da repodaki karşılığı). Tema klasörü dışında `Color(0x…)`, `Color.fromARGB`, `Color.fromRGBO`, `Colors.<ad>` (transparent hariç) ya da hex metni geçmez; repodaki koruma testi bunu yakalar.
- `ColorScheme` tokenlardan türetilir; `ColorScheme.fromSeed` ve dinamik renk kullanılmaz. Eşleme: primary=accent, onPrimary=onAccent, surface=surface, onSurface=text, onSurfaceVariant=textMuted, outline=border, error=late, onError=açıkta surfaceRaised / koyuda bg, scaffoldBackgroundColor=bg.
- negative, negativeText, accentText, chartCommitted, surfaceRaised ve focus bir `ThemeExtension` (KalanTokens) içindedir.
- Elevation gölgeleri kapatılır ya da en aza indirilir; `surfaceTintColor` saydam.

Doğru:
```dart
final t = Theme.of(context).extension<KalanTokens>()!;
Text(kalanMetni, style: TextStyle(color: kalan < 0 ? t.negative : Theme.of(context).colorScheme.primary));
```
Yanlış:
```dart
Text(kalanMetni, style: const TextStyle(color: Color(0xFF1D4E89)));
```

## Logo

Şekil ve oranlar değişmez: K harfi, sağ alt bacağın yerinde üç ayrı taksit parçası, en uçtaki parça "kalan". Gerçek şekil repodaki SVG'dir (`assets/brand`).

- Açık: zemin #F5F0E6, K #1A2330, ilk iki parça #B87A0A, kalan parçası #1D4E89.
- Koyu: zemin #11161D, K #EFE9DD, ilk iki parça #C98F24, kalan parçası #8FB8F2.

## Örnek: açık temada ana ekran

- Zemin bg. Üstte "Bu dönemden kalan" textMuted. Altında büyük sayı "12.450 ₺" accent.
- İnce çubuk: söz verilmiş kısım chartCommitted, kalan kısım accent; altında "Söz verilmiş 8.300 ₺ · Kalan 12.450 ₺" text renginde.
- Ödeme listesi surface kartlarda, kenar border, satırlar text, tarih textMuted.
- Günü geçmiş satırın başında saat ikonu ve "2 gün gecikti" late.
- "Plan ekle" düğmesi accent dolgulu, yazısı onAccent.
- Eksi durumda: büyük sayı "−1.200 ₺" negative, altında "Bu dönem 1.200 ₺ eksik görünüyor" negativeText. Kırmızı yok.

## İş bitince

Kullandığın tokenları listele (ör. "bg, surface, text, accent, chartCommitted").
