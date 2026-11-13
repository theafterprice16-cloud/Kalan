# Sıradaki işler

Sıra önemlidir. Parantez içindekiler özelliğin görüldüğü rakip uygulamalardır.

1. **İleri bakış** (Pro): önümüzdeki dönemler çubuk olarak, sıkışık dönem işareti, bütün planların bittiği tarih (PayDown).
2. **Dene** (Pro): yeni bir planın etkisini kaydetmeden gösterme.
3. ~~**Bildirim ve hatırlatmalar**~~ Tamamlandı (13 Kasım 2026): her ödeme için "önceden" (1, 2, 3, 5 ya da 7 gün; varsayılan 2) ve "gününde" bildirimi, saat ayarı (09:00), aynı gün ve türde birleştirme, en yakın 60, plan bazında Genel ayar / Kapalı / Farklı gün, "Bildirimde tutarı göster", ilk plandan sonra izin sayfası, dokununca ana ekran. Sonraya kalanlar (ayrı maddeler): ~~bildirimden "Ödendi" işaretleme~~ (tamamlandı, aşağıda); **ısrarlı hatırlatma**, varsayılan kapalı (Due); otomatik çekim / elle ödeme ayrımı (`defaultLeadDaysFor` hazır); maaş günü özeti; hesap kesim uyarısı. Planlayıcı yeni türler için hazır.
4. **İade bekliyor** işareti; gecikme ücreti kaydı (Frizzbee); kısmi ya da farklı tutarla ödeme (Bills Monitor).
5. **Tutarları gizle** düğmesi (BillWise); Face ID ve parmak izi kilidi (Bobby); aylık takvim görünümü (Bills Monitor); durum filtresi ve arama (Tortol).
6. **Dosyaya dışa aktarma ve dosyadan geri yükleme** (ücretsiz; kimlik dosyası B bölümü: "dışa aktarma her zaman açıktır").
7. **Ekran görüntüsünden ve yapıştırılan metinden plan ekleme** (Pro; PayDown). Bulut AI + küçük ara sunucu, açık rıza ve onay ekranı. `PlanDraft` → onay → kayıt yolunu kullanır.
8. **Pro satın alma**: aylık, yıllık, ömür boyu. `EntitlementService` arkasına bağlanır.
9. **Ana ekran widget'ı**, iOS ve Android (Subby).
10. **Türkiye resmi tatil kaydırması**; mağaza hazırlığı.
11. **8 dili ekle** (docs/ceviriler-beklemede/ dosyalarından başla): İspanyolca, Fransızca, Almanca, Portekizce-Brezilya, Rusça, Çince Basitleştirilmiş, İtalyanca, Endonezce.

## Tamamlananlar

- ~~**Devam eden planı ortasından ekleme**~~ Tamamlandı (13 Kasım 2026): her plan türünde "Bu plan zaten sürüyor" anahtarı; ödenmiş taksit sayısı ve sıradaki ödeme tarihi girilir, geçmiş taksitler "Kalan'dan önce ödendi" kaydı olarak saklanır; ilerleme "3/10", plan ayrıntısında tek satır özet; "Planı düzenle" ile sonradan düzeltme; aylık ve kart planlarında toplam taksit sayısı da değişir (plan toplamı sabit, ödenmemişler yeniden bölünür).

- ~~**Günü geçenler bölümü**~~ Tamamlandı (13 Kasım 2026): ödenmemiş ve günü geçmiş ödemeler ana ekranda ayrı bölümde, bu dönemin kalanından düşülerek; "Ödendi" → "Bugün" ya da "Gününde"; satır kendiliğinden kalkmaz; "ödendi" bilgi mesajında "Geri al". Sonraya: gecikme ücreti kaydı, tekrarlayan hatırlatma, simge sayacı.

- ~~**Bildirimden "ödendi" işaretleme**~~ Tamamlandı (13 Kasım 2026): "önceden" ve "gününde" bildirimlerinde "Ödendi" (birleşik bildirimde "Hepsi ödendi"), "Akşam hatırlat" (20:00) ve "Yarın hatırlat"; uygulama açılmadan, arka planda; ertelemeler veritabanında saklanır ve yeniden kurmada kaybolmaz; iOS'ta işaretleme için telefon kilidi açılır. Sonraya: ısrarlı hatırlatma, widget'tan işaretleme.

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
