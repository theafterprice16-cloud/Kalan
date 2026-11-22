# Yayın öncesi kontrol listesi

Her mağaza yayınından önce sırayla bakılır. Bir madde tamamlanmadan yayın yapılmaz.

## Veri dosyaları

- [ ] Sağlayıcı şablonlarını kaynak linklerinden yeniden doğrula (`assets/provider_templates.json`, Yol Haritası 25). Her şablonun `sources` linkini aç; taksit sayısı, aralık, ilk ödeme günü ve "sonra öde" süresi sayfayla aynı mı bak. Değişen ya da artık doğrulanamayan kalıbı düzelt ya da sil, kontrol ettiğin şablonun `checked` tarihini o günün tarihi yap. Ücret, faiz ya da oran ekleme. CI, kontrol tarihi 6 aydan eski şablon için uyarı verir (`tool/check_provider_templates.dart`).
- [ ] Tatil listesini yenile ve kaynaklardan doğrula (`assets/holidays.json`, Yol Haritası 26). Her ülkenin `sources` linkini aç; yeni yılın resmî tatillerini (dini bayramlar yalnızca resmî olarak ilan edildiyse) ve hafta sonu günlerini ekle, `lastYear` ve `checked` tarihini güncelle. Tahmini tarih, bölgesel tatil, yarım gün ve telafi iş günü ekleme. Resmî kaynağı bulunamayan ülke ya da yıl eklenmez. Yeni ülke eklersen Türkçe ve İngilizce ARB'deki `holidayCountryName` mesajına adını ekle. CI, listesi bu yıl ya da daha önce biten ülke için uyarı verir (`tool/check_holidays.dart`). Liste değişince uygulama açılışta ödenmemiş kart taksitlerinin tarihlerini bir kez yeniden hesaplar.
