---
name: flutter-cross-ui
description: Kalan'da yeni ya da değişen her ekran, widget, geçiş, diyalog, anahtar, menü ve animasyon işinde iOS (Apple HIG) ve Android (Material 3) davranışlarını Kalan'ın marka kurallarıyla birleştirir. kalan-palet ile birlikte okunur.
---

# Kalan: iOS + Android arayüz kuralları

Kalan'da önce marka gelir: iki telefonda da aynı Kalan görünür (Mürekkep ve Safran, düz yüzeyler, sakin ton). Platforma uyan şey **görünüm değil davranıştır**: geçişler, geri jesti, açılır pencere, anahtar, kaydırma ve titreşim her telefonun kendi alışkanlığında çalışır. Bu ürün sahibi kararıdır (18 Kasım 2026, `docs/DECISIONS.md`).

Renk tokenları ve renk yasakları `kalan-palet`'tedir; burada tekrar edilmez. Bu skill ile `kalan-palet` ya da `docs/DECISIONS.md` çelişirse onlar geçerlidir.

## 1. Marka katmanı

1. Import her zaman `package:material_ui/material_ui.dart` (`package:flutter/material.dart` kullanılmaz; DECISIONS "Teknik").
2. Renk, köşe, yazı ve bileşen biçimi yalnızca `KalanTheme` (`lib/core/theme/kalan_theme.dart`) ve `context.colors.<token>` üzerinden gelir. Ekranda `Color(...)`, `Colors.x` (transparent hariç), sayıyla `BorderRadius.circular(n)`, `TextStyle(fontSize: n)` yazılmaz.
3. Köşeler: kart 12, açılır pencere ve alt sayfa 16, giriş kutusu 8, düğme ve gösterge hap (stadium). Yeni bileşen bu dört değerden birini alır; değer temada ya da `lib/core/theme` altındaki sabitlerde durur.
4. Boşluk 4'ün katıdır: 4, 8, 12, 16, 24, 32. Sabitler `lib/core/theme` altında tek dosyada tutulur; ekranda çıplak sayı yazılmaz.
5. Yüzey dili düzdür: derinlik bg → surface → surfaceRaised sırası ve ince `border` ile verilir. `elevation` her zaman 0, `scrolledUnderElevation` 0, gölge yok.
6. **Cam yok.** Liquid Glass'ın buzlu camı, `BackdropFilter`, bulanıklık ve saydam katman kullanılmaz; yüzen gezinme ya da kontrol katmanı da düz `surface` + `border`'dır. (Ürün sahibi kararı; `kalan-palet` "cam efekti" yasağı.)
7. Yazı tipi telefonun kendi yazı tipidir (iOS SF, Android Roboto); özel font eklenmez. Hiyerarşi yalnızca `textTheme` rolleriyle:

| Yer | Rol |
|---|---|
| Büyük kalan sayısı | `displayMedium` / `displayLarge` + `AmountText` |
| Ekran başlığı | `titleLarge` |
| Kart ve satır başlığı | `titleMedium` |
| Gövde metni | `bodyLarge` / `bodyMedium` |
| Tarih, not, ikincil | `bodySmall` + `textMuted` |
| Düğme yazısı | `labelLarge` (tema verir) |

8. Tutarlar her zaman `AmountText` ya da `tabular` rakamlarla yazılır, böylece sayılar alt alta hizalanır. Biçim yalnızca `ref.money`.
9. Finansal netlik: ekranda tek ana sayı olur; ikincil bilgi daha küçük ve `textMuted` renktedir. Süs ikonu, ünlem, emoji, rozet kullanılmaz.

## 2. iOS katmanı (Apple HIG)

1. Sayfa geçişi sağdan kayar ve kenardan sağa kaydırarak geri gidilir. Bu davranış tek yerde, temanın `pageTransitionsTheme`'inde iOS için `CupertinoPageTransitionsBuilder` ile kurulur; ekranlarda elle `CupertinoPageRoute` ya da özel `PageRouteBuilder` yazılmaz (go_router sayfaları temayı izler).
2. Geri jestini bozan şey yapılmaz: tam ekran `GestureDetector` ile yatay sürükleme, `PopScope(canPop: false)` yalnızca kaydedilmemiş değişiklik varken.
3. Açılır pencere `showAdaptiveDialog` + `AlertDialog.adaptive`; iPhone'da Apple biçimi çıkar. Eylem düğmeleri `lib/core/design`'daki tek yardımcıdan gelir (iOS'ta `CupertinoDialogAction`, Android'de `TextButton`). Geri alınamaz eylemde düğme kelimesi açıktır ("Sil") ve `late` rengi kullanılır.
4. Alt sayfa (bottom sheet) iki platformda da aynı Kalan alt sayfasıdır; tutamak gösterilir, aşağı kaydırarak kapanır.
5. Kaydırma sekmesi (bounce) Flutter'ın platform davranışıdır; `physics` elle değiştirilmez.
6. Hareket yay (spring) hissindedir ama **sıçramaz**: sakin ton için aşma (overshoot) yok. Süreler 150–300 ms; `MediaQuery.disableAnimationsOf(context)` açıksa animasyon kısaltılır ya da kapatılır.
7. Dokunma alanı Apple'da en az 44x44 pt'dir; Kalan iki platformda da daha büyük olanı, 48x48'i uygular.

## 3. Android katmanı (Material 3)

1. `ColorScheme` tokenlardan türetilir (`kalan-palet` eşlemesi); `fromSeed` ve dinamik renk yok.
2. Alt gezinme `NavigationBar`'dır: hap gösterge `surfaceRaised` + `border`, seçili ikon `text`, seçili olmayan `textMuted`, etiketler her zaman görünür. Gösterge `accent` olmaz (accent yalnızca "kalan").
3. Sayfa geçişi Android için temada `PredictiveBackPageTransitionsBuilder` (öngörülü geri); manifest ayarı gerekiyorsa ayrı karar olarak rapora yazılır.
4. Yüzey katmanları Material 3'ün tonal yükseltmesiyle değil Kalan'ın üç yüzey tokenıyla ayrılır (`surfaceTint` kapalı).
5. Material 3 Expressive'den yalnızca "standard" hareket alınır: yumuşak yay, kısa süre, sıçrama yok. Şekil değiştiren düğme, büyük renk blokları ve "expressive" sıçrayan yay kullanılmaz.
6. Dokunma hedefi en az 48x48 dp; temadaki düğmelerin `minimumSize` değerleri korunur.

## 4. Ortak kurallar

1. `Platform.isIOS` ya da `defaultTargetPlatform` dallanması ekranlarda yazılmaz. Önce `.adaptive` bileşen (`Switch.adaptive`, `Checkbox.adaptive`, `Radio.adaptive`, `Slider.adaptive`, `CircularProgressIndicator.adaptive`, `AlertDialog.adaptive`, `showAdaptiveDialog`); yetmezse platform farkı `lib/core/design` içinde tek yardımcıda toplanır.
2. Adaptif bileşen iPhone'da Cupertino rengi (ör. yeşil anahtar) getirebilir. Renk tokenlardan gelmiyorsa renkler yardımcıda tokenla verilir; iOS golden görüntüsünde yeşil görülmemelidir.
3. Titreşim yalnızca `lib/core/design`'daki tek yardımcıdan: seçim değişince `HapticFeedback.selectionClick`, "ödendi" ve kayıt başarılı olunca `HapticFeedback.lightImpact`. Hata, uyarı ve her dokunuşta titreşim yok.
4. TR/EN metin taşması: Türkçe metin İngilizceden ~%30 uzun olabilir. Düğme ve etiket metni kesilmez, satır kaydırır; yalnızca kullanıcı adları (plan, kaynak) `maxLines` + `ellipsis` alır. Sabit genişlikli metin kutusu yok. Değişen ekran `textScaler` 2.0 ile taşmadan açılır.
5. Büyük harf çevirisi dile göre yapılır: Türkçede `i` → `İ`. Kullanıcı metninde düz `toUpperCase()` yerine yerel ayarlı dönüştürme kullanılır.
6. Her durum renkle birlikte kelime ya da ikonla anlatılır; ikon düğmelerinin `tooltip`/`semanticLabel` metni ARB'dedir.
7. Golden: değişen her ekran açık ve koyu temada; adaptif bileşen içeren ekranlar ek olarak iOS platformunda (`debugDefaultTargetPlatformOverride = TargetPlatform.iOS`).

## Örnek

```dart
// Yanlış: platform dallanması, sabit renk ve boyut, cam
if (Platform.isIOS) showCupertinoDialog(...);
Container(color: Colors.white.withOpacity(.6), padding: const EdgeInsets.all(15),
  child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), ...));

// Doğru: adaptif diyalog, token, 4'ün katı boşluk, düz yüzey
final ok = await showAdaptiveDialog<bool>(
  context: context,
  builder: (_) => AlertDialog.adaptive(
    title: Text(l10n.deletePlanTitle),
    actions: [adaptiveAction(context, l10n.cancel), adaptiveAction(context, l10n.delete, destructive: true)],
  ),
);
DecoratedBox(decoration: BoxDecoration(color: context.colors.surface, border: Border.all(color: context.colors.border)));
```

(`adaptiveAction` adı örnektir; repodaki karşılığı kullanılır.)

## Teslimden önce 5 madde

1. Ekranda sabit renk, sayıyla köşe/yazı boyutu, 4'ün katı olmayan boşluk, gölge, saydamlık ya da cam var mı? Olmamalı.
2. `accent` yalnızca kalan sayısı, birincil düğme ya da grafikte kalan mı? `late` yalnızca gecikme, hata, silme mi?
3. Diyalog, anahtar, onay kutusu adaptif mi; ekranda `Platform.isIOS` kaldı mı; iOS golden'da yeşil ya da mavi Apple rengi var mı?
4. Sağa kaydırarak geri gitme ve Android geri tuşu çalışıyor mu; her dokunma hedefi en az 48x48 mi?
5. Türkçe metin ve `textScaler` 2.0 ile taşma var mı; açık ve koyu golden temiz mi?
