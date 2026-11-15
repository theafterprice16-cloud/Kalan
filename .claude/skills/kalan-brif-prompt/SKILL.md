---
name: kalan-brif-prompt
description: Kalan yol haritasındaki bir özellik brifini, başka bir oturuma verilecek uygulama prompt'una çevirir. Yalnızca kullanıcı açıkça "şu maddenin prompt'unu yaz" dediğinde kullan. Bir maddenin uygulanması istendiğinde ("N. maddeyi yap") bu skill değil kalan-gelistirme kullanılır.
---

# Kalan: briften Claude Code prompt'una

Yol haritasındaki 1–47. maddelerin her birinin altında "Prompt mühendisine brif" vardır. Bu skill o brifi, "0. Temel" prompt'uyla aynı yapıda, Claude Code'un baştan sona tek başına yürütebileceği bir uygulama prompt'una çevirir.


**Kapsam:** Bu skill yalnızca prompt metni üretir; kod yazmaz, dosya değiştirmez. Claude Code'da bir maddenin uygulanması istendiğinde bu skill kullanılmaz, `kalan-gelistirme` kullanılır.

## 1. Önce açık soruları kapat

Brifin sonunda "Açık sorular" bölümü vardır. Prompt'u yazmadan önce:

- Her açık soruyu, brifteki seçenekleriyle birlikte ürün sahibine sor. Cevabı kendin seçme. Ürün sahibi kararlarında ya da `docs/DECISIONS.md`'de cevabı olan soruyu sorma; kararı prompt'a yaz.
- "Bu madde gereksiz olabilir" sorusuyla başlayan briflerde (39, 42, 44, 46, 47) önce bunu sor; cevap "yapma" ise prompt yazma.
- 43. madde (ekran görüntüsünden plan ekleme): okuma yönteminin kararı verildi: cihazda, işletim sisteminin kendi metin tanımasıyla (Karar 3). Bulut, sunucu, API anahtarı ya da ağ isteği içeren prompt yazma; okuma yöntemini sorma.
- Cevaplar gelince prompt'a karar olarak yaz; prompt'un içinde açık soru bırakma.
- "Bağımlılıklar" satırındaki maddeler yapılmamışsa bunu söyle ve sırayı sor.

## 2. Prompt'un yapısı

Bölümleri bu sırayla ve bu etiketlerle yaz. Dil Türkçe.

```
<rol>
Kıdemli bir Flutter geliştiricisisin. [Maddenin gerektirdiği uzmanlık: yerel bildirimler, widget'lar, satın alma, yerelleştirme …]. Kalan uygulamasının reposunda çalışıyorsun. İşini küçük, test edilmiş adımlarla yapar, mevcut davranışı bozmazsın.
</rol>

<calisma_bicimi>
- Bu görevi baştan sona tek başına yürüt. Adımlar arasında onay isteme; bir adım bitince sonrakine geç.
- Belirsiz bir nokta çıkarsa en mantıklı ve en az riskli seçimi yap, devam et ve seçimini bitiş raporuna "Kararlar" başlığıyla yaz.
- Önce oku, sonra değiştir: hiçbir dosyayı içeriğini görmeden düzenleme.
- Her adımın sonunda `flutter analyze` ve ilgili testleri çalıştır; kırmızı test bırakıp sonraki adıma geçme.
- Küçük ve anlamlı commit'ler at.
- Bitince `docs/DECISIONS.md` ve `docs/ILERLEME.md` dosyalarını güncelle, commit'le ve çalıştığın dalı push'la. PR'ı CLAUDE.md'deki kurala göre aç ve birleştir; <cikti_formati> raporunu PR açıklamasına yaz.
- Kapsam dışı bir sorun görürsen düzeltme; rapora "Kapsam dışı gözlemler" olarak yaz.
</calisma_bicimi>

<baglam>
[Kalan'ın bir paragraflık tanımı + bu maddenin amacı ve brifteki kullanıcı senaryosu + uygulamanın bugünkü durumu: diller, para birimleri, bu maddenin dayandığı önceki maddeler.]
</baglam>

<degismez_kurallar>
- Banka bağlantısı, hesap açma ve bulut eşitleme yok. Tüm veri cihazda kalır.
- Reklam, izleme ve analiz paketi yok. Yeni bir ağ isteği ekleme.
- Ton sakin: kullanıcıyı korkutan, yargılayan ya da puanlayan metin ve renk yok.
- Tek para birimi seçilir; kur çevirisi yapılmaz.
- Uygulama sade kalır; bütçe uygulaması değildir.
- Ücretsiz sürümde en fazla 4 açık plan; Pro ile sınırsız. Bu sınıra dokunma.
- Pro tek seferlik satın almadır; abonelik yok.
- Tüm geliştirmeler Mürekkep ve Safran paletine uyar; yalnızca tema tokenları kullanılır.
</degismez_kurallar>

<kapsam>
[Brifteki "Kapsam" maddeleri + kapatılan açık soruların kararları. Her madde doğrulanabilir bir davranış olsun.]
</kapsam>

<tasarim>
[Brifteki "Tasarım" satırı: hangi yüzeyde hangi token. Yeni renk yok.]
</tasarim>

<adimlar>
Adım 1 - Repoyu incele (hiçbir şeyi değiştirmeden): CLAUDE.md, docs/DECISIONS.md, docs/DESIGN_TOKENS.md, ilgili mevcut kod, veritabanı şeması ve migration'lar, mevcut testler ve CI.
Adım 2..n - [İşi küçük, sıralı adımlara böl: veri modeli → hesap/mantık → arayüz → metinler (TR ve EN ARB) → testler → belgeler.]
Son adım - docs/DECISIONS.md ve docs/ILERLEME.md güncelle, commit'le, push'la, CLAUDE.md'deki kurala göre PR aç ve birleştir.
</adimlar>

<ornekler>
[Brifteki senaryodan 2-4 somut girdi → beklenen çıktı. Ekran metni örnekleri sakin tonda.]
</ornekler>

<testler>
[Numaralı liste: birim, widget ve gerekiyorsa golden testler (açık ve koyu tema). "Hesap motoru testleri değişmeden geçiyor" satırı her zaman olur.]
</testler>

<yapilmayacaklar>
[Brifteki "Kapsam dışı" maddeleri, hangi maddeye ait olduklarıyla. Ayrıca: yeni dil ekleme (TR ve EN dışındaki ARB'lere dokunma), yeni paket ekleme (gerekiyorsa adını ve nedenini açıkça yaz), ağ isteği, Ücretsiz/Pro sınırını değiştirme.]
</yapilmayacaklar>

<kabul_olcutleri>
[Kapsamdaki her madde için gözle ya da testle doğrulanabilir bir ölçüt. flutter analyze temiz, testler ve CI yeşil, docs/DECISIONS.md güncel.]
</kabul_olcutleri>

<cikti_formati>
Bitiş raporu Türkçe ve şu başlıklarla: 1. Özet 2. Değişen dosyalar 3. Migration (varsa) 4. Testler ve CI durumu 5. Görüntüler (açık, koyu) 6. Kararlar 7. Kapsam dışı gözlemler 8. Ürün sahibinin elle kontrol etmesi gerekenler
</cikti_formati>
```

## 3. Brif alanı → prompt bölümü

| Brifteki alan | Prompt'ta gittiği yer |
|---|---|
| Amaç, Kullanıcı senaryosu | baglam, ornekler |
| Kapsam | kapsam, kabul_olcutleri |
| Kapsam dışı | yapilmayacaklar |
| Araştırma bulguları | baglam içinde yalnızca davranışı belirleyen bulgu (bir-iki cümle); rakip ve kaynak listesi prompt'a girmez |
| Kaynaklar | prompt'a girmez |
| Pazar farkları | kapsam ya da yapilmayacaklar; metinlerin çeviriye uygun yazılması notu |
| Kalan kurallarıyla ilişkisi | degismez_kurallar'a ek satır |
| Tasarım | tasarim |
| Ücretsiz/Pro | kapsam (Pro ise kilit davranışı ve Pro ekranına yönlendirme) |
| Bağımlılıklar | baglam ("şu maddeler yapıldı, şunlara dayanır") |
| Açık sorular | prompt'a girmez; kararları kapsam'a yazılır |

## 4. Yazım kuralları

- Paket adı uydurma. Repoda hangi paketin kullanıldığını bilmiyorsan "repodaki mevcut karşılığını kullan" de ve Adım 1'de buldurt.
- Dosya yolu veriyorsan "ya da repodaki mevcut karşılığı" diye ekle.
- Her kural bir nedenle birlikte yazılır; büyük harfle bağırma.
- Ücret, oran, yasal sınır gibi ülkeye göre değişen değerleri koda gömdürme.
- Ekran ve bildirim metni örnekleri sakin tonda: ünlem, emoji, "Son gün!" yok.
- Prompt tek başına okunabilir olmalı: başka sohbete, brife ya da bu skill'e gönderme yapma.

## 5. Teslim

Prompt'u tek bir kod bloğunda ver. Altına üç satır ekle: kapatılan açık sorular ve kararları; varsayım yaptığın yerler; ürün sahibinin elle bakması gerekenler.
