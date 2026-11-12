# Kalan

Taksitleri ve "şimdi al, sonra öde" planlarını tek takvimde toplayan, her maaş döneminde geriye ne kaldığını gösteren Flutter uygulaması (iOS + Android, TR + EN).

Ürünün tek doğruluk kaynağı: `docs/kimlik/kalan-uygulama-dosyasi.html`. "B · Kimlik" bölümü bağlayıcıdır. Verilmiş kararlar `docs/DECISIONS.md`, sıradaki işler `docs/BACKLOG.md`.

## Değişmez kurallar

1. Hesap, giriş, banka/sağlayıcı bağlantısı, reklam yok. Veri yalnızca cihazda. Analitik, çökme raporu ya da ağ isteği yapan paket eklenmez (sormadan asla).
2. Takvim, tahmin değil: yalnızca bilinen ödemeler. Bilinmeyen tutar uydurulmaz, kullanıcıya sorulur.
3. Yargı yok: puan, rozet, seri, kırmızı alarm, ünlem, emoji yok. Mercan (#E4572E) yalnızca eksiye düşen dönemde.
4. Ödeme yapılmaz, para tutulmaz, kredi/kart önerilmez, tavsiye verilmez.
5. Sağlayıcı/banka logosu yok; ad düz metin + nötr harf rozeti (`LetterBadge`).
6. Yirmi saniye kuralı: şablonla plan ekleme tek ekranda, en çok dört alan.
7. Terimler sözlüğü birebir (aşağıda).
8. Ses tonu: "sen", kısa ve sakin cümleler, tutarlar rakam + para birimi. Örnek: "Bu dönem 4 ödeme var. Toplam 3.250 TL."
9. Para tutarları `int` küçük birimle (kuruş, cent). `double` kullanılmaz.

Ek: Arayüz metni kodda sabit yazılmaz (`lib/l10n/*.arb`, Türkçe ve İngilizce). Durum yalnızca renkle anlatılmaz. Dokunma hedefi en az 48x48.

Uygulama dilleri şimdilik yalnızca Türkçe ve İngilizce. Ayrıca istenmedikçe yeni dil ekleme, mevcut çevirileri değiştirme.

## Para

- Tek para birimi, kur çevirisi yok, kur çekilmez. Tutarlar `int` küçük birim.
- Kayıt: `lib/core/money/currency.dart` (kod, sembol, ayırt edici sembol, ondalık, ülkeler). Ekranlarda sembol ya da ondalık sayısı yazılmaz.
- Biçimlendirme ve ayrıştırma yalnızca `lib/core/money/money_format.dart`; ekranlar `ref.money`, `ref.parseMoney`, `ref.moneyInput`, `ref.amountKeyboard` kullanır (`lib/app/format.dart`). Bildirim, widget ve dışa aktarma da aynı yolu kullanır. `test/app/money_path_test.dart` başka yolu yakalar.
- **Para birimi eklemek:** `Currency.all` listesine bir satır ekle ve Türkçe ile İngilizce ARB dosyalarındaki `currencyName` select mesajına `KOD{Ad}` dalını ekle. Başka adım yok; testler yeni satırı otomatik kapsar.

## Komutlar

```bash
flutter pub get
dart run build_runner build -d          # Drift şeması değişince
flutter gen-l10n                         # ARB değişince (flutter run/test da üretir)
dart format lib test
flutter analyze
flutter test
dart run drift_dev make-migrations       # şema sürümü artırınca (önce schemaVersion++)
python3 tool/generate_icons.py           # ikon ve açılış görsellerini yeniden üretir
```

## Klasör haritası

```
lib/
  core/
    date/       LocalDate (saat dilimsiz gün)
    money/      Currency, para biçimlendirme ve ayrıştırma
    engine/     Saf Dart hesap motoru (Flutter import'u yasak, testle denetlenir)
    design/     Renkler, tema, AmountText, LetterBadge, PeriodBar
    routing/    go_router
  data/
    db/         Drift tabloları ve AppDatabase
    repositories/
  entitlement/  Ücretsiz/Pro yetki soyutlaması
  features/     onboarding, home, plans, sources, recurring, settings, roadmap
  l10n/         app_en.arb, app_tr.arb, generated/
assets/roadmap.json   Yol Haritası içeriği (docs/ROADMAP_CONTENT.md)
drift_schemas/        Şema anlık görüntüleri (göç testi için)
test/                 lib/ yapısını izler
```

## Terimler (kodda İngilizce)

| TR | Kod |
|---|---|
| Plan | `Plan` |
| Ödeme | `Payment` |
| Kaynak | `Source` |
| Dönem | `PayPeriod` |
| Söz verilmiş | `spokenFor` |
| Kalan | `left` |
| Dene | `TryIt` |
| Sıkışık dönem | `tight` |
| Ekstre günü | `statementDay` |
| Son ödeme günü | `dueDay` |
| İade bekliyor | `refundPending` |
| Sabit ödeme | `RecurringPayment` |

## Çalışma kuralları

- Belgeler Türkçe; kod, dosya adları, commit mesajları İngilizce.
- Her değişiklikten sonra format, analyze, test temiz olmalı.
- Yeni paket eklemeden önce gerekçeyi `docs/DECISIONS.md`'ye yaz; ağ yapan paket ekleme.
- Plan oluşturmanın tek yolu: taslak (`PlanDraft`) → kullanıcı onayı → kayıt.
