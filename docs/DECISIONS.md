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
| Şema | Drift `schemaVersion` 1. Şema anlık görüntüsü `drift_schemas/`, göç testleri `test/drift/`. Yabancı anahtarlar açık; plan silinince ödemeleri silinir, planı olan kaynak silinemez. |


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

## Hatırlatmalar (13 Kasım 2026)

| Konu | Karar |
|---|---|
| Kapsam | Yalnızca yerel bildirim (`flutter_local_notifications`). Sunucu, push servisi, Firebase, hesap ve internet yok. Ücretsiz sürümde tam çalışır, Pro'ya bağlı değildir. |
| Zamanlama | 7 gün önce, 3 gün önce, 1 gün önce ve ödeme günü ayrı ayrı açılıp kapanır; varsayılan 3 gün önce ve ödeme günü. Saat varsayılan 09:00, cihazın yerel saatine göre. |
| Tarih kaynağı | Bildirimler, hesap motorunun ürettiği ve veritabanında saklanan gerçek ödeme tarihinden hesaplanır (ekstre, son ödeme günü, hafta sonu kaydırması uygulanmış). Bildirim kodu tarih hesaplamaz. |
| Saf Dart planlayıcı | `lib/core/reminders`: ödemeler + ayarlar + "şimdi" → bildirim listesi. Aynı güne ve aynı türe düşen ödemeler tek özet olur; ödenmiş, arşivlenmiş ve hatırlatması kapalı planlar ile geçmiş zamanlar atlanır. Yeni bildirim kuralı önce burada testle eklenir. |
| Kimlikler | `vade günü (epoch) × 4 + tür`. Kararlı olduğu için aynı bildirim iki kez kurulmaz; yeniden kurma eskisinin yerine geçer. Israrlı hatırlatma ileride ayrı bir tür olarak eklenebilir. |
| Kayan pencere | iOS en çok 64 bekleyen bildirim tutar; en yakın 60 kurulur. Her yeniden kurmada bekleyenlerin hepsi silinir ve baştan kurulur (gösterilmiş bildirimler bildirim merkezinde kalır). |
| Yeniden kurma anları | Uygulama açılınca ve öne gelince (saat dilimi de yenilenir); plan, ödeme, sabit ödeme, "ödendi" ve ayar değişikliklerinde (veritabanı akışları tek merkezden dinlenir); Android'de yeniden başlatma, saat ve saat dilimi değişiminde (`ReminderRescheduleReceiver`, arka planda Dart). |
| Android zamanlama | Kesin olmayan (`inexactAllowWhileIdle`) zamanlama. `SCHEDULE_EXACT_ALARM` ve `USE_EXACT_ALARM` kullanılmaz: mağaza bu izinleri alarm/takvim uygulamalarına ayırıyor. Hatırlatma birkaç dakika geç gelebilir; bu kabul edildi. |
| Android kanalı | "Ödeme hatırlatmaları", varsayılan önem. Tek renkli `ic_stat_kalan` ikonu, vurgu rengi mint (#3DDC97, KalanColors). |
| iOS | İzin yalnızca alert, sound ve badge için istenir. Uygulama ön plandayken de bildirim görünür. |
| İzin akışı | İlk plan ya da ilk sabit ödeme kaydedilince önce Kalan'ın açıklama penceresi, sonra sistem izni. "Şimdi değil" kesindir: hatırlatmalar kapalı başlar, bir daha kendiliğinden sorulmaz, Ayarlar'dan açılır (açılınca sistem izni istenir). |
| "Ödendi" düğmesi | Yalnızca ödeme günü bildiriminde ve o gün tek ödeme varsa. Uygulama kapalıyken arka plan izolatında çalışır: veritabanını açar (`shareAcrossIsolates`), ödemeyi işaretler, bildirimi kaldırır, hatırlatmaları yeniden kurar. |
| Tutar gizliliği | "Bildirimlerde tutarı gizle" tek gizlilik servisinde (`PrivacySettings`). İleride gelecek "tutarları gizle" düğmesi de buraya eklenecek. |
| Plan bazında | Plan ve sabit ödeme ayrıntısında "Bu plan için hatırlatma" anahtarı (şema v2 sütunu, varsayılan açık). |
| Kayıt yeri | Hatırlatma ayarları ve plan anahtarları Drift şema v2'de (göç testiyle). Arka plan izolatı aynı veritabanını okur. |
| Derin bağlantı | Bildirime dokununca `/day/<tarih>` ("Günün ödemeleri") açılır; uygulama kapalıysa açılış rotası olarak. |
| Web | Bildirim kodu web'de çalışmaz; Ayarlar'da "Bu özellik telefonda çalışır" yazar. |
| Paketler | `flutter_local_notifications` (yerel bildirim), `timezone` (yaz saati doğru yerel saat), `flutter_timezone` (cihazın saat dilimi adı). Üçü de ağ kullanmaz. `timezone` paketi yalnızca web'de saat dilimi verisini indirmek için kullanılan bir dosyada `http`'ye bağlı; Kalan gömülü veriyi kullanır ve o dosyayı içe aktarmaz. Ağ bekçisi testi bu istisnayı yalnızca bu koşullarla kabul eder. |

