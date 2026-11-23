# Kalan yedek biçimi (sürüm 1)

Yol haritası 29 (dışa aktarma) bu dosyayı yazar; 30 (geri yükleme) okur. Okuyucu `lib/core/backup/backup_file.dart` içindeki `readBackup`, model `lib/core/backup/backup_data.dart`. Bu belge ile uygulamanın yazdığı dosya `test/data/backup_collector_test.dart` içinde alan alan karşılaştırılır: aşağıdaki tablolarda olmayan bir alan dosyada çıkarsa ya da tablodaki bir alanın türü değişirse test kırmızı olur.

## Genel kurallar

- Dosya UTF-8 JSON metnidir, adı `kalan-yedek-2026-11-19.json` gibidir (uygulama dilinde, ASCII, tarihli).
- Biçim veritabanı şemasından bağımsızdır: her değer anlamlı bir adla yazılır; sütun adı, iç kimlik numarası ya da şema sürümü yoktur. Kayıtlar arası bağlar (`sourceId`, `chargeSourceId`) yalnızca bu dosyanın içinde geçerli numaralardır.
- Para: her tutar, `currency` alanındaki para biriminin küçük biriminde tam sayıdır (kuruş, cent; JPY'de 1, KWD'de 1000 = 1 dinar). Kesirli sayı yoktur. Kur çevirisi yoktur.
- Takvim günü: `yyyy-MM-dd` (`2026-11-19`), saat dilimi yok.
- An (zaman damgası): UTC, ISO 8601, saniyeye kadar: `2026-11-19T07:30:05Z`.
- Seçenek değerleri adlarıyla yazılır (aşağıda her alanın alabileceği değerler); adlar dondurulmuştur (test).
- Boş değer `null` olarak yazılır. Okuyucu `null` ile eksik alanı aynı sayar.
- Okuyucu bilmediği alanları yok sayar (daha yeni bir Kalan alan eklemiş olabilir). `formatVersion` okuyucunun bildiğinden büyükse dosyayı sakin bir hatayla reddeder (`newerVersion`): önce uygulama güncellenmeli.
- Yedekte olmayanlar: Kalan Pro durumu (mağaza satın alımıdır, veri değildir), uygulama kilidi, "Tutarları gizle", tema, dil, bildirim izni sorusunun gösterilip gösterilmediği ve bildirimden seçilen "Akşam/Yarın hatırlat" ertelemeleri (geçici). Bunlar bu telefona özeldir.

## Zarf

Şifresiz dosyada içerik `data` alanındadır. Şifreli dosyada `data` yoktur; içerik `ciphertext` alanındadır.

| Alan | Tür | Açıklama |
|---|---|---|
| `format` | string | Her zaman `kalan-backup`. Değilse dosya Kalan yedeği sayılmaz (`notABackup`). |
| `formatVersion` | int | Biçim sürümü; bugün `1`. |
| `appVersion` | string | Dosyayı yazan uygulamanın sürümü (`1.0.0+1`). |
| `createdAt` | string | Dosyanın yazıldığı an (UTC). |
| `currency` | string | ISO 4217 para birimi kodu; içerikteki `settings.currency` ile aynı olmalı. |
| `encrypted` | bool | Parolayla şifreli mi. |
| `dataSha256` | string | Yalnızca şifresizde: `data` alanının sıkıştırılmış JSON metninin (anahtar sırası dosyadaki gibi, boşluksuz) SHA-256 özeti, küçük harf onaltılık. Kazara bozulmayı yakalar; bilerek yapılan düzenlemeye karşı koruma değildir (bunun için parola). Uymazsa `damaged`. |
| `data` | object | Yalnızca şifresizde: içerik (aşağıda). |
| `kdf` | object | Yalnızca şifrelide: paroladan anahtar türetme ayarları. |
| `kdf.algorithm` | string | `argon2id` (Kalan bunu yazar) ya da `pbkdf2-hmac-sha256` (okuyucu bunu da tanır; yedek yol). |
| `kdf.memoryKiB` | int | Argon2id bellek miktarı, KiB. Kalan 47104 (46 MiB) yazar. Okuyucu 8 ile 262144 (256 MiB) arasını kabul eder. |
| `kdf.iterations` | int | Tur sayısı. Kalan Argon2id'de 2 yazar. Okuyucu Argon2id'de 1-64, PBKDF2'de 1-2.000.000 kabul eder. |
| `kdf.parallelism` | int | Argon2id şerit sayısı; Kalan 1 yazar (1-16). PBKDF2'de yoktur. |
| `kdf.salt` | string | Her dosyada yeniden üretilen rastgele tuz, base64 (16 bayt). |
| `cipher` | object | Yalnızca şifrelide: şifreleme. |
| `cipher.algorithm` | string | Her zaman `AES-256-GCM`. |
| `cipher.nonce` | string | Her dosyada yeniden üretilen rastgele nonce, base64 (12 bayt). |
| `ciphertext` | string | base64: şifreli içerik (UTF-8 JSON, `data` ile aynı yapı) ve arkasında 16 baytlık GCM etiketi. |

### Şifreleme

1. Anahtar: parolanın UTF-8 baytları (olduğu gibi; kırpılmaz, Unicode normalleştirmesi yapılmaz), `kdf.salt` ile Argon2id (sürüm 0x13, 32 bayt çıktı). PBKDF2 yolunda HMAC-SHA256, 256 bit.
2. Ek doğrulanan veri (AAD): şu dizinin boşluksuz JSON metni, UTF-8: `["kalan-backup", formatVersion, appVersion, createdAt, currency, true, kdf.algorithm, (argon2id ise) kdf.memoryKiB, kdf.iterations, kdf.parallelism | (pbkdf2 ise) kdf.iterations, kdf.salt, cipher.algorithm, cipher.nonce]`. Metin değerleri (oluşturma anı, tuz ve nonce dahil) dosyada yazıldığı gibidir; aynı baytların başka bir base64 yazımı da değişiklik sayılır. Böylece başlıktaki tek bir bayt değişse de dosya açılmaz.
3. AES-256-GCM, `cipher.nonce` ile.

Yanlış parola ile değiştirilmiş dosya birbirinden ayırt edilemez: ikisi de `wrongPasswordOrChanged`. Parola hiçbir yerde saklanmaz; unutulursa dosya açılamaz.

## İçerik (`data`)

| Alan | Tür | Açıklama |
|---|---|---|
| `data.settings` | object | Ürün ayarları. |
| `data.sources` | array | Kaynaklar ve kartlar. |
| `data.sources[]` | object | Bir kaynak. |
| `data.plans` | array | Planlar, numara sırasıyla; arşivdekiler, beklemedekiler ve kapatılanlar dahil. |
| `data.plans[]` | object | Bir plan. |
| `data.recurringPayments` | array | Sabit ödemeler. |
| `data.recurringPayments[]` | object | Bir sabit ödeme. |

### Ayarlar (`data.settings`)

| Alan | Tür | Açıklama |
|---|---|---|
| `data.settings.currency` | string | ISO 4217 kodu; bütün tutarlar bu birimde. |
| `data.settings.payFrequency` | string | Maaş düzeni: `monthly`, `biweekly`, `weekly`. |
| `data.settings.payDay` | int | Aylık maaş günü (ayın günü, 1-31). |
| `data.settings.payAnchorDate` | string | Haftalık ve iki haftalıkta bilinen bir maaş günü (takvim günü). |
| `data.settings.netIncome` | int | Bir maaşın net tutarı; girilmediyse `null`. |
| `data.settings.tightThreshold` | int | Sıkışık dönem eşiği; kapalıysa `null`. |
| `data.settings.reminders` | object | Bildirim tercihleri. |
| `data.settings.reminders.enabled` | bool | Hatırlatmalar açık mı. |
| `data.settings.reminders.leadDays` | int | Genel "kaç gün önce": 1, 2, 3, 5, 7. |
| `data.settings.reminders.minuteOfDay` | int | Hatırlatma saati, gece yarısından dakika (540 = 09:00). |
| `data.settings.reminders.showAmounts` | bool | "Bildirimde tutarı göster". ("Tutarları gizle" bu değildir; o yedeğe girmez.) |
| `data.settings.reminders.repeatMode` | string | Israrlı hatırlatma: `off`, `evening`, `daily`. |
| `data.settings.reminders.paydaySummary` | bool | Maaş günü özeti açık mı. |
| `data.settings.lastPayLaterRule` | object | Son kullanılan "Sonra öde" kuralı; hiç kullanılmadıysa `null`. |
| `data.settings.lastPayLaterRule.kind` | string | `days`, `nextMonthDay`, `chosenDate`. |
| `data.settings.lastPayLaterRule.value` | int | `days`: gün sayısı; `nextMonthDay`: ayın günü; `chosenDate`: `null`. |
| `data.settings.lastAmountEntry` | string | Plan eklemede son giriş yolu: `total`, `installment`; henüz yoksa `null`. |
| `data.settings.holidayCountry` | string | Tatil ülkesi, ISO 3166-1 alfa-2; `""` "Yok"; `null` henüz önerilmedi. |
| `data.settings.appliedHolidays` | object | Kayıtlı kart tarihlerinin hesaplandığı hafta sonu ve resmî tatiller (26); "Yok" ise `null`. Geri yüklemede tarihlerin ikinci kez kaydırılmaması için. |
| `data.settings.appliedHolidays.country` | string | Ülke kodu. |
| `data.settings.appliedHolidays.weekendDays` | array | Hafta sonu günleri. |
| `data.settings.appliedHolidays.weekendDays[]` | int | ISO hafta günü: 1 pazartesi … 7 pazar. |
| `data.settings.appliedHolidays.lastYear` | int | Listenin tam olduğu son yıl. |
| `data.settings.appliedHolidays.days` | array | Resmî tatil günleri. |
| `data.settings.appliedHolidays.days[]` | string | Takvim günü. |

### Kaynak (`data.sources[]`)

| Alan | Tür | Açıklama |
|---|---|---|
| `data.sources[].id` | int | Dosya içi numara (planlar buna bağlanır). |
| `data.sources[].name` | string | Ad (1-60 karakter). |
| `data.sources[].kind` | string | `provider` (sağlayıcı), `card` (kart), `account` (banka hesabı). |
| `data.sources[].statementDay` | int | Kartın ekstre günü (ayın günü, 1-31); yoksa `null`. |
| `data.sources[].dueDay` | int | Kartın son ödeme günü (ayın günü, 1-31); yoksa `null`. |
| `data.sources[].moveDueToBusinessDay` | bool | Hafta sonuna denk gelen son ödeme günü iş gününe kayar mı. |
| `data.sources[].moveDueForHolidays` | bool | Resmî tatilde kayar mı (26). |
| `data.sources[].statementReminder` | object | Hesap kesim hatırlatması (17). |
| `data.sources[].statementReminder.enabled` | bool | Açık mı. |
| `data.sources[].statementReminder.daysBefore` | int | Kaç gün önce: 1 ya da 2. |
| `data.sources[].createdAt` | string | Eklendiği an. |

### Plan (`data.plans[]`)

| Alan | Tür | Açıklama |
|---|---|---|
| `data.plans[].id` | int | Dosya içi numara. |
| `data.plans[].sourceId` | int | Kaynağın dosya içi numarası; yalnızca kaynaksız "Sonra öde" planında `null`. |
| `data.plans[].title` | string | Plan adı; yoksa `null` (ekranda kaynak adı ya da "Sonra öde · 14 Ara"). |
| `data.plans[].kind` | string | `payIn4`, `monthly`, `card`, `manual`, `payLater`. |
| `data.plans[].installmentCount` | int | Taksit sayısı. |
| `data.plans[].purchaseDate` | string | Alışveriş günü; yoksa `null`. |
| `data.plans[].deferMonths` | int | Ertelenen ay sayısı. |
| `data.plans[].isCashAdvance` | bool | Taksitli nakit avans mı. |
| `data.plans[].origin` | string | Nasıl eklendi: `template`, `manual`. |
| `data.plans[].createdAt` | string | Kaydedildiği an (yedek hatırlatması ilk plandan sayar). |
| `data.plans[].reminders` | object | Planın hatırlatma seçimi. |
| `data.plans[].reminders.enabled` | bool | `false`: kapalı. |
| `data.plans[].reminders.leadDays` | int | Planın kendi "kaç gün önce"si; `null`: genel ayar. |
| `data.plans[].repeatMode` | string | Israrlı hatırlatma (`off`, `evening`, `daily`); `null`: genel ayar. |
| `data.plans[].payLaterRule` | object | "Sonra öde" kuralı; diğer türlerde `null`. |
| `data.plans[].payLaterRule.kind` | string | `days`, `nextMonthDay`, `chosenDate`. |
| `data.plans[].payLaterRule.value` | int | Gün sayısı ya da ayın günü; seçilen tarihte `null`. |
| `data.plans[].intervalDays` | int | Her N günde bir (1-365); `null`: her ayın aynı günü. |
| `data.plans[].paymentMethod` | string | `automatic`, `manual`; `null`: belirtilmedi. |
| `data.plans[].chargeSourceId` | int | Otomatik ödemenin çekildiği kaynağın dosya içi numarası; `null`: seçilmedi. |
| `data.plans[].status` | string | `open`, `onHold` (beklemede), `closed` (kapatıldı). Bütün ödemeleri ödenmiş açık plan arşivdedir. |
| `data.plans[].closeReason` | string | Kapatma nedeni: `refund`, `cancel`; değilse `null`. |
| `data.plans[].heldSince` | string | Beklemeye alındığı gün. |
| `data.plans[].holdCheckFrom` | string | "Hâlâ iadeyi mi bekliyorsun?" sorusunun 30 gününün başladığı gün. |
| `data.plans[].reopenedOn` | string | Yeniden açıldığı gün. |
| `data.plans[].closedOn` | string | Kapatıldığı gün. |
| `data.plans[].installmentFee` | int | Taksit başı ücret, yazıldığı gibi (22); yoksa `null`. |
| `data.plans[].installmentFeeScope` | string | `everyPayment`, `firstPaymentOnly`. |
| `data.plans[].productPrice` | int | Ürün fiyatı (23); girilmediyse `null`. |
| `data.plans[].payments` | array | Ödemeler, sıra numarasıyla. |
| `data.plans[].payments[]` | object | Bir ödeme. |
| `data.plans[].payments[].seq` | int | Plandaki sıra numarası (eski ortasından eklenen planlarda 1'den başlamayabilir). |
| `data.plans[].payments[].dueDate` | string | Geçerli son ödeme günü. |
| `data.plans[].payments[].amount` | int | Taksit tutarı (ücretler hariç). |
| `data.plans[].payments[].paidAt` | string | "Ödendi" işaretlendiği an; ödenmediyse `null`. Kalan'dan önce ödenmişte planın kaydedildiği an. |
| `data.plans[].payments[].isEdited` | bool | Tutarı elle düzeltildi mi. |
| `data.plans[].payments[].paidBeforeKalan` | bool | Plan eklenmeden önce ödenmiş ("zaten sürüyor"). |
| `data.plans[].payments[].paidOn` | string | Günü geçenler listesinde seçilen ödeme günü; yoksa `null`. |
| `data.plans[].payments[].originalDueDate` | string | "Tarihi değiştir"den önceki ilk tarih (20); yoksa `null`. |
| `data.plans[].payments[].extraFee` | int | Ek ücret (21); yoksa `null`. |
| `data.plans[].payments[].extraFeeNote` | string | Ek ücret notu (en çok 80 karakter); yoksa `null`. |
| `data.plans[].payments[].installmentFee` | int | Bu ödemenin aldığı taksit başı ücret (22); yoksa `null`. |

### Sabit ödeme (`data.recurringPayments[]`)

| Alan | Tür | Açıklama |
|---|---|---|
| `data.recurringPayments[].id` | int | Dosya içi numara. |
| `data.recurringPayments[].name` | string | Ad. |
| `data.recurringPayments[].amount` | int | Bugünkü tutar. Geçmiş tekrarlar kendi tutarını saklamaz. |
| `data.recurringPayments[].recurrence` | string | `weekly`, `biweekly`, `monthly`, `yearly`. |
| `data.recurringPayments[].startDate` | string | Başlangıç günü. |
| `data.recurringPayments[].endDate` | string | Bitiş günü; yoksa `null`. |
| `data.recurringPayments[].createdAt` | string | Eklendiği an. |
| `data.recurringPayments[].reminders` | object | Hatırlatma seçimi (plandaki gibi). |
| `data.recurringPayments[].reminders.enabled` | bool | `false`: kapalı. |
| `data.recurringPayments[].reminders.leadDays` | int | Kendi "kaç gün önce"si; `null`: genel ayar. |
| `data.recurringPayments[].repeatMode` | string | Israrlı hatırlatma; `null`: genel ayar. |
| `data.recurringPayments[].paidOccurrences` | array | "Ödendi" işaretli tekrarlar, güne göre. |
| `data.recurringPayments[].paidOccurrences[]` | object | Bir tekrar. |
| `data.recurringPayments[].paidOccurrences[].date` | string | Tekrarın günü. |
| `data.recurringPayments[].paidOccurrences[].paidAt` | string | İşaretlendiği an. |

## Anlamsal doğrulama

Türler doğru olsa da şu durumlarda dosya `damaged` sayılır (`BackupData.validate`): bilinmeyen para birimi; ayın günü 1-31 dışında (maaş, ekstre, son ödeme); hatırlatma dakikası 0-1439 dışında; "kaç gün önce" 1, 2, 3, 5, 7 dışında; hesap kesim "kaç gün önce" 1 ya da 2 dışında; eksi gelir ya da eşik; 1'den küçük tutar, ek ücret, taksit başı ücret ya da ürün fiyatı; 1'den küçük taksit sayısı; eksi ertelenen ay; 1-365 dışında aralık; kaynak ya da sabit ödeme adı 1-60 karakter dışında, plan adı ya da ek ücret notu 80 karakterden uzun; tatil ülkesi 2 karakterden uzun; aynı numaralı iki kaynak, plan ya da sabit ödeme; bir planda aynı sıra numaralı iki ödeme; bir sabit ödemede aynı günlü iki tekrar; olmayan bir kaynağa bağlanan `sourceId` ya da `chargeSourceId`.

## Okuma hataları

| Hata | Ne zaman |
|---|---|
| `notABackup` | JSON değil ya da `format` `kalan-backup` değil. |
| `newerVersion` | `formatVersion` okuyucununkinden büyük. |
| `passwordNeeded` | Şifreli ve parola verilmedi. |
| `wrongPasswordOrChanged` | Şifreli; parola yanlış ya da dosyada bir bayt değişmiş. |
| `damaged` | Eksik ya da yanlış türde alan, bilinmeyen seçenek değeri, geçersiz gün, sınır dışı şifreleme ayarı, bozuk base64, uymayan özet ya da para birimi, anlamsal doğrulamadan geçemeyen değer. |

## Sürüm değişikliği

Alan eklemek sürüm gerektirmez (eski okuyucu yok sayar). Bir alanın anlamını, adını ya da türünü değiştirmek, bir seçenek değerini yeniden adlandırmak ya da zorunlu alan eklemek `formatVersion`'ı artırır; okuyucu eski sürümleri okumaya devam eder.
