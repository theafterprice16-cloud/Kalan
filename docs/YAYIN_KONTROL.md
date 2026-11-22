# Yayın öncesi kontrol listesi

Her mağaza yayınından önce sırayla bakılır. Bir madde tamamlanmadan yayın yapılmaz.

## Veri dosyaları

- [ ] Sağlayıcı şablonlarını kaynak linklerinden yeniden doğrula (`assets/provider_templates.json`, Yol Haritası 25). Her şablonun `sources` linkini aç; taksit sayısı, aralık, ilk ödeme günü ve "sonra öde" süresi sayfayla aynı mı bak. Değişen ya da artık doğrulanamayan kalıbı düzelt ya da sil, kontrol ettiğin şablonun `checked` tarihini o günün tarihi yap. Ücret, faiz ya da oran ekleme. CI, kontrol tarihi 6 aydan eski şablon için uyarı verir (`tool/check_provider_templates.dart`).
