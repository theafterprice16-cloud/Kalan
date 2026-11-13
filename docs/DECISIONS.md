# Kararlar

Kimlik dosyasında ya da ilk prompt'ta cevabı olmayan, 12 Kasım 2026'daki plan onayında kabul edilen kararlar. Bir kararı değiştirirsen bu dosyayı ve ilgili testi birlikte güncelle.

## Ürün

| # | Konu | Karar |
|---|---|---|
| 1 | Paket kimliği | Geçici olarak `app.kalan.mobile` (iOS Bundle ID ve Android applicationId). Kimlik dosyasının önerdiği `kalan.app` alan adından türetildi. Mağazaya ilk yüklemeden önce kesinleştir; yüklemeden sonra değiştirilemez. |
| 2 | Vadesi geçmiş, ödenmemiş ödeme | Kendi tarihinin döneminde kalır. Ana ekranın üstünde sakin bir "Ödenmemiş" bölümünde de listelenir. İçinde bulunulan dönemin söz verilmiş tutarına ikinci kez eklenmez. |
| 3 | Maaş günü hafta sonuna denk gelirse | Dönem yine o gün başlar (kaydırma yok). |
| 4 | Ekstre günü yapılan alışveriş | O günün ekstresine girer (alışveriş günü ≤ ekstre günü). |
| 5 | Kuruş artığı | `taban(toplam / n)` her ödemeye; artan kuruş ilk ödemeye eklenir. |
| 6 | Tek ödemenin tutarı düzeltilince | Fark, sonraki ödenmemiş ve elle düzeltilmemiş ödemelere eşit dağıtılır (artık kuruş ilkine). Böyle ödeme yoksa ya da bir ödeme 0 veya altına düşecekse düzeltme yapılmaz. Plan toplamı değişmez. |
| 7 | Plan adı | İsteğe bağlı; boşsa kaynak adı gösterilir. Şablon ekranında "Ayrıntı ekle" altında katlı durur, dört alana sayılmaz. |
| 8 | Aylık taksit şablonu | Toplam tutar ve taksit sayısı sorulur. Taksit tutarıyla giriş "Yarıda başlayan plan" ve "Elle giriş"te var. |
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
| 24 | Yarıda başlayan plan | Toplam taksit sayısı, kalan taksit sayısı, taksit tutarı ve sonraki ödeme tarihi girilir. Yalnızca kalan ödemeler kaydedilir; plan toplamı bunların toplamıdır. İlerleme etiketi baştan sayar ("4/12"). Kart kaynağında sonraki tarihler kartın son ödeme gününe göre üretilir. |
| 24a | Sabit ödemelerin geçmiş tekrarları | "Ödenmemiş" bölümünde gösterilmez (yalnızca plan ödemeleri). Aksi hâlde başlangıçtan bu yana işaretlenmemiş her kira satırı listeyi doldururdu. |
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

Bu bölüm aynı günün ilk hatırlatma kararlarının yerini alır. Ürün sahibiyle netleşen kararlar: iki bildirim ("önceden" ve "gününde"), tek "kaç gün önce" seçimi, bildirimde "Ödendi" düğmesi yok, dokununca ana ekran.

| Konu | Karar |
|---|---|
| Kapsam | Yalnızca yerel bildirim (`flutter_local_notifications`). Sunucu, push servisi, Firebase, hesap, analiz ve internet yok. Ücretsiz sürümde tam çalışır, Pro'ya bağlı değildir. |
| İki bildirim | Her ödeme için biri "kaç gün önce" ("önceden"), biri ödeme günü ("gününde"). Önceden bildirimi hiçbir zaman ödeme gününe düşmez (en az 1 gün). |
| Kaç gün önce | Seçenekler 1, 2, 3, 5, 7; varsayılan 2 (bazı sağlayıcılar parayı bir gün erken çekiyor). Genel ayarı plana uygulayan tek fonksiyon `defaultLeadDaysFor` (`lib/core/reminders/reminder_models.dart`); elle/otomatik ödeme ayrımı geldiğinde yalnızca orası değişir. |
| Saat | Varsayılan 09:00, Ayarlar'dan değişir (sistem saat seçici, dilin 12/24 saat biçimi). Kuruluma adım eklenmedi. Yerel saat diliminde hesaplanır; yaz saati geçişinde 09:00 yine 09:00'dır. |
| Tutar | Varsayılan görünür. "Bildirimde tutarı göster" kapalıyken metinde tutar olmaz (kilit ekranı gizliliği). Ayar tek gizlilik servisinde (`PrivacySettings`); veritabanında `hideAmountsInNotifications` sütunu olarak (tersi) duruyor. |
| Birleştirme | Aynı gün ve aynı türdeki bildirimler tek bildirimdir; gruplama tetiklenme gününe göre yapılır. Farklı "kaç gün önce" seçen planlar aynı güne düşerse tek "önceden" bildirimi olur ve metin en erken tarihi söyler ("13 Kasım Perşembe gününden itibaren 2 ödeme var"). Tek para birimi olduğu için toplam yazılır; plan adları genişletilmiş gövdede (Android BigText, iOS uzun gövde) virgülle sıralanır. |
| 60 sınırı | iOS en çok 64 bekleyen bildirim tutar; tarih sırasına göre en yakın 60 kurulur. Android'de de aynı kural, tek kod yolu. |
| Kimlikler | `tetiklenme günü (epoch) × 2 + tür`. Deterministik: yeniden kurma çift bildirim üretmez. |
| Saf Dart planlayıcı | `lib/core/reminders`: ödemeler (etkin tarihleriyle), genel ayarlar, plan seçimleri, şimdiki an (saat dilimiyle) ve metin üreticisi (dil) → sıralı bildirim listesi (kimlik, an, başlık, gövde, genişletilmiş gövde, payload). Metinleri `L10nReminderTexts` ARB'den, tarihi intl'den (`MMMMEEEEd`: "14 Kasım Cuma", "Friday, November 14"), tutarı ortak para biçimlendiricisinden üretir. |
| Tarih kaynağı | Hesap motorunun ürettiği ve veritabanında saklanan etkin son ödeme günü (kart hesap kesimi ve hafta sonu kaydırması uygulanmış). Bildirim, ekrandaki günle aynıdır; bildirim kodu tarih hesaplamaz. |
| Hariç tutulanlar | Ödenmiş ödemeler, "Kapalı" planlar, ana anahtar kapalıyken her şey, tetiklenme anı geçmiş bildirimler (geçmiş "önceden" bildirimi atlanır, "gününde" yine kurulur). Uygulamada plan arşivi yok; bitmiş planların ödemeleri zaten ödenmiş olduğundan hariçtir. |
| Plan bazında | Plan ayrıntısında ve sabit ödeme düzenleme ekranında "Hatırlatma": Genel ayar (varsayılan) / Kapalı / Farklı gün (1, 2, 3, 5, 7). Saat her zaman genel ayardan. Plan ekleme ekranına eklenmedi (yirmi saniye kuralı: en çok dört alan). |
| Yeniden kurma | Her çalışmada Kalan'ın bekleyen bildirimleri iptal edilir ve liste baştan kurulur (gösterilmiş bildirimler bildirim merkezinde kalır). Tetikleyiciler: uygulama açılışı, ön plana dönüş (saat dilimi de yenilenir), plan ekleme/düzenleme/silme, "ödendi" ve geri alma, sabit ödeme değişiklikleri, hatırlatma ayarları, dil ve para birimi değişikliği (veritabanı akışları tek merkezden, `ReminderSync`); Android'de yeniden başlatma, saat ve saat dilimi değişimi (`ReminderRescheduleReceiver`, uygulama açılmadan arka planda Dart). Art arda gelen değişiklikler 300 ms beklemeyle tek çalışmada toplanır; arayüz beklemez. |
| Android zamanlama | Kesin olmayan (`inexactAllowWhileIdle`) zamanlama. `SCHEDULE_EXACT_ALARM` ve `USE_EXACT_ALARM` istenmez: Google Play bu izinleri hatırlatma uygulamalarında kısıtlıyor; birkaç dakikalık kayma kabul edildi. Eklentinin önyükleme alıcısı ve `RECEIVE_BOOT_COMPLETED` ile bildirimler yeniden başlatmada korunur. |
| Android kanalı ve ikon | "Ödeme hatırlatmaları", varsayılan önem. Küçük ikon `ic_stat_kalan`: logonun beyaz silueti, şeffaf zemin, şekil değişmeden. Vurgu rengi `KalanColors.light.accent` (DESIGN_TOKENS accent, #1D4E89); kodda kaynağı yorumla belirtildi. |
| iOS | İzin alert, sound ve badge için. Uygulama ön plandayken de bildirim görünür (`UNUserNotificationCenter` delegesi ve sunum seçenekleri). Uygulama ikonu kullanılır. |
| İzin akışı | Uygulama açılışında sorulmaz. İlk plan kaydedildikten hemen sonra Kalan'ın alt sayfası: "Hatırlatmaları aç" sistem iznini ister, "Şimdi değil" kapatır. Sayfa bir kez gösterilir; "Şimdi değil", kaydırarak kapatma ya da sistem reddi tekrar sorulmaz. Hatırlatmalar açık kalır; izin kapalıyken Ayarlar > Hatırlatmalar'da "Bildirim izni kapalı" satırı ve "Ayarları aç" düğmesi görünür. Sistem zaten izin veriyorsa (Android 12 ve altı) sayfa gösterilmez. Sabit ödeme izin sormaz. |
| "Ödendi" düğmesi | Bildirimde yok (ayrı bir backlog maddesi). Önceki sürümdeki eylem, arka plan işleyicisi, iOS eklenti kaydı ve `ActionBroadcastReceiver` kaldırıldı. |
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

