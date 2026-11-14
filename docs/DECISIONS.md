# Kararlar

Kimlik dosyasında ya da ilk prompt'ta cevabı olmayan, 12 Kasım 2026'daki plan onayında kabul edilen kararlar. Bir kararı değiştirirsen bu dosyayı ve ilgili testi birlikte güncelle.

## Ürün

| # | Konu | Karar |
|---|---|---|
| 1 | Paket kimliği | Geçici olarak `app.kalan.mobile` (iOS Bundle ID ve Android applicationId). Kimlik dosyasının önerdiği `kalan.app` alan adından türetildi. Mağazaya ilk yüklemeden önce kesinleştir; yüklemeden sonra değiştirilemez. |
| 2 | Vadesi geçmiş, ödenmemiş ödeme | **Değiştirildi (13 Kasım 2026):** ödenmemiş ve günü geçmiş ödeme, hangi dönemden gelirse gelsin içinde bulunulan dönemin söz verilmiş tutarına girer ve "Günü geçenler" bölümünde listelenir ("Günü geçenler" bölümüne bak). Eski kural: kendi döneminde kalır, bu döneme eklenmezdi. |
| 3 | Maaş günü hafta sonuna denk gelirse | Dönem yine o gün başlar (kaydırma yok). |
| 4 | Ekstre günü yapılan alışveriş | O günün ekstresine girer (alışveriş günü ≤ ekstre günü). |
| 5 | Kuruş artığı | `taban(toplam / n)` her ödemeye; artan kuruş ilk ödemeye eklenir. |
| 6 | Tek ödemenin tutarı düzeltilince | Fark, sonraki ödenmemiş ve elle düzeltilmemiş ödemelere eşit dağıtılır (artık kuruş ilkine). Böyle ödeme yoksa ya da bir ödeme 0 veya altına düşecekse düzeltme yapılmaz. Plan toplamı değişmez. |
| 7 | Plan adı | İsteğe bağlı; boşsa kaynak adı gösterilir. Şablon ekranında "Ayrıntı ekle" altında katlı durur, dört alana sayılmaz. |
| 8 | Aylık taksit şablonu | Toplam tutar ve taksit sayısı sorulur. (Eski not: taksit tutarıyla giriş "Yarıda başlayan plan"daydı; o tür 13 Kasım 2026'da "Bu plan zaten sürüyor" anahtarıyla değiştirildi, aşağıya bak.) |
| 9 | Plan ne zaman biter | Bütün ödemeleri "ödendi" olunca arşive geçer. Tarihin geçmesi tek başına yetmez. |
| 10 | Sıkışık dönem | Eşik varsayılan olarak boş (kapalı). Kalan < eşik ise ana ekranda kehribar işaret ve "Sıkışık dönem" metni. Gelir girilmemişse hesaplanmaz. Eksiye düşen dönem mercan ve metinle gösterilir; sıkışık dönemden önceliklidir. |
| 11 | Sabit ödeme | Tekrar: haftalık, iki haftada bir, aylık, yıllık. Tutar zorunlu (değişken faturada kullanıcı bildiği tutarı girer, uygulama tahmin üretmez). Bitiş tarihi isteğe bağlı. Her tekrar için "ödendi" işareti var. Ücretsiz sınıra sayılmaz. |
| 12 | Kartın ekstre ya da son ödeme günü değişirse | O karta bağlı kart taksidi planlarında ödenmemiş ve elle düzeltilmemiş ödemelerin tarihleri yeniden hesaplanır. |
| 13 | Ücretsiz sınır | 4 açık plan. 5. plan eklenmek istenince sakin bir bilgi gösterilir, ekleme yapılmaz. Satış dili yok. Debug derlemede Ayarlar'da Pro anahtarı var. |
| 14 | Dışa aktarma | Ücretsiz (kimlik B bölümü bağlayıcı: "dışa aktarma her zaman açıktır"). A bölümündeki gelir modeli tablosu bununla çelişiyordu. |
| 15 | İleri bakış | Pro (kimlik A · Gelir modeli). |
| 16 | Kalan sayısının rengi | Gece & Nane: artıda mintText (açık #0E7A53, koyu #3DDC97), eksi dönemde amberText. Bkz. docs/DESIGN_TOKENS.md. |
| 17 | İkincil metin | textMuted (açık #5B6673, koyu #9AA5B1). |
| 17a | Dönem çubuğu | Söz verilmiş chartCommitted, kalan mint, eksi dönemde aşan kısım amber. |
| 17b | Form hataları ve silme | coral (yalnızca gecikme, hata ve geri alınamaz silme). |
| 18 | Dil | Varsayılan sistem dili; TR değilse EN. Ayarlar'dan değiştirilebilir. iOS `Info.plist` içindeki `CFBundleLocalizations` yalnızca `tr` ve `en` listeler; iOS dili uygulamaya bu listeyle iletir. Diğer 8 dilin çevirileri `docs/ceviriler-beklemede/` altında bekliyor. |
| 19 | Para birimi değişimi | Ayarlar'dan; önce "Tutarlar çevrilmez, yalnızca para birimi etiketi değişir" uyarısı ve örnek önizleme (₺1.234,56 → Rp1.235) gösteren onay penceresi. Kur çevirisi yok. Ondalık sayısı farklıysa saklanan bütün tutarlar (ödemeler, sabit ödemeler, gelir, eşik) tek işlemde yeni üsse ölçeklenir; azalan ondalıkta yarım yukarı yuvarlanır. Ödeme ve sabit ödeme tutarı en az 1 birim kalır (şema 0'a izin vermez). |
| 20 | Tutar biçimi | Tek biçimlendirici `formatMoney` (lib/core/money). Sembolün yeri, ayraçlar ve boşluk uygulama dilinden (intl), sembol ve ondalık sayısı para biriminden gelir: tr ₺1.234,56 · de 1.234,56 € · pt R$ 1.234,56 · id Rp1.234.567. Kuruşsuz tutarlarda ondalık gösterilmez (₺3.250). intl sembolü bölünmez boşlukla bağlar; tutar satır sonunda bölünmez. Kimlik dosyasındaki "3.250 TL" örneği bu kararla eskidi (kullanıcı onayı, 12 Kasım 2026). Tutar tam sayı kalır: intl yalnızca tam kısmı biçimler, kuruş tam sayıdan eklenir. Diğer dillerdeki örnekler biçimlendiricinin yeteneğini gösterir; uygulama şimdilik yalnızca tr ve en ile açılır (Almanca telefonda €1,234.56). |
| 21 | Maaş günü girişi | Aylık: ayın günü (1-31; ay kısaysa son güne sıkışır). İki haftada bir: son maaş tarihi. Haftalık: haftanın günü. Net tutar bir maaşın tutarıdır. |
| 22 | 4 ödemeli plan | İlk ödeme alışveriş günü; sonra 14 günde bir, toplam 4 ödeme. |
| 23 | Kart taksidi tarihi | Ödeme tarihi, taksidin düştüğü ekstre tarihinden sonraki ilk son ödeme günüdür (aynı gün sayılmaz). Hafta sonu kaydırması kart başına ayar, varsayılan açık; cumartesi ve pazar pazartesiye kayar. Resmi tatiller BACKLOG'da. |
| 24 | Yarıda başlayan plan | **Değiştirildi (13 Kasım 2026):** ayrı plan türü kaldırıldı; yerine her türde "Bu plan zaten sürüyor" anahtarı var ("Devam eden planı ortasından ekleme" bölümü). Eski kural: kalan taksit sayısı girilir, yalnızca kalan ödemeler kaydedilirdi. Bu yolla eklenmiş planlar olduğu gibi çalışmaya devam eder. |
| 24a | Sabit ödemelerin geçmiş tekrarları | "Günü geçenler" bölümünde gösterilmez ve bu döneme taşınmaz (yalnızca plan ödemeleri). Aksi hâlde başlangıçtan bu yana işaretlenmemiş her kira satırı listeyi doldururdu. Bu dönemin günü geçmiş sabit ödemesi dönem listesinde kalır ve "x gün önce" notunu taşır. |
| 24b | Yaklaşan ödeme | Ödenmemiş ve bugün ya da yarın olan ödemede kehribar nokta ve "Bugün"/"Yarın" metni. |
| 25 | Ödenmiş ödemenin düzeltilmesi | Ödenmiş ödeme düzeltilemez; önce "ödenmedi" yapılır. |

| 26 | Uygulama ikonu | Kullanıcının K logosu, Gece & Nane renkleriyle yeniden çizildi: zemin #0B0F14, gövde #F2F5F7, üç parça #3DDC97. Geometri orijinal çizimden ölçüldü; kaynak `assets/brand/kalan_icon.svg`, üretici `tool/generate_icons.py`, platform ikonları `flutter_launcher_icons`. Orijinal çizim `docs/kimlik/logo-ilk-renkler.png` olarak tarihçede. |
| 27 | Açılış ekranı | Android ve iOS: #0B0F14 zemin (açık ve koyu modda aynı), ortada işaret. |
| 28 | Para birimleri | 17 birim: TRY, USD, EUR, GBP, BRL, MXN, COP, CLP, RUB, KZT, CNY, SGD, MYR, IDR, CAD, AUD, CHF. Tek kaynak `lib/core/money/currency.dart`. Veritabanında ISO kodu (metin) saklanır; şema değişmedi. |
| 29 | IDR ve COP ondalığı | ISO 4217 iki hane der, ama günlük hayatta kuruş (sen, centavo) kullanılmıyor ve fiyatlar tam sayı. Uygulamada 0 ondalık: gösterimde ondalık yok, girişte ondalık tuşu çıkmaz ve ondalık reddedilir. CLP de 0. |
| 30 | Paylaşılan $ işareti | MXN, COP, CLP, CAD, AUD, SGD: cihaz bölgesi para biriminin ülkesiyse yalın $, değilse MX$, COL$, CLP$, CA$, A$, S$. USD her yerde $. Bölge uygulama dilinden bağımsızdır (cihaz bölgesi). |
| 31 | Varsayılan para birimi | Kurulumda cihaz bölgesine göre önerilir (euro bölgesi dahil); eşleşme yoksa USD. Liste aranabilir: kod, sembol ve uygulama dilindeki ad ile. |
| 32 | Tutar girişi | Ayraçlar uygulama diline göre. Gruplama ayracı yalnızca üçlü gruplarda kabul edilir; Türkçede "62.5" 625 diye okunmaz, reddedilir. fr ve ru'da boşluk gruplaması serbest. |

## Teknik

| Konu | Karar |
|---|---|
| Material | Flutter 3.50'de Material, resmi `material_ui` paketi olarak geliyor (`package:flutter/material.dart` kullanımdan kalktı). Şablonun eklediği bu paket korunuyor. |
| Paketler | `flutter_riverpod` (durum), `drift` + `drift_flutter` (SQLite; drift_flutter dosya yolunu ve SQLite kütüphanesini sağlar), `go_router` (yönlendirme), `flutter_localizations` + `intl` (ARB ve yerel biçim). Geliştirme: `build_runner` + `drift_dev` (Drift kod üretimi ve göç testi). Lint için ek paket yok: `flutter_lints` + sıkı analizör ayarları. Hiçbiri çalışma anında ağ isteği yapmaz. |
| Kod üretimi | Riverpod kod üretimi kullanılmıyor (sadelik). Drift'in ürettiği `*.g.dart` dosyaları commit edilir; böylece depo çekildiği gibi çalışır. |
| Tarih | `LocalDate` (yıl, ay, gün), veritabanında epoch günü (`int`). Saat dilimi ve yaz saati sorunları yok. |
| Ödemeler | Plan kaydedilirken üretilip saklanır (her seferinde yeniden hesaplanmaz), böylece elle düzeltmeler kalıcıdır. |
| Ağ izni | Ana `AndroidManifest.xml`'de INTERNET izni yok (testle denetlenir). `debug` ve `profile` manifest'lerindeki izin Flutter'ın geliştirme araçları (hot reload) için zorunlu ve yayın derlemesine girmez. |
| İkon üretimi | `tool/generate_icons.py` yalnızca geliştirmede çalışır ve Pillow ister; uygulamanın bağımlılığı değildir. |
| SQLite derlemesi | `sqlite3` 3.x paketi (drift_flutter üzerinden) derleme sırasında hazır SQLite ikilisini GitHub'dan indirir ve SHA-256 ile doğrular. Bu yalnızca derleme anıdır; uygulama çalışırken ağ kullanılmaz. |
| Şema | Drift `schemaVersion` 3 (v2 ve v3: hatırlatmalar). Şema anlık görüntüsü `drift_schemas/`, göç testleri `test/drift/`. Yabancı anahtarlar açık; plan silinince ödemeleri silinir, planı olan kaynak silinemez. |


## Palet: Gece & Nane (12 Kasım 2026)

| Konu | Karar |
|---|---|
| Eski palet neden bırakıldı | Lacivert-krem palet (mürekkep #14213D, kâğıt #F7F5F0, yeşil #23B58E, mercan #E4572E, kehribar #F2A541) yalnızca açık tema için düşünülmüştü: koyu temada duman ve mürekkep yetersiz kontrast verdi, ek tonlar (inkRaised, smokeLight vb.) gerekti. Yeşil açık zeminde metin olarak okunmadı (2,4:1). Eksi dönemin mercanla gösterilmesi "kırmızı alarm" hissi veriyordu. Gece & Nane koyu tema öncelikli, ölçülmüş kontrastlı tek bir token setidir; eksi dönemi sakin amber ile, gerçek sorunları (gecikme, hata, silme) coral ile ayırır. |
| Tek kaynak | `KalanColors` ThemeExtension (`lib/core/theme`). Başka yerde renk yazılmaz; bekçi test yakalar. |
| Eksi dönem metni | "Bu dönem ₺X eksik kalıyor." korunur (çeviri değişmez), rengi textMuted, ikonu amberText. |
| "Gecikti" rozeti | Ödenmemiş ve tarihi bugünden önce olan her ödemede coral ikon + "Gecikti/Overdue" metni (ana ekran ve plan ayrıntısı). "Ödenmemiş" bölümünün tanımı (DECISIONS 2) değişmedi. |
| Tema seçimi saklama | `shared_preferences` (Flutter ekibinin paketi; cihazda saklar, ağ kullanmaz). Veritabanına sütun eklenmedi; görüntü tercihi kullanıcı verisi değildir. |
| flutter_launcher_icons | Yalnızca geliştirme bağımlılığı; uygulamaya girmez, ağ kullanmaz. Ürettiği hatalı Xcode ayarı geri alınır ve testle korunur. |
| Karartma | `bg` %60 opaklık; yeni ton sayılmaz. |
| Golden testleri | Flutter SDK'daki Roboto ile çizilir; CI aynı SDK sürümünü kullanır. Test yazı tipinde "→" karakteri olmadığı için önizleme penceresinde kutu görünür; cihazda sistem yazı tipi çizer. |

## Hatırlatmalar (13 Kasım 2026, ikinci sürüm)

Bu bölüm aynı günün ilk hatırlatma kararlarının yerini alır. Ürün sahibiyle netleşen kararlar: iki bildirim ("önceden" ve "gününde"), tek "kaç gün önce" seçimi, dokununca ana ekran. "Bildirimde Ödendi düğmesi yok" kararı 13 Kasım 2026'da değişti: bkz. "Bildirimden ödendi".

| Konu | Karar |
|---|---|
| Kapsam | Yalnızca yerel bildirim (`flutter_local_notifications`). Sunucu, push servisi, Firebase, hesap, analiz ve internet yok. Ücretsiz sürümde tam çalışır, Pro'ya bağlı değildir. |
| İki bildirim | Her ödeme için biri "kaç gün önce" ("önceden"), biri ödeme günü ("gününde"). Önceden bildirimi hiçbir zaman ödeme gününe düşmez (en az 1 gün). |
| Kaç gün önce | Seçenekler 1, 2, 3, 5, 7; varsayılan 2 (bazı sağlayıcılar parayı bir gün erken çekiyor). Genel ayarı plana uygulayan tek fonksiyon `defaultLeadDaysFor` (`lib/core/reminders/reminder_models.dart`); elle/otomatik ödeme ayrımı geldiğinde yalnızca orası değişir. |
| Saat | Varsayılan 09:00, Ayarlar'dan değişir (sistem saat seçici, dilin 12/24 saat biçimi). Kuruluma adım eklenmedi. Yerel saat diliminde hesaplanır; yaz saati geçişinde 09:00 yine 09:00'dır. |
| Tutar | Varsayılan görünür. "Bildirimde tutarı göster" kapalıyken metinde tutar olmaz (kilit ekranı gizliliği). Ayar tek gizlilik servisinde (`PrivacySettings`); veritabanında `hideAmountsInNotifications` sütunu olarak (tersi) duruyor. |
| Birleştirme | Aynı gün ve aynı türdeki bildirimler tek bildirimdir; gruplama tetiklenme gününe göre yapılır. Farklı "kaç gün önce" seçen planlar aynı güne düşerse tek "önceden" bildirimi olur ve metin en erken tarihi söyler ("13 Kasım Perşembe gününden itibaren 2 ödeme var"). Tek para birimi olduğu için toplam yazılır; plan adları genişletilmiş gövdede (Android BigText, iOS uzun gövde) virgülle sıralanır. |
| 60 sınırı | iOS en çok 64 bekleyen bildirim tutar; tarih sırasına göre en yakın 60 kurulur. Android'de de aynı kural, tek kod yolu. |
| Kimlikler | `tetiklenme günü (epoch) × 2 + tür`. Deterministik: yeniden kurma çift bildirim üretmez. Ertelenmiş bildirimler `2^30 + erteleme kaydı`; debug deneme bildirimleri 2147480000 ve 2147480001. |
| Saf Dart planlayıcı | `lib/core/reminders`: ödemeler (etkin tarihleriyle), genel ayarlar, plan seçimleri, şimdiki an (saat dilimiyle) ve metin üreticisi (dil) → sıralı bildirim listesi (kimlik, an, başlık, gövde, genişletilmiş gövde, payload). Metinleri `L10nReminderTexts` ARB'den, tarihi intl'den (`MMMMEEEEd`: "14 Kasım Cuma", "Friday, November 14"), tutarı ortak para biçimlendiricisinden üretir. |
| Tarih kaynağı | Hesap motorunun ürettiği ve veritabanında saklanan etkin son ödeme günü (kart hesap kesimi ve hafta sonu kaydırması uygulanmış). Bildirim, ekrandaki günle aynıdır; bildirim kodu tarih hesaplamaz. |
| Hariç tutulanlar | Ödenmiş ödemeler, "Kapalı" planlar, ana anahtar kapalıyken her şey, tetiklenme anı geçmiş bildirimler (geçmiş "önceden" bildirimi atlanır, "gününde" yine kurulur). Uygulamada plan arşivi yok; bitmiş planların ödemeleri zaten ödenmiş olduğundan hariçtir. |
| Plan bazında | Plan ayrıntısında ve sabit ödeme düzenleme ekranında "Hatırlatma": Genel ayar (varsayılan) / Kapalı / Farklı gün (1, 2, 3, 5, 7). Saat her zaman genel ayardan. Plan ekleme ekranına eklenmedi (yirmi saniye kuralı: en çok dört alan). |
| Yeniden kurma | Her çalışmada Kalan'ın bekleyen bildirimleri iptal edilir ve liste baştan kurulur (gösterilmiş bildirimler bildirim merkezinde kalır). Tetikleyiciler: uygulama açılışı, ön plana dönüş (saat dilimi de yenilenir), plan ekleme/düzenleme/silme, "ödendi" ve geri alma, sabit ödeme değişiklikleri, hatırlatma ayarları, dil ve para birimi değişikliği (veritabanı akışları tek merkezden, `ReminderSync`); Android'de yeniden başlatma, saat ve saat dilimi değişimi (`ReminderRescheduleReceiver`, uygulama açılmadan arka planda Dart). Art arda gelen değişiklikler 300 ms beklemeyle tek çalışmada toplanır; arayüz beklemez. |
| Android zamanlama | Kesin olmayan (`inexactAllowWhileIdle`) zamanlama. `SCHEDULE_EXACT_ALARM` ve `USE_EXACT_ALARM` istenmez: Google Play bu izinleri hatırlatma uygulamalarında kısıtlıyor; birkaç dakikalık kayma kabul edildi. Eklentinin önyükleme alıcısı ve `RECEIVE_BOOT_COMPLETED` ile bildirimler yeniden başlatmada korunur. |
| Android kanalı ve ikon | "Ödeme hatırlatmaları", varsayılan önem. Küçük ikon `ic_stat_kalan`: logonun beyaz silueti, şeffaf zemin, şekil değişmeden. Vurgu rengi `KalanColors.light.accent` (DESIGN_TOKENS accent, #1D4E89); kodda kaynağı yorumla belirtildi. |
| iOS | İzin alert, sound ve badge için. Uygulama ön plandayken de bildirim görünür (`UNUserNotificationCenter` delegesi ve sunum seçenekleri). Uygulama ikonu kullanılır. |
| İzin akışı | Uygulama açılışında sorulmaz. İlk plan kaydedildikten hemen sonra Kalan'ın alt sayfası: "Hatırlatmaları aç" sistem iznini ister, "Şimdi değil" kapatır. Sayfa bir kez gösterilir; "Şimdi değil", kaydırarak kapatma ya da sistem reddi tekrar sorulmaz. Hatırlatmalar açık kalır; izin kapalıyken Ayarlar > Hatırlatmalar'da "Bildirim izni kapalı" satırı ve "Ayarları aç" düğmesi görünür. Sistem zaten izin veriyorsa (Android 12 ve altı) sayfa gösterilmez. Sabit ödeme izin sormaz. |
| "Ödendi" düğmesi | ~~Bildirimde yok.~~ Değişti (13 Kasım 2026): bildirimde "Ödendi" / "Hepsi ödendi" ve erteleme düğmeleri var; bkz. "Bildirimden ödendi". |
| Dokunma | Bildirime dokununca ana ekran açılır (go_router); uygulama kapalıyken de uygulama ana ekranda başlar. Önceki sürümdeki "Günün ödemeleri" ekranı kaldırıldı. |
| Kayıt | Drift şema v3: genel `reminderLeadDays` (varsayılan 2), plan ve sabit ödemede `reminderLeadDays` (boş = genel ayar) ve mevcut aç/kapa sütunu. v2'nin ayrı gün sütunları kaldırıldı. Geçişte mevcut planlar "Genel ayar" olur; v1 ve v2'den geçiş testli. |
| Deneme bildirimi | Yalnızca debug derlemede (`kDebugMode`) Ayarlar > Hatırlatmalar'ın altında "Deneme bildirimi (10 saniye sonra)". Yayın derlemesinde derlenmez. |
| Web | Bildirim kodu web'de çalışmaz; Ayarlar'da "Bu özellik telefonda çalışır" yazar. |
| Renk | Ayarlar'da seçili seçenek ve açık anahtar, DESIGN_TOKENS kuralı gereği mürekkep (`text`) rengindedir; prompt "accent" diyordu, bağlayıcı belge kazandı (accent yalnızca "kalan" için). Seçili seçenekte onay işareti de vardır. |
| Paketler | `flutter_local_notifications` 23.0.1 (yerel bildirim), `timezone` 0.11.2 (yaz saati doğru yerel saat), `flutter_timezone` 5.1.1 (cihazın saat dilimi adı). Hepsi kararlı, bakımı süren sürümler; hiçbiri ağ kullanmaz. Sistem ayarlarını açmak için ek paket yok: küçük bir platform kanalı (`kalan/system`). `timezone` paketi yalnızca web'de saat dilimi verisini indirmek için kullanılan bir dosyada `http`'ye bağlı; Kalan gömülü veriyi kullanır ve o dosyayı içe aktarmaz. Ağ bekçisi testi bu istisnayı yalnızca bu koşullarla kabul eder. |
| Android derleme | `flutter_local_notifications` 23 ve `androidx.core` 1.19 için `compileSdk = 37`; hedef SDK Flutter varsayılanı. |

## Palet: Mürekkep ve Safran (13 Kasım 2026)

| Konu | Karar |
|---|---|
| Palet seçimi | Gece & Nane'nin yerine Mürekkep ve Safran: kâğıt zemin, mürekkep yazı, "kalan" lacivert, "söz verilmiş" safran, eksi dönem koyu safran, gecikme vişne. Yeşil-kırmızı ikilisi bilerek yok. Değerler ürün sahibinin verdiği tablodan birebir alındı; 31 kontrast çiftinin hepsi eşiği geçiyor ve test tablodaki oranları doğruluyor. |
| Tek kaynak | `KalanColors` (sınıf ve dosya adı korundu; tokenlar yeni adlarla). ColorScheme yalnızca bu tokenlardan türetilir, seed ya da dinamik renk yok. Eski → Yeni eşlemesi `docs/DESIGN_TOKENS.md` dosyasında. |
| accent'in yeri | Yalnızca büyük "kalan" sayısı, birincil düğme/FAB dolgusu ve grafikte kalan kısım. Anahtar, onay kutusu, sekme, tarih ve saat seçici mürekkep (`text`) ile seçili gösterilir. Bağlantı ve metin düğmeleri `accentText`. |
| Eksi dönem | Büyük sayı `negative` ve eksi işaretli; açıklama metni artık `negativeText`, ikon `negative`. Sıkışık dönem eksi olmadığı için notunun ikonu mürekkep. |
| Karartma | Saydamlıkla ara ton üretilmediği için açılır pencere ve alt sayfaların arkası karartılmaz; pencere `surfaceRaised` zemin ve `border` kenarla ayrılır. |
| Seçim ve dokunma geri bildirimi | Metin seçimi vurgusu ve dokunma dalgası (ripple) Flutter'ın kendi türettiği tonlarla kalır; Kalan kodu ton üretmez. Ürün sahibi isterse ayrıca kararlaştırılır. |
| Odak halkası | Düğmelerde `focus`, 2 px, kontrolden 2 px uzakta (`BorderSide.strokeAlign` 3). Giriş alanında 2 px `focus` kenar. |
| Tema varsayılanı | Değişmedi: `ThemeMode.system`; Sistem / Açık / Koyu seçimi `shared_preferences` ile cihazda saklanır, yeniden açılışta korunur (testli). |
| Logo | Şekil aynı; açık ve koyu iki renk takımı. iOS'a koyu görünüm ikonu eklendi (`flutter_launcher_icons` 0.14 destekliyor); bu araç ikon kümesini tek boyutlu yeni biçime geçirdi, kullanılmayan eski boyutlar silindi. Tonlu ikon eklenmedi (istenmedi). Android uyarlanabilir ikonu açık renklerle; Android başlatıcıları koyu ikon seçmediği için tek takım. |
| Açılış ekranı | İki tema: zemin `bg`, ortada işaret. iOS'ta adlandırılmış renk (`LaunchBackground`) ve koyu görünümlü `LaunchImage`; Android'de `values-night` ve `drawable-night-nodpi`. |
| Platform renk dosyaları | Android `colors.xml`, iOS storyboard ve renk kümesi, bildirim vurgu rengi platform gereği renk kodu içerir; değerler tokenlarla aynıdır ve `test/app/assets_test.dart` denetler. Renk kodu bekçisi `lib/` içindeki Dart dosyalarına bakar. |

## Para birimleri: 75 birim (13 Kasım 2026)

| Konu | Karar |
|---|---|
| Kapsam | 22 yerel sürüm için 58 yeni birim; toplam 75. Hepsi tek kayıtta (`Currency.all`): ISO kodu, sembol, ayırt edici sembol, basamak, ülkeler, birlikte kullanıldığı ülkeler, ilişkili yerel sürümler. |
| Saklama ölçeği | Tutarlar `int` küçük birim; ölçek ISO değil günlük kullanım (CLDR) basamağıdır: 0 basamakta 1 birim = 1, 2 basamakta 100, 3 basamakta 1000. 3 basamaklılar: KWD, BHD, OMR, JOD, TND, LYD. 0 basamaklılar: COP, CLP, IDR, PYG, CRC, XOF, XAF, UZS, TWD, IQD, LBP, PKR, GNF, MGA, YER, SYP, JPY, VND. |
| Migration | Yazılmadı. Mevcut 17 birimin saklama ölçeği tabloyla zaten aynı (COP ve IDR önceden 0 basamaktı). Testle sabitlendi. Yeni birimlerde önceden saklanmış veri olamaz. |
| Sembol | Uygulama içinde tutarlar her zaman birimin kendi sembolüyle yazılır (COP için "$"). Önceki "bölge dışında ayırt edici sembol" davranışı bu kural gereği kaldırıldı. Seçicide, para birimi alanında ve Ayarlar satırında ayırt edici sembol ve ISO kodu yazılır ("COL$ · COP"); dışa aktarma geldiğinde aynı etiket kullanılacak. |
| Sağdan sola semboller | Arapça semboller (ر.س gibi) U+2068/U+2069 ile yalıtılır; rakamların sırası bozulmaz, düzen soldan sağa kalır. Ayrıştırıcı sembolleri (nokta içerenler dahil: "B/.", "د.ك") önce siler. |
| Giriş | Alanlar para biriminin izin vermediğini içeri almaz: 0 basamaklıda ondalık ayırıcı, 3 basamaklıda üçten fazla, 2 basamaklıda ikiden fazla ondalık. 0 basamaklıda klavyede ondalık tuşu yok. Tam değeri yine `parseAmount` denetler. |
| Tam tutarlar | Mevcut karar korundu: kuruşu sıfır olan tutar ondalıksız yazılır ("₺12.500"); ondalık varsa her zaman birimin basamak sayısı kadar ("12,500" KWD = 12 dinar 500 fils). |
| Seçici | Ada, koda, sembole ve ayırt edici sembole göre arama (Türkçe i/İ ve ı farkı gözetilmez). Liste adına göre sıralı (Türkçede ç, ğ, ı, ö, ş, ü kendi yerinde). Başta "Önerilen": cihaz bölgesinin birimi, sonra orada birlikte kullanılanlar (PA → PAB, USD; PS → JOD, ILS). Bölge bilinmiyorsa uygulama dili ("tr" → TRY, başka → USD). |
| Adlar | 75 ad yalnızca Türkçe ve İngilizce ARB'de. Mevcut Türkçe "Kazak tengesi" çevirisi korundu (tablodaki "Kazakistan tengesi" yerine); mevcut çeviriler değiştirilmez kuralı. |
| Doğrulanamayanlar | Tablodaki notlar (KZT kuruş kullanımı, AUD/NZD nakit yuvarlaması, SAR/AED yeni işaretleri, CDF'de dolar, SYP sıfır atma) kayda yansıtılmadı; tablo değerleri kullanıldı. |

## Devam eden planı ortasından ekleme (13 Kasım 2026)

Ürün sahibiyle netleşen kararlar: ödenmiş taksit sayısı girilir (kalan değil; ekstredeki "3/10" ile aynı), sıradaki ödeme tarihi girilir, geçmiş taksitler gerçek ödeme kaydı olarak "Kalan'dan önce ödendi" işaretiyle saklanır.

| Konu | Karar |
|---|---|
| Ayrı tür yerine anahtar | "Yarıda başlayan" plan türü (karar 24) kaldırıldı; kalan sayısıyla giriş ve dördüncü bir yol bırakılmadı. Her türde "Bu plan zaten sürüyor" anahtarı, tutar ve taksit alanlarının altında. Kapalıyken ekran öncekiyle aynı (tek fark anahtarın kendisi). Motordaki eski `PlanCalculator.midway` ve testleri değiştirilmeden duruyor; arayüz kullanmıyor. |
| Alanlar | Aylık ve kart: mevcut sayı alanı "Toplam taksit" adını alır, "Ödenmiş taksit" eklenir, ilk ödeme / satın alma tarihi yerine "Sıradaki ödeme tarihi" gelir. 4 ödemeli: toplam 4 sabit, ödenmiş 1–3 seçilir, sıradaki tarih. Elle giriş: yalnızca "Ödenmiş taksit"; girilen listenin ilk N ödemesi işaretlenir, tarihler değişmez. Ekrana tek anahtar ve en çok üç alan eklendi. |
| Kayıt | `payments.paidBeforeKalan` (bool, varsayılan false; mevcut `isEdited` gibi ödeme satırında). Şema v4; geçişte bütün mevcut kayıtlar false, tutar ve tarih değişmez (testli). Bu kayıtlar `paidAt` dolu, yani ödenmiş; işaret yalnızca gösterimi ve düzenlemeyi ayırır. |
| Geriye tarih | Saf `underwayDates` (motor): aylıkta sıradaki tarihin ayın günü, motorun ay sonu kuralıyla (31 Ocak, 28 Şubat, 31 Mart); 4 ödemelide 14 gün; kartta `dueMonthOf` ve `CardTerms.dueInMonth` ile kartın aylık son ödeme günü (hafta sonu kaydırması dahil). Tutarlılık testli: ilk tarihten ileri kurulan plan aynı listeyi verir. Aylıkta ilk tarih ay sonuna kırpılmışsa (ör. sıradaki 31 Mart, 1 ödenmiş → 28 Şubat) ileri yön de planın kendi gününü (31) kullanır; liste yine aynıdır. |
| Kart önerisi | `nextCardDueAfter`: bugünden sonraki ilk son ödeme günü (bugün son ödeme günüyse bir sonraki). Kart seçilince ya da anahtar açılınca dolar; kullanıcı tarihi değiştirince öneri bir daha üzerine yazmaz. |
| Tutarlar | Toplam tutar eskisi gibi girilir ve `splitEvenly` ile bölünür: kuruş farkı ilk taksitte kalır (bu bir "Kalan'dan önce ödendi" kaydı olabilir). |
| Dönem hesabı | Bu kayıtlar ödenmiş ödemeler gibi söz verilmiş tutara girer: tarihi içinde bulunulan döneme düşen dahil olur, önceki dönemler hesaplanmaz. Ana ekranda listelenmez; "Bu dönem N ödeme var" cümlesindeki sayı ve toplam tutar onları da içerir (toplamla tutarlı kalsın diye). |
| Hiç gecikmiş değil | Ödenmiş oldukları için gecikmiş sayılmaz, bildirim kurulmaz (planlayıcı testiyle kilitli), late kullanılmaz. |
| Gösterim | Plan ayrıntısında ödeme listesinin üstünde tek satır: "3 taksit Kalan'dan önce ödendi · ₺2.550" (textMuted, dokunulmaz); tek tek satır ve tarih yok. Ekleme ekranının önizlemesinde de aynı satır; listelenen ödemeler yalnızca kalanlar. |
| İlerleme | Liste ve ayrıntıda mevcut "{paid}/{count} ödendi" metni korundu (içinde "3/10" gösterimi var; mevcut çeviri ve testler değişmesin diye). Sayılar ARB'de `decimalPattern` biçimiyle intl'den gelir. Ekran okuyucu etiketi: "10 taksitten 3 tanesi ödendi". Ödenmiş sayısı = Kalan'dan önce ödenenler + uygulamada işaretlenenler (+ eski yolla eklenmiş planların baştaki eksik sırası). |
| Düzenleme ekranı | Uygulamada plan düzenleme ekranı yoktu; plan ayrıntısına "Planı düzenle" eklendi. Aynı anahtar ve alanlar dolu gelir. Toplam taksit aylık ve kart planlarında düzenlenebilir (aşağıdaki satır); 4 ödemelide gösterilmez, elle girişte salt okunurdur. |
| Taksit sayısını değiştirme (13 Kasım 2026) | Plan toplamı sabit kalır: ödenmiş taksitler ve elle düzenlenmiş ödemeler tutarını ve tarihini korur; ödenmemiş kalan tutar diğer ödenmemiş taksitlere `splitEvenly` ile yeniden bölünür (kuruş farkı ilkinde). Neden: plan "toplam tutar + taksit sayısı" ile eklenir ve tek ödeme düzenlemesi de toplamı korur. Azaltınca ödemeler sondan silinir; en az, son ödenmiş taksitten sonra bir ödenecek taksit kalacak kadar (`minInstallmentCount`). Artırınca yeni ödemeler planın düzeniyle (`underwayDates`, son elle düzenlenmemiş ödemeden) tarihlenir. Elle girişte tarih kuralı olmadığı için değiştirilemez. Saf `resizePlan` fonksiyonu tablo testli; "ödenmiş taksit" ile birlikte tek işlemde kaydedilir, biri reddedilirse ikisi de geri alınır. |
| Düzenleme kuralları | Uygulamada "ödendi" işaretlenen ödemelere asla dokunulmaz. Ödenmiş taksit alanı planın başındaki, uygulamada işaretlenmemiş ödemeleri kapsar; üst sınır bu baştaki dizinin uzunluğu (ve toplam − 1). Sayı artarsa sıradakiler işaretlenir; azalırsa ya da anahtar kapanırsa onay sorulur ("2 taksit ödenmemiş olarak geri gelecek.") ve o kayıtlar ödenmemiş olur; tarihi geçmişte kalanlar normal kuralla gecikmiş görünür. Sıradaki tarih değişirse uygulamada ödenmiş ve elle düzenlenmiş ödemeler dışındakiler planın düzeniyle yeniden hesaplanır (kartta mevcut kural gibi); elle girişte tarih alanı yok. |
| Eski planlar | Ayrı "Yarıda başlayan" türüyle eklenmiş planlar (ilk sırası 1 değil) değişmeden çalışır, eski açıklama satırını gösterir; düzenle düğmesi onlarda yok. |
| Ücretsiz sınır | Değişmedi: aynı `canAddPlan` ve hak yönetimi; ortasından eklenen plan da açık plan sayılır (testli). |
| Anahtar rengi | Prompt anahtar için accent istiyordu; DESIGN_TOKENS kuralı (accent yalnızca "kalan") gereği anahtarlar mürekkep rengindedir. |
| Test değişiklikleri | Kaldırılan tür yüzünden iki mevcut ekran testi güncellendi: `add_plan_test.dart`'taki "plan already started" testi kaldırıldı (yerine `underway_test.dart`), `accessibility_test.dart` döngüsü "Yarıda başlayan" yerine her türde anahtarı açıyor. Motor testlerinin hiçbiri değişmedi. |

## Günü geçenler (13 Kasım 2026)

Ürün sahibiyle netleşen kararlar: geciken ödeme = etkin son ödeme günü bugünden önce olan ödenmemiş ödeme; her zaman içinde bulunulan dönemin söz verilmiş tutarına girer; "Ödendi" denince "Bugün" ya da "Gününde" sorulur; satır kendiliğinden kalkmaz; bölüm boşsa görünmez; ücretsizdir.

| Konu | Karar |
|---|---|
| Tek dönem kuralı | Saf `countingDate` (`lib/core/engine/past_due.dart`): ödenmemiş ve günü geçmiş → bugün (yani bu dönem); ödenmiş ve `paidOnDay` son ödeme gününden sonra → `paidOnDay`; diğer her şey → son ödeme günü (önceki davranış). Ana ekranın dönem toplamı bu fonksiyonla hesaplanır; başka kopyası yok. `isPastDue` ve `daysPastDue` aynı dosyada. Eski `isOverdue` fonksiyonu ve testi değiştirilmeden duruyor; kullanılmıyor. |
| Değişmezlik | Günü geçmiş ödemesi olmayan veride hiçbir dönem toplamı değişmez (tablo testiyle kilitli). Eski ödenmiş kayıtların `paidOnDay` alanı boştur; son ödeme günlerinin döneminde kalırlar (Örnek 4). |
| Ödendiği gün | Yeni sütun `payments.paidOnDay` (epoch günü, boş olabilir; şema v5, geçiş testli). Yalnızca "Ne zaman ödedin?" penceresi doldurur: "Bugün" → bugün, "Gününde" → son ödeme günü. Mevcut `paidAt` zaman damgası yeniden yorumlanmadı (kullanıcılar zamanında ödediğini çoğu zaman günler sonra işaretliyor). "Ödenmedi" yapılınca `paidOnDay` da silinir. |
| Gösterim | Ana ekranda büyük sayının kartının hemen altında, bu dönemin listesinin üstünde. En eski son ödeme günü en üstte; en çok 3 satır, fazlası "Tümünü göster (n)" ile aynı yerde açılır. Önceki dönemden gelen ödeme varsa başlığın altında textMuted açıklama satırı. Geciken ödeme dönem listesinde ikinci kez görünmez. "Bu dönem N ödeme var" cümlesi ve toplamı geciken ödemeleri de sayar (toplamla tutarlı). |
| Satır | Harf rozeti, plan adı (büyük yazıda kısalır), "x gün önce" notu ve saat ikonu (late; renk tek başına değil), tutar, "Ödendi" metin düğmesi (accentText). Satıra dokunmak plan ayrıntısını açar. Gün sayısı takvim günü farkıdır. |
| Pencere | Alt sayfa: "Bugün · Bu dönemin hesabında kalır.", "Gününde, 28 Ekim · Ödeme o döneme yazılır.", Vazgeç. "Ödendi" sonrası bilgi mesajında sakin bir "Geri al" düğmesi var (6 saniye, kendiliğinden kapanır): ödeme ödenmemiş hâline ve ödendiği gün bilgisi silinmiş olarak döner; günü geçenlerdeki satır geri gelir. Aynı düğme ana ekrandaki tek dokunuşla "ödendi"de de var; "ödenmedi" mesajında yok (tekrar dokunmak yeter). Her sekme kendi `ScaffoldMessenger`ını kullanır (`lib/core/routing/tab_messengers.dart`): mesaj "Plan ekle" düğmesinin üstünde durur, onu örtmez; yalnızca mesajı gösteren sekmede çizilir. Tam ekran sayfalar (plan ekleme, plan silme, sabit ödeme, ödeme düzeni, kaynak) kapanırken mesajı `popWithMessage` ile dönülen sekmenin mesaj alanında gösterir; sekmeye dönülmüyorsa kendi alanında. Plan ayrıntısında geciken bir ödeme "ödendi" yapılınca da aynı pencere açılır; günü geçmemiş ödemelerin akışı aynı. |
| Plan ayrıntısı | Eski "Gecikti" etiketi yerine "x gün önce" notu ve saat ikonu (aynı `OverdueBadge` biçimi, late). Başka değişiklik yok. |
| Gün değişimi | Uygulama ön plana dönünce "bugün" yenilenir (`todayProvider` geçersiz kılınır); bölüm ve gün notları buna göre güncellenir. |
| Sabit ödemeler | Geçmiş dönemlerdeki işaretlenmemiş tekrarlar bölüme girmez (karar 24a). |
| Kırılım | Ana ekranda söz verilmiş tutarın kırılımı yok; yeni kırılım eklenmedi. |
| Bildirimler | Geciken ödemeye yeni bildirim kurulmaz (tetiklenme anı geçmişte). "Ödendi" sonrası mevcut yeniden kurma (veritabanı akışı) çalışır; testli. |
| Ortasından eklenenler | "Kalan'dan önce ödendi" kayıtları ödenmiş olduğu için asla geciken sayılmaz; testli. |
| Test değişiklikleri | Eski karar 2'yi kodlayan üç mevcut ekran testi yeni karara göre güncellendi (`home_test.dart`'ta iki test, `underway_test.dart`'ta bir satır). Ana ekran golden'ları seed verisindeki iki geciken ödemeyi artık bu dönemde gösterir. Motor testlerinin hiçbiri değişmedi. |

## Bildirimden ödendi (13 Kasım 2026)

Ürün sahibiyle netleşen kararlar: "Ödendi" hem "önceden" hem "gününde" bildiriminde; birleşik bildirimde "Hepsi ödendi"; erteleme bildirimin türüne göre ("gününde" → "Akşam hatırlat" 20:00, "önceden" → "Yarın hatırlat" ertesi gün aynı saat); her bildirimde en çok iki düğme; ücretsiz.

| Konu | Karar |
|---|---|
| Düğmeler | Tek ödeme "Ödendi", birden çok ödeme "Hepsi ödendi" (bildirimdeki bütün ödemeler). "Gününde" bildiriminde saat 18:00 ya da daha erkense "Akşam hatırlat"; değilse yalnızca "Ödendi". "Önceden" bildiriminde "Yarın hatırlat"; bildirimdeki ödemelerden biri ertesi gün ödenecekse gösterilmez ("gününde" bildirimi o işi görür; birleşik bildirimde aynı anda iki bildirim gelmesin diye "biri" yeterli). Ertelenmiş bildirimde yalnızca "Ödendi" / "Hepsi ödendi"; yeniden ertelenemez. Kurallar saf Dart planlayıcıda (`reminderActions`), tablo testli. |
| Düğme adları | ARB'de (`reminderAction*`), çevirmen açıklamalı (sistem düğmesi, 1-2 kelime). Bildirimler uygulamanın o anki diliyle kurulur; iOS kategorileri dil değişince yeniden kaydedilir (`replaceAll` düğme adlarını karşılaştırır). |
| Payload | JSON: sürüm, tür (`ahead` / `onDay` / `snoozed`), metnin türü, tetiklenme günü ve saati, ödeme anahtarları (`p12` plan ödemesi, `r3.20406` sabit ödemenin o günkü tekrarı). Çözülemeyen her şey (eski `home`, bozuk metin, bilinmeyen sürüm) sessizce atlanır. Dokunma yine ana ekranı açar. |
| Ortak işleyici | `ReminderActionHandler` (`lib/features/reminders/reminder_actions.dart`): arka plan isolate'i ve (platform eylemi uygulamaya gönderirse) ön plandaki uygulama aynı fonksiyonu çağırır. İşaretleme uygulamanın kendi "ödendi" kodundan geçer (`PlanRepository.setPaid`, `setPaidOn`, `RecurringRepository.setPaid`); ikinci bir yol yok. Her ödeme işlem içinde veritabanından yeniden okunur: silinmiş ya da zaten ödenmiş olan atlanır, hata gösterilmez. Sonra 1. maddenin yeniden kurma mantığı çalışır. |
| Günü geçmiş ödeme | Eyleme basıldığı anda günü geçmişse (ör. "gününde" bildirimine ertesi gün basıldı) Günü geçenler'deki "Bugün" gibi işaretlenir (`paidOnDay` = bugün, bu dönemin hesabında kalır). Günü geçmemiş ödeme normal "ödendi" olur. Sabit ödemeler Günü geçenler'e girmediği için normal işaretlenir. |
| Erteleme kaydı | Drift şema v6, `reminder_snoozes` tablosu: tür, tetiklenme günü, dakika, ödeme anahtarları; aynı erteleme ikinci kez eklenmez (benzersiz anahtar, `insertOrIgnore`). Planlayıcıya girdi olur, 60 sınırına dahildir ve tarihine göre sıralanır. Yeniden kurma önce zamanı geçmiş ya da ödemelerinin hepsi ödenmiş/silinmiş ertelemeleri siler. Ertelenmiş bildirim aynı metni üretir, kalan ödenmemiş ödemelerle ("Bildirimde tutarı göster" ayarına uyar). "Akşam hatırlat" 20:00 geçtikten sonra basılırsa hiçbir şey kaydedilmez. |
| Arka planda çalışma | Düğmeler uygulamayı açmaz: eklenti kendi arka plan motorunda `reminderActionInBackground` fonksiyonunu çalıştırır (`@pragma('vm:entry-point')`, uygulama kapalı, arka planda ya da ekrandayken). iOS'ta `AppDelegate` eklenti kaydını (`setPluginRegistrantCallback`) yapar; Android'de eklentinin `ActionBroadcastReceiver`'ı manifestte. Android'de düğme bildirimi kapatır (`cancelNotification`), iOS'ta sistem kapatır. Sıra: önce yalnızca veritabanı açılır ve değişiklik yapılır (işaretleme ya da erteleme kaydı), bildirim servisi ancak ondan sonra başlatılıp bildirimler yeniden kurulur. Neden: iOS bir düğmeye arka planda yalnızca birkaç saniye verir; asıl iş önce biter, yeniden kurma yarıda kalırsa uygulamanın bir sonraki açılışı ya da ön plana dönüşü onu yapar. |
| Veritabanı erişimi | `drift_flutter`'ın paylaşılan isolate yolu (`shareAcrossIsolates`): süreçteki ilk açan küçük bir veritabanı isolate'i başlatır, diğerleri (uygulama, bildirim eylemi, Android'in yeniden kurma alıcısı) ona bağlanır. Tek SQLite bağlantısı olduğu için yazmalar çakışmaz, işlemler sırayla çalışır ve uygulama açıksa ekranları arka plandaki yazmayı hemen görür. Uygulama ile iki ayrı isolate aynı anda sıkı döngüyle yazınca kilitlenme ve kayıp olmadığı testli (`test/data/database_sharing_test.dart`). WAL ve `busy_timeout` 5 sn (`beforeOpen`) yalnızca ek güvencedir; süreçte tek bağlantı olduğu için normalde devreye girmez. İki ayrı SQLite bağlantısıyla sıkı döngüde yazma güvenceli değildir (14 Kasım 2026: CI'da bu düzeni sınayan eski test yük altında "database is locked" verdi; uygulama bu düzeni kullanmadığı için test gerçek yola, paylaşılan veritabanına çevrildi). Ön plana dönüşte plan ve sabit ödeme sağlayıcıları ayrıca yenilenir. Yeni paket yok. |
| Cihaz kilidi | iOS: "Ödendi" ve "Hepsi ödendi" `authenticationRequired`; telefon kilitliyse önce Face ID, Touch ID ya da kod istenir. Erteleme düğmeleri kilit istemez (yalnızca sonra hatırlatır). Android: eklenti eylem için kilit açma seçeneği sunmuyor; en yakın eşdeğer olarak düğmeli hatırlatmalar `NotificationVisibility.secret`: güvenli kilit ekranında (PIN, desen, biyometri) bildirimin içeriği ve düğmeleri hiç görünmez; ses ya da titreşimle haber verir, kilit açılınca bildirim gölgesinde düğmeleriyle durur. Güvenli kilidi olmayan telefonda bildirim normal görünür. |
| Uygulama kilidi | Kalan'ın kendi kilidi (27. madde) ileride eklenip açık olsa bile bildirim düğmeleri onu sormaz. Telefon kilitliyse önce telefonun kilidi açılır. Neden: düğme hiçbir bilgi göstermez, yalnızca işaretler; telefon kilidi yetkisiz kişiyi engeller. Uygulama kilidi eklenirken bu kural değiştirilmez. |
| Debug | Ayarlar > Hatırlatmalar'da yalnızca debug derlemede "Eylemli deneme bildirimi (10 saniye sonra)": ödenmemiş en yakın gerçek ödemenin (önce bugün ve sonrası, yoksa en yakın geçmiş) "gününde" bildirimini düğmeleriyle 10 saniye sonra kurar. Ödenmemiş ödeme yoksa sakin bir not gösterir. Yayın derlemesinde derlenmez (`kDebugMode`). |
| Kapsam dışı | Widget'tan işaretleme, bildirimden tutar düzeltme ya da not, ısrarlı/tekrarlayan hatırlatma, akşam saati ayarı, üçüncü düğme, uygulama kilidi. |
| Test hata görüntüleri | `test/golden/failures/` başarısız golden çalışmasının çıktısıdır; repoya girmez (`.gitignore`). Daha önce yanlışlıkla eklenmiş 112 dosya kaldırıldı. |

## Israrlı hatırlatma (14 Kasım 2026)

Ürün sahibiyle netleşen kararlar: üç mod ("Kapalı" varsayılan, "Akşam bir kez daha", "Her gün"), genel ayardan ya da plan bazında; tekrarlar yalnızca kullanıcının bildirim saatinde ve 20:00'de, son günden en çok 7 gün sonrasına kadar; sessiz saat ayarı yok; "Ödendi" / "Hepsi ödendi" bütün tekrarları durdurur; ücretsiz.

| Konu | Karar |
|---|---|
| Tek kaynak | Bütün mantık 1. maddenin saf Dart planlayıcısında (`reminderMoments`, `planReminders`). İkinci zamanlama sistemi, arka plan görevi ya da tekrarlayan sistem alarmı yok; tekrarlar 60 sınırına girer ve uygulama açılışı, ön plana dönüş ve bildirim eylemlerinden sonraki yeniden kurmayla ilerler. |
| Anlar | Her ödeme için "önceden" ve "gününde" (kullanıcı saati) her zaman; "Akşam bir kez daha": bu iki günün 20:00'i; "Her gün": "önceden" gününden son günden 7 gün sonrasına kadar her gün kullanıcı saati ve 20:00. Aynı an ve tür tek bildirim (1. maddedeki gibi birleşir); 1. maddenin sabah bildirimi ikinci kez üretilmez. Geçmiş anlar atlanır. |
| "Akşam bir kez daha" ayrıntısı | Yalnızca normal hatırlatmanın geldiği günlerde ("önceden" ve "gününde") 20:00; arada ve son günden sonra yok. |
| 20:00 kuralı | Kullanıcı saati 18:00'den sonraysa 20:00 tekrarı hiç kurulmaz ("Akşam hatırlat" ile aynı eşik, `ReminderSettings.eveningAllowed`): "Her gün" günde bire iner, "Akşam bir kez daha" etkisiz kalır. Gece bildirim yolu yok. |
| Türler | Bildirimin tetiklendiği güne göre: son günden önce "önceden", son gün "gününde", sonrası yeni "gecikmiş" (`ReminderKind.overdue`). "Önceden" ve "gününde" tekrarları 1. maddenin metinlerini aynen kullanır. |
| Gecikmiş metni | "14 Kasım'daki 1 ödeme henüz işaretlenmedi: Tabby, ₺400" / birden çok: "3 ödeme henüz işaretlenmedi, toplam ₺2.450"; tutar gizliyse tutarsız. "Henüz işaretlenmedi" suçlamaz (ödenmiş ama işaretlenmemiş olabilir); tekrar ettikçe değişmez. Türkçe ek ("'daki", "'deki", "'taki") ayın sesine göre ARB'deki ICU select ile seçilir; tarih intl'den ("14 Kasım", "November 14"). |
| Etkin mod | Plan seçimi "Genel ayar" (boş) ise genel mod, değilse plan seçimi (`repeatModeFor`). Planın hatırlatması "Kapalı" ise tekrar da yok. Ödenmiş ve "Kalan'dan önce ödendi" ödemeler tekrar almaz; silinmiş planlar zaten girdi değildir; uygulamada arşiv yok. Sabit ödemeler de planlar gibi kendi seçimine sahiptir (boş = Genel ayar). |
| Kimlikler | Sabah "önceden" / "gününde": değişmeyen `gün × 2 + tür`. 20:00 anları ve sabah "gecikmiş": `2^29 + gün × 4 + yuva`. Ertelemeler `2^30 + kayıt`. Deterministik; yeniden kurma çift bildirim üretmez. Mod kapalı kullanıcının listesi bu işten önceki hâliyle birebir aynıdır (testle). |
| Düğmeler | Tekrar bildirimleri de "Ödendi" / "Hepsi ödendi" taşır. Bildirimdeki bir ödemenin ısrarlı modu açıksa ikinci düğme "Yarın hatırlat"tır ("gününde" sabahında da: akşam tekrarı zaten geleceği için "Akşam hatırlat" gösterilmez). Bir ödemenin penceresinin son günü (son günden 7 gün sonra) "Yarın hatırlat" yoktur. Ertelenmiş bildirim yeniden ertelenemez. Israrlı modu kapalı ödemelerde 4. madde davranışı hiç değişmez. Karışık birleşik bildirimde (biri ısrarlı, biri değil) ısrarlı kural geçerli. |
| "Yarın hatırlat" (ısrarlı) | 4. maddenin erteleme tablosu genişletildi (`reminder_snoozes.skips_day`, ikinci tablo yok): kayıt, o günün kalan tekrarlarını atlar ve ertesi gün kullanıcı saatinde hatırlatır; o an zaten bir hatırlatma varsa ikincisi kurulmaz. Tekrarlar sonraki günlerde normal sürer. Kayıt, zamanı geçince ya da ödemeler ödenince/silinince temizlenir. Eylem bildirimin payload'ındaki `repeating` işaretine bakar. Israrlı mod açılmadan önce kurulmuş bir 4. madde ertelemesi bir tekrarla aynı ana düşerse o ödeme ikinci kez hatırlatılmaz. |
| Veri | Şema v7: `app_settings.repeat_mode` (varsayılan 0 = Kapalı), `plans.repeat_mode` ve `recurring_payments.repeat_mode` (boş = Genel ayar), erteleme tablosunda `skips_day` ve tür 2 ("gecikmiş"). Geçişten sonra herkes Kapalı'dadır (testle). |
| Arayüz | Ayarlar > Hatırlatmalar: "Israrlı hatırlatma" satırı, altında yardımcı metin; "Her gün" seçiliyken "Senin bildirim saatinde ve akşam 20:00'de." (saat dilin 12/24 biçiminde). Ana anahtar kapalıyken satır pasif, değer korunur. Plan ayrıntısı: "Israrlı hatırlatma" seçimi (Genel ayar (mod) / Kapalı / Akşam bir kez daha / Her gün); planın hatırlatması Kapalı ise pasif. Ödemeler ekranın üstünde kalsın diye ödeme listesinin altında. Plan düzenleme ekranında hatırlatma alanı yok, oraya eklenmedi. Sabit ödeme düzenleme ekranında "Hatırlatma"nın hemen altında aynı seçim; kaydetle birlikte saklanır. Etkin modu Kapalı olmayan açık planların (ve sabit ödemelerin) listede, planların ayrıntıda da adının yanında küçük tekrar ikonu (`textMuted`), ekran okuyucu "Israrlı hatırlatma açık". |
| Renk | Seçili seçenekte onay işareti; renkler mevcut seçim penceresinden (DESIGN_TOKENS: seçili seçenek `text`, accent yalnızca "kalan"). Prompt seçili seçenek için accent diyordu; bağlayıcı belge kazandı. `late` kullanılmadı. |
| 9. madde | Otomatik çekim / elle ödeme ayrımı repoda yok; bu yüzden "Elle ödediğin planlarda önerilir" ve "Bu plan otomatik çekiliyor" yardımcı metinleri eklenmedi. |
| Debug | Yalnızca debug derlemede (`kDebugMode`) "Israrlı deneme (1'er dakika arayla 3 bildirim)": ödenmemiş en yakın ödemenin bugünkü tekrar bildirimi 1, 2 ve 3 dakika sonra. "Ödendi" yeniden kurmayı tetiklediği için kalan ikisi iptal olur. Gerçek kurallarda dakikalık tekrar yok. |

## Sonra öde (14 Kasım 2026)

Ürün sahibiyle netleşen kararlar: tür adı "Sonra öde" / "Pay later"; açık kayıt 4 açık plan sınırına sayılır, ödenip arşive gidince düşer (mevcut `canAddPlan`, yeni kural yok); varsayılan süre son kullanılan kural, ilk seferde 30 gün; mağaza adı isteğe bağlı, boşsa veritabanına ad yazılmaz ve dile göre otomatik etiket gösterilir; ücretsiz.

| Konu | Karar |
|---|---|
| Tür | `PlanKind.payLater`: tek ödeme, tutarı planın tutarı, tarihi son ödeme günü. Mevcut plan ekleme ekranında beşinci tür; ayrı ekran, liste ya da ana ekran bölümü yok. |
| Süre kuralları | `PayLaterRule` (saf Dart, `lib/core/engine/pay_later.dart`): "14 gün" ve "30 gün" (alışveriş + N gün), "Gün sayısı" (1–180), "Gelecek ayın N. günü" (1–31; o ay kısaysa ayın son günü), "Tarih seç". Tek fonksiyon `payLaterDueDate`; ay sonu ve artık yıl kuralı motorun `LocalDate.addMonths` / `LocalDate.clamped` yardımcılarıyla aynı, kod kopyası yok. Yalnızca tarih, saat yok. |
| Hafta sonu | Kaydırma yapılmaz: tarihi sağlayıcı belirler, Kalan değil. Kart seçilse bile hesap kesim günü ya da kart taksidi hesabı uygulanmaz. |
| Kural saklama | Plan kuralı saklar (`plans.pay_later_rule`, `pay_later_value`) ve alışveriş tarihini (`purchase_day`). Düzenlemede alışveriş tarihi ya da kural değişince son ödeme günü yeniden hesaplanır; "Tarih seç"te seçilen tarih korunur. Ödenmiş planda yalnızca ad ve kaynak değişir; tutar ve tarih değişmez (ödenmiş ödemelere dokunulmaz). |
| Son kullanılan | Genel ayar (`app_settings.last_pay_later_rule`, `last_pay_later_value`): tür + N ("gün sayısı 45", "gelecek ayın 27'si"). "Tarih seç" hatırlanmaz; önceki hatırlanan kural kalır. Boşken 30 gün. |
| Türkçe çip metni | "Gelecek ayın {day}'i" yerine ek gerektirmeyen "Gelecek ayın {day}. günü"; sayı girilmeden önce "Gelecek ayın …". İngilizcede sıra eki olmadan "Next month on day {day}" (ICU'da sıra sayısı eki yok). |
| Ad | Mağaza adı `plans.title`'a yazılır; boşsa hiçbir ad yazılmaz. Ekranda ve bildirimde ad yoksa "Sonra öde · 14 Ara" / "Pay later · Dec 14" (kısa tarih intl'den, `planNameIn` / `context.planName`): dil değişince etiket de değişir. Kaynak seçilse bile ad yoksa otomatik etiket gösterilir. |
| Kaynak | Mevcut form kaynağı zorunlu tutuyor; "Sonra öde"de isteğe bağlı (prompt kararı). Bunun için `plans.source_id` boş olabilir hâle geldi (şema v8, tablo yeniden kuruldu; mevcut planların kaynağı aynen korunur, ödemeler silinmez — testli). Kaynak yalnızca bilgi amaçlı. |
| Form | Sırayla: Tutar (zorunlu), Mağaza adı (isteğe bağlı), "Ne zaman ödeyeceksin?" çipleri (son kullanılan seçili), gerekiyorsa sayı alanı (sayı klavyesi), anlık son ödeme günü (`text`) ve kalan gün (`textMuted`), alışveriş tarihi ("Bugün"), kaynak. Kaydet yalnızca tutar geçerliyken etkin; en az etkileşim: tür, tutar, kaydet. "Bu plan zaten sürüyor" bu türde yok; ödeme önizleme kartı yerine son ödeme günü satırı onay adımıdır. Sınıra ulaşan ücretsiz kullanıcıda mevcut mesaj aynen görünür. |
| Gösterim | Listede ve ayrıntıda "3/10" ilerlemesi yok; "Son ödeme günü: 14 Aralık" (`text`) ve "30 gün sonra" (`textMuted`; geçmişse mevcut "x gün önce"). Ayrıntıda alışveriş tarihi, son ödeme günü, kural ("30 gün sonra" / "Gelecek ayın 27. günü" / "Seçilen tarih") ve varsa kaynak. Ödeme satırına dokununca tek ödeme düzenleme penceresi değil, planın düzenleme ekranı açılır (tutar ve tarih birlikte değişir). Ana ekranda diğer ödemelerle aynı listede. |
| Diğer maddeler | Türe özel kod yok: ödeme genel ödeme yolundan geçtiği için dönem toplamı (`countingDate`), bildirimler (önceden/gününde, aynı günde birleşme), Günü geçenler, bildirimden "Ödendi" ve ısrarlı hatırlatma kendiliğinden çalışır (testli). Kapanma mevcut kural: ödenince arşiv ("Biten"); "ödendi" geri alınınca plan yeniden açılır. Tek genel değişiklik: ad yoksa otomatik etiket (yukarıda). |
| Renk | Seçili tür ve çip mevcut seçim stilindedir (onay işareti, `text` mürekkep; DESIGN_TOKENS: accent yalnızca "kalan"). Prompt accent diyordu; bağlayıcı belge kazandı. `late` kullanılmadı. |
| Mevcut veriler | Mevcut planların ödemeleri, tutarları ve kalan değeri değişmez; motor testleri değiştirilmeden geçer. |

