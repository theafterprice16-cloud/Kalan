# Sıradaki işler

Sıra önemlidir. Parantez içindekiler özelliğin görüldüğü rakip uygulamalardır.

1. **İleri bakış**: ~~önümüzdeki dönemler çubuk olarak~~ Tamamlandı (19 Kasım 2026, yol haritası 12; Karar 4 gereği ücretsiz, herkese 6 dönem). ~~yoğun hafta işareti~~ tamamlandı (19 Kasım 2026, yol haritası 14; grafikte ve takvimde, ana ekranda yok). ~~gelecek dönemin açığı~~ tamamlandı (19 Kasım 2026, yol haritası 15: grafikte gelire kadar safran, aşan kısım koyu safran; dönem özetinde "Bu dönem X eksik görünüyor."; bildirim yok). Kalan: bütün planların bittiği tarih (PayDown).
2. **Dene** (Pro): yeni bir planın etkisini kaydetmeden gösterme.
3. ~~**Bildirim ve hatırlatmalar**~~ Tamamlandı (13 Kasım 2026): her ödeme için "önceden" (1, 2, 3, 5 ya da 7 gün; varsayılan 2) ve "gününde" bildirimi, saat ayarı (09:00), aynı gün ve türde birleştirme, en yakın 60, plan bazında Genel ayar / Kapalı / Farklı gün, "Bildirimde tutarı göster", ilk plandan sonra izin sayfası, dokununca ana ekran. Sonraya kalanlar (ayrı maddeler): ~~bildirimden "Ödendi" işaretleme~~ (tamamlandı, aşağıda); ~~**ısrarlı hatırlatma**~~ (tamamlandı, aşağıda); otomatik çekim / elle ödeme ayrımı (`defaultLeadDaysFor` hazır); maaş günü özeti; hesap kesim uyarısı. Planlayıcı yeni türler için hazır.
4. **İade bekliyor** işareti; gecikme ücreti kaydı (Frizzbee); kısmi ya da farklı tutarla ödeme (Bills Monitor).
5. **Tutarları gizle** düğmesi (BillWise); Face ID ve parmak izi kilidi (Bobby); ~~aylık takvim görünümü (Bills Monitor)~~ tamamlandı (19 Kasım 2026, yol haritası 13: İleriki dönemler ekranında "Grafik | Takvim"); durum filtresi ve arama (Tortol).
6. **Dosyaya dışa aktarma ve dosyadan geri yükleme** (ücretsiz; kimlik dosyası B bölümü: "dışa aktarma her zaman açıktır").
7. **Ekran görüntüsünden ve yapıştırılan metinden plan ekleme** (Pro; PayDown). Bulut AI + küçük ara sunucu, açık rıza ve onay ekranı. `PlanDraft` → onay → kayıt yolunu kullanır.
8. ~~**Pro satın alma**~~ Tamamlandı (18 Kasım 2026, yol haritası 11): yalnızca ömür boyu tek ürün (Karar 2); aylık ve yıllık yok. `Entitlement` arkasında, resmi `in_app_purchase` ile.
9. **Ana ekran widget'ı**, iOS ve Android (Subby).
10. **Türkiye resmi tatil kaydırması**; mağaza hazırlığı.
11. **8 dili ekle** (docs/ceviriler-beklemede/ dosyalarından başla): İspanyolca, Fransızca, Almanca, Portekizce-Brezilya, Rusça, Çince Basitleştirilmiş, İtalyanca, Endonezce.

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

## Notlar

- Tutar gösteren her yeni yer (bildirim, widget, dışa aktarma) `formatMoney` kullanır; dışa aktarma ham tam sayı tutarı ve para birimi kodunu yazar.

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
