# Açılır pencereyle soru sorma (AskUserQuestion)

Amaç, kullanıcıyı bir kez ve topluca sorgulamak, sonra işi kesintisiz bitirmektir.

## Ne zaman

- İşin başında ve yalnızca ürün kararları için sorulur: metin, varsayılan değer, kapsamın sınırı, Ücretsiz/Pro, gizlilik tercihi.
- Brifteki "Açık sorular" listesinden şunlar çıkarılır:
  - Ürün sahibi kararlarının cevapladıkları (betik çıktısında "ESKİ SAYILAN … cevaplandı" diye görünür)
  - `docs/DECISIONS.md`'de cevabı olanlar
  - Koddan cevaplanabilenler (gerekirse `kalan-kesif` ile bakılır)
- `kalan-mimar` planında "kullanıcıya sorulacak" diye gelen kararlar da bu turda sorulur. Plan, sorular sorulmadan önce alınmalıdır; bu yüzden Büyük işte sıra şöyledir: plan → tek soru turu → uygulama.
- İş ortasında yeni bir ürün belirsizliği çıkarsa yalnızca o kısım için tek bir çağrı yapılır. Teknik belirsizlik sorulmaz: en az riskli seçim yapılır ve rapora yazılır.
- Ekranda görünecek tercihler (bir öğenin yeri, iki yerleşimden hangisi, görünen metin) ürün kararıdır ve sorulur. Mevcut ekranlarda aynı iş için bir desen varsa o uygulanır, sorulmaz.

## Kime soruyorsun

Ürün sahibi yazılımcı değildir. Soru ve seçenekler, uygulamayı yalnızca kullanan birinin anlayacağı dilde yazılır: kod adı (`PlanKind`, `splitEvenly`), dosya adı ve teknik terim yoktur. Seçeneğin açıklaması, kullanıcının ekranda ne göreceğini ya da ne yaşayacağını anlatır.

Yerleşim sorularında her seçeneğe `preview` alanıyla küçük bir metin çizimi eklenir:

```
Plan ekle
[ Toplam | Taksit ]
Taksit tutarı   [ 850      ]
Taksit sayısı   [ 9        ]
Toplam 7.650 TL · hesaplandı
```

## Nasıl

- Her çağrıda 1-4 soru, her soruda 2-4 seçenek olur. Kullanıcı her zaman "Other" ile kendi cevabını yazabilir.
- Önerilen seçenek ilk sıradadır ve etiketinin sonunda "(Önerilen)" yazar. Öneri brife, kararlara ve ürün ilkelerine dayanır.
- `header` en fazla 12 karakterdir (örnek: "Tür adı", "Süre", "Sınır").
- Soru metni tek başına anlaşılır olur ve madde numarasını içerir. Kullanıcı pencereyi açtığında senin önceki mesajını göremeyebilir.
- Birbirini dışlamayan seçenekler için `multiSelect: true` kullanılır.
- Asla sorulmayacaklar: "Plan uygun mu?", "Devam edeyim mi?", "Başlayayım mı?", "Commit atayım mı?"

## Cevaplardan sonra

`docs/DECISIONS.md` sonuna şu biçimde eklenir:

```
## 2026-11-15 · 6. madde
- Tür adı: "Sonra öde" / "Pay later" (kullanıcı seçti)
- Varsayılan süre: 30 gün (kullanıcı seçti)
```

Ardından iş durmadan sürer.

## Örnek: 6. madde ("Sonra öde" tek ödemeli plan)

Brifte 3 açık soru var. 1. soru (4 plan sınırına sayılır mı) Karar 4 ile cevaplıdır: sayılır. Sorulmaz. Kalan iki soru tek çağrıda sorulur:

```json
{
  "questions": [
    {
      "question": "6. madde: Tek ödemeli plan türünün adı ne olsun?",
      "header": "Tür adı",
      "multiSelect": false,
      "options": [
        {"label": "Sonra öde (Önerilen)", "description": "EN: Buy now, pay later. Brifteki kavramla ve terim sözlüğüyle aynı."},
        {"label": "Tek ödeme", "description": "EN: Single payment. Nötr ama ne olduğunu anlatmaz."},
        {"label": "Faturayla öde", "description": "EN: Pay by invoice. Almanya ve İsveç alışkanlığına yakın."}
      ]
    },
    {
      "question": "6. madde: Yeni bir 'sonra öde' kaydında varsayılan süre ne olsun?",
      "header": "Süre",
      "multiSelect": false,
      "options": [
        {"label": "30 gün (Önerilen)", "description": "Araştırmadaki pazarların çoğunda (İsveç, İsviçre, İtalya, Portekiz) yaygın."},
        {"label": "Son kullanılan", "description": "Kullanıcı aynı sağlayıcıyı tekrar kullanıyorsa hızlı."},
        {"label": "Uygulama diline göre", "description": "Daha karmaşık; şimdilik yalnızca TR ve EN var."}
      ]
    }
  ]
}
```
