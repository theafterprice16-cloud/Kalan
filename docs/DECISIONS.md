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
| 16 | Kalan sayısının rengi | Açık temada koyu yeşil #127A5F (kâğıt üzerinde #23B58E kontrastı 2,4:1, yetersiz). Karanlık temada kalan yeşili #23B58E. Kimlikteki "açık zeminde yeşil metin koyu yeşil" kuralına dayanır. |
| 17 | Karanlık temada ikincil metin | Duman #5F6880 mürekkep zeminde okunmadığı için karanlık temada #A3ABBF kullanılır. |
| 18 | Dil | Varsayılan sistem dili; TR değilse EN. Ayarlar'dan değiştirilebilir. |
| 19 | Para birimi değişimi | Ayarlar'dan değiştirilebilir; tutarlar çevrilmez, yalnızca sembol değişir. Ekranda bu yazılır. |
| 20 | Tutar biçimi | Kuruşsuz tutarlarda ondalık gösterilmez ("3.250 TL"), kuruşlu tutarlarda iki hane ("3.250,50 TL"). TR: tutar + boşluk + sembol (TL, $, £, €). EN: sembol + tutar ($, £, €, ₺). |
| 21 | Maaş günü girişi | Aylık: ayın günü (1-31; ay kısaysa son güne sıkışır). İki haftada bir: son maaş tarihi. Haftalık: haftanın günü. Net tutar bir maaşın tutarıdır. |
| 22 | 4 ödemeli plan | İlk ödeme alışveriş günü; sonra 14 günde bir, toplam 4 ödeme. |
| 23 | Kart taksidi tarihi | Ödeme tarihi, taksidin düştüğü ekstre tarihinden sonraki ilk son ödeme günüdür (aynı gün sayılmaz). Hafta sonu kaydırması kart başına ayar, varsayılan açık; cumartesi ve pazar pazartesiye kayar. Resmi tatiller BACKLOG'da. |
| 24 | Yarıda başlayan plan | Toplam taksit sayısı, kalan taksit sayısı, taksit tutarı ve sonraki ödeme tarihi girilir. Yalnızca kalan ödemeler kaydedilir; plan toplamı bunların toplamıdır. İlerleme etiketi baştan sayar ("4/12"). Kart kaynağında sonraki tarihler kartın son ödeme gününe göre üretilir. |
| 25 | Ödenmiş ödemenin düzeltilmesi | Ödenmiş ödeme düzeltilemez; önce "ödenmedi" yapılır. |

## Teknik

| Konu | Karar |
|---|---|
| Material | Flutter 3.50'de Material, resmi `material_ui` paketi olarak geliyor (`package:flutter/material.dart` kullanımdan kalktı). Şablonun eklediği bu paket korunuyor. |
| Paketler | `flutter_riverpod` (durum), `drift` + `drift_flutter` (SQLite; drift_flutter dosya yolunu ve SQLite kütüphanesini sağlar), `go_router` (yönlendirme), `flutter_localizations` + `intl` (ARB ve yerel biçim). Geliştirme: `build_runner` + `drift_dev` (Drift kod üretimi ve göç testi). Lint için ek paket yok: `flutter_lints` + sıkı analizör ayarları. Hiçbiri çalışma anında ağ isteği yapmaz. |
| Kod üretimi | Riverpod kod üretimi kullanılmıyor (sadelik). Drift'in ürettiği `*.g.dart` dosyaları commit edilir; böylece depo çekildiği gibi çalışır. |
| Tarih | `LocalDate` (yıl, ay, gün), veritabanında epoch günü (`int`). Saat dilimi ve yaz saati sorunları yok. |
| Ödemeler | Plan kaydedilirken üretilip saklanır (her seferinde yeniden hesaplanmaz), böylece elle düzeltmeler kalıcıdır. |
| Ağ izni | Ana `AndroidManifest.xml`'de INTERNET izni yok (testle denetlenir). `debug` ve `profile` manifest'lerindeki izin Flutter'ın geliştirme araçları (hot reload) için zorunlu ve yayın derlemesine girmez. |
| SQLite derlemesi | `sqlite3` 3.x paketi derleme sırasında hazır SQLite kütüphanesini indirir (yalnızca derleme anı; uygulama çalışırken ağ kullanılmaz). |
