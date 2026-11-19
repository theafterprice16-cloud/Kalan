# İlerleme

Yol haritası maddeleri (0-47) için `/clear` sonrası hafıza. `kalan-gelistirme` skill'i her işin sonunda günceller. Madde listesi: `python3 .claude/skills/kalan-gelistirme/scripts/kalan_kaynak.py liste`.

## Tamamlanan

İlk kayıt (16 Kasım 2026) `docs/BACKLOG.md`, `docs/DECISIONS.md` ve git geçmişinden çıkarıldı.

- 0. Temel: palet (Mürekkep ve Safran), logo, 75 para birimi (13 Kasım 2026)
- 1. Bildirim ve hatırlatmalar (13 Kasım 2026)
- 2. Devam eden planı ortasından ekleme (13 Kasım 2026)
- 3. Gecikenler bölümü ("Günü geçenler", 13 Kasım 2026)
- 4. Bildirimden "ödendi" işaretleme (13 Kasım 2026)
- 5. Israrlı hatırlatma (14 Kasım 2026)
- 6. "Sonra öde" tek ödemeli plan türü (14 Kasım 2026, PR #9 ve #10)
- 7. Ödeme aralığı seçimi (16 Kasım 2026): aylık taksit ve 4 ödemeli planda her ayın aynı günü / 30 gün / 2 hafta / hafta / özel N gün; önizlemede aynı ay notu; düzenlemede yalnızca ödenmemiş taksitler; şema v9

- 8. Toplam tutarla ya da taksit tutarıyla giriş (16 Kasım 2026): plan eklemede "Toplam" / "Taksit" parçalı düğmesi, diğer değer anında "hesaplandı" notuyla, artık ilk taksitte ve ekranda açık; son kullanılan yol hatırlanır (ilk açılış "Toplam"); şema v10; ardından: yol değişince klavye açık kalır, çok uzun tutara "çok büyük" hata metni

- 9. Ödeme şekli (16 Kasım 2026): her planda "Otomatik çekilir" / "Elle ödenir" / "Belirtilmedi"; kart taksidi otomatik gelir; otomatikte isteğe bağlı çekildiği yer; elle ödenen plana hatırlatma genel ayardan bir gün önce; bildirim metni şekle göre; ana ekranda ikon; şema v11

- 10. Maaş günü özeti bildirimi (16 Kasım 2026): her maaş döneminin ilk günü, hatırlatma saatinde tek bildirim; ödeme sayısı, toplam ve (gelir varsa) kalan, ana ekranla aynı hesap; Ayarlar'da anahtar, varsayılan açık; şema v12

- 11. Pro satın alma (18 Kasım 2026): tek ürün ömür boyu Kalan Pro; fiyat mağazadan; 5. planda sakin alt sayfa, satın alınca plan aynı alanlarla kaydedilir; Ayarlar'da Kalan Pro ve geri yükleme; Pro yalnızca mağazanın açık sinyaliyle kalkar; durum cihazda (veritabanı değil); iOS için StoreKit test dosyası. Panel işleri (App Store Connect, Google Play Console) ürün sahibinde

- 12. İleriki dönemlerin grafiği (19 Kasım 2026): ana ekranda büyük sayının altında küçük 6 çubuklu "İleriki dönemler" şeridi; dokununca ayrı ekran, bu dönem seçili; her çubukta söz verilmiş (safran) ve kalan (lacivert), eksi dönemde gelir çizgisi ve "−… eksik"; çubuğa dokununca o dönemin özeti ve ödemeleri; gelir yoksa yalnızca söz verilmiş ve gelir daveti; herkese 6 dönem, ücretsiz; hesap ana ekranla aynı yerden; şema değişmedi

Ara işler:

- Arayüz uyum düzenlemesi (18 Kasım 2026): iPhone'da sağdan kayan sayfa ve kenardan geri, Android'de öngörülü geri; onay pencereleri iPhone'da Apple düzeninde düz Kalan penceresi; anahtarlar iki telefonda mürekkep renginde; boşluk ve köşe ölçüleri tek dosyada; "ödendi" ve kayıtta hafif titreşim; bekçi testi ve iPhone golden'ları (40-43)

## Sıradaki

- 13. maddeden devam (liste: `kalan_kaynak.py liste`)

## Yarım kalan

Yok.
