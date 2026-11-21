---
name: kalan-yerellestirme
description: Kalan'da çeviri, ARB metni, tarih/tutar biçimi, para birimi, sağdan sola düzen ya da 22 yerel sürümden birine özel terim işi yapılırken pazar kurallarını uygular.
---

# Kalan yerelleştirme kuralları

Hedef: 22 yerel sürüm (16 dil), 75 para birimi. Altyapı 24. maddede kuruldu: her yerel sürümün boş ARB dosyası ve `lib/l10n/app_locales.dart`'ta durumu var; bugün yalnızca tr ve en açık. Yeni metinler yalnızca TR ve EN ARB'ye yazılır; diğer yerel sürümlerin eksikleri `docs/ceviriler/cevrilecekler.json`'da birikir ve dosya her işte commit'lenir; çeviriler yol haritasının sonundaki toplu çeviride yapılır. Görev açıkça istemedikçe TR ve EN dışındaki ARB dosyalarına yazma.

Yerel sürümler: tr, en-US, en-GB, es-ES, es-419, pt-BR, pt-PT, de-DE, de-CH, fr-FR, fr-CA, it, id, ru, zh-Hans, zh-Hant, ar, pl, nl, sv, ja, vi.

## Genel kurallar

- Sayı, tarih ve para biçimi `intl` paketinin yerel verisiyle üretilir; elle biçim yazılmaz. Testlerde beklenen değeri de intl'den üret. Aşağıdaki biçim örnekleri yalnızca kontrol içindir.
- Metinler ARB'de yer tutucularla (tutar, tarih, sayı) yazılır; cümle parçaları kodda birleştirilmez.
- Sayıya göre değişen kelimelerde ICU plural kullan. Rusça ve Lehçede üç biçim vardır (1 платёж / 2 платежа / 5 платежей; 1 rata / 2 raty / 5 rat).
- Yerel finans terimi varsa aynen kullanılır; komşu yerel sürümün terimi kopyalanmaz (pt-BR ≠ pt-PT, es-ES ≠ es-419, fr-FR ≠ fr-CA, zh-Hans ≠ zh-Hant, de-DE ≠ de-CH).
- Ses tonu her dilde aynıdır: sakin, kısa, yargısız; ünlem ve emoji yok.
- Sağlayıcı adları düz metindir, logo yok. Sağlayıcı şablonları ülkeye göre ayrılır.
- Ücret, oran ve yasal sınırlar uygulamaya sabit yazılmaz; ülkeden ülkeye ve sık değişir.
- "Doğrulanamadı" notlu bilgiler kesinmiş gibi koda gömülmez; yayın öncesi yerel bir okurla kontrol edilir.

## Para birimleri

- Tutarlar tam sayı (minor unit) olarak saklanır; double ile para hesabı yapılmaz.
- Saklama ölçeği ISO'ya değil "günlük" basamak sayısına göredir (Unicode CLDR ve günlük kullanım): 0 basamakta 1 birim = 1, 2 basamakta = 100, 3 basamakta = 1000.
- 0 basamaklı (ondalık tuşu çıkmaz): JPY, VND, CLP, COP, IDR, PYG, CRC, XOF, XAF, GNF, MGA, UZS, TWD, PKR, IQD, LBP, SYP, YER.
- 3 basamaklı: KWD, BHD, OMR, JOD, TND, LYD.
- Diğerleri 2 basamak (SEK, CHF, CAD dahil; nakit yuvarlaması uygulanmaz).
- Sembolü paylaşılan birimlerde ($, ¥, kr, Bs) uygulama içinde normal sembol; para birimi seçicide ve dışa aktarmada ayırt edici sembol ve ISO kodu (US$, MX$, COL$, CN¥, JP¥, NT$, HK$ …).
- Seçici ada, ISO koduna ve sembole göre arar; başta cihaz bölgesine göre "Önerilen" bölümü olur (ör. PA → PAB ve USD), bölge bilinmiyorsa dile göre.
- Tek para birimi seçilir; kur çevirisi yok.
- Sayılar çok basamaklı olabilir (IDR, VND): ana ekrandaki büyük sayı taşmamalı.

## Sağdan sola (ar)

- Bütün ekranlar sağdan sola çevrilir; grafikler ve ilerleme çubukları da sağdan başlar.
- `EdgeInsetsDirectional`, `AlignmentDirectional`, start/end kullan; left/right sabitleme.
- Rakamlar her zaman Batı biçiminde (0-9), seçenek yok (ürün sahibi kararı, 24. madde). Arapça klavyeden yazılan ٠-٩ tutar alanında 0-9 olur.
- Körfez ile Mısır'ın günlük dili farklı; ortak yazı dili (modern standart Arapça) kullan.
- Arapça para sembolleri (ر.س gibi) bozulmadan görünmeli. SAR ve AED'nin 2025'te duyurulan yeni işaretlerinin yazı tipi desteği doğrulanmadı; Arapça kısaltma ve ISO kodu kullan.
- Doğrulanmadı: hafta sonunun cuma–cumartesi olması ve "faiz" kelimesinden kaçınma gereği.

## Yerel sürüm notları

**tr** Terimler: hesap kesim, son ödeme, asgari ödeme, ek taksit, taksitli nakit avans. 12.11.2026 · 1.250,00 ₺ · hitap "sen". Taksit kredi kartında; kullanıcı taksiti değil ekstreyi öder. Yasal taksit sınırlarını dayatma.

**en-US** "installment" (iki l), "Pay in 4". 11/12/2026 (ay önce) · $1,250.00 · hafta pazar başlar. Sağlayıcı: Afterpay.

**en-GB** "instalment" (tek l), "Pay in 3". 12/11/2026 (gün önce) · £1,250.00 · hafta pazartesi başlar. "Afterpay" burada "Clearpay".

**es-ES** plazos, cuotas, fraccionar, aplazar; faizde "TAE". "meses sin intereses" ve "fecha de corte" KULLANILMAZ. 12/11/2026 · 1.250,00 € · hitap "tú".

**es-419** Meksika: meses sin intereses (MSI), fecha de corte, fecha límite de pago. Arjantin, Kolombiya, Şili: cuotas. "$" dört ayrı para biriminde ortak; kod (MXN, COP, CLP, ARS) görünmeli. COP ve CLP kuruşsuz. Hitap ülkeye göre değiştiği için nötr dil.

**pt-BR** parcela, fatura, fechamento, vencimento, à vista, sem juros. 12/11/2026 · R$ 1.250,00 · hitap "você". Taksit "3/10" biçiminde gösterilir.

**pt-PT** "parcela" yerine prestação, "parcelado" yerine pagamento fracionado; telemóvel, ecrã. 1 250,00 € (işaret sonda). Ekstre döngüsü ikinci planda; "30 gün sonra öde" ve üçlü plan önde.

**de-DE** Rechnung, Zahlungsziel, Rate, Mahngebühr, Inkasso, Verwendungszweck. 12.11.2026 · 1.250,00 €. "du" ya da "Sie"den biri seçilip tutarlı kullanılır.

**de-CH** "ß" yok ("Strasse"). CHF 1'250.00 (binlik kesme işareti, ondalık nokta). İcra: Betreibung. Çok sayıda küçük kayıt beklenir.

**fr-FR** échéance, mensualité, paiement en plusieurs fois, prélèvement. 12/11/2026 · 1 250,00 € (boşlukla, işaret sonda) · hitap "vous".

**fr-CA** "échéance/mensualité" yerine versement; achetez maintenant, payez plus tard; magasiner; courriel. 2026-11-12 · 1 250,00 $ (işaret sonda). İki haftalık aralık temel ihtiyaç.

**it** rata / rate, scadenza, tasso zero, mora. 12/11/2026 · 1.250,00 € · hitap "tu".

**id** cicilan, tenor, jatuh tempo, denda, tagihan. Rp 1.250.000 (kuruş yok).

**ru** рассрочка, оплата частями, платёж (üç çoğul biçim). 12.11.2026 · 1 250,00 ₽. Kazakistan için tenge (₸). Rusya'da mağaza satışı kapalı; pratik pazar Kazakistan ve çevresi.

**zh-Hans** 分期, 账单日, 还款日, 逾期. 2026年11月12日 · ¥1,250.00; Singapur S$, Malezya RM. Aynı yazı üç ülkede üç ayrı para birimi ve sağlayıcı listesiyle kullanılır.

**zh-Hant** Basitleştirilmişin harf çevirisi yetmez; kelimeler farklı: 繳款, 帳單, 無卡分期. NT$1,250 (kuruş yok); HK$1,250.00 (var). Asıl risk elle ödemeyi unutmak.

**ar** Yukarıdaki sağdan sola bölümü. Para birimleri ayrı: SAR, AED, EGP ve diğerleri. Körfez'de kısa vadeli faizsiz, Mısır'da uzun vadeli planlar önde.

**pl** raty, płatność odroczona, termin płatności (üç çoğul biçim). 12.11.2026 · 1 250,00 zł. "Sonra öde" planında gün sayısı serbest girilebilmeli (30 ve 45 gün).

**nl** achteraf betalen, termijn, herinnering, aanmaning, incassokosten. 12-11-2026 · € 1.250,00 (işaret başta) · hitap "je".

**sv** faktura, förfallodag, delbetalning, påminnelseavgift, inkasso. 2026-11-12 · 1 250,00 kr · hitap "du".

**ja** 後払い, 分割払い, 支払期日, コンビニ払い, 口座振替. 2026年11月12日 · ¥1,250 (kuruş yok) · kibar dil. Hatırlatma "son gün" değil "27'sine kadar" mantığıyla, birkaç gün önceden başlar.

**vi** ví trả sau, trả góp, ngày đến hạn, phí chậm trả, nợ xấu. 12/11/2026 · 1.250.000 ₫ (kuruş yok).

## Bilgisi zayıf pazarlar

Hong Kong, Malezya, Belçika, Şili, Kolombiya ve Quebec için doğrulanmış kaynak yok; Kazakistan ve Mısır tek kaynağa dayanıyor. Maaş günü alışkanlıkları (İsveç ve Japonya'da ayın 25'i, ABD ve Kanada'da iki haftada bir) doğrulanmadı; varsayılan olarak koda gömme.

## Bir çeviri işi bitince kontrol et

1. Yerel terimler bu dosyadakilerle aynı mı, komşu yerel sürümden kopya var mı?
2. Çoğul biçimleri ICU ile mi yazıldı?
3. Tarih ve tutar intl'den mi geliyor, basamak sayısı doğru mu?
4. Uzun metinler ve çok basamaklı tutarlar taşıyor mu?
5. ar için düzen, grafik ve ilerleme çubuğu sağdan mı başlıyor?
