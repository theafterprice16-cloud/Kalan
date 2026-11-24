# Sıradaki işler

Sıra önemlidir. Parantez içindekiler özelliğin görüldüğü rakip uygulamalardır.

1. **İleri bakış**: ~~önümüzdeki dönemler çubuk olarak~~ Tamamlandı (19 Kasım 2026, yol haritası 12; Karar 4 gereği ücretsiz, herkese 6 dönem). ~~yoğun hafta işareti~~ tamamlandı (19 Kasım 2026, yol haritası 14; grafikte ve takvimde, ana ekranda yok). ~~gelecek dönemin açığı~~ tamamlandı (19 Kasım 2026, yol haritası 15: grafikte gelire kadar safran, aşan kısım koyu safran; dönem özetinde "Bu dönem X eksik görünüyor."; bildirim yok). Kalan: bütün planların bittiği tarih (PayDown).
2. **Dene** (Pro): yeni bir planın etkisini kaydetmeden gösterme.
3. ~~**Bildirim ve hatırlatmalar**~~ Tamamlandı (13 Kasım 2026): her ödeme için "önceden" (1, 2, 3, 5 ya da 7 gün; varsayılan 2) ve "gününde" bildirimi, saat ayarı (09:00), aynı gün ve türde birleştirme, en yakın 60, plan bazında Genel ayar / Kapalı / Farklı gün, "Bildirimde tutarı göster", ilk plandan sonra izin sayfası, dokununca ana ekran. Sonraya kalanlar (ayrı maddeler): ~~bildirimden "Ödendi" işaretleme~~ (tamamlandı, aşağıda); ~~**ısrarlı hatırlatma**~~ (tamamlandı, aşağıda); otomatik çekim / elle ödeme ayrımı (`defaultLeadDaysFor` hazır); maaş günü özeti; hesap kesim uyarısı. Planlayıcı yeni türler için hazır.
4. **İade bekliyor** işareti; gecikme ücreti kaydı (Frizzbee); kısmi ya da farklı tutarla ödeme (Bills Monitor).
5. ~~**Tutarları gizle** düğmesi (BillWise)~~ tamamlandı (23 Kasım 2026, yol haritası 28: ana ekranda göz ikonu ve Ayarlar > Gizlilik'te anahtar; bütün ekranlar ve bildirimler); ~~Face ID ve parmak izi kilidi (Bobby)~~ tamamlandı (22 Kasım 2026, yol haritası 27: "Uygulama kilidi", telefonun kendi kimlik doğrulamasıyla); ~~aylık takvim görünümü (Bills Monitor)~~ tamamlandı (19 Kasım 2026, yol haritası 13: İleriki dönemler ekranında "Grafik | Takvim"); durum filtresi ve arama (Tortol).
6. ~~**Dosyaya dışa aktarma**~~ tamamlandı (23 Kasım 2026, yol haritası 29: tablo (CSV) ve parolalı/parolasız tam yedek, Ayarlar > Veri; ücretsiz). ~~**Dosyadan geri yükleme**~~ tamamlandı (24 Kasım 2026, yol haritası 30: kurulumda "Yedeğim var", Ayarlar > Veri'de "Yedekten geri yükle", veri varken onay ve 30 gün "Önceki verine dön"; ücretsiz).
7. **Ekran görüntüsünden ve yapıştırılan metinden plan ekleme** (Pro; PayDown). Bulut AI + küçük ara sunucu, açık rıza ve onay ekranı. `PlanDraft` → onay → kayıt yolunu kullanır.
8. ~~**Pro satın alma**~~ Tamamlandı (18 Kasım 2026, yol haritası 11): yalnızca ömür boyu tek ürün (Karar 2); aylık ve yıllık yok. `Entitlement` arkasında, resmi `in_app_purchase` ile.
9. **Ana ekran widget'ı**, iOS ve Android (Subby). Not (27): uygulama kilidi açıkken widget'ta tutar gizleme tercihi gerekecek. Not (28): "Tutarları gizle" tercihine uymalı (açıkken widget'ta tutar yerine "•••"; tutar tek para yolundan, `ref.money` gibi örtüyü uygulayan yoldan gelmeli).
10. ~~**Türkiye resmi tatil kaydırması**~~ Tamamlandı (22 Kasım 2026, yol haritası 26: 24 ülke, kart taksitleri); mağaza hazırlığı.
11. **8 dili ekle** (docs/ceviriler-beklemede/ dosyalarından başla): İspanyolca, Fransızca, Almanca, Portekizce-Brezilya, Rusça, Çince Basitleştirilmiş, İtalyanca, Endonezce. Yol haritası 24 (22 yerel sürüm): **altyapı tamam (21 Kasım 2026); çeviriler toplu çeviride** (yol haritasının sonu, `docs/ceviriler/`).

## Tamamlananlar

- ~~**Devam eden planı ortasından ekleme**~~ Tamamlandı (13 Kasım 2026): her plan türünde "Bu plan zaten sürüyor" anahtarı; ödenmiş taksit sayısı ve sıradaki ödeme tarihi girilir, geçmiş taksitler "Kalan'dan önce ödendi" kaydı olarak saklanır; ilerleme "3/10", plan ayrıntısında tek satır özet; "Planı düzenle" ile sonradan düzeltme; aylık ve kart planlarında toplam taksit sayısı da değişir (plan toplamı sabit, ödenmemişler yeniden bölünür).

- ~~**Günü geçenler bölümü**~~ Tamamlandı (13 Kasım 2026): ödenmemiş ve günü geçmiş ödemeler ana ekranda ayrı bölümde, bu dönemin kalanından düşülerek; "Ödendi" → "Bugün" ya da "Gününde"; satır kendiliğinden kalkmaz; "ödendi" bilgi mesajında "Geri al". Sonraya: gecikme ücreti kaydı, tekrarlayan hatırlatma, simge sayacı.

- ~~**Bildirimden "ödendi" işaretleme**~~ Tamamlandı (13 Kasım 2026): "önceden" ve "gününde" bildirimlerinde "Ödendi" (birleşik bildirimde "Hepsi ödendi"), "Akşam hatırlat" (20:00) ve "Yarın hatırlat"; uygulama açılmadan, arka planda; ertelemeler veritabanında saklanır ve yeniden kurmada kaybolmaz; iOS'ta işaretleme için telefon kilidi açılır. Sonraya: widget'tan işaretleme.

- ~~**Israrlı hatırlatma**~~ Tamamlandı (14 Kasım 2026): "Kapalı" (varsayılan), "Akşam bir kez daha", "Her gün"; genel, plan ve sabit ödeme bazında; yalnızca bildirim saatinde ve 20:00'de, son günden en çok 7 gün sonrasına kadar; son günden sonra yargısız "henüz işaretlenmedi" metni; "Ödendi" bütün tekrarları durdurur, "Yarın hatırlat" yalnızca o günü atlar; listede ve ayrıntıda tekrar ikonu. Sonraya: elle/otomatik ayrımı gelince yardımcı metinler (9. madde).

- ~~**Kart ekstre tahmini**~~ Tamamlandı (19 Kasım 2026, yol haritası 16): Kaynaklar ve kartlar ekranında her kart için sıradaki ve sonraki 5 ekstre (yalnızca kart taksitleri, ödenmişler dahil); ekstreye dokununca taksit listesi; "Yalnızca Kalan'a girdiğin taksitler." notu; karta özel rota (17. maddenin bildirimi için). Ücretsiz.

- ~~**Hesap ve kart bazında hazır tutulacak tutar**~~ Tamamlandı (19 Kasım 2026, yol haritası 18): yeni kaynak türü "Banka hesabı"; Kaynaklar ve kartlar ekranında otomatik ödemesi olan her kaynakta "Hesapta bulunsun" (banka hesabı) ya da "Bu karta yansıyacak" (kart): sıradaki çekim, dönem sonuna kadar toplam, "Ayrıntı" ile gün gün birikimli liste, kapalı "Sonraki dönem"; kaynağı seçilmemiş otomatik ödemeler ayrı kartta; ödemeden önceki hatırlatmaya banka hesabının adı ve tutarı. Bakiye yok. Sabit ödemeler sayılmaz (ödeme şekli alanları yok).

- ~~**Hesap kesim öncesi uyarı**~~ Tamamlandı (19 Kasım 2026, yol haritası 17): kart ayarlarında "Hesap kesim hatırlatması" (varsayılan kapalı, 1 ya da 2 gün önce, varsayılan 2); bildirim genel hatırlatma saatinde, kesim tarihini ve sonraki ekstreyi söyler, tutar ve düğme yok; 60 sınırında en son sırada; dokununca kartın ekstreleri. Ücretsiz.

- ~~**"Sonra öde" tek ödemeli plan türü**~~ Tamamlandı (14 Kasım 2026): plan eklemede beşinci tür; tutar yaz, kaydet; 14 gün / 30 gün / Gelecek ayın N. günü / Gün sayısı / Tarih seç; son kullanılan kural hatırlanır; mağaza adı ve kaynak isteğe bağlı, adsız kayıt "Sonra öde · 14 Ara"; 4 plan sınırına sayılır; bildirim, gecikenler, bildirimden "ödendi" ve ısrarlı hatırlatmayla çalışır. Sonraya: sağlayıcı şablonları (25. madde), fatura numarası ve not (40. madde).

- ~~**İade, iptal ve itiraz**~~ Tamamlandı (19 Kasım 2026, yol haritası 19): planı beklet (kalan taksitler hesaba ve bildirimlere girmez, gecikmiş sayılmaz), yeniden aç, tutarı düzelt (yalnızca düşürür, ödenmişler değişmez) ve kapat (neden İade/İptal, arşivde görünür); beklemedeki plan 4 plan sınırına sayılır; 30 gün sonra plan içinde "Hâlâ iadeyi mi bekliyorsun?". Ücretsiz. Kapsam dışı: iade tutarının gelir kaydı, sağlayıcıyla iletişim.

- ~~**Taksit erteleme**~~ Tamamlandı (20 Kasım 2026, yol haritası 20): plan ayrıntısında taksite dokununca "Tarihi değiştir" → tarih seçici → dönemlere etkisi önizlemesi → Kaydet; "Sonraki taksitleri de kaydır" (kapalı gelir); "Ertelendi · ilk tarih …" / "Öne alındı · ilk tarih …" notu; yalnızca özgün tarih saklanır; kart taksitlerinde yok. Ücretsiz. Kapsam dışı: sağlayıcıda erteleme, erteleme ücreti (21), toplu erteleme.

- ~~**Ek ücret kaydı**~~ Tamamlandı (20 Kasım 2026, yol haritası 21): bir ödemeye sağlayıcının eklediği tek seferlik ücreti elle kaydetme (tutar ve isteğe bağlı kısa not); geciken satırda "Ek ücret ekle", diğer ödemelerde işlem listesinde; ücret ödemenin sayıldığı dönemin söz verilmiş tutarına ve hatırlatma tutarına girer; plan toplamına ve kart ekstresine girmez; silmede "Geri al". Ücretsiz. Kapsam dışı: ücret hesaplama ya da önerme, gecikme faizi, yıllık toplam, sabit ödemelere ücret.
- ~~**Taksit başı ücret**~~ Tamamlandı (20 Kasım 2026, yol haritası 22): planın her taksitte (ya da yalnızca ilk taksitte) aldığı sabit ücret; plan ekleme ve düzenlemede kapalı bölümde, varsayılan boş; kart taksitlerinde yok; ücret yalnızca ödenmemiş taksitlere yazılır, ödenmişler kendi ücretini korur; taksit satırında ücret dahil tutar ve "taksit ücreti dahil" notu; plan özetinde "Plan tutarı / Taksit ücretleri / Toplam"; ücret dönem toplamına, kalana ve hatırlatma tutarına girer. Ücretsiz. Kapsam dışı: yüzdeli ücret ve faiz (23).

- ~~**Faizli planlarda toplam geri ödeme**~~ Tamamlandı (21 Kasım 2026, yol haritası 23): aylık taksit, kart taksidi ve elle girişte isteğe bağlı "Ürün fiyatı" (kapalı bölümde); plan özetinde tek "Toplam geri ödeme" satırı, altında "Ürün fiyatı" ve "Fark" (yalnızca fark sıfırdan büyükken, açık planda); taslak önizlemesinde de; yalnızca gösterim, kalan, dönem ve bildirim değişmez; faiz oranı sorulmaz. Ücretsiz.

- ~~**Uygulama kilidi**~~ Tamamlandı (22 Kasım 2026, yol haritası 27): Ayarlar > Gizlilik'te "Uygulama kilidi"; açarken bir kez telefonun doğrulaması (önce yüz ya da parmak izi, olmazsa telefon şifresi); "Yeniden kilitle" Hemen / 1 dakika (varsayılan) / 5 dakika; soğuk açılışta ve süre dolunca kilit ekranı (zemin, logo, "Kilidi aç"), kendiliğinden bir kez sorar; uygulama değiştiricide zemin ve logo; bildirimde tutar görünüyorsa sakin öneri satırı; ekran kilidi yoksa açılmaz, sonradan kalkarsa kendiliğinden kapanır ve bir kez söyler; bildirimden "Ödendi" uygulama kilidini sormaz. Ücretsiz. Kapsam dışı: uygulamaya özel PIN, veritabanı şifreleme, widget'ta tutar tercihi.

- ~~**Resmî tatil kaydırması**~~ Tamamlandı (22 Kasım 2026, yol haritası 26): kart taksitlerinin son ödeme günü tatil ülkesinin hafta sonu ve ülke geneli resmî tatillerine göre sonraki iş gününe kayar; kart ayarlarında "Resmî tatilde kaydır" (varsayılan açık) ve liste süresi notu; Ayarlar'da "Tatil ülkesi" (cihaz bölgesinden, yoksa para biriminden önerilir; "Yok" eski cumartesi-pazar kuralı); plan ayrıntısında "Resmî tatil nedeniyle kaydırıldı"; liste uygulamayla gelir (24 ülke, 2026-2028, resmî kaynaklı), CI eski liste için uyarır. Ücretsiz. Kapsam dışı: bölgesel tatil, yarım gün, telafi iş günü, bankaların özel uygulamaları, diğer plan türleri.

## Notlar

- Tutar gösteren her yeni yer (bildirim, widget) `formatMoney` kullanır. Dışa aktarma (29): yedek ham tam sayı tutarı ve ISO kodunu, tablo yerelden bağımsız `formatMinorPlain` (tek para yolunda) ve `pickerLabel` yazar.

## Yapılmayacaklar

Rakiplerde var, Kalan'da yok; eklenmez ve önerilmez:

- Banka bağlantısı ve otomatik işlem akışı (Rocket Money, Monarch, Emma, YNAB, PocketGuard)
- Hesap açma ve e-posta yönlendirme (Frizzbee, Cushion)
- Sağlık puanı, rozet, seri (Frizzbee, BillWise)
- Fatura ödeme ve para aktarma (Prism)
- Abonelik iptali ve pazarlık (Rocket Money)
- Harcama kategorileri, bütçe, raporlar (YNAB, Spendee, Monefy)
- Kredi ve kart teklifi (Credit Karma)
- AI sohbet ve koç (StatementBear)
- Bulut eşitleme ve ortak hane (ilk sürümde yok)

- ~~**Sağlayıcı hazır şablonları**~~ Tamamlandı (22 Kasım 2026, yol haritası 25): plan eklemede plan türlerinin altında "Sağlayıcıdan başla"; cihaz bölgesine göre en çok 5 sağlayıcı, ada göre sıralı, düz metin ve harf rozeti; seçince tür, taksit sayısı, aralık, ilk ödeme günü ya da "sonra öde" kuralı ve kaynak dolu gelir, tutarı kullanıcı yazar; her alan değiştirilebilir; formun altında "başlangıç değerleri · son kontrol" notu; kaynak yalnızca kayıtta oluşur; şablonlar uygulamayla gelen dosyada (19 ülke, resmî kaynak linkli), 6 aydan eski şablona CI uyarısı. Ücretsiz. Kapsam dışı: ücret, faiz, gecikme kuralı, logo, internetten güncelleme.
