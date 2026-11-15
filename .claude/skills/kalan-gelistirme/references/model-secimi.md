# Model seçimi: gerekçe ve madde tablosu

## Neden bu düzen (belgelenmiş gerçekler, Kasım 2026)

- **Fiyat sırası:** Claude API liste fiyatları, milyon token başına girdi / çıktı:

  | Model | Girdi | Çıktı |
  |---|---|---|
  | Opus 5.5 | 4 $ | 20 $ |
  | Sonnet 5.5 | 2 $ | 10 $ |
  | Haiku 5.5 | 0,10 $ | 0,50 $ |

  Haiku 5.5'te 100 bin token'ı aşan istem 0,50 $ / 2,50 $'a çıkar; bu yüzden Haiku ajanlarında `autoCompactWindow: 100000` var.

  Abonelikte bu dolar rakamları fatura değildir. Yine de pahalı model ve büyük bağlam plan limitinden daha hızlı düşer. Claude Code belgesi yüksek harcamanın en sık iki nedenini şöyle sayar: hiç temizlenmeyen uzun oturumlar ve varsayılan model olarak bırakılan Opus.
- **Önbellek kuralları** (code.claude.com/docs/en/prompt-caching):
  - Her modelin ayrı önbelleği vardır. Oturum ortasında `/model` değişimi bütün geçmişi önbelleksiz yeniden işletir.
  - Skill ya da komut frontmatter'ında oturumdan farklı bir `model` yazmak da o tur için model değişimidir. Bu yüzden bu skill'de `model:` alanı yoktur.
  - `opusplan` kullanıldığında her plan modu geçişi bir model değişimidir.
  - Opus 5.5, Sonnet 5.5 ve Haiku 5.5'te effort değişimi önbelleği bozmaz (abonelik ya da API anahtarı ile).
  - Alt ajan kendi önbelleğini kurar ve abonelikte de 5 dakikalık TTL alır. Fork ise ana oturumun önbelleğini paylaşır.
  - Skill çağırmak önbelleği bozmaz; talimatlar sona eklenir.
- **Alt ajan modelinin belirlenme sırası** (sub-agents):
  1. Çağrıdaki `model` parametresi
  2. Ajan dosyasındaki `model`
  3. `CLAUDE_CODE_SUBAGENT_MODEL`
  4. Ana model

  `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` bütün bu düzeni ezer; bu projede kullanılmamalı.
- **Hazır Explore ajanı:** Artık ana modeli kullanır; ana model Opus ise arama da Opus'la yapılır. Bu yüzden aramalar Haiku'daki `kalan-kesif` ile yapılır.
- **Alt ajan ne zaman kullanılmaz** (sub-agents): sık gidip gelme gereken işler, aynı bağlamı paylaşan aşamalar, hızlı ve hedefli değişiklikler. Bunlar ana oturumda yapılır.
- **Danışman (`/advisor`, deneysel):** Ana model Sonnet, danışman Opus olduğunda Opus yalnızca karar anlarında çalışır. Danışman her çağrıda bütün konuşmayı önbelleksiz okur; uzun oturumda pahalılaşır. Odaklı bir istemle çağrılan `kalan-mimar` daha öngörülebilir maliyetlidir.
- **Effort:** 5.5 modellerinde varsayılan effort `medium`'dur. Anthropic, Opus 5.5'in `medium`'da Opus 5'in `high` düzeyine eşit ya da daha iyi olduğunu bildiriyor. `max` belgeye göre aşırı düşünmeye yatkındır ve kullanılmaz.

## Karar ağacı

1. Arama, okuma ya da doğrulama mı? → `kalan-kesif` / `kalan-kontrol` (Haiku)
2. Tek dosyada küçük değişiklik mi, ya da dosyalar zaten okundu mu? → ana oturum
3. Dosya listesi verilebilen bağımsız bir parça mı? → `kalan-uygulayici` (Sonnet). Birbirine bağlıysa → ana oturum
4. Büyük emek ya da riskli alan mı? → önce `kalan-mimar` (Opus) planı, sonda `kalan-mimar` incelemesi
5. Aynı hata iki kez düzelmedi mi? → `kalan-mimar` kök neden analizi
6. Bu konuşmanın bağlamına muhtaç bir yan iş mi? → fork (ortak önbellek)

Genel kural: Veritabanı şeması değişen her madde sonda `kalan-mimar` incelemesi alır.

## Madde tablosu

Kısaltmalar: **Plan M** = önce `kalan-mimar` planı. **İnc M** = bitirmeden `kalan-mimar` diff incelemesi. **Ana** = ana oturum uygular. **Uyg** = parçalar `kalan-uygulayici`'ye verilebilir. **Keşif** = önce `kalan-kesif` ile mevcut durumu kontrol et.

| No | Madde | Emek | Şerit | Not |
|---|---|---|---|---|
| 0 | Temel: palet, logo, para birimleri | Büyük | Plan M · Ana + Uyg · İnc M | Brif tam bir uygulama prompt'u içerir. Para birimi kaydı ve ARB adları Uyg'ye verilebilir. Migration testi şart. |
| 1 | Bildirim ve hatırlatmalar | Orta | Plan M · Ana · İnc M | iOS'ta en fazla 64 bekleyen bildirim olabilir; yeniden kurma mantığı riskli. |
| 2 | Devam eden planı ortasından ekleme | Küçük | Ana | |
| 3 | Gecikenler bölümü | Küçük | Ana · İnc M | Kalan hesabına etkisi var. |
| 4 | Bildirimden "ödendi" | Küçük | Ana | Arka plan işleyicisi; iki denemede olmazsa mimar. |
| 5 | Israrlı hatırlatma | Küçük | Ana | |
| 6 | "Sonra öde" tek ödemeli plan | Küçük | Ana | 1. soru cevaplı: sınıra sayılır. |
| 7 | Ödeme aralığı seçimi | Küçük | Ana · İnc M | Ay sonu ve tarih aritmetiği. |
| 8 | Toplam ya da taksit tutarıyla giriş | Küçük | Ana · İnc M | Yuvarlama; 0 ve 3 basamaklı birimler. |
| 9 | Ödeme şekli etiketi | Küçük | Ana | Şema değişiyorsa İnc M. |
| 10 | Maaş günü özeti | Küçük | Ana | |
| 11 | Pro satın alma | Orta | Plan M · Ana · İnc M | 1-3. sorular kararla cevaplı (tek seferlik, fiyat, yalnızca mağaza API'leri); 4 ve 5 sorulacak. |
| 12 | İleriki dönemlerin grafiği | Orta | Ana (+Uyg widget) | 1. ve 2. sorular cevaplı: herkese 6 dönem. |
| 13 | Takvim görünümü | Orta | Ana (+Uyg) | |
| 14 | Yoğun dönem işareti | Küçük | Ana | |
| 15 | Dönem açığı uyarısı | Küçük | Ana | |
| 16 | Kart bazında ekstre tahmini | Orta | Plan M · Ana · İnc M | Hesap kesim mantığı. |
| 17 | Hesap kesim öncesi uyarı | Küçük | Ana | |
| 18 | Hazır tutulacak tutar | Küçük | Ana | |
| 19 | İade, iptal, itiraz | Orta | Plan M · Ana · İnc M | 1. soru (sınıra sayılır mı) açık; sorulacak. |
| 20 | Taksit erteleme | Küçük | Ana · İnc M | Dönem kayması. |
| 21 | Gecikme ücreti kaydı | Küçük | Ana | |
| 22 | Taksit başı ücret | Küçük | Ana | |
| 23 | Faizli planlarda toplam | Küçük | Ana | |
| 24 | 14 dil, 22 yerel sürüm | Büyük | Plan M · altyapı Ana · diller Uyg (dil başına ayrık dosyalar paralel) · İnc M | Çeviriyi Haiku'ya verme (ton). Ana dili konuşan biri gözden geçirmeli. |
| 25 | Sağlayıcı şablonları | Orta | Ana + Uyg (veri dosyası) | |
| 26 | Resmî tatil kaydırması | Orta | Plan M · Ana · İnc M | Tarih kaydırma. |
| 27 | Biyometrik kilit | Küçük | Ana | |
| 28 | Tutarları gizleme | Küçük | Ana | |
| 29 | Dışa aktarma | Küçük | Plan M · Ana · İnc M | Yedek biçimi ve şifreleme 30. maddeyi bağlar. |
| 30 | Yedekten geri yükleme | Orta | Plan M · Ana · İnc M | Veri kaybı riski. |
| 31 | Ana ekran widget'ı | Orta | Plan M · Ana | Yerel iOS ve Android kodu, paylaşılan depo. |
| 32 | Kilit ekranı widget'ı | Küçük | Ana | |
| 33 | Widget'tan "ödendi" | Küçük | Ana | |
| 34 | Uygulama simgesi sayacı | Küçük | Ana | |
| 35 | "Dene" | Orta | Plan M · Ana · İnc M | Kaydetmeden simülasyon. |
| 36 | Erken ödeme | Küçük | Ana · İnc M | |
| 37 | Borç bitiş tarihi | Küçük | Ana | |
| 38 | Plan ilerleme çubuğu | Küçük | Keşif · Ana | Benzeri zaten olabilir. |
| 39 | Arama ve filtre | Küçük | Ana | Türkçe I/İ duyarsızlığı. |
| 40 | "Ödendi" notu | Küçük | Ana | |
| 41 | Değişken sabit ödemeler | Orta | Plan M · Ana · İnc M | Tarihli tutar değişikliği hesaba girer. |
| 42 | Yıllık sabit ödemeler | Küçük | Keşif · Ana · İnc M | Mevcut destek olabilir; tekrar kuralı. |
| 43 | Ekran görüntüsünden ekleme | Büyük | Plan M · Ana + Uyg (ayrıştırıcı testleri) · İnc M | Cihazda okuma, ağ yok. |
| 44 | Yapıştırılan metinden ekleme | Orta | Ana | 43'ün ayrıştırıcısı kullanılır; 1. soru: gerekli mi? |
| 45 | Telefon takvimine aktarma | Orta | Ana | |
| 46 | Maaşın ne kadarı bağlı | Küçük | Ana | 1. soru: yapılsın mı? |
| 47 | Web önizleme | Orta | Ana | 1. soru: yapılsın mı? |

## Kaynaklar

- https://code.claude.com/docs/en/costs
- https://code.claude.com/docs/en/prompt-caching
- https://code.claude.com/docs/en/sub-agents
- https://code.claude.com/docs/en/model-config
- https://code.claude.com/docs/en/advisor
- https://code.claude.com/docs/en/skills
