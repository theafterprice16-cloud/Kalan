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
| Kaç gün önce | Seçenekler 1, 2, 3, 5, 7; varsayılan 2 (bazı sağlayıcılar parayı bir gün erken çekiyor). Genel ayarı plana uygulayan tek fonksiyon `defaultLeadDaysFor` (`lib/core/reminders/reminder_models.dart`). 16 Kasım 2026 (9. madde): genel ayarı izleyen planlarda otomatik ve belirtilmemiş = genel ayar, elle = genel ayar + 1; kural yalnızca orada. Plan ayrıntısındaki "Genel ayar (N gün önce)" de aynı fonksiyondan okunur. |
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
| 9. madde | Otomatik çekim / elle ödeme ayrımı repoda yoktu; bu yüzden "Elle ödediğin planlarda önerilir" ve "Bu plan otomatik çekiliyor" yardımcı metinleri eklenmedi. 16 Kasım 2026: ayrım geldi ("Ödeme şekli" bölümü); yardımcı metin olarak ödeme şekli seçiminin altındaki iki kısa not eklendi. |
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
| Gösterim | Listede ve ayrıntıda "3/10" ilerlemesi yok; "Son ödeme günü: 14 Aralık" (`text`) ve "30 gün sonra" (`textMuted`; geçmişse mevcut "x gün önce"). Ayrıntıda alışveriş tarihi, son ödeme günü, kural ("30 gün sonra" / "Gelecek ayın 27. günü" / "Seçilen tarih") ve varsa kaynak. Ödeme satırına dokununca tek ödeme düzenleme penceresi değil, planın düzenleme ekranı açılır (tutar ve tarih birlikte değişir). Ana ekranda diğer ödemelerle aynı listede; "1/1" yerine, sabit ödemelerdeki "Sabit" etiketi gibi "Sonra öde" yazar (14 Kasım 2026, ürün sahibinin onayıyla: tek ödemede "1/1" bilgi vermiyor). |
| Diğer maddeler | Türe özel kod yok: ödeme genel ödeme yolundan geçtiği için dönem toplamı (`countingDate`), bildirimler (önceden/gününde, aynı günde birleşme), Günü geçenler, bildirimden "Ödendi" ve ısrarlı hatırlatma kendiliğinden çalışır (testli). Kapanma mevcut kural: ödenince arşiv ("Biten"); "ödendi" geri alınınca plan yeniden açılır. Tek genel değişiklik: ad yoksa otomatik etiket (yukarıda). |
| Renk | Seçili tür ve çip mevcut seçim stilindedir (onay işareti, `text` mürekkep; DESIGN_TOKENS: accent yalnızca "kalan"). Prompt accent diyordu; bağlayıcı belge kazandı. `late` kullanılmadı. |
| Mevcut veriler | Mevcut planların ödemeleri, tutarları ve kalan değeri değişmez; motor testleri değiştirilmeden geçer. |


## Ödeme aralığı (16 Kasım 2026)

Ürün sahibiyle netleşen kararlar (Yol Haritası 7, açık sorular): "4 ödemeli plan" ayrı tür olarak kalır, 4 ödeme sabittir, ama aralığı seçilebilir (varsayılan iki haftada bir); "Aylık taksit"te varsayılan her ayın aynı günü. Ayın 31'inde başlayan aylık planda kısa aylarda ayın son günü. "Özel (N günde bir)" ilk sürümde var. Aralık seçimi plan ekleme ekranında görünür, tarihin altında.

| Konu | Karar |
|---|---|
| Seçenekler | Her ayın aynı günü · 30 günde bir · İki haftada bir · Haftada bir · Özel (N günde bir, 1–365). Yalnızca "Aylık taksit" ve "4 ödemeli plan" türlerinde. Kart taksidi ekstreye bağlı kalır; "Elle giriş" kendi "Aralık / Birim" alanlarıyla aynen kalır; "Sonra öde" tek ödemedir. |
| Motor | Saf `PaymentInterval` (`lib/core/engine/schedule.dart`): `null` gün = her ayın aynı günü (motorun ay sonu kuralı: 31 Oca, 28 Şub, 31 Mar; kayma yok), aksi hâlde N günde bir (`addDays`). Tarihler tek fonksiyondan (`PaymentInterval.dateAt`); ileri yön, geriye tarih (`IntervalPattern`, `underwayDates`) ve taksit sayısını artırma aynı kuralı kullanır. Dönem ve kalan hesabına dokunulmadı; yalnızca taksit tarihleri üretilir. |
| Hafta sonu | Bu türlerde hafta sonu kaydırması yoktu ve eklenmedi (tarihi sağlayıcı belirler, "Sonra öde" kararı gibi). Kartın hafta sonu kaydırması değişmedi. |
| Yirmi saniye kuralı | "Aylık taksit"te aralık seçimi beşinci öğedir: ürün sahibi kararıyla istisna. Yazı alanı değil, hazır seçili gelen bir seçimdir; dokunmadan geçilebilir. "Özel" seçilince tek sayı alanı açılır. |
| Önizleme | Aynı aya birden çok ödeme düşerse önizlemede sakin bir satır: "Aynı aya düşen ödemeler: Ağustos 2027 (2)." (`textMuted`, uyarı rengi yok). Her ayın aynı günü seçiliyken bu satır çıkmaz (iki ödeme aynı aya düşmez). |
| Saklama | `plans.interval_days` (şema v9): boş = her ayın aynı günü, 1–365 = N günde bir. Diğer türlerde boş ve kullanılmaz. Göç: mevcut 4 ödemeli planlara 14 yazılır; mevcut aylık planlar boş kalır (zaten her ayın aynı günü). Tarihler ve tutarlar değişmez (testli). |
| Aralığı değiştirme | Plan düzenleme ekranında aynı seçim. Değişince ödenmemiş ve elle düzeltilmemiş taksitlerin tarihi yeniden hesaplanır; uygulamada "ödendi" işaretlenmiş taksitlere asla dokunulmaz. Kalan'dan önce ödenmiş taksitlerin (gösterilmeyen, ama dönem toplamına giren) tarihleri, "Geriye tarih yalnızca `underwayDates` ile, ileri yön kuralıyla tutarlı" kuralı gereği çapadan geriye yeni aralıkla hesaplanır (16 Kasım 2026, ürün sahibinin "kurallara göre düzelt" talebiyle). Çapa (ürün sahibi kararı, 16 Kasım 2026, diff incelemesinden sonra): "Ödenmiş taksit"ten sonraki ilk ödenmemiş ve elle düzeltilmemiş taksit; tarihi yerinde kalır, sonrakiler yeni aralıkla ondan hesaplanır, böylece hiçbir taksit geçmişe düşmez. Gerekçe: çapa ilk ödeme olunca, baştaki taksitleri ödenmiş bir planda kalan taksitler geçmişe düşüp gecikmiş görünüyordu. "Sıradaki ödeme tarihi" de değiştirilirse taksitler o tarihten yeni aralıkla hesaplanır (mevcut "zaten sürüyor" kuralı). Değişiklik reddedilirse (ör. taksit sayısı bölünemiyor) aralık da dahil hiçbir şey kaydedilmez. Aylık ve 4 ödemelide tarih kuralını depo kendisi aralıktan kurar (`editPlan`). |
| Renk | Seçim mevcut `ChoiceField` stilindedir (Sonra öde kararıyla aynı gerekçe: accent yalnızca "kalan"). Yeni renk yok. |
| Eski planlar | 13 Kasım 2026 öncesi (şema v4 öncesi) yalnızca kalan taksitleriyle eklenmiş planların düzenleme ekranı yok (`startsAtFirstPayment`); onlarda aralık değiştirilemez. Bu yol artık uygulamada üretilmiyor; uygulama yayımlanmadığı için gerçek veride beklenmiyor. Açmak, eksik geçmiş taksitlerle "zaten sürüyor" mantığını yeniden yazmayı gerektirir; değiştirilmedi. |
| Tür adı | "Aylık taksit" adı değiştirilmedi (mevcut çevirilere dokunulmaz); aralık seçimi altında görünür. |

## Toplam ya da taksit tutarıyla giriş (16 Kasım 2026)

Yol Haritası 8. Açık sorular ürün sahibinin iş tanımında cevaplandı: bölme artığı ilk taksitte kalır (mevcut `splitEvenly`, değişmedi); varsayılan giriş yolu son kullanılan, hiç kullanılmamışsa "Toplam".

| Konu | Karar |
|---|---|
| Kapsam | Çok ödemeli bütün türlerde (4 ödemeli plan, aylık taksit, kart taksidi, elle giriş), "Bu plan zaten sürüyor" açıkken de. "Sonra öde" tek ödeme olduğu için değişmedi. Plan düzenleme ekranına eklenmedi. |
| Seçici | Tutar alanının hemen üstünde parçalı düğme (`SegmentedButton`): "Toplam" / "Taksit". Alan sayısı artmaz: tek tutar alanı, etiketi yola göre "Toplam tutar" ya da "Taksit tutarı". 4 ödemeli planda sayı sabit 4, taksit yolunda yalnızca taksit tutarı girilir. Seçili parçada onay işareti var (durum yalnızca renkle anlatılmaz). Renk tema varsayılanı (`secondaryContainer` = `surfaceRaised`); accent kullanılmadı, yeni renk yok. |
| Hesaplanan satır | Tutar alanının altında, her tuşta güncellenir, `textMuted` ve "· hesaplandı" notuyla. Toplam yolunda "Taksit ₺2.000 · hesaplandı"; bölünmüyorsa "İlk taksit ₺333,34, diğer 2 taksit ₺333,33 · hesaplandı". Taksit yolunda "Toplam ₺7.650 · hesaplandı". Değerler eksik ya da geçersizken satır görünmez. |
| Motor | Draft her zaman toplamla kurulur: taksit yolunda toplam = taksit × sayı (`totalFromInstallment`, `lib/core/engine/amount_entry.dart`), sonra mevcut `PlanCalculator` / `underwayPlan` / `markPaidBefore` yolları. İkinci hesap yolu yok. Özet `installmentSplit` doğrudan `splitEvenly` sonucundan okunur. Birime özel kod yok: küçük birimde tam sayı bölme, JPY'de artığı tam yen, KWD'de fils olarak dağıtır (tablo testli). |
| Sınırlar | Sayı 1–120 (`maxInstallments`), taksit en az 1 küçük birim. Taksit × sayı, toplam alanının alabileceği en büyük tutarı (13 tam basamak, `maxTypedAmountMinor`) ve 2^53−1'i (`maxEntryTotalMinor`, web dahil her platformda kesin tam sayı) aşamaz; aşarsa taksit alanında "Toplam çok büyük oluyor. Taksiti ya da taksit sayısını küçült." yazar. Toplam yolunun sınırları değişmedi. |
| Yol değişimi | Taksit sayısı korunur. Toplam → Taksit: eşit pay (artıksız taban) yazılır; toplam bölünmüyorsa yeni toplam "hesaplandı" notuyla görünür (1.000 / 3 → 333,33, toplam 999,99). Taksit → Toplam: taksit × sayı yazılır. Yazılan hiçbir şey kaybolmaz: hesaplanamıyorsa (sayı yok ya da geçersiz) hedef alan olduğu gibi kalır; kullanıcı öbür yola yalnızca bakıp döndüyse (taşınan değer ve sayı değişmediyse) alan yazdığı gibi kalır (1.000 / 3 → Taksit → Toplam: yine 1.000). |
| Tek ödeme | Sayı 1 iken hesaplanan satır gösterilmez (taksit toplamın aynısı). |
| Klavye | Yol değişirken tutar alanı odaktaysa odak yeni alana geçer; klavye kapanmaz. |
| "Tutar çok büyük" (16 Kasım 2026, 8. madde ardından) | Bütün tutar alanlarında (plan ekleme, sonra öde, sabit ödeme, ödeme düzenleme, kurulum) biçimi doğru ama 13 tam basamaktan uzun tutar artık "Bu tutar çok büyük." alır; önceden biçim hatası örneğini ("Tutarı rakamla yaz, örneğin 1250,50.") alıyordu. Ayrım yalnızca `money_format.dart` içinde (`amountTooLarge`); kabul edilen tutarlar değişmedi. |
| Hatırlama | `app_settings.last_amount_entry` (şema v10, boş = Toplam). Çok ödemeli plan kaydedildiğinde yazılır; "Sonra öde" kaydı dokunmaz. Göç: mevcut kullanıcılar boş başlar, yani ekran bugünkü gibi "Toplam" ile açılır. Yedek biçimi henüz yok; bu ayar ileride yedeğe girerse adıyla saklanır (`total` / `installment`). |

## Kaynak öncelik sırası ve geliştirme düzeni (16 Kasım 2026)

| Konu | Karar |
|---|---|
| Kaynak öncelik sırası | Ürün sahibinin 15 Kasım 2026 kararı: 1) bu dosya, 2) `docs/kalan-birlesik.html` içindeki ürün sahibi kararları, 3) aynı dosyadaki Yol Haritası (ürün, özellik, tasarım, dil, para birimi) ve Fiyatlandırma (fiyat, mağaza, maliyet), 4) `docs/kimlik/kalan-uygulama-dosyasi.html` yalnızca ilke, ses tonu ve kimlik için. `docs/BACKLOG.md` eski sıralamadır; 7. madde (bulut AI) Karar 3 ile, 8. madde (aylık/yıllık Pro) Karar 2 ile geçersizdir. |
| Geliştirme düzeni | İşler `kalan-gelistirme` skill'iyle yapılır: arama ve test Haiku, ana oturum ve bağımsız parçalar Sonnet, büyük ya da riskli işin planı, riskli diff incelemesi ve iki denemede çözülmeyen hata Opus (`.claude/agents/`). Ürün kuralları `kalan-palet`, `kalan-urun-kurallari`, `kalan-yerellestirme` skill'lerinde. İlerleme `docs/ILERLEME.md`'de tutulur. |
| Ürün sahibi profili (16 Kasım 2026) | Ürün sahibi yazılımcı değildir; kodu okumaz, uygulamayı telefonda deneyerek kontrol eder. Bu yüzden `kalan-gelistirme`: soruları ve raporu sade Türkçeyle, kod ve dosya adı olmadan yazar; raporda "Telefonda dene" adımları ve PR'daki ekran görüntülerinin yeri bulunur; ekranda görünecek tercihler ürün kararı sayılır ve önizlemeyle sorulur; arayüz değişikliğinde golden görüntüleri komşu ekranlarla karşılaştırılarak görsel uyum kontrol edilir. Neden: testler hesabın doğruluğunu denetler, ekranın uyumunu denetlemez; ürün sahibi de bunu koddan yakalayamaz. |
| Ana oturum modeli (16 Kasım 2026) | Ürün sahibinin kararı: ana oturum varsayılan olarak Opus (`.claude/settings.json`). Neden: ürün sahibi kodu okumadığı için hataları ve görsel uyumsuzlukları kendisi yakalayamaz; yargı gerektiren kararlar güçlü modelde kalır. Limit daralınca küçük ve kuralları net işlerde (metin, çeviri, küçük düzeltme) oturum Sonnet ile açılabilir. Alt ajanların modelleri değişmedi. |

## Ödeme şekli (16 Kasım 2026)

Yol Haritası 9. Açık sorular ürün sahibinin iş tanımında cevaplandı: mevcut planlarda varsayılan "belirtilmemiş" (kart taksidi hariç), "Elle" tek seçenek (alt seçenek yok), ikon ana ekran satırında da görünür.

| Konu | Karar |
|---|---|
| Seçenekler | Her planda "Otomatik çekilir", "Elle ödenir" ya da "Belirtilmedi". Belirtilmemiş, önceki davranışın birebir aynısıdır (zaman ve metin, testli). Sabit ödemelerde ödeme şekli yok. |
| Varsayılan | Yeni kart taksidi planı "Otomatik çekilir"; diğer yeni planlar "Belirtilmedi". Kullanıcı seçerse onun seçimi kalır. |
| Saklama | `plans.payment_method` (şema v11, adıyla: `automatic` / `manual`; boş = belirtilmemiş) ve `plans.charge_source_id` (çekildiği yer, isteğe bağlı, kaynağa bağlı; kaynak silinirse boşalır). Göç: mevcut kart taksidi planları `automatic`, diğer bütün planlar boş; başka hiçbir veri değişmez (testli). |
| Çekildiği yer neden ayrı alan | `plans.source_id` planın kime ödendiğidir (sağlayıcı ya da kart): 4 ödemeli Zip planı Zip'e bağlıdır, ama para bir karttan çekilir. Çekildiği yeri `source_id`'ye yazmak planın sağlayıcısını değiştirirdi. En sade değişiklik tek bir boş olabilir sütun. Kart taksidinde çekildiği yer seçilmemişse planın kendi kartı sayılır; bu yüzden göçte ve kartın kendisi seçildiğinde boş saklanır (kart değişirse çekildiği yer de onu izler). Kart taksidinde "Seçilmedi" seçeneği yok. Diğer planlarda çekildiği yer yalnızca "Otomatik" iken sorulur; başka şekle geçince unutulur. |
| Kaç gün önce | Planın kendi seçimi (Kapalı / Farklı gün) her zaman önce gelir. Genel ayarı izleyen planlarda: otomatik ve belirtilmemiş = genel ayar, elle = genel ayar + 1 (genel 7 ise 8). Yalnızca `defaultLeadDaysFor`. |
| Bildirim metni | "Önceden" ve "gününde" bildiriminde, birleşen ödemelerin hepsi aynı şekilse bugünkü cümlenin sonuna tek cümle eklenir: otomatik "Otomatik çekilir; tutar hesabında bulunsun." / "It's taken automatically; keep the amount in your account.", elle "Bu ödemeyi sen yapıyorsun." / "You make this payment yourself." (çoğulu da var). Karışık, belirtilmemiş ve gecikmiş bildirimlerde metin eskisi gibi. Seçim saf Dart'ta (`reminderMethodOf`), metin `ReminderTexts`'ten. Tutar gizliyken de cümle kalır, tutar yazılmaz. Israrlı hatırlatma, düğmeler, gecikme ve dönem hesabı değişmedi. |
| Ton | Brifteki "Ödemeyi yapmayı unutma" örneği kullanılmadı: uygulamanın sakin ton testi "unutma"yı yasaklıyor (yargı/alarm sözcüğü). Yerine bilgi veren "Bu ödemeyi sen yapıyorsun." yazıldı. Ünlem yok. |
| Yer | Plan ekleme: "Ayrıntı ekle" bölümünde (formdaki alan sayısı değişmedi); "Sonra öde" formunun altına da yalnızca ödeme şeklini içeren "Ayrıntı ekle" eklendi. Plan düzenleme (taksitli ve sonra öde): kaydet düğmesinin üstünde. Plan ayrıntısı: ödemelerin altında, "Israrlı hatırlatma"nın üstünde bir satır (ikon + kelime, "Otomatik çekilir · Bonus"); dokununca seçim açılır, otomatikse ardından çekildiği yer sorulur. Ödemeler ekranın üstünde kalsın diye ayar satırlarıyla birlikte altta (mevcut desen). |
| İkon | Mevcut Material ikon setinden, textMuted: otomatik `account_balance_outlined` (hesap), elle `front_hand_outlined` (el). Önce dönen oklar denendi; plan ayrıntısında hemen altındaki "Israrlı hatırlatma" ikonuna çok benzediği için değiştirildi. Ana ekran satırında tarihin önünde 16 px (satırdaki "Ödendi" onay ikonuyla aynı boyut); belirtilmemişte ikon yok. Ekran okuyucu ikonu kelimeyle okur ("Otomatik çekilir", "Elle ödenir"). Günü geçenler bölümündeki satırlara eklenmedi. |
| Renk | Seçim mevcut `ChoiceField` stilinde: seçili seçenekte onay işareti, tema varsayılan rengi. Brifteki "seçili seçenek accent" uygulanmadı (accent yalnızca "kalan"). Yeni renk yok. |
| Düzenleme ekranı | Ödeme şekli eklenince kaydet düğmesi küçük ekranlarda aşağı kaydı; form artık tümüyle kurulan kaydırılabilir sütun (`SingleChildScrollView`), görünüm aynı. Bir test, odaklı alan ekranı geri kaydırdığı için mevcut `saveEdit` yardımcısını kullanacak şekilde güncellendi (davranış değişmedi). |
| Tekrar ve ertelenen bildirimler | Israrlı hatırlatmanın anları ve düğmeleri değişmedi (testli). Elle ödenen planda "önceden" günü bir gün öne geldiği için "her gün" tekrarı da bir gün önce başlar; bu, +1 gün kuralının doğal sonucu. "Önceden" ve "gününde" türündeki tekrar ve ertelenen bildirimler de ödeme şekli cümlesini taşır (aynı ödeme, aynı bilgi). |
| "Kendi kartı" | Yalnızca kart taksidi planında planın kartı "çekildiği yer" sayılır. Kaynak adı bir kartla eşleşen 4 ödemeli, aylık, elle ya da sonra öde planlarında sayılmaz (diff incelemesi bulgusu, düzeltildi). |
| Farklı gün listesi | Elle ödenen planda genel ayar 3/5/7 ise "genel ayara göre" gün 4/6/8 olur ve seçeneklerde yoktur; "Farklı gün" listesi açılınca genel ayarın günü işaretli gelir. |

## Maaş günü özeti (16 Kasım 2026)

Yol Haritası 10. Açık sorular ürün sahibinin iş tanımında cevaplandı: varsayılan açık (mevcut kullanıcılarda da), gelir yoksa yalnızca ödeme sayısı ve toplam (bildirim yine gelir), hafta sonuna denk gelen maaş gününde bildirim o gün (kaydırma yok, Karar 3).

| Konu | Karar |
|---|---|
| Ne zaman | Her maaş döneminin motordaki ilk günü (aylıkta ay kısaysa son gün, iki haftada bir ve haftalıkta bilinen maaş gününden adımla), kullanıcının hatırlatma saatinde. Yalnızca sıradaki özet kurulur: bugün maaş günüyse ve saat geçmediyse bugünkü, yoksa bir sonraki dönemin (`nextPaydayPeriod`). |
| İçerik | Ana ekranın o sabah göstereceği sayılar: aynı hesap (`periodSummaryOn`, `lib/data/period_totals.dart`; ana ekran da artık bunu kullanır), dönemin ilk günü "bugün" sayılarak. Böylece o güne kadar ödenmemiş kalan günü geçmiş ödemeler yeni dönemin toplamına girer (`countingDate`, ana ekranla aynı). Ödemeler değişince içerik yeniden kurulur. |
| Metin | "Yeni dönem başladı. Bu dönem 6 ödeme, toplam 8.300 TL. Kalan 12.450 TL." Gelir yoksa kalan cümlesi yok. Eksi kalanda "Bu dönem 1.200 TL eksik görünüyor." (eksi işareti olmadan tutar). Ödeme yoksa "Bu dönem ödeme yok." Tavsiye, yorum, ünlem yok. EN: "A new pay period has started. 6 payments this period, ₺8,300 in total. ₺12,450 left." / "This period looks ₺1,200 short." |
| Tutar gösterme | Mevcut "Bildirimde tutarı göster" anahtarı kapalıysa özet yalnızca ödeme sayısını söyler ("Bu dönem 6 ödeme var."); kilit ekranında tutar görünmesin diye. Uygulama genelindeki tutar gizleme (28. madde) yapılınca özet ona da uyacak; şimdi kod yok. |
| Ayrı bildirim | Ödeme bildirimleriyle birleştirilmez, düğmesi yok, dokununca ana ekran. Kendi kimlik aralığı (3 × 2^28 + gün). Ödeme bildirimlerinin listesi, zamanı ve metni değişmedi (testli). Özet planlayıcıda ayrı adımdır (`withPaydaySummary`); bildirim türü listesine yeni tür eklenmedi, böylece düğme ve erteleme kuralları hiç etkilenmez. |
| 60 sınırı | Özet sınırın içinde sayılır; ödeme bildirimleri önceliklidir: liste 60 ödeme bildirimiyle doluysa özet o kurulumda eklenmez. |
| Açma/kapama | Ayarlar > Hatırlatmalar'da "Israrlı hatırlatma"nın altında anahtar (mevcut anahtar stili; accent yok). Hatırlatmalar ana anahtarı kapalıyken özet de kurulmaz ve satır pasif görünür. Bildirim izni yoksa mevcut izin satırı geçerli; yeni izin isteği yok. Saklama: `app_settings.payday_summary_enabled` (şema v12, varsayılan açık; göçte mevcut satır açık gelir). |
| Yeniden kurma | Mevcut tek merkez (`ReminderSync`): planlar, ödemeler, sabit ödemeler ve ayarlar (gelir, maaş günü, para birimi, dil, saat, anahtar) değişince; uygulama açılınca ve öne gelince. İkinci zamanlayıcı yok. |
| Test yardımcısı | Sahte bildirim kapısı ödeme bildirimlerini ve özeti ayrı listeler (`pending` / `paydays`); gerçek kapıya ikisi birlikte verilir. Mevcut testler değişmeden geçer. |
| Bilinen sınırlar (diff incelemesi) | 1) Yalnızca sıradaki özet kurulduğu için, özet geldikten sonra uygulama bir sonraki maaş gününe kadar hiç açılmazsa (ve bildirimden "Ödendi" de kullanılmazsa) sonraki dönemin özeti kurulmaz; uygulama açılınca yeniden kurulur. Brifteki "yalnızca sıradaki dönem başı" kararının sonucu. 2) Android'de zamanlama kesin olmadığından, saat geçmiş ama bildirim henüz gösterilmemişken uygulama açılırsa o günün özeti düşebilir; ödeme hatırlatmalarında da var olan durum. 3) Maaş günü özet geldikten sonra hatırlatma saati daha geç bir saate alınırsa özet aynı gün bir kez daha gelir; "gününde" hatırlatmasında da böyle. Üçü de bu maddede değiştirilmedi. |

## iOS + Android arayüz kuralları (18 Kasım 2026)

| Konu | Karar |
|---|---|
| Ağırlık | Önce marka: iki telefonda da aynı Kalan görünümü. Platforma uyan davranıştır (sayfa geçişi, geri jesti, açılır pencere, anahtar, kaydırma, titreşim). |
| Liquid Glass | Kullanılmaz. Cam, bulanıklık ve saydam katman yok; yüzen katmanlar da düz `surface` + `border`. Apple'dan yalnızca geçiş, kaydırarak geri, titreşim ve dokunma alanı alınır. |
| Material 3 Expressive | Yalnızca "standard" yumuşak hareket; sıçrayan yay, şekil değiştiren düğme, büyük renk blokları yok. |
| Yazı tipi | Telefonun kendi yazı tipi (SF / Roboto); özel font yok. Hiyerarşi `textTheme` rolleriyle. |
| Dokunma | İki platformda en az 48x48 (Apple'ın 44 pt alt sınırını da karşılar). |
| Skill | `.claude/skills/flutter-cross-ui`: her UI işinde `kalan-palet` ile birlikte, ayrıca istenmeden uygulanır. |

## Arayüz uyum düzenlemesi (18 Kasım 2026)

Mevcut ekranlar `flutter-cross-ui` kurallarına bağlandı; iş mantığı, veritabanı ve metinler değişmedi.

| Konu | Karar |
|---|---|
| iPhone'da açılır pencere (ürün sahibi, 18 Kasım 2026) | Apple'ın hazır penceresi (`CupertinoAlertDialog`, `AlertDialog.adaptive`) her zaman buzlu cam ve karartma kullanıyor; "cam yok" kararıyla çeliştiği için kullanılmaz. iPhone'da düz Kalan penceresi Apple düzeninde: başlık ve mesaj ortada, düğmeler alt kenarda ince çizgiyle ayrılmış. Android'de Material pencere. Tek yol: `showKalanDialog` + `KalanAlertDialog` + `KalanDialogAction` (`lib/core/design/kalan_dialog.dart`). Silme `late`. Dışarı dokununca iki telefonda da kapanır. |
| Seçim listeli pencereler | Tema, dil gibi listeler (`ChoiceDialog`) iki telefonda da Kalan'ın liste penceresi olarak kalır; yalnızca açılış yolu `showKalanDialog`. |
| Android öngörülü geri (ürün sahibi, 18 Kasım 2026) | Manifest'e `android:enableOnBackInvokedCallback="true"` eklendi; temada Android için `PredictiveBackPageTransitionsBuilder`. iOS'ta temanın kendi Cupertino geçişi (sağdan kayma, kenardan geri) kullanılır. |
| Cupertino paketi | `CupertinoPageTransitionsBuilder` ve `CupertinoDialogAction` artık ayrı `cupertino_ui` paketinde; doğrudan bağımlılık eklenmedi (yeni paket yok). iOS geçişi temanın varsayılanından gelir, pencere düğmeleri Kalan'ın kendi yardımcısı. |
| Anahtarlar | `SwitchListTile.adaptive`; iPhone'da şekil Apple'ın, renk temadaki mürekkep tokenları (`ThemeData.adaptations` ile; yeşil yok). |
| Yükleniyor göstergesi | `.adaptive` sürüme geçmedi: iPhone sürümü tokenla renklendirilemeyen Apple grisi kullanıyor. |
| Ölçüler | Boşluk `KalanSpace` (4, 8, 12, 16, 24, 32; liste altı FAB payı 96), köşe `KalanRadius` (8, 12, 16): `lib/core/theme/kalan_spacing.dart`. 4'ün katı olmayanlar en yakın kata yuvarlandı, eşitlikte küçüğe; 2 sıfır olmasın diye 4 (2→4, 6→4, 10→8, 20→16; ana kartın iç boşluğu diğer kartlarla aynı 16 oldu). |
| Titreşim | Yalnızca `KalanHaptics.success()` (hafif): "ödendi" işaretleme (ana ekran, günü geçenler, plan ayrıntısı) ve plan / sabit ödeme kaydı. Geri alma, işareti kaldırma ve bildirim düğmesinde yok. |
| Bekçi | `test/app/ui_guard_test.dart`: `lib/features` altında cam, platform dallanması, çıplak `showDialog`, `HapticFeedback`, adaptif olmayan anahtar, sayıyla köşe ve boşluk yakalanır. Bildirim ağ geçidindeki iOS metin seçimi istisna. iPhone penceresinde düğmeler büyük yazıda alt alta dizilir; başlık ekran okuyucuya başlık olarak bildirilir. |

## Pro satın alma (11) (18 Kasım 2026)

Ürün sahibi kararları (Karar 2 ve 18 Kasım 2026; brifteki "abonelik + tek seferlik" önerisi geçersiz):

| Konu | Karar |
|---|---|
| Model | Tek ürün, ömür boyu "Kalan Pro" (non-consumable). Abonelik, deneme, indirim, tanıtım fiyatı, geri sayım yok. |
| Fiyat | ABD 14,99 $, Türkiye 249,99 ₺; diğer bölgeler mağazanın yerel fiyatı. Uygulama fiyatı yalnızca mağazadan okur (`ProductDetails.price`); okunamazsa "Fiyat şu an alınamadı." ve "Yeniden dene". Fiyat kodda ve ARB'de yok (bekçi testi). |
| Kütüphane | Yalnızca resmi `in_app_purchase` (+ aynı ailenin `in_app_purchase_android` ve `in_app_purchase_storekit` paketleri, doğrudan bağımlılık olarak; ağaçta zaten vardı, yalnızca platforma özel sorgular için doğrudan import ediliyor). RevenueCat ya da sunucu doğrulaması yok. Kullanıcı kimliği (applicationUserName) verilmez. |
| İade / iptal | Planlar silinmez, görünür ve düzenlenebilir kalır; açık plan 4'ün altına inene kadar yeni plan eklenemez. Pro yalnızca mağazanın açık sinyaliyle kalkar; ağ hatası, zaman aşımı, ulaşılamama ve hata Pro'yu asla kaldırmaz. Kural tek saf fonksiyonda (`verdictFor`, `lib/entitlement/pro_rules.dart`) ve tablo testinde. |
| Aile paylaşımı | Açık (App Store Connect ayarı; StoreKit test dosyasında da açık). |
| Pro ekranı listesi | "Yakında" listesi yok; bugün yalnızca "Sınırsız açık plan". Diğer Pro maddeleri (32, 35, 36, 43, 44, 45) satırlarını tek kaynağa ekler: `lib/features/pro/pro_features.dart`. |
| 5. plan | Kayıt sırasında sınıra gelince alt sayfa: [Pro'ya bak] [Şimdi değil]. "Şimdi değil" alanları korur. |
| Görünüm | "Pro'yu al" accent dolgu + onAccent; "Satın alımı geri yükle" accentText metin düğmesi; fiyat `text`; ekran zemini `surface`. Rozet, parıltı, degrade, taç yok. |
| iOS testi | StoreKit yapılandırma dosyası `ios/Runner/Kalan.storekit`, Runner şemasının Çalıştır adımına bağlı. Ürün kimliği `kalan_pro_lifetime` (tek sabit: `proProductId`, iOS ve Android aynı, paket kimliğine bağlı değil). |

Teknik kararlar (Claude, 18 Kasım 2026):

| Konu | Karar |
|---|---|
| Saklama | Son bilinen durum (`notPro` / `pending` / `pro`) cihazda `shared_preferences` ile (`pro.status`), tema seçimiyle aynı yol. Veritabanına konmadı: onboarding'den önce de mağaza olayı gelebilir (yeniden kurulum, ebeveyn onayı, aile paylaşımı) ve o sırada ayar satırı yok; Pro kullanıcı verisi olmadığından yedeğe ve dışa aktarmaya da girmemeli. Şema değişmedi. Okunamayan değer "ücretsiz" sayılır. |
| Açılış | Saklanan durum ilk karede geçerli (çevrimdışı Pro çalışır); mağaza arka planda sorgulanır. Satın alma akışı uygulama açılınca dinlenmeye başlar (onboarding öncesi dahil). |
| Android sinyali | Google Play satın alma sorgusu (`queryPastPurchases`) başarılı ve ürün yoksa "sahip değil" sayılır; iade edilen satın alma listeden düşer. Hata kodu ya da istisna: koru. Hesap değişince Play "yok" der ve Pro kalkar; aynı hesapla "geri yükle" geri getirir (karar 4'ün sonucu). |
| iOS sinyali | Açılışta StoreKit 2'nin cihazdaki yetki listesi okunur; liste boşsa "bilinmiyor" sayılır ve Pro korunur (eklenti iade bilgisini taşımıyor). Kullanıcı "Satın alımı geri yükle"ye dokunduğunda App Store ile eşitleme (`AppStore.sync`) başarılıysa boş liste "sahip değil" sayılır ve Pro kalkar. Yani iPhone'da iade, geri yüklemede fark edilir. |
| Dışarıdan gelen satın alma olayı | Satın alma sürmüyorken gelen "satın alındı" olayı doğrudan Pro vermez; mağazanın listesi sorulur (App Store eklentisi iadeleri de "satın alındı" diye iletiyor). Ebeveyn onayı ve aile paylaşımı bu yolla açılır. |
| Sıra | Önce durum cihaza yazılır, sonra `completePurchase`. Onaylanmamış satın alma (Android 3 gün kuralı) her açılışta yeniden tamamlanır. |
| Satın alma sonrası | Pro açılınca Pro ekranı kendiliğinden kapanır ve kullanıcının başlattığı kayıt aynı alanlarla sürer (plan eklenir, ana ekranda "Plan eklendi."). Kullanıcı "Kaydet"e zaten dokunmuştu; önizleme ekrandaydı. |
| Fiyat yokken | Fiyat okunamadıysa "Pro'yu al" pasif: kullanıcı fiyatı görmeden satın alma başlatmaz. |
| Bekleyen ödeme | "Ödeme onay bekliyor. Onaylanınca Pro açılır." notu; Pro sayılmaz; "Pro'yu al" yine dokunulabilir (reddedilen istek takılı kalmasın). |
| Hata dili | İptal sessiz. Satın alma hatası Pro ekranında tek satır, `late` yalnızca ikonda. Geri yükleme sonucu kısa bildirim: "Pro açıldı." / "Bu mağaza hesabında Pro bulunamadı." / "Mağazaya şu an ulaşılamadı. Sonra yeniden dene." |
| Ayarlar | "Kalan Pro" satırı (Ücretsiz / Pro / Onay bekliyor) ve "Satın alımı geri yükle" satırı, Tema'dan sonra. Debug derlemedeki Pro anahtarı kaldı; yayın derlemesinde etkisiz (`KalanEntitlement.debugBuild`). |
| Bekçi | `test/app/purchase_guard_test.dart`: `lib/features`, `lib/core`, `lib/app` içinde mağaza paketi import'u yok; kullanıcı kimliği alanları yok; fiyat kodda ve ARB'de yok. CI, birleşik yayın manifest'inde INTERNET izni varsa kırmızı olur. |
| Ağ izni | Google Play Billing, Google'ın `datatransport` kütüphanesini getiriyor; bu kütüphane kendi tanı verisi için `INTERNET` ve `ACCESS_NETWORK_STATE` izni ekliyor. Ürün sahibi kararı (19 Kasım 2026): ikisi de yayın derlemesinden `android/app/src/release/AndroidManifest.xml` içinde `tools:node="remove"` ile çıkarılır. Satın alma Play Store uygulaması üzerinden (`com.android.vending.BILLING`, IPC) yürür; Kalan'ın kendi ağ isteği yok. Debug ve profile derlemeleri Flutter aracı için `INTERNET`i korur. Açık iş: Google Play iç test sürümünde satın almanın izinsiz çalıştığı doğrulanacak (Play geliştirici hesabı gerekiyor). |

## İleriki dönemler (12) (19 Kasım 2026)

Ürün sahibi kararları (yeniden sorulmaz):

| Konu | Karar |
|---|---|
| Dönem sayısı | Herkese aynı 6 dönem, bu dönem dahil; ücretsiz (Karar 4). Brifteki 3 / 12 ve "Pro'da daha çok" seçenekleri geçersiz. |
| Yer | Ana ekranda büyük kalan kartının hemen altında küçük 6 çubuklu şerit; dokununca ayrı "İleriki dönemler" ekranı, bu dönem seçili. |
| Gelir yoksa | Çubuklar yalnızca söz verilmiş kısımla çizilir; ekranda tek satır davet: "Gelirini girersen her dönemde ne kaldığını da görürsün." Grafik gizlenmez. |
| Çizim | Paket yok (fl_chart vb. eklenmez); basit widget'larla. |
| Dönem | Maaş dönemi (takvim ayı değil). Dönem sınırları ve bir ödemenin hangi döneme girdiği yalnızca mevcut hesaptan (`countingDate`, `periodSummaryOn`); grafikteki bu dönem ana ekranla birebir aynı. |

Teknik kararlar (Claude, 19 Kasım 2026):

| Konu | Karar |
|---|---|
| Veri | `comingPeriods` (`lib/features/periods/coming_periods.dart`): her dönem için `periodSummaryOn` (toplam, gelir, kalan, durum) ve ana ekranın satır kuralı `homeEntriesFor` (ana ekran sağlayıcısından çıkarıldı, ana ekran da onu kullanır). Günü geçmiş ödenmemiş ödemeler yalnızca bu dönemde listelenir ve sayılır. Motor değişmedi. |
| Sayı | Özetteki ödeme sayısı ana ekrandaki gibi `itemCount` (Kalan'dan önce ödenmiş taksitler sayıya ve toplama girer, listede görünmez; ana ekranla aynı). |
| Çubuk altı | Dönem adı olarak maaş günü (kısa tarih, "15 Ara"): haftalık ve iki haftalık maaşta da ayırt edilir. Altında dönemin ana sayısı: gelir varsa kalan, yoksa söz verilmiş; eksi dönemde "−₺1,2 B eksik" (`negativeText`). |
| Kısa tutar | `formatMoneyShort` (`money_format.dart`): 1.000 birimin altında tam biçim, üstünde intl compact ("₺12,4 B", "$12.4K", "Rp1.25M"); küçük basamak gösterilmez. Ekranlar `ref.moneyShort` kullanır. |
| Ölçek | 6 çubuk tek ölçekte: en yüksek değer = en büyük söz verilmiş ya da gelir. Sıfır olmayan kısım en az 4 px. |
| Eksi dönem | Ürün sahibinin bu madde için verdiği çizim: çubuğun tamamı `chartCommitted`, gelir seviyesinde ince `negative` çizgi (2 px, çubuktan geniş, zemin üstünde de görünür), çubuk altında eksi işaretli "−₺1,2 B eksik". DESIGN_TOKENS kural 10'a istisna olarak yazıldı. Seçili dönemin özetinde ana ekranla aynı cümle: "Bu dönem ₺1.200 eksik kalıyor." Kırmızı ve `late` yok. |
| Seçim ve odak | Seçili çubuk `text` renginde ince çerçeve; klavye odağında `focus` halkası. Her çubuk tek Semantics düğümü (düğme, seçili bilgisi, dönem ve tutarlar). |
| Dar ekran | Sütun en az 56 px; sığmazsa satır yatay kayar (yön Directionality'yi izler, sağdan sola dilde ilk dönem sağda). |
| Ana ekran şeridi | Etiket yok; tek dokunma hedefi; 6 dönemin hiçbirinde ödeme yoksa şerit gizli, ekran "Önümüzdeki 6 dönemde ödeme yok." der. |
| Günü geçenler | Ekranda bu dönemin günü geçmiş ödemeleri ana ekrandaki satırla ("Günü geçen N ödeme", "Ödendi" → "Ne zaman ödedin?") gösterilir; böylece işaretleme iki ekranda aynı veriyi üretir. Diğer satırlar ana ekranın ödeme satırı. |
| Gün değişimi | Seçili dönem başlangıç gününe göre tutulur: gün dönüp dönemler kayınca aynı dönem seçili kalır; o dönem geçmişte kaldıysa bu dönem seçilir (19 Kasım 2026 düzeltmesi). |
| Gelir daveti | Ayarlar'daki net tutar penceresini doğrudan açar (`editNetIncome`); kaydedince grafik kendiliğinden güncellenir. |
| Animasyon | Yok. |
| Ödeme satırı | Büyük yazıda (2x) taşma düzeltildi: "Bugün/Yarın" notu satır kaydırır. Tutar kendi genişliğinde kalır; yalnızca ad sütunu 96 px'in altına inecekse küçülür (ilk sürümdeki %40 sınırı, dar telefonda uzun tutarları gereksiz küçültüyordu; 19 Kasım 2026 düzeltmesi). Golden'lar aynı. |
| Günü geçen satırı | Ekran okuyucu satıra çift dokununca plan açılır (Semantics'e dokunma eylemi eklendi; 19 Kasım 2026). |


## Takvim görünümü (13) (19 Kasım 2026)

Ürün sahibi kararları (yeniden sorulmaz):

| Konu | Karar |
|---|---|
| Yer | Ayrı sekme yok. İleriki dönemler ekranının üstünde "Grafik \| Takvim" seçimi; varsayılan "Grafik"; seçim uygulama açık kaldıkça hatırlanır. |
| Gün kutusu | Yalnızca işaret; tutar yazılmaz. Toplam, güne dokununca açılan bölümde. |
| Sabit ödemeler | Plan ödemeleriyle aynı işaret. |
| İşaretler | Bekleyen: dolu nokta (`text`). Ödenmiş: içi boş nokta ve küçük tik (`textMuted`). Gecikmiş: `late` nokta ve küçük saat ikonu. Maaş günü: `text` halka. Bugün: `border` çerçeve. Takvimde `accent` ve `chartCommitted` yok (brifteki accent halka ve chartCommitted nokta geçersiz). Her işaretin şekli farklı, ekran okuyucu etiketi var. |
| Bir günde çok durum | Tek işaret; öncelik gecikmiş > bekleyen > ödenmiş. Maaş halkası diğer işaretle birlikte durur. Ekran okuyucu hepsini sayar ("14 Kasım, 2 ödeme, 1 tanesi gecikmiş, maaş günü"). |
| Gecikmiş ödeme | Kendi son ödeme gününde görünür; takvim onu bugüne taşımaz. Ödenmiş ödeme ("Bugün" ile ödenmiş olsa da) son ödeme gününde görünür. Dönem toplamı yine yalnızca `countingDate` ile; takvim ay ya da dönem toplamı göstermez. |
| Ay aralığı | Geriye en çok 12 ay; ileriye son plan ödemesinin ya da bitiş günü olan sabit ödemenin ayına kadar, en az 6 ay. Bitişsiz sabit ödeme aralığı uzatmaz. "Bugün" bu aya döner (bu aydayken pasif). Ok düğmeleri ve yatay kaydırma. |
| Haftanın ilk günü | Cihazın bölge ayarından (intl yerel verisi, `FIRSTDAYOFWEEK`): ABD pazar, Türkiye pazartesi. Sıra: intl'de dil_bölge ("en_US"); yoksa bölgenin CLDR `weekData` ilk günü (ürün sahibi kararı, 19 Kasım 2026: İngilizce telefon + Türkiye bölgesi pazartesi başlasın diye standarttan birebir alınan ülke listesi eklendi; "elle sıra yazılmaz" kuralına bu tek istisna; listede olmayan bölge pazartesi, CLDR `001`); bölge yoksa dilin intl verisi; en son Material'ın uygulama dili varsayılanı. Bölge `deviceRegionProvider`'dan. Gün adları intl'in kısa adı ("Pzt", "Mon"). |
| Gün bölümü | Güne dokununca altta kart: tarih ve gün adı, maaş günüyse "Maaş günü", ödemeler ana ekranın satırıyla ("ödendi" aynı kod), "Toplam …" ya da "Bu gün ödeme yok." |
| Sağdan sola | Izgara satırları `Directionality`'yi izler; kaydırma yönü okuma yönüne göre. |

Teknik kararlar (Claude, 19 Kasım 2026):

| Konu | Karar |
|---|---|
| Gün haritası | `calendarMonth` (`lib/features/periods/calendar_month.dart`, saf Dart): ayın her günü için ödemeler, durum ve maaş günü. Tarihler motorun sakladığı etkin son ödeme günü ve `recurringOccurrences`; yeni tarih kuralı yok. Maaş günleri `PaySchedule` dönem başlangıçları (12. maddeyle aynı kaynak). Plan satırı `planEntryOf` ile ana ekranla aynı yerden kurulur. |
| Durum | Plan ödemesi: ödendi → ödenmiş; `isPastDue` → gecikmiş; diğer → bekleyen. "Kalan'dan önce ödendi" kayıtları hiç görünmez. Sabit ödeme: işaretli gün → ödenmiş; işaretsiz geçmiş tekrar yalnızca içinde bulunulan dönemdeyse gecikmiş (ana ekrandaki "x gün önce" ile aynı); önceki dönemlerin işaretsiz tekrarları bekleyen gibi düz nokta, "x gün önce" notu yok (karar 24a; ödenmiş saymak bilinmeyeni uydurmak olurdu, gizlemek dönem listesiyle çelişirdi). |
| "Ödendi" | Gün bölümünde ana ekranın `PaymentTile` satırı (tek dokunuş, repository `setPaid`, "Geri al"); gecikmiş plan ödemesinde ana ekranın `PastDueRow` satırı ("Ne zaman ödedin?"). İkinci kod yolu yok. `PaymentTile`'a yalnızca `showDaysAgo` (varsayılan açık) eklendi. |
| Seçim hafızası | Bellekte (Riverpod), uygulama kapanınca "Grafik"e döner. Kalıcı yapılmadı: ana ekrandaki şerit 12. maddedeki gibi önce grafiği beklenen yerde açar. |
| Seçim bileşeni | Plan eklemedeki "Toplam \| Taksit" ile aynı `SegmentedButton` ve tema (seçili parça: mürekkep yazı, onay işareti, yükseltilmiş yüzey). Yeni tema rengi yazılmadı. |
| Düzen | Seçim ekranın ilk satırı, içerikle birlikte kayar. Ay başlığı satırında ay adı, "Bugün", önceki ve sonraki ay. Gün hücresi 56 px yüksek; iPhone genişliğinde 53 px geniş (48x48 testli). Dar ekranda yan boşluk küçülür; 336 dp'ye kadar hücre 48 geniş kalır (testli), daha dar ekranda yedi sütun 48'e sığmaz. Ekran okuyucu güne çift dokunarak bölümü açar. Gün sayısı büyük yazıda en çok 1,3 kat büyür, hücre taşmaz. Diğer ayın günleri `textMuted`, işaretsiz, dokunulmaz. |
| Test değişikliği | `coming_periods_screen_test.dart`'ta bir satır: seçim üstte durduğu için "4/4" satırı ekranın altında kalıyor; `skipOffstage: false` ile aranıyor. Mantık değişmedi. 52 ve 53 numaralı golden'lar seçimle yenilendi. |


## Yoğun hafta (14) (19 Kasım 2026)

"Yoğun hafta" (busy week) plan ödemelerinin bir haftaya yığılmasıdır; bir gözlemdir, uyarı değildir. "Sıkışık dönem" (tight, kalanın eşiğin altına düşmesi) ayrı kavramdır; kodda (`BusyWeek`) ve metinde ayrı adlar.

Ürün sahibi kararları (yeniden sorulmaz):

| Konu | Karar |
|---|---|
| Tanım | 7 günlük bir aralıkta en az 3 plan ödemesi VE bunlar o dönemin plan ödemelerinin en az yarısı. İki koşul birlikte. |
| Eşik | Sabit; kullanıcı değiştiremez. Tek yer: `BusyWeekRule` (`lib/core/engine/busy_week.dart`, saf Dart). |
| Yer | Yalnızca İleriki dönemler grafiği ve takvim; ana ekranda yok. |
| Sabit ödemeler | Sayılmaz; yalnızca plan ödemeleri. |
| Pencere | Dönem içindeki her günden başlayan 7 günlük kayan pencere; dönem sonunu aşmaz. Birden çok pencere koşulu sağlarsa en çok ödemeli olan, eşitlikte en erken başlayan. Dönemde en çok bir yoğun hafta. |
| Gösterilen aralık | İlk ve son ödeme günü ("17–21 Ara"), 7 günün tamamı değil. |
| Ödenmiş ödemeler | Sayılır (yığılma ödeme durumundan bağımsız). |
| Grafik | Çubuğun altında (üstünde değil) küçük simge ve "yoğun"; dönem özetinde tek satır "Yoğun hafta: 17–21 Ara · 4 ödeme · ₺5.200", `surfaceRaised` kutuda. |
| Takvim | Yoğun haftanın günleri gün sayılarının altında ince mürekkep çizgiyle birleşik; ilk günde aynı simge; ekran okuyucu "yoğun hafta" der. |

Teknik kararlar (Claude, 19 Kasım 2026):

| Konu | Karar |
|---|---|
| Hangi tarih | Plan ödemesinin motorun sakladığı etkin son ödeme günü; dönemi de bu gün belirler (takvimdeki noktalarla aynı yer). Günü geçmiş ödenmemiş bir ödeme bu dönemin toplamına girse de (`countingDate`) yığılmada kendi gününde sayılır; böylece takvim çizgisi noktalarla örtüşür. Dönem toplamı ve sayısı değişmedi. |
| Kalan'dan önce ödenenler | Sayılmaz: tarihleri hiçbir yerde gösterilmez (ortasından eklenen plan kuralı). |
| Tek veri yolu | `busyWeekIn` (`coming_periods.dart`): grafik `ComingPeriod.busyWeek`, takvim `calendarBusyWeeks` aynı fonksiyonu kullanır. Beklemedeki/kapatılmış plan (19) henüz yok; geldiğinde `plans` listesine ne girerse o sayılır. |
| Simge | `Icons.layers_outlined` (üst üste katmanlar), her yerde `text` renginde. `late`, `negative` kullanılmaz (testli). |
| Dokununca | Grafikte simge çubuğun sütunundadır: sütuna ya da simgeye dokunmak dönemi seçer ve özetteki açıklama kutusunu gösterir (ayrı açılır kutu yok; ikinci dokunma hedefi 48x48'e sığmazdı). Takvimde yoğun haftanın herhangi bir gününe dokununca gün bölümünde aynı kutu. |
| Kutu | `surfaceRaised`, ince `border` çizgisi (kart üstünde de seçilsin diye), metin `text`, tarih `textMuted`. Tarih çevrilmiş cümlenin içinde bulunup soluk yazılır; sözcük sırası çevirmende kalır. |
| Ekran okuyucu | Grafik sütununun etiketine açıklama cümlesi eklenir; takvim gününün etiketine ", yoğun hafta" (bugün'den önce). 13. maddenin üç takvim testindeki beklenen etiketler bu yüzden güncellendi (örnek veride 10–14 Kasım yoğun hafta). |
| Tarih aralığı | `dayRange` (`format.dart`): aynı ayda "17–21 Ara" / "Dec 17–21" (ARB'de sıra), aylar arasında "29 Ara – 2 Oca", tek günde "17 Ara". |
| Takvim çizgisi | Gün sayısının hemen altında, işaret satırının üstünde (bugün ve seçili gün çerçevesinin alt kenarıyla çakışmasın diye); ilk ve son günde hücre ortasından başlar/biter, hafta satırı değişince kendiliğinden kesilir. |
| İki haftalık ve haftalık maaş | Aynı kural. Haftalık maaşta dönem 7 gün olduğundan 3 ve üstü plan ödemesi olan her dönem yoğun haftadır (tanımın doğal sonucu). |


## Dönem açığı (15) (19 Kasım 2026)

Bir dönemin ödemeleri geliri aşıyorsa kullanıcı bunu dönem gelmeden, yargısız bir notla görür. Gelir girilmemişse hiçbir iz yoktur.

Ürün sahibi kararları (yeniden sorulmaz):

| Konu | Karar |
|---|---|
| Metin | İçinde bulunulan dönem: "Bu dönem X eksik kalıyor." (ana ekranın cümlesi, aynen). Gelecek dönemler: "Bu dönem X eksik görünüyor." İngilizcede "This period is X short." / "This period looks X short." |
| Bildirim | Yok. |
| Grafik | Eksi dönemde çubuğun gelire kadar olan kısmı `chartCommitted`, geliri aşan kısmı `negative`; arada gelir seviyesinde ince `text` çizgi; çubuk altında "−… eksik" (`negativeText`). 12'deki "çubuğun tamamı safran, `negative` çizgi" çiziminin yerini alır (DESIGN_TOKENS kural 10). |
| Geciken ödemeler | Yalnızca bu dönemin hesabına girer (motordaki `countingDate`); gelecek dönemlere sızmaz. Yeni kural yok. |
| Yerler | Ana ekran değişmedi. İleriki dönemler grafiği (ana ekran şeridi dahil) yeni çizimle. Dönem özeti gelecek dönemde "eksik görünüyor". Takvim değişmedi. |
| Ekran okuyucu | Eksi çubuğun etiketi "eksik" kelimesini ve tutarı söyler. |

Teknik kararlar (Claude, 19 Kasım 2026):

| Konu | Karar |
|---|---|
| Hesap | `PeriodSummary.shortMinor` (saf Dart, motor): gelirin aşıldığı tutar, artı işaretli; gelir yoksa ya da kalan 0 ve üstüyse null. Durum `negative` olduğunda ve yalnızca o zaman dolu. Gelire eşit olan dönem eksi değildir; bir kuruş fazlası eksidir (testli). |
| Bu dönem mi | `ComingPeriod.isCurrent`: `comingPeriods` listesindeki ilk dönem (bugünü içeren). "kalıyor" / "görünüyor" seçimi yalnızca buna bakar. |
| Çizim ölçüsü | Aşan kısım ölçekli; yalnızca bütün parçalardaki ortak 4 px alt sınır (bir kuruş fazla bile görünür, abartılmaz). Eksi çubuğun tepe yuvarlaklığı aşan kısmın yüksekliğini geçmez (8 px yuvarlak ince bandı yutmasın diye). Yer daralırsa gelire kadar olan kısım kısalır. Gelir 0 ise çubuğun tamamı `negative`, çizgi tabanda. Çizgi 2 px, üst kenarı gelir seviyesinde (aşan kısmın üstüne binmez), çubuktan her yanda 4 px geniş: zemin üstünde de görünür, seçili sütunun çerçevesine değmez (12'de çizgi sütun boyunca uzanıyordu). İlk sürümdeki 8 px alt sınır, küçük açığı abarttığı için kaldırıldı (19 Kasım 2026, ürün sahibinin düzeltme isteği). |
| Eksi işareti | Dönem özetinde cümlenin yanında ana ekrandaki eksi ikonu (`remove_circle_outline`, `negative`) ve cümle `negativeText`; cümledeki tutar işaretsiz (ana ekranla aynı). Çubuk altındaki tutar için aşağıdaki "Çubuk altı tutar" satırına bak. |
| Ekran okuyucu metni | "15 Şubat – 14 Mart: söz verilmiş ₺31.200, ₺1.200 eksik görünüyor." (bu dönemde "eksik kalıyor"). Tutar işaretsiz okunur ("eksi … eksik" tekrarı olmasın diye). Eski `comingPeriodsBarLabelShort` anahtarı kaldırıldı; yerine `comingPeriodsBarLabelShortNow` ve `comingPeriodsBarLabelShortAhead`. Özet: `comingPeriodsShortAhead`. |
| Test değişikliği | `coming_periods_screen_test.dart`'ta bu dönemin çubuk etiketi beklentisi yeni metne, `BarGeometry` eksi dönem testi yeni çizime göre güncellendi. Ana ekran testleri değişmedi. Golden 03 ve 52 (eksi) yeni çizimle yenilendi; 58 yeni (Örnek 1, TR/EN, açık/koyu). |
| Çubuk altı tutar | 12'deki "Kısa tutar" kararının yerini alır (19 Kasım 2026, ürün sahibinin düzeltme isteği). Altı tutarın hepsi sütununa tam biçimde, kullanıcının yazı boyutunda, tek satırda ve seçim çerçevesinden içeride pay bırakarak sığıyorsa hepsi tam yazılır ("-₺1.200 eksik"). Biri bile sığmıyorsa hepsi kısa yazılır ("-₺1,2 B eksik"). Satırda iki biçim karışmaz; tutar kesilmez, bölünmez, küçültülmez. Ölçüm `ComingPeriodsChart` içinde, aynı yazı stiliyle. Standart iPhone genişliğinde (390) beş haneli tutarlar kısa kalır; tam tutar özette. |
| Maaş günü bildirimi | Dönemin ilk günü gönderildiği için içinde bulunulan dönemdir: cümle ana ekranla aynı, "Bu dönem X eksik kalıyor." / "This period is X short." (önceden "görünüyor" / "looks"; 10. maddeden kalan tutarsızlık, ürün sahibinin düzeltme isteği). |

## Kart ekstre tahmini (16) (19 Kasım 2026)

Kart taksidinde kullanıcı taksiti değil ekstreyi öder. Kaynaklar ve kartlar ekranında her kart, sıradaki ve sonraki beş ekstresine düşen taksitleri gösterir.

Ürün sahibi kararları (yeniden sorulmaz):

| Konu | Karar |
|---|---|
| Yer | Mevcut Kaynaklar ve kartlar ekranı; her kartın kendi kartında. |
| Kaç ekstre | Sıradaki ve sonraki 5 ekstre (toplam 6). |
| Hangi planlar | Yalnızca o kartın kart taksidi planları. Karttan çekilen diğer planlar (sonra öde gibi) bu görünümde yok. |
| Ödenmiş taksit | Ekstre toplamına girer (ekstre tutarı ödenip ödenmediğinden bağımsızdır). |
| Ücret ve renk | Ücretsiz. Toplamlar `text`; `accent` kullanılmaz. |
| Sıradaki ekstre | Son ödeme günü bugün ya da sonra olan ilk ekstre. Hesap kesim tarihi geçmişse "Kesildi" notu (`textMuted`, kilit ikonu). |
| Satır | "14 Kas ekstresi", "3 taksit · Son ödeme 24 Kas" ve toplam; taksiti olmayan ekstre "Taksit yok · Son ödeme …", toplam yazılmaz. |
| Ayrıntı | Ekstreye dokununca: plan adı, taksit sırası ("3/10"), tutar ve "Ödendi". |
| Not | Kartın altında `textMuted`: "Yalnızca Kalan'a girdiğin taksitler." (toplam kart borcu değildir). |
| Bölüm görünmez | Kartın altı ekstresinin hiçbirinde taksit yoksa. |
| Terimler | Ekstre, hesap kesim, son ödeme ayrı ARB anahtarları; çevirmen açıklamalarında pazar karşılığı notu. Çeviri bu maddede yok. |
| Rota | 17. maddenin bildirimi için karta özel rota (kart kimliğiyle). |

Teknik kararlar (Claude, 19 Kasım 2026):

| Konu | Karar |
|---|---|
| Taksitin ekstresi | Tek saf fonksiyon: `CardTerms.statementForDue(due)`. Kaydedilmiş son ödeme gününe, son ödeme günü (`dueFor`) en yakın olan ekstre; eşitlikte önceki. Motorun ürettiği her tarih kendi ekstresine birebir döner (tüm 31×31 gün çifti, hafta sonu açık/kapalı, iki yıl testli). Elle kaydırılmış, ortasından eklenmiş ya da kart günleri değiştikten sonra eski tarihte kalmış (ödenmiş) bir taksit de birkaç gün kaysa geldiği ekstrede kalır. Gerekçe: "son ödeme günü bu tarihe eşit ya da sonra olan ilk ekstre" kuralı tek günlük kaymada taksiti sonraki aya atıyor ve o ayı iki kez sayıyordu (mimar incelemesi). |
| Sıradaki ekstre | Ayrı fonksiyon: `CardTerms.nextStatement(today)`, son ödeme günü bugün ya da sonra olan ilk ekstre. "Kesildi": hesap kesim tarihi bugünden önce. Kesim günü kendisi "Kesildi" değildir (o günkü alışveriş o ekstreye girer, DECISIONS 4). |
| Altı ekstre | `cardStatements` (motor, `lib/core/engine/card_statement.dart`): sıradaki ekstreden başlayarak her ay `statementInMonth` (ay sonuna sıkıştırılmış kesim günü). Ekstre tarihi hesabı `cardInstallmentDates` ile aynı yerden (`statementInMonth`); davranış değişmedi. |
| Aynı son ödeme günlü iki ekstre | Kesim 28-30 ve son ödeme ondan 1-3 gün sonra gibi nadir ayarlarda kısa ay iki ekstreye aynı son ödeme gününü verir (ör. 28 Şub ve 28 Mar ekstreleri ikisi de 30 Mar). Tarih tek başına ayıramaz; aynı planın ardışık taksitleri ardışık ekstrelere konur (motorun kuralı). Tek ödemeli bir kayıt önceki ekstrede kalır; ikisinin son ödeme günü zaten aynıdır. Elle birkaç gün kaydırılmış ortak günlü taksit de ileri taşınır (uzaklık eşitse); sonraki taksidin tarihi elle değiştirilmişse önceki taksit ona bakılarak taşınmaz (mimar incelemesi, testli). |
| Sıradaki ekstreler dışında kalan ekstre | Ayrıntı ekranı yüklenirken bekleme göstergesi. Açılan ekstre artık sıradaki altı ekstreden biri değilse (eski bağlantı, silinmiş kart) "Bu ekstre kartının sıradaki ekstreleri arasında değil." yazar; "Taksit yok" denmez (bilinmeyen şey söylenmez). |
| Ortasından eklenen kart planı | Önce "bilinen eksik" olarak bırakılmıştı; aynı gün ürün sahibinin isteğiyle düzeltildi (aşağıdaki "Kart tarihleri ekstre ekstre" bölümü). |
| Kalan'dan önce ödenmiş | Sayıya ve toplama girer; ayrıntıda tek tek listelenmez ve tarihi yazılmaz: planın adıyla tek satır "1 taksit Kalan'dan önce ödendi · ₺1.200" (mevcut metin). |
| Rotalar | `/sources?card=ID` ekranı o karta kaydırarak açar (17. madde bildirimi bunu kullanacak). `/source/ID/statement/GÜN` tek ekstreyi açar (GÜN: hesap kesim tarihinin epoch günü). |
| Ekran düzeni | Kaynaklar ve kartlar ekranında her kaynak artık kendi `surface` kartında (önce düz liste satırıydı); kart başlığı, bölünmüş çizgi, "Ekstreler", altı satır, not. Ekstre satırı en az 48 yüksekliğinde, sonda `chevron_right`. Ayrıntı ekranı plan ayrıntısındaki başlık kartı desenini izler; büyük sayı yok (ana sayı "kalan"dır). Büyük yazıda tutar sığmazsa küçülür (ödeme satırıyla aynı ölçü). |
| Sıralama | Ekstre içinde son ödeme gününe, sonra plana, sonra taksit sırasına göre. |
| Metinler | Yeni anahtarlar `cardStatement*` (TR ve EN). Plural: "{count} taksit". Başka dil dosyasına dokunulmadı. |
| Şema | Değişmedi. |

## Kart tarihleri ekstre ekstre (16 ardından) (19 Kasım 2026)

Ürün sahibinin isteği: 16'da bilerek bırakılan eksik kurallara göre düzeltilsin. CLAUDE.md "geriye tarih ileri yön kuralıyla tutarlı" der; kart planında ileri yön kuralı her ekstreye bir taksittir (`cardInstallmentDates`).

| Konu | Karar |
|---|---|
| Sorun | "Bu plan zaten sürüyor", ortasından eklenen kart planı, kart günleri değişince alışveriş tarihsiz planın yeniden hesabı ve önerilen "sıradaki ödeme" tarihi, kartın her ayki son ödeme gününü kullanıyordu. Ekstre günü 28-30 ve son ödeme günü bundan sonra olan kartta kısa ay iki ekstreye aynı son ödeme gününü verir ve bir ayı boş bırakır (28 Şub ve 28 Mar ekstreleri ikisi de 30 Mar'da, şubatta hiçbir ekstrenin son ödemesi yok). Eski düzen "28 Şubat" gibi hiçbir alışverişin almayacağı bir tarih üretiyor, ekstre görünümü de bu planları yanlış bölüyordu. |
| Kural | Tek fonksiyon `dueAfterStatements` (motor): girilen tarihin ayındaki son ödemenin ekstresinden ekstre ekstre ilerler, tarih `dueFor(ekstre)`. Girilen tarih aynen kalır. |
| Normal kartlar | Tarihler birebir aynı (ortak son ödeme günü olmayan bütün kartlar: 31×31 gün çifti, hafta sonu açık/kapalı, iki yıllık tarihler; testli). Tek istisna eski bir hata: hafta sonu kaydırması önceki ayın son ödemesini bu ayın 1-2'sine taşıdığında, ayın 1'i girilirse önceki taksit girilen günden sonraya düşüyordu; artık sıra korunur. Diğer değişiklikler yalnızca 28/29, 28/30, 28/31, 29/30, 29/31, 30/31 ayarlı kartlarda. |
| Sıra güvencesi | Girilen tarihten önceki taksitler hiçbir kartta ondan sonraya, sonrakiler ondan önceye düşmez (bütün kartlar, iki yıllık her girilen tarih; testli; mimar incelemesi). Ortak son ödeme gününden önce girilen tarih önceki ekstreye ait sayılır. |
| Ortak son ödeme günü girilirse | Girilen ödeme sonraki ekstreye ait sayılır; ileriki ödemeler ayda bir düşer, aynı güne ikinci bir ödeme çıkmaz. Önceki (Kalan'dan önce ödenmiş) taksitler ileri yön kuralındaki gibi önceki ekstrelere yerleşir. |
| Ekstresi olmayan ay | Girilen tarihin ayında hiçbir ekstrenin son ödemesi yoksa (şubat) o tarihten sonraki ilk ekstre. |
| Önerilen sıradaki tarih | Bugünden sonraki ilk ekstre son ödeme günü; o kartta 28 Şubat önerilmez. |
| Kayıtlı veri | Değişmez; şema ve göç yok. Yalnızca yeni hesaplar (yeni plan, düzenleme, kart günü değişimi) yeni kuralı izler. |

## Hesap kesim hatırlatması (17) (19 Kasım 2026)

Hesap kesiminden önce ve sonra yapılan alışveriş farklı ekstrelere düşer; kullanıcı kesim gününü önceden bilsin.

Ürün sahibi kararları (yeniden sorulmaz):

| Konu | Karar |
|---|---|
| Anahtar | Kart bazında "Hesap kesim hatırlatması"; varsayılan kapalı (mevcut kartlarda da). Mürekkep renginde (mevcut adaptif anahtar), açıklama `textMuted`. Brifteki "accent" yerine mürekkep: accent yalnızca "kalan" içindir. |
| Kaç gün önce | 1 ya da 2; varsayılan 2. |
| Metin | "{card} kartının hesabı {days} gün sonra, {date} tarihinde kesiliyor. Bu tarihten sonraki taksitler {next} ekstresine girer." EN: "Your {card} statement closes in {days} days, on {date}. Installments after that go on the {next} statement." ICU çoğul; tarihler intl `MMMMd` ("14 Kasım", "November 14"). |
| Tutar ve düğme | Yok. |
| 60 sınırı | En son sıradadır: önce bütün ödeme hatırlatmaları, sonra maaş günü özeti; yer kalırsa kesim hatırlatmaları en yakından başlayarak. Ödeme hatırlatmalarının yerini hiç almaz. |
| Dokunma | O kartın ekstre görünümü (16, `/sources?card=ID`). |

Uygulanan kararlar (prompt'ta gerekçeli verildi):

| Konu | Karar |
|---|---|
| Saat | Genel hatırlatma saati (varsayılan 09:00). |
| Görünürlük | Anahtar yalnızca ekstre günü (ve kaydetmek için zaten zorunlu olan son ödeme günü) seçili kartta görünür; sağlayıcıda ve günleri seçilmemiş yeni kartta yok. Günleri eksik kart kaydedilirse anahtar kapanır (mimar incelemesi). |
| Kesim tarihi | Motordan: ilk ekstre `CardTerms.statementFor(bugün)`, sonrakiler `statementInMonth` (ay sonuna sıkıştırılır: 31 → 30 Kasım, 28 Şubat). Motor kesim tarihini hafta sonu ya da tatile göre kaydırmıyor; bildirim de kaydırmaz (14 Kasım 2026 cumartesi, bildirim "14 Kasım" der). Brifteki "kaydırmaya uyar" maddesi bu yüzden uygulanmadı; yeni tarih kuralı yazılmadı. |
| Birden çok kart | Aynı gün iki kartın hatırlatması iki ayrı bildirimdir. |
| Tutarı göster ayarı | Etkilemez (bildirimde tutar yok). |

Teknik kararlar (Claude, 19 Kasım 2026):

| Konu | Karar |
|---|---|
| Kayıt | Şema v13: `sources.statement_reminder_enabled` (varsayılan false) ve `sources.statement_reminder_days` (varsayılan 2, yalnızca 1 ya da 2). Göçte mevcut kartlar kapalı ve 2 gün; testli. Kart sağlayıcıya çevrilirse anahtar kapanır. |
| Planlayıcı | Ayrı adım `withStatementClosings` (`lib/core/reminders/reminder_planner.dart`), maaş günü özetinden sonra. Kart başına sıradaki 12 ekstre (bir yıl); tetiklenme anı geçmiş olanlar atlanır (kesim 14, saat 09:00'u geçmişse 12'sinde: sonraki ay). Aynı anda başka bildirim varsa onlardan sonra sıralanır. Anahtar kapalıyken liste nesnesi bile aynı döner. |
| Kimlik | `2^28 + (kart kimliği mod 2^18) × 1024 + tetiklenme günü mod 1024`: ödeme kimliklerinin (gün × 2, ~41.000) üstünde, ısrarlı hatırlatma kimliklerinin (2^29+) altında. Aynı kartta 1024 gün içinde tekrar etmez. |
| Payload | `card:ID`; düğme verisi yok. Ödeme bildirimi ve maaş günü özeti `home` olarak kalır. |
| Dokunma | Uygulama açıkken kartın ekstreleri o anki ekranın üstüne açılır (geri, önceki ekrana döner). Uygulama kapalıyken bildirimin açtığı ilk açılışta ana ekranın üstüne açılır (`launchPayloadProvider`). |
| Yeniden kurma | `ReminderSync` artık kaynak (kart) akışını da dinler: kart günleri, anahtar ya da gün değişince bildirimler yeniden kurulur. Arka plandaki yeniden kurma aynı yolu (`rescheduleAll`) kullanır. |
| Gün seçimi | Anahtar açıkken görünür (mevcut seçenek bileşeni, seçili seçenekte onay işareti); seçenek adları mevcut "1 gün önce" / "2 gün önce" metinleri. Başlık "Kaç gün önce" / "Days before" (Ayarlar'daki mevcut İngilizce karşılıkla aynı). |
| İzin ve ana anahtar | Yeni izin isteği yok. Hatırlatmalar ana anahtarı kapalıyken kesim hatırlatması da kurulmaz; kart ayarındaki anahtar yine değiştirilebilir. |
| Metinler | Yeni anahtarlar `statementReminder*` ve `reminderStatementClosing` (TR ve EN); çevirmen açıklamalarında "Yalnızca bilgi; alışverişe teşvik etme, aciliyet ifadesi kullanma." notu. Başka dil dosyasına dokunulmadı. |

