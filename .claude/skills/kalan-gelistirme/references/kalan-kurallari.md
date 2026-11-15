# Kalan: kurallar nerede

Kaynak: Kalan birleşik kaynak dosyası, ürün sahibi kararları (15.11.2026).

## Öncelik sırası

1. `docs/DECISIONS.md` (sonradan verilen kararlar; en yeni bilgi)
2. Ürün sahibi kararları: `python3 .claude/skills/kalan-gelistirme/scripts/kalan_kaynak.py kararlar`
3. Fiyat, mağaza kuralları ve maliyet için Fiyatlandırma (14.11.2026); ürün, özellik, tasarım, dil ve para birimi için Yol Haritası
4. Uygulama Dosyası (12.11.2026); yalnızca ilke, ses tonu ve kimlik bölümleri

Bir skill ile kaynak çelişirse kaynak ve `docs/DECISIONS.md` esas alınır; farkı rapora yaz.

## Konuya göre oku

Ayrıntılı kurallar repodaki üç skill'de durur. Yalnızca işin gerektirdiğini oku; skill bu konuşmada zaten yüklendiyse yeniden okuma.

| İş | Skill |
|---|---|
| Her UI, ekran metni, bildirim, Pro/satın alma, mağaza metni, ağ işi | `kalan-urun-kurallari`: değişmez kurallar, ses tonu, terim sözlüğü, Pro modeli |
| Renk, tema, ikon, grafik, logo | `kalan-palet`: 14 token, kullanım kuralları, Flutter eşlemesi |
| ARB, çeviri, tarih/tutar biçimi, para birimi, sağdan sola | `kalan-yerellestirme`: 22 yerel sürüm, basamak kuralları |

Nasıl okunur:
- **Ana oturum:** Skill aracıyla adıyla yükle.
- **Alt ajan:** Dosyayı Read ile oku: `.claude/skills/<ad>/SKILL.md`.
- **Bulunamazsa:** Bilgiyi betikle kaynaktan al (`bolum palet`, `bolum para`, `kararlar`) ve skill'in bulunamadığını rapora yaz. Kuralı tahmin etme.

Büyük tablolar yalnızca gerektiğinde, betikle:
- Pazar fiyatları: `bolum fiyatlar --belge fiyat`
- 75 para biriminin tablosu: `bolum para`
- Paletin kaynak bölümü: `bolum palet`

## Her işte akılda tut (kısa)

- Veri cihazda kalır; yeni ağ isteği, analiz ya da üçüncü taraf satın alma paketi yok.
- Para tam sayı (minor unit); `double` yok; biçim `intl`'den.
- Renk yalnızca tema tokenlarıyla.
- Yeni metin yalnızca TR ve EN ARB'ye, yer tutucu ve plural ile.
- Ücretsiz sürümde 4 açık plan: sabit ödemeler sayılmaz, tek ödemeli "sonra öde" sayılır.

## Repo belgeleri

0\. Temel maddesinin kurduğu belgeler:
- `CLAUDE.md`
- `docs/DECISIONS.md` (tarihli kararlar)
- `docs/DESIGN_TOKENS.md`
- `docs/ILERLEME.md` (biten maddeler ve yarım kalan iş; bu skill yazar)
