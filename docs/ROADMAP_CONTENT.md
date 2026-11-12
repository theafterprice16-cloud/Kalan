# Yol Haritası içeriği

Ayarlar → Yol Haritası ekranı içeriğini uygulamaya gömülü `assets/roadmap.json` dosyasından okur. Ağ isteği yoktur; içerik değişince yeni bir sürüm çıkarman gerekir.

Dosya şimdilik boş bir listedir (`[]`). Boşken ekranda tek cümlelik sakin bir boş durum görünür.

## Biçim

Dosya bir JSON listesidir. Her madde şu alanları taşır:

| Alan | Zorunlu | Açıklama |
|---|---|---|
| `id` | evet | Tekil kimlik. Küçük harf ve tire önerilir (`yerel-bildirimler`). İki madde aynı kimliği taşıyamaz. |
| `title.tr`, `title.en` | evet | Kısa başlık, iki dilde. |
| `summary.tr`, `summary.en` | evet | Bir iki cümlelik açıklama, iki dilde. |
| `status` | evet | `planned` (Planlandı), `in_progress` (Yapılıyor) ya da `shipped` (Yayınlandı). |
| `targetVersion` | hayır | Hedef sürüm, metin olarak (`"1.1"`). Bilmiyorsan alanı hiç yazma. |

Ses tonu kimlik dosyasındakiyle aynıdır: "sen" hitabı, kısa ve sakin cümleler, ünlem ve emoji yok, söz verme yok.

## Örnek

```json
[
  {
    "id": "yerel-bildirimler",
    "title": {
      "tr": "Ödeme hatırlatmaları",
      "en": "Payment reminders"
    },
    "summary": {
      "tr": "Ödemeden iki gün önce ve ödeme günü sabahı telefonuna bildirim gelir.",
      "en": "Your phone reminds you two days before a payment and on the morning it's due."
    },
    "status": "in_progress",
    "targetVersion": "1.1"
  },
  {
    "id": "disa-aktarma",
    "title": {
      "tr": "Dosyaya dışa aktarma",
      "en": "Export to a file"
    },
    "summary": {
      "tr": "Planlarını bir dosyaya kaydedip başka bir telefona taşıyabilirsin.",
      "en": "Save your plans to a file and move them to another phone."
    },
    "status": "planned"
  }
]
```

## Adımlar

1. `assets/roadmap.json` dosyasını aç ve maddeleri yukarıdaki biçimde yaz.
2. `flutter test test/features/roadmap_test.dart` çalıştır. Test, dosyanın şemaya uyduğunu ve bu belgedeki örneğin geçerli olduğunu doğrular. Eksik dil, bilinmeyen durum ya da tekrar eden kimlik testi kırar.
3. Uygulamayı çalıştırıp Ayarlar → Yol Haritası ekranına bak.
