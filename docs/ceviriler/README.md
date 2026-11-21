# Çeviriler

Kalan'ın 22 yerel sürümü için çeviri durumu (Yol Haritası 24). Bugün yalnızca Türkçe ve İngilizce açık; diğer diller yol haritasının sonundaki "Toplu çeviri" işinde tek seferde çevrilir ve bir kez gözden geçirilir.

## Bu klasörde

- `cevrilecekler.json`: çevrilmeyi bekleyen metinler, yerel sürüm başına anahtar listesi. Elle yazılmaz; `flutter gen-l10n` (ve `flutter pub get`, `flutter run`, derleme) `l10n.yaml`'daki `untranslated-messages-file` ayarıyla üretir. Bir iş TR ve EN'ye yeni metin eklediğinde anahtar burada 20 yerel sürümün altında kendiliğinden görünür (en_GB İngilizceyi devraldığı için listede yok; `pt` yalnızca pt_BR ve pt_PT'nin ortak yedeği). Dosya her işte commit'lenir; `test/l10n/arb_integrity_test.dart` ve CI güncel olduğunu denetler.

## Kurallar

- Yeni metin yalnızca `lib/l10n/app_en.arb` ve `app_tr.arb`'ye yazılır. Diğer ARB dosyaları şimdilik boştur (yalnızca `@@locale`); eksik metinler İngilizceye düşer.
- Bir dil, çevirisi tamamlanmadan açılmaz. Açmak `lib/l10n/app_locales.dart`'ta durumu değiştirmektir: "taslak" (dil seçicide "Taslak" notuyla, sistem dilinden seçilmez) ya da "gözden geçirildi" (seçici, sistem dili, iOS ve Android listeleri). Ardından `dart run tool/sync_locales.dart`.
- Açık her yerel sürümde bütün anahtarlar ve İngilizceyle aynı yer tutucular bulunur; sayı sayan her mesaj ICU plural'dır ve dilin bütün CLDR kategorilerini taşır (ar: zero, one, two, few, many, other; ru ve pl: one, few, many, other). Testler: `test/l10n/arb_integrity_test.dart`, `test/l10n/plural_test.dart`.
- Dil adları `app_locales.dart`'ta kendi dillerindedir ("Português (Brasil)", "العربية") ve çevrilmez.
- Tarih, sayı ve para biçimi intl'den gelir; elle kalıp yazılmaz. Her dilde Batı rakamları (0-9), Arapça dahil. Kur çevirisi yok; dil değişince para birimi değişmez.

## Temel dosyalar ve bölgeler

| Dosya | Yerel sürüm |
|---|---|
| `app_en` | en-US (şablon) |
| `app_en_GB` | en-GB |
| `app_es`, `app_es_419` | es-ES, es-419 |
| `app_pt_BR`, `app_pt_PT` | pt-BR, pt-PT (`app_pt` ortak yedek) |
| `app_de`, `app_de_CH` | de-DE, de-CH |
| `app_fr`, `app_fr_CA` | fr-FR, fr-CA |
| `app_zh`, `app_zh_Hant` | zh-Hans, zh-Hant (tarih ve sayı zh_TW verisinden) |
| `app_tr`, `app_it`, `app_id`, `app_ru`, `app_ar`, `app_pl`, `app_nl`, `app_sv`, `app_ja`, `app_vi` | kendi dilleri |

Hangi temel dosyanın hangi bölgeyi taşıdığı toplu çeviride kesinleşir.

## Toplu çeviri için notlar

- Başlangıç malzemesi: `docs/ceviriler-beklemede/` (8 dilin eski taslakları; o tarihten sonra eklenen ve değişen anahtarlar için `cevrilecekler.json`'a bak).
- Pazar terimleri, hitap biçimi ve yerel notlar: `.claude/skills/kalan-yerellestirme/SKILL.md`.
- Arapça cümle içinde Latin harfli plan ya da mağaza adı (ör. "Klarna") geçen bildirim ve satırlarda yön karışmaması için adı FSI/PDI (U+2068/U+2069) ile yalıtmayı değerlendir; tutarlar zaten yalıtılıyor.
- Çevrilen her dil ana dili konuşan biri tarafından okunduktan sonra "gözden geçirildi" yapılır.
