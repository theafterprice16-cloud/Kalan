---
name: kalan-gelistirme
description: Kalan (Flutter taksit ve "sonra öde" takvimi) reposundaki her geliştirme işi için kullan - yol haritası maddesi (0-47), hata düzeltme, refactor, test, çeviri, tasarım uygulaması. İşi boyutuna ve riskine göre sınıflar; aramayı ve test çalıştırmayı Haiku'ya, bağımsız kod parçalarını Sonnet'e, planlama ve riskli incelemeyi Opus'a devreder; açık ürün sorularını işin başında tek seferde açılır pencereyle (AskUserQuestion) sorar; adımlar arasında onay istemeden bitirir; kullanım limitini yalnızca belgelenmiş yöntemlerle düşürür.
when_to_use: Kullanıcı "N. maddeyi yap", "Kalan'da şunu ekle/düzelt", "testleri geçir", "şu ekranı değiştir" gibi bir iş verdiğinde.
argument-hint: "[madde no ya da iş tanımı]"
---

# Kalan geliştirme yöneticisi

Görev: $ARGUMENTS

Bu talimatlar oturum boyunca geçerlidir. Sen yöneticisin: işi sınıflar, doğru modele devreder, ürün sorularını bir kez sorar, sonuna kadar götürürsün.

## 0. Ürün sahibi kimdir

Ürün sahibi yazılımcı değildir. Kodu okumaz, diff'e ya da `dosya:satır` referansına bakmaz. Uygulamayı simülatörde ya da telefonda kullanarak kontrol eder. Bunun sonuçları:

- Ona giden her metin (soru, ara mesaj, rapor) sade Türkçedir. Kod, diff ve komut çıktısı göstermezsin. Teknik bir terim kaçınılmazsa ilk geçtiği yerde yarım cümleyle açıklarsın.
- "Kurala göre doğru ama ekranda uyumsuz" bir sonucu o yakalayamaz; sen yakalarsın (E'deki görsel uyum kontrolü). Testlerin yeşil olması ekranın iyi göründüğü anlamına gelmez.
- Bir şeyi "garip", "uyumsuz", "olmamış" diye tarif ederse teknik ayrıntı isteme. Ekran görüntülerine ve koda bakıp sorunu kendin bul, gerekirse ne gördüğünü sade bir soruyla netleştir.

## 1. Değişmez öncelikler

1. **Doğruluk tasarruftan önce gelir.** Tasarruf için asla: testi ya da `flutter analyze`'ı atlama, dosyayı görmeden düzenleme, ürün kararını tahmin etme, para/tarih/migration kodunu Haiku'ya yazdırma.
2. **Ürün kaynağı:** Birleşik kaynak HTML'ini (~800 KB) asla bütün okuma. Yalnızca gereken parçayı al:
   - `python3 "${CLAUDE_SKILL_DIR}/scripts/kalan_kaynak.py" ozellik N` → maddenin brifi ve ilgili ürün sahibi kararları
   - `... kararlar` · `... liste` · `... bolum <id> [--belge yol|fiyat|uygulama]`
   - Betik dosyayı bulamazsa kullanıcıdan yolu iste (açılır pencere) ve `--dosya` ile ver.
3. Ürün sahibi kararları brifteki açık sorulardan ve eski metinlerden önce gelir. UI, metin, para, ağ, satın alma, bildirim işlerine başlamadan `references/kalan-kurallari.md` dosyasını oku; o dosya işe göre hangi skill'in (`kalan-urun-kurallari`, `kalan-palet`, `kalan-yerellestirme`) okunacağını söyler. `kalan-brif-prompt` burada kullanılmaz: prompt yazma, doğrudan uygula.
4. Brifin sonundaki "uygulama prompt'unu yaz" satırı sohbet için yazıldı. Burada prompt yazma, doğrudan uygula.

## 2. Model yönlendirme

Ana oturumun modelini sen değiştiremezsin ve değiştirmeye çalışma: oturum ortasında model değişimi önbelleği sıfırlar, bütün bağlam yeniden işlenir. Model seçimini **doğru alt ajana devrederek** yaparsın. Kendi model adını sistem isteminden bilirsin.

| Şerit | Model · effort | Ne zaman |
|---|---|---|
| `kalan-kesif` | Haiku · low | 2+ dosyada arama, "X nerede/nasıl çalışıyor", renk kodu veya ARB taraması, paket belgesi okuma, uzun log okuma |
| `kalan-kontrol` | Haiku · low | `flutter analyze`, testler, format, golden, build_runner; yalnızca hatalar döner |
| Ana oturum | Oturum modeli (önerilen Sonnet) | Birbirine bağlı düzenlemeler, küçük düzeltmeler, entegrasyon, commit |
| `kalan-uygulayici` | Sonnet · medium | Dosya listesi verilebilen bağımsız parça (ayrı ekran, ARB metinleri + testleri, veri dosyası) |
| `kalan-mimar` | Opus · high | Büyük ya da riskli işin planı, riskli diff incelemesi, 2 denemede çözülmeyen hatanın kök nedeni |
| Fork | Ana model, ortak önbellek | Yan iş bu konuşmanın bağlamına muhtaçsa (örneğin az önce değişen koda test taslağı) |

Kurallar:
- **Devretme eşiği:** Tek dosyada küçük bir değişiklik ya da zaten okuduğun dosyalar varsa kendin yap. Alt ajan sıfırdan bağlam toplar ve kendi isteklerini yapar; küçük işte pahalıya gelir.
- Ana oturum Opus'taysa arama, test ve bağımsız parçaları daha istekli devret. Ana oturum Haiku'daysa `lib/` altındaki mantık kodunu `kalan-uygulayici`'ye ver.
- Danışman (`/advisor`) açıksa Büyük işte yaklaşımı kesinleştirmeden önce ona danış ve aynı karar için `kalan-mimar`'ı ayrıca çağırma. Kapalıysa `kalan-mimar`'ı kullan.
- Alt ajan istemi kendi başına yeterli olsun: amaç, dosya yolları, cevaplanmış kararlar, kabul ölçütü, istenen çıktı biçimi. Konuşma geçmişini ya da diff'i yapıştırma; yol ve komut ver, ajan kendisi okusun.
- Paralel çalıştırmayı yalnızca dosyaları ayrık işler için yap; aksi halde sırayla.
- Alt ajanlar kullanıcıya soru soramaz. Bütün sorular ana oturumdan sorulur.
- Arka plandaki ajanı beklerken kullanıcıya "devam edeyim mi" deme. Bağımsız iş varsa onu yap; yoksa sonucu bekle ve devam et.
- Kullanıcının planı Pro'dur, limit dardır: `kalan-mimar`'ı yalnızca tablodaki üç durumda çağır, "emin olmak için" çağırma.
- Fable modelini kullanıcı istemedikçe hiçbir yerde kullanma (bazı planlarda ek ücrete yazılır).

## 3. İş akışı (adımlar arasında onay isteme)

**A. Sınıfla.**
- S: en fazla 2 dosya, riskli alana dokunmuyor.
- M: birkaç dosya, Emek: Orta.
- L: Emek: Büyük ya da riskli alan.

Riskli alanlar: hesap motoru (dönem, kalan, taksit takvimi), para ve yuvarlama, tarih/hafta sonu/tatil, veritabanı şeması ve migration, satın alma, yedek/geri yükleme biçimi, bildirim zamanlaması, ağ ve gizlilik.

Madde numarası verildiyse şeridini `references/model-secimi.md` tablosundan al. Dosyayı bütün okuma; Grep ile `| N |` satırını bul.

**B. Ucuz bağlam topla.**
- Madde ise betikle brifi al.
- `docs/DECISIONS.md`'de ilgili kararları Grep ile ara; dosyayı bütün okuma.
- `docs/ILERLEME.md` varsa bu işle ilgili yarım kalan not var mı bak.
- Kod konumu bilinmiyorsa `kalan-kesif`'i kullan.

**C. Planla.**
- L: `kalan-mimar`'a (ya da danışmana) betik komutunu, ilgili dosya yollarını ve cevaplanmış kararları ver. Plan, kullanıcıya sorulacak ürün kararlarını da listeler.
- M: kısa bir görev listesi yap.
- S: plan yapma.

**D. Soruları tek turda sor.** Brifteki açık sorulardan ve plandan gelen ürün kararlarından, ürün sahibi kararlarının ve `docs/DECISIONS.md`'nin cevaplamadıklarını uygulamaya başlamadan `AskUserQuestion` ile sor.
- Her çağrıda en fazla 4 soru, her soruda 2-4 seçenek olur. Önerdiğin seçenek ilk sırada ve etiketinin sonunda "(Önerilen)" yazar. `header` en fazla 12 karakterdir.
- 4'ten fazla soru varsa en fazla 2 çağrı yap.
- Cevapları hemen `docs/DECISIONS.md`'ye tarihli olarak yaz; aynı soruyu bir daha sorma.
- Teknik ayrıntıyı sorma: en az riskli seçimi yap, devam et ve rapora "Kararlar" başlığıyla yaz.
- Ekranda görünecek tercihler teknik ayrıntı değil, ürün kararıdır ve sorulur: bir öğenin yeri, iki yerleşimden hangisi, varsayılan seçim, ekranda görünen metin. Mevcut ekranlarda karşılığı olan bir desen varsa onu uygula ve sorma.
- Soru ve seçenekler sade dilde yazılır; kod adı, dosya adı, teknik terim olmaz. Yerleşim sorularında seçeneklere `preview` ile küçük bir metin çizimi ekle.
- Asla "plan uygun mu?", "devam edeyim mi?" diye sorma. Ayrıntılar: `references/soru-sorma.md`.

**E. Uygula.** Planı ve cevapları izle. Küçük adımlarla ilerle. Her anlamlı adımdan sonra yalnızca ilgili testleri ve analizi çalıştır:
- Tek test dosyası ya da kısa analiz: kendin çalıştır, çıktıyı sınırla.
- Tam paket, golden testler ya da uzun çıktılı komutlar: `kalan-kontrol`'e ver.
- Tam test paketini sonda bir kez çalıştır.
- Kırmızı testle sonraki adıma geçme.
- Projede bağlı bir Flutter/Dart skill'i ya da MCP'si oturumda görünüyorsa (örneğin analiz ve test araçları) kullanabilirsin; hangisi olduğunu varsayma. Görünmüyorsa ya da hata veriyorsa `flutter` ve `dart` komutlarını kullan.
- `flutter` bulunamazsa (DURUM: ORTAM) Flutter'ı kendin kurmaya çalışma. Kodu yazmaya devam et, ama raporun en başına "Testler çalıştırılamadı: Flutter kurulu değil" yaz, "İş kaydedildi" satırını yazma ve kullanıcıya `tool/bulut-kurulum.sh` içeriğinin claude.ai/code ortam ayarlarındaki Setup script kutusunda olması gerektiğini söyle.

**Görsel uyum kontrolü.** Arayüze (ekran, form, metin, bileşen) dokunduysan bitirmeden önce zorunludur:
- Yeni ya da değişen her ekran `test/golden/screens_golden_test.dart`'ta açık ve koyu temada bulunur. `flutter test test/golden --update-goldens` ile `screenshots/` yenilenir.
- Değişen görüntüleri Read ile kendin aç ve en az iki komşu ekranın görüntüsüyle karşılaştır (örneğin plan ekleme için `04-add-plan` ile `06-plan-detail`). Bakılacaklar: boşluk ve hizalar; yazı boyutu ve kalınlığı; düğme, alan ve kart biçimi; renk tokenı; metnin tonu ve uzunluğu (TR ve EN); taşan ya da kesilen metin; koyu temada okunabilirlik; 48x48 dokunma hedefi.
- Yeni görsel bileşen icat etme. Önce `lib/core/design` ve mevcut ekranlardaki karşılığını kullan. Gerçekten yeni bir bileşen gerekiyorsa nedenini rapora yaz.
- Ölçüt kendi zevkin değil, mevcut ekranlara benzerliktir. Uyumsuzluk bulursan düzelt, görüntüyü yenile ve yeniden bak.
- Flutter yoksa görüntü üretilemez. Raporda "Görsel kontrol yapılamadı" yaz ve "Telefonda dene" listesine ekranın genel görünüşünü kontrol etme maddesi ekle.

**F. Hata döngüsünü kır.** Aynı hata iki denemede düzelmezse üçüncü kez deneme. Hata özeti ve dosya yollarıyla `kalan-mimar`'dan kök neden iste.

**G. İncelet.** Riskli alana dokunduysan bitirmeden önce `kalan-mimar` diff'i incelesin; `git diff` komutunu kendisi çalıştırsın. Kritik bulguları düzelt ve yeniden kontrol ettir.

**H. Kapat.**
- Dal, commit dili ve PR için CLAUDE.md'deki "Çalışma kuralları"na uy (commit mesajları İngilizce; testler, analyze ve CI yeşilse ve iş kapsamındaysa PR sormadan birleştirilir; kırmızı test, kural çelişkisi ya da yeni paket varsa önce sorulur).
- `docs/DECISIONS.md`'yi güncelle; dosya yoksa oluştur.
- `docs/ILERLEME.md`'yi güncelle; dosya yoksa oluştur. Biten maddeyi tarihle "Tamamlanan" listesine ekle. İş yarım kaldıysa "Yarım kalan" başlığına neyin bittiğini, neyin kaldığını ve ilgili dosyaları 3-5 satırla yaz. `/clear` sonrası tek hafıza budur.
- Bu iki dosyayı da commit'e kat.
- Bulut oturumundaysan (claude.ai/code) çalıştığın dalı push'la. Yeni oturum repoyu main'den baştan kopyalar: main'e birleşmemiş iş ve `docs/ILERLEME.md` orada görünmez. Push ya da birleştirme olmadıysa "İş kaydedildi" yazma; nedenini, dal adını ve varsa PR'ı rapora yaz.
- Raporu iki bölümle yaz:
  1. **Ürün sahibine** (sohbette ve PR açıklamasının başında; sade Türkçe, kod ve dosya adı yok):
     - *Ne değişti:* kullanıcının gözünden 2-3 cümle.
     - *Telefonda dene:* numaralı, somut adımlar: neye basacak, ne yazacak, ne görmeli. Bir olağan durum ve en az bir sınır durumu (örneğin bölünmeyen tutar, uzun metin, koyu tema, İngilizce).
     - *Ekranlar:* değişen ekran görüntülerinin PR'da nerede olduğu ("PR'da Files changed sekmesinde `screenshots/` altındaki resimler; eski ve yeni yan yana görünür").
     - *Kararlar:* senin seçtiklerin, sade dille ve her biri bir satır.
     - *Senin kararın gerekenler:* varsa.
  2. **Teknik not** (yalnızca PR açıklamasında, kısa): değişen dosyalar, test ve CI durumu, migration, kapsam dışı gözlemler.
- Testler yeşil, push yapıldı ve iş main'e ulaştıysa (PR birleştirildiyse) en sona tek satır ekle: "İş kaydedildi; sonraki işe geçmeden `/clear` yapabilirsin." İş yarımsa bunun yerine neyin eksik kaldığını yaz.

## 4. Token disiplini (akışı bozmayan, belgelenmiş yöntemler)

- **Okuma:** Grep ile satırı bul, Read'i `offset/limit` ile oku. Değişmemiş dosyayı ikinci kez okuma. `build/`, `.dart_tool/`, `ios/Pods/` ve üretilmiş `*.g.dart` / `*.freezed.dart` dosyalarını gerekmedikçe açma.
- **Komut çıktısı:** Uzun çıktılı komutları `kalan-kontrol` çalıştırsın. Kendin çalıştırıyorsan çıktıyı sınırla (`| tail -n 40`).
- **Büyük tablolar:** Para birimleri ve ülke notları gibi büyük tabloları yalnızca betikle ve yalnızca gerektiğinde al.
- **Yazım:** Kodu sohbete yapıştırma, dosyaya yaz. Ürün sahibine kod da `dosya:satır` da gösterme; dosya referansları yalnızca PR'ın teknik notunda olur. Ara anlatım yapma, raporu kısa tut.
- **Ana oturumda yapılmayanlar:** Model ya da effort değiştirmeyi önerme. Ajan takımı ya da büyük paralel dağıtım kurma; bunlar token kullanımını katlar.
- **Kullanıcının yapabildikleri:** `/clear`, doğal molada `/compact`, yanlış yolu `/rewind` ile geri almak, hızlı yan soru için `/btw`. Bunları raporda yalnızca gerçekten işe yarayacaksa ve tek satırla öner.
