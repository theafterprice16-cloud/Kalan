# Kalan

Taksitleri ve "şimdi al, sonra öde" planlarını tek takvimde toplayan, her maaş döneminde geriye ne kaldığını gösteren Flutter uygulaması (iOS + Android, TR + EN).

Ürün kaynakları ve öncelik sırası (ürün sahibi kararı, 15 Kasım 2026):
1. `docs/DECISIONS.md` (verilmiş kararlar; en yeni bilgi). Büyük bir dosya: bütün okuma, Grep ile ara.
2. Birleşik kaynak `docs/kalan-birlesik.html` içindeki "ürün sahibi kararları". Dosya ~800 KB: bütün okuma, yalnızca betikle parça al: `python3 .claude/skills/kalan-gelistirme/scripts/kalan_kaynak.py kararlar | liste | ozellik N`.
3. Aynı dosyadaki Yol Haritası (ürün, özellik, tasarım, dil, para birimi; maddeler 0-47) ve Fiyatlandırma (fiyat, mağaza, maliyet).
4. `docs/kimlik/kalan-uygulama-dosyasi.html`: yalnızca ilke, ses tonu ve kimlik ("B · Kimlik" bağlayıcıdır).

`docs/BACKLOG.md` eski sıralamadır. Ürün sahibi kararlarıyla çelişen maddeleri geçersizdir: ekran görüntüsünden okuma cihazda yapılır, bulut ve sunucu yok (Karar 3); Pro yalnızca tek seferlik satın almadır, aylık ve yıllık yok (Karar 2).

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

- Her ödeme için iki bildirim: "önceden" (genel ayar 1/2/3/5/7 gün, varsayılan 2; plan bazında Genel ayar / Kapalı / Farklı gün) ve "gününde", 09:00. Aynı gün ve türde tek bildirim, en yakın 60. Varsayılan gün tek yerde: `defaultLeadDaysFor`.
- Planlayıcı: `lib/core/reminders` (saf Dart; metinleri `ReminderTexts` arayüzüyle alır). Platform: `lib/features/reminders` (`NotificationGateway` arkasında). Yeniden kurma `ReminderSync` ile veritabanı akışlarından tek merkezde, kısa beklemeyle.
- Tarih her zaman motorun sakladığı etkin son ödeme günü. Dokununca ana ekran.
- Bildirim düğmeleri: "Ödendi" / "Hepsi ödendi", "Akşam hatırlat" (gününde, saat ≤ 18:00), "Yarın hatırlat" (önceden, ertesi gün ödeme yoksa); en çok iki. Kurallar `reminderActions`'ta. İşleyici tek: `ReminderActionHandler`, arka planda `reminderActionInBackground`; işaretleme yalnızca repository'lerin "ödendi" kodundan. Ertelemeler `reminder_snoozes` tablosunda, planlayıcıya girdi.
- Israrlı hatırlatma (`ReminderRepeat`: Kapalı / Akşam bir kez daha / Her gün; genel, plan ve sabit ödeme bazında): anlar yalnızca planlayıcıda (`reminderMoments`), yalnızca kullanıcı saatinde ve 20:00'de (saat ≤ 18:00 ise), son günden en çok 7 gün sonrasına kadar. Mod kapalıyken bildirim listesi birebir eskisi gibi kalır. Israrlı ödemede "Yarın hatırlat" o günü atlayan erteleme kaydıdır (`skipsDay`); ikinci tablo ya da zamanlayıcı yazılmaz.
- Veritabanı süreç içinde paylaşılır (`AppDatabase.openShared`); arka plandaki isolate ayrı bağlantı açmaz.
- Yalnızca yerel bildirim; Android'de kesin olmayan zamanlama (exact alarm izni yok).
- Web'de kapalı (`NotificationGateway.supported`).

## Ortasından eklenen planlar

- "Bu plan zaten sürüyor": geçmiş taksitler gerçek ödeme kaydıdır (`payments.paidBeforeKalan`, ödenmiş). Tek tek listelenmez, tarihleri gösterilmez, gecikmiş sayılmaz, bildirim almaz; dönem toplamına normal ödenmiş ödeme gibi girer.
- Geriye tarih yalnızca motorun `underwayDates` fonksiyonuyla (ileri yön kuralıyla tutarlı). Düzenleme, uygulamada "ödendi" işaretlenen ödemelere asla dokunmaz.

## Sonra öde

- `PlanKind.payLater`: tek ödeme; son ödeme günü yalnızca `payLaterDueDate` ile (motorun ay sonu kuralı, hafta sonu kaydırması yok). Plan kuralı saklar; düzenlemede tarih kurala göre yeniden hesaplanır, "Tarih seç" korunur. Son kullanılan kural genel ayarda.
- Mağaza adı ve kaynak isteğe bağlı (`plans.source_id` boş olabilir). Ad yoksa ekran ve bildirimde `planNameIn` / `context.planName` ("Sonra öde · 14 Ara"); `displayName` ekranda kullanılmaz.
- Türe özel bildirim, gecikme ya da dönem kodu yazılmaz; ödeme genel yollardan geçer.

## Günü geçenler

- Bir ödemenin hangi dönemin toplamına girdiği yalnızca motordaki `countingDate` ile belirlenir: ödenmemiş ve günü geçmiş → bu dönem; "Bugün" ile ödenmiş → ödendiği gün (`payments.paidOnDay`); diğer her şey → son ödeme günü. Başka yerde bu kural yazılmaz.
- Geciken satır kendiliğinden kalkmaz, gizlenmez; late yalnızca "x gün önce" notu ve saat ikonunda.

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

## Model seçimi, limit ve oturum düzeni

- Ürün sahibi yazılımcı değildir: kodu okumaz, uygulamayı telefonda deneyerek kontrol eder. Ona sade Türkçeyle, kod ve dosya adı olmadan yaz; arayüz değişikliğinde golden görüntülerine kendin bakıp mevcut ekranlarla uyumu kontrol et (ayrıntı `kalan-gelistirme` skill'inde).
- Her geliştirme işi `kalan-gelistirme` skill'iyle yapılır (`/kalan-gelistirme <madde no ya da iş>`). Skill işi Haiku, Sonnet ve Opus alt ajanlarına (`.claude/agents/`) böler; ana oturum Opus'tur (`.claude/settings.json`; ürün sahibi kodu okumadığı için). Limit daralınca küçük ve kuralları net işlerde Sonnet seçilebilir.
- Ürün kuralı ayrıntıları repodaki skill'lerde: renk `kalan-palet`, metin, ses tonu, terimler ve Pro `kalan-urun-kurallari`, çeviri ve para biçimi `kalan-yerellestirme`. `kalan-brif-prompt` yalnızca açıkça prompt istenince kullanılır.
- Hafıza diskte: biten maddeler ve yarım kalan iş `docs/ILERLEME.md`, kararlar `docs/DECISIONS.md`. Her işin sonunda ikisi güncellenir ve işle birlikte main'e ulaşır.
- Kullanıcı her işten sonra `/clear` yapar ya da yeni oturum açar. "Kaldığımız yerden devam" denirse önce `docs/ILERLEME.md` oku ve `git log --oneline -10` çalıştır; tahmin yürütme.
- Bulut oturumu (claude.ai/code) repoyu her seferinde main'den baştan kopyalar: push'lanmamış ve main'e birleşmemiş iş sonraki oturumda yoktur.
- Bulut oturumunda ilk testten önce bir kez `flutter pub get`. `flutter` yoksa kurmaya çalışma; bunu raporun başına yaz (kurulum betiği: `tool/bulut-kurulum.sh`, ortam ayarlarındaki Setup script).

## Çalışma kuralları

- Belgeler Türkçe; kod, dosya adları, commit mesajları İngilizce.
- Her değişiklikten sonra format, analyze, test temiz olmalı.
- Yeni paket eklemeden önce gerekçeyi `docs/DECISIONS.md`'ye yaz; ağ yapan paket ekleme.
- Plan oluşturmanın tek yolu: taslak (`PlanDraft`) → kullanıcı onayı → kayıt.
- PR birleştirme: testler, `flutter analyze` ve CI (Android derlemesi dahil) yeşilse ve değişiklik istenen işin kapsamındaysa, PR ürün sahibine sormadan birleştirilir; ardından ona kısaca bildirilir. Kırmızı test, kural çelişkisi ya da yeni paket varsa önce sorulur.

# Compact instructions

Özetlerken şunları koru: değişen dosyalar, açık hatalar ve test durumu, kullanıcının verdiği ürün kararları, sıradaki adım.
