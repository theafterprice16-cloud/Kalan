# Kalan

Flutter ile yazılmış taksit ve "sonra öde" takvimi (iOS + Android). Tek soruya cevap verir: "Bu maaştan, söz verdiklerim çıktıktan sonra bana ne kalıyor?" Bütçe uygulaması değildir.

## Değişmez kurallar

- **Gizlilik:** Bütün veri cihazda kalır. Sunucu, hesap, bulut eşitleme, reklam, analiz ya da izleme paketi yok. Yeni ağ isteği ekleme.
- **Para:** Tutarlar tam sayı (minor unit) olarak saklanır; para hesabında `double` kullanma. Biçimi `intl` üretir, elle biçim yazma. Kur çevirisi yok.
- **Renk:** Renkler yalnızca tema klasöründe, "Mürekkep ve Safran" tokenlarıyla tanımlanır. Başka yerde `Color(0x…)`, `Colors.x` ya da hex yazma. Yeşil ağırlıklı eski palet geçersiz.
- **Metin:** Yeni metinler yalnızca TR ve EN ARB dosyalarına yazılır, yer tutucu ve plural ile; metni elle birleştirme.
- **Ses tonu:** Sakin, kısa, yargısız. Emoji, ünlem, kırmızı alarm, tebrik yok.
- **Satın alma:** Tek seferlik "Kalan Pro", yalnızca resmî `in_app_purchase` ile. Üçüncü taraf satın alma paketi yok.
- **Ücretsiz sürüm:** En fazla 4 açık plan.
- **Belirsizlik:** Ürün kararını tahmin etme; kullanıcıya sor.

Ayrıntılar claude.ai hesabından gelen skill'lerde: renk için `kalan-palet`, metin, ses tonu, terimler ve Pro için `kalan-urun-kurallari`, çeviri ve para biçimi için `kalan-yerellestirme`. Bir skill ile `docs/DECISIONS.md` çelişirse `docs/DECISIONS.md` geçerlidir.

## Bilgi nerede

| Ne | Nerede |
|---|---|
| Geliştirme iş akışı ve model seçimi | `kalan-gelistirme` skill'i |
| Yol haritası maddeleri (0-47) ve ürün belgeleri | `python3 .claude/skills/kalan-gelistirme/scripts/kalan_kaynak.py ozellik N` |
| Sonradan verilen kararlar | `docs/DECISIONS.md` |
| Hangi maddeler bitti, yarım kalan ne | `docs/ILERLEME.md` |

Birleşik kaynak HTML dosyasını (~800 KB) hiçbir zaman bütün okuma; yalnızca betikle parça al. `docs/DECISIONS.md` dosyasında da Grep ile ara.

## Çalışma düzeni

- Her geliştirme işi `kalan-gelistirme` skill'iyle yapılır.
- Kontrol komutları: `flutter analyze`, `flutter test`, `dart format .`. Kırmızı testle iş bitmiş sayılmaz.
- Bulut oturumunda ilk testten önce bir kez `flutter pub get` çalıştır. `flutter` yoksa kurmaya çalışma; bunu raporun başına yaz.
- İş bitince sırasıyla: testler yeşil, `docs/DECISIONS.md` ve `docs/ILERLEME.md` güncel, commit atılmış (bulut oturumunda push'lanmış). Ardından kullanıcı `/clear` yapar ya da yeni oturum açar.
- `/clear` sonrası konuşma geçmişi yoktur. Kullanıcı "kaldığımız yerden devam" derse önce `docs/ILERLEME.md` dosyasını oku ve `git log --oneline -10` çalıştır; tahmin yürütme.
- Bulut oturumunda (claude.ai/code, GitHub'dan kopyalanan repo) commit'ten sonra çalışılan dalı mutlaka push'la: yeni oturum repoyu baştan kopyalar, push'lanmamış iş ve `docs/ILERLEME.md` kaybolur. PR'ı yalnızca kullanıcı isterse aç.

# Compact instructions

Özetlerken şunları koru: değişen dosyalar, açık hatalar ve test durumu, kullanıcının verdiği ürün kararları, sıradaki adım.
