---
name: kalan-urun-kurallari
description: Kalan için özellik, ekran metni, bildirim, Pro/satın alma ya da mağaza metni yazılırken ürünün değişmez kurallarını, ses tonunu, terim sözlüğünü ve ömür boyu Pro modelini uygular.
---

# Kalan: ürün kuralları, ses tonu ve Pro

Kalan, taksitleri, "şimdi al, sonra öde" planlarını ve sabit ödemeleri tek takvimde toplayan ve her maaş döneminde geriye ne kaldığını tek sayıyla gösteren, Flutter ile yazılmış iOS/Android uygulamasıdır. Ana ekranın sorusu: "Bu maaştan, söz verdiklerim çıktıktan sonra bana ne kalıyor?"

## Değişmez kurallar

- Banka bağlantısı, hesap açma ve bulut eşitleme yok. Tüm veri cihazda kalır.
- Reklam, izleme ve analiz paketi yok. Yeni bir ağ isteği ekleme.
- Üçüncü taraf satın alma SDK'sı yok; satın alma yalnızca StoreKit 2 ve Google Play Billing ile (Flutter'da resmî `in_app_purchase`). Gizlilik etiketi "Veri toplanmıyor" kalmalı.
- Tek para birimi seçilir; kur çevirisi yapılmaz.
- Uygulama sade kalır; bütçe uygulaması değildir (kategori, bütçe, net varlık, yatırım yok).
- Borç satılmaz: kredi, kart ya da "sonra öde" reklamı ve yönlendirmesi yok.
- Puan, seri, rozet, konfeti, kutlama ekranı yok.
- Ücretsiz sürümde en fazla 4 açık plan; Pro ile sınırsız. Bu sınıra dokunma.
  - Sabit ödemeler sınıra sayılmaz; tek ödemeli "sonra öde" kayıtları sayılır (Karar 4).
  - İade nedeniyle bekletilen (beklemedeki) plan sınıra sayılır; kapatılan plan sayılmaz (19. madde, ürün sahibi kararı 19 Kasım 2026, `docs/DECISIONS.md`).
- Sabit ödemeler kapsamdadır (Karar 7). Tahmini tutar yalnızca 41. maddedeki kurallarla ve "tahmini" etiketiyle gösterilir.
- Cihazlar arası taşıma yalnızca dışa aktarma ve yedekten geri yükleme dosyasıyla yapılır (29-30. maddeler).
- Sağlayıcı ve banka logoları kullanılmaz; ad düz metinle ve nötr harf rozetiyle gösterilir.

Bu kurallardan biriyle çelişen bir istek gelirse uygulama; çelişkiyi yaz ve ürün sahibine sor.

## Ürün ilkeleri

1. Önce sayı: her ekran tek bir soruya cevap verir.
2. Yargı yok: durum olduğu gibi gösterilir.
3. Veri kullanıcınındır: dışa aktarma her zaman açık ve ücretsiz.
4. Yirmi saniye kuralı: yeni plan eklemek 20 saniyeyi geçiyorsa tasarım yanlıştır.
5. Takvim, tahmin değil: yalnızca bilinen ödemeler gösterilir; bilinmeyen tutar uydurulmaz, kullanıcıya sorulur.
6. Onaysız kayıt olmaz: otomatik okunan her alan kullanıcıya gösterilir ve onaylanmadan kaydedilmez.

## Ses tonu

Kişilik: hesap bilen, sakin bir arkadaş. Net, dürüst, kısa. Paniğe sürüklemez, övmez, azarlamaz.

| Nitelik | Böyle yaz | Böyle yazma |
|---|---|---|
| Net | "Bu dönem 4 ödeme var. Toplam 3.250 TL." | "Finansal yolculuğunda harika bir adım attın!" |
| Sakin | "Cuma günü 62 dolar çekilecek." | "DİKKAT! Ödemeni kaçırmak üzeresin!" |
| Yargısız | "Bu plan eklenirse 2. dönemde 400 TL eksik kalıyor." | "Bu alışverişi yapmamalısın." |
| Dürüst | "Bu tutarı okuyamadım. Sen girer misin?" | Tahmini tutarı kesinmiş gibi göstermek |
| Kısa | "Ödendi olarak işaretlendi." | Üç cümlelik tebrik ve açıklama |

- Türkçede hitap "sen". İngilizcede ikinci tekil, kısaltmalı gündelik dil.
- Emoji ve ünlem yok. "Son gün!", "Acele et!" gibi ifadeler yok.
- Para tutarları her zaman rakamla ve para birimiyle.
- Sahte aciliyet, geri sayım, "son fırsat", eksiklik duygusu yok.
- Metinler çeviriye uygun yazılır: tutar ve tarih yer tutucuyla, cümle parçaları birleştirilmeden.

## Terimler sözlüğü (bu karşılıkları aynen kullan)

| TR | EN | Anlamı |
|---|---|---|
| Plan | Plan | Tek bir alışverişin taksitlere bölünmüş ödeme düzeni |
| Ödeme | Payment | Bir planın tek taksidi; tarihi ve tutarı vardır |
| Kaynak | Source | Planın bağlı olduğu sağlayıcı ya da kart |
| Dönem | Pay period | İki maaş günü arasındaki süre |
| Söz verilmiş | Spoken for | Bir dönemde çekilecek bütün ödemelerin toplamı |
| Kalan | Left | Dönem geliri eksi söz verilmiş; ana sayı |
| Dene | Try it | Yeni planın etkisini kaydetmeden gösteren hesap |
| Sıkışık dönem | Tight period | Kalanın kullanıcının eşiğinin altına düştüğü dönem |
| Ekstre günü | Statement date | Kartın hesap kesim günü |
| Son ödeme günü | Due date | Kart ekstresinin son ödeme günü |
| Sonra öde | Buy now, pay later | Kısa vadeli taksit hizmetleri |
| 4 ödemeli plan | Pay in 4 | İki haftada bir dört eşit ödeme |
| İade bekliyor | Refund pending | Ürünü iade edilmiş, ödemeleri henüz durmamış plan |

Slogan: "Geriye ne kaldığını gör." / "See what's left."

## Pro: karar verilmiş model

**Kalan Pro tek seferlik (ömür boyu) satın almadır.** Tek bir non-consumable ürün. Abonelik, aylık/yıllık plan, ücretsiz deneme, lansman indirimi ve tanıtım fiyatı YOK. Eski belgelerde geçen "aylık 2,99 $ / yıllık 19,99 $ / ömür boyu 39,99 $" üçlüsü geçersizdir; kod, metin ya da mağaza içeriğinde abonelik varsayma.

- Fiyatlandırma raporundaki öneri: Türkiye ₺249,99, ABD $14.99; diğer pazarlar raporun 22 pazar tablosunda. Fiyatı koda gömme; mağazadan gelen yerel fiyatı göster.
- Satın alma ve geri yükleme yalnızca App Store / Google Play üzerinden. "Satın alımı geri yükle" her zaman görünür.
- Pro ekranı ücretsiz sürümde görünür.

Pro'da açılanlar: sınırsız açık plan; kilit ekranı widget'ı (32); "Dene" (35); erken ödeme kaydı ve etkisi (36); ekran görüntüsünden plan ekleme (43); yapıştırılan metinden plan ekleme (44); telefon takvimine aktarma (45).

Ücretsiz kalanlar (Pro'ya taşıma): bildirimler ve ısrarlı hatırlatma, gecikenler, ileriki dönem grafiği (herkese aynı 6 dönem), takvim, kart ekstre tahmini, ana ekran widget'ı, biyometrik kilit, tutar gizleme, dışa aktarma, yedekten geri yükleme. Pro bir "kilit açma" paketidir; veriyi, hatırlatmayı ya da dışa aktarmayı rehin tutmaz.

Pro ekranı metni:
- TR: "Ücretsiz sürümde 4 açık plan var. Pro ile sınır kalkar ve şunlar açılır: …" / "{fiyat} · bir kez ödenir. Abonelik yok, yenileme yok." / [Pro'yu al] [Satın alımı geri yükle]
- EN: "The free version keeps up to 4 open plans. Pro removes the limit and adds: …" / "{price} · pay once. No subscription, nothing renews." / [Get Pro] [Restore purchase]
- 5. plan eklenirken: "Ücretsiz sürümde 4 açık plan var. Bir planı bitirdiğinde ya da Pro ile yenisini ekleyebilirsin." [Pro'ya bak] [Şimdi değil]

## Ekran görüntüsünden ekleme (43): karar verildi

Okuma cihazda, işletim sisteminin kendi metin tanımasıyla yapılır (Karar 3). Bu bir Pro özelliğidir.

- Sunucu, bulut yapay zekâ, API anahtarı ve ağ isteği yok.
- Görüntü saklanmaz ve cihazdan çıkmaz.
- Her zaman onay ekranı gösterilir; emin olunmayan alan boş bırakılır; onaysız kayıt olmaz.
- Bulut seçeneğine ait "ayda 30 okuma" gibi sınırlar geçersizdir; Pro ekranına ya da mağaza metnine yazma.

## Açık kararlar (varsayım yapma, ürün sahibine sor)

- İlk yayının zamanı ve kapsamı. Süre uydurulmaz.
