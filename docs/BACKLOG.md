# Sıradaki işler

Sıra önemlidir. Parantez içindekiler özelliğin görüldüğü rakip uygulamalardır.

1. **İleri bakış** (Pro): önümüzdeki dönemler çubuk olarak, sıkışık dönem işareti, bütün planların bittiği tarih (PayDown).
2. **Dene** (Pro): yeni bir planın etkisini kaydetmeden gösterme.
3. **Yerel bildirimler**: ödemeden iki gün önce ve ödeme günü sabahı; gün ve saat ayarlanabilir (Frizzbee). Bildirimden "Ödendi" (BillWise). Ödenince kalan hatırlatmalar iptal olur. Israrlı hatırlatma, varsayılan kapalı (Due).
4. **İade bekliyor** işareti; gecikme ücreti kaydı (Frizzbee); kısmi ya da farklı tutarla ödeme (Bills Monitor).
5. **Tutarları gizle** düğmesi (BillWise); Face ID ve parmak izi kilidi (Bobby); aylık takvim görünümü (Bills Monitor); durum filtresi ve arama (Tortol).
6. **Dosyaya dışa aktarma ve dosyadan geri yükleme** (ücretsiz; kimlik dosyası B bölümü: "dışa aktarma her zaman açıktır").
7. **Ekran görüntüsünden ve yapıştırılan metinden plan ekleme** (Pro; PayDown). Bulut AI + küçük ara sunucu, açık rıza ve onay ekranı. `PlanDraft` → onay → kayıt yolunu kullanır.
8. **Pro satın alma**: aylık, yıllık, ömür boyu. `EntitlementService` arkasına bağlanır.
9. **Ana ekran widget'ı**, iOS ve Android (Subby).
10. **Türkiye resmi tatil kaydırması**; mağaza hazırlığı.
11. **8 dili ekle** (docs/ceviriler-beklemede/ dosyalarından başla): İspanyolca, Fransızca, Almanca, Portekizce-Brezilya, Rusça, Çince Basitleştirilmiş, İtalyanca, Endonezce.

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
