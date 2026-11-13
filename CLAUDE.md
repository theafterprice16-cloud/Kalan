# Kalan

Taksitleri ve "şimdi al, sonra öde" planlarını tek takvimde toplayan, her maaş döneminde geriye ne kaldığını gösteren Flutter uygulaması (iOS + Android, TR + EN).

Ürünün tek doğruluk kaynağı: `docs/kimlik/kalan-uygulama-dosyasi.html`. "B · Kimlik" bölümü bağlayıcıdır. Verilmiş kararlar `docs/DECISIONS.md`, sıradaki işler `docs/BACKLOG.md`.

## Değişmez kurallar

1. Hesap, giriş, banka/sağlayıcı bağlantısı, reklam yok. Veri yalnızca cihazda. Analitik, çökme raporu ya da ağ isteği yapan paket eklenmez (sormadan asla).
2. Takvim, tahmin değil: yalnızca bilinen ödemeler. Bilinmeyen tutar uydurulmaz, kullanıcıya sorulur.
3. Yargı yok: puan, rozet, seri, kırmızı alarm, ünlem, emoji yok. Eksi dönem koyu safran (`negative`); vişne (`late`) yalnızca gecikme, hata ve silme.
4. Ödeme yapılmaz, para tutulmaz, kredi/kart önerilmez, tavsiye verilmez.
5. Sağlayıcı/banka logosu yok; ad düz metin + nötr harf rozeti (`LetterBadge`).
6. Yirmi saniye kuralı: şablonla plan ekleme tek ekranda, en çok dört alan.
7. Terimler sözlüğü birebir (aşağıda).
8. Ses tonu: "sen", kısa ve sakin cümleler, tutarlar rakam + para birimi. Örnek: "Bu dönem 4 ödeme var. Toplam 3.250 TL."
9. Para tutarları `int` küçük birimle (kuruş, cent). `double` kullanılmaz.

Ek: Arayüz metni kodda sabit yazılmaz (`lib/l10n/*.arb`, Türkçe ve İngilizce). Durum yalnızca renkle anlatılmaz. Dokunma hedefi en az 48x48.

Uygulama dilleri şimdilik yalnızca Türkçe ve İngilizce. Ayrıca istenmedikçe yeni dil ekleme, mevcut çevirileri değiştirme.

## Hatırlatmalar

Ödemeyi etkileyen her değişiklikten sonra bildirimler yeniden kurulur; yeni bildirim kuralı önce saf Dart planlayıcıya testle eklenir.

- Planlayıcı: `lib/core/reminders` (saf Dart). Platform: `lib/features/reminders` (`NotificationGateway` arkasında). Yeniden kurma `ReminderSync` ile veritabanı akışlarından tek merkezde.
- Yalnızca yerel bildirim; Android'de kesin olmayan zamanlama (exact alarm izni yok).
- Web'de kapalı (`NotificationGateway.supported`).

## Renk

Tüm geliştirmeler Mürekkep ve Safran paletine uyar; yalnızca tema tokenları kullanılır; yeni renk eklemek için ürün sahibinden onay alınır.

- Palet, kontrastlar ve kurallar: docs/DESIGN_TOKENS.md. `accent` yalnızca "kalan" (büyük sayı, birincil düğme, grafikte kalan); `negative`/`negativeText` yalnızca eksi kalan; `late` yalnızca gecikme, hata, silme; `chartCommitted` yalnızca grafik.
- Degrade, gölge ve saydamlıkla ara ton yok. Her yeni ekran açık ve koyu temada golden testle doğrulanır.

- Tokenlar: `lib/core/theme/kalan_colors.dart`; tema: `kalan_theme.dart`; ekranlarda `context.colors.<token>`.
- Bekçi: `test/app/color_guard_test.dart`; kontrast: `test/core/theme/contrast_test.dart`; golden: `test/golden/` → `screenshots/`.

## Para

- Tek para birimi, kur çevirisi yok, kur çekilmez. Tutarlar `int` küçük birim.
- Kayıt: `lib/core/money/currency.dart`, 75 birim (kod, sembol, ayırt edici sembol, 0/2/3 basamak, ülkeler, yerel sürümler). Ekranlarda sembol ya da ondalık sayısı yazılmaz.
- Tutarlarda birimin kendi sembolü; seçicide ve dışa aktarmada `pickerLabel` ("COL$ · COP"). Saklama ölçeği günlük basamak sayısıdır (KWD 1000, JPY 1).
- Biçimlendirme ve ayrıştırma yalnızca `lib/core/money/money_format.dart`; ekranlar `ref.money`, `ref.parseMoney`, `ref.moneyInput`, `ref.amountKeyboard`, `ref.amountFormatters` kullanır (`lib/app/format.dart`). Bildirim, widget ve dışa aktarma da aynı yolu kullanır. `test/app/money_path_test.dart` başka yolu yakalar.
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
python3 tool/generate_icons.py           # marka SVG/PNG kaynakları (assets/brand)
dart run flutter_launcher_icons          # platform ikonları (sonra project.pbxproj değişikliğini geri al)
flutter test test/golden --update-goldens  # golden görüntüleri yenile
```

## Klasör haritası

```
lib/
  core/
    date/       LocalDate (saat dilimsiz gün)
    money/      Currency, para biçimlendirme ve ayrıştırma
    reminders/  Saf Dart hatırlatma planlayıcısı
    engine/     Saf Dart hesap motoru (Flutter import'u yasak, testle denetlenir)
    design/     AmountText, LetterBadge, PeriodBar, form alanları
    theme/      KalanColors (Mürekkep ve Safran), tema, tema seçimi
    routing/    go_router
  data/
    db/         Drift tabloları ve AppDatabase
    repositories/
  entitlement/  Ücretsiz/Pro yetki soyutlaması
  features/     onboarding, home, plans, sources, recurring, settings, roadmap, reminders, currency
  l10n/         app_en.arb, app_tr.arb, generated/
assets/roadmap.json   Yol Haritası içeriği (docs/ROADMAP_CONTENT.md)
assets/brand/         İkon kaynakları (SVG + PNG)
screenshots/          Golden görüntüleri
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
