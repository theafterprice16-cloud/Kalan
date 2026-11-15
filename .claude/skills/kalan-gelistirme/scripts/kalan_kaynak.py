#!/usr/bin/env python3
"""Kalan birleşik kaynak dosyasından yalnızca gereken parçayı düz metin olarak çıkarır.

800 KB'lık HTML'i bütünüyle okumak yerine tek bir maddeyi ya da bölümü (1-3 bin token) verir.

Kullanım:
  python3 kalan_kaynak.py ozellik 12            # 12. maddenin brifi + ilgili ürün sahibi kararları
  python3 kalan_kaynak.py ozellik 12 --tam      # araştırma bulguları ve kaynak linkleri dahil
  python3 kalan_kaynak.py kararlar              # geçerli kararların kısa listesi
  python3 kalan_kaynak.py bolum palet           # yol haritası bölümü: ozet palet palet-prompt para ulkeler elenen arastirma kararlar
  python3 kalan_kaynak.py bolum metinler --belge fiyat   # fiyat bölümü: ozet pro rakipler pazar kurallar modeller maliyet fiyatlar alternatifler lansman metinler riskler varsayimlar
  python3 kalan_kaynak.py liste                 # 48 maddenin numara, ad, emek, ücret listesi
  --dosya YOL   birleşik HTML'in yolu (verilmezse repo içinde aranır)
Yalnızca Python standart kütüphanesi kullanır.
"""
import html
import json
import os
import re
import sys
from html.parser import HTMLParser

BELGE_ID = {"yol": "kb-kaynak-yol-haritasi", "fiyat": "kb-kaynak-fiyat", "uygulama": "kb-kaynak-uygulama"}
ATLA = {".git", "build", ".dart_tool", "node_modules", "Pods", ".gradle", ".idea", "ios", "android", "macos", "linux", "windows", "web"}


def hata(mesaj):
    sys.stderr.write("HATA: " + mesaj + "\n")
    sys.exit(2)


def repo_koku(yol):
    """Yukarı doğru çıkıp .git ya da pubspec.yaml bulunan ilk klasörü döndürür."""
    yol = os.path.abspath(yol)
    aday = None
    while True:
        if os.path.isdir(os.path.join(yol, ".git")):
            return yol
        if aday is None and os.path.isfile(os.path.join(yol, "pubspec.yaml")):
            aday = yol
        ust = os.path.dirname(yol)
        if ust == yol:
            return aday or os.getcwd()
        yol = ust


def dosya_bul(baslangic):
    """Repo içinde birleşik kaynak dosyasını arar (önce adına, sonra içeriğine bakar)."""
    adaylar = []
    for kok, klasorler, dosyalar in os.walk(baslangic):
        klasorler[:] = [k for k in klasorler if k == ".claude" or (k not in ATLA and not k.startswith("."))]
        for d in dosyalar:
            if d.lower().endswith(".html"):
                adaylar.append(os.path.join(kok, d))
    adaylar.sort(key=lambda p: (0 if "birlesik" in os.path.basename(p).lower() else 1, len(p)))
    for yol in adaylar:
        try:
            if os.path.getsize(yol) < 100_000:
                continue
            with open(yol, encoding="utf-8", errors="ignore") as f:
                bas = f.read(20_000)
            if 'id="kb-kararlar-json"' in bas or "Kalan – Birleşik Kaynak" in bas:
                return yol
        except OSError:
            continue
    return None


def blok(kaynak, kimlik):
    m = re.search(r'<script[^>]*id="%s"[^>]*>(.*?)</script>' % re.escape(kimlik), kaynak, re.S)
    if not m:
        hata("'%s' bloğu bulunamadı; dosya birleşik kaynak dosyası mı?" % kimlik)
    return m.group(1).replace("<\\/script", "</script")


class Metin(HTMLParser):
    """HTML'i okunur düz metne çevirir; style/script/button içeriğini atar."""
    BLOK = {"p", "div", "li", "h1", "h2", "h3", "h4", "h5", "tr", "br", "section", "article",
            "pre", "table", "dt", "dd", "summary", "details", "blockquote", "header", "ul", "ol"}

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.parca, self.atla, self.pre, self.hucre, self.dugme = [], 0, 0, 0, []

    def handle_starttag(self, t, a):
        if t == "button":
            # Sıralama düğmeleri tablo başlığını taşır; kopyala/genişlet düğmeleri atılır.
            sinif = dict(a).get("class") or ""
            atla = "sort" not in sinif
            self.dugme.append(atla)
            if atla:
                self.atla += 1
            return
        if t in ("style", "script", "svg", "nav"):
            self.atla += 1
            return
        if t == "pre":
            self.pre += 1
        if t in ("td", "th"):
            self.hucre += 1
        if t == "br" and self.hucre:
            self.parca.append(" · ")
            return
        if t in self.BLOK:
            self.parca.append("\n")
        if t in ("h2", "h3", "h4"):
            self.parca.append("#" * int(t[1]) + " ")
        if t == "li":
            self.parca.append("- ")
        if t in ("td", "th"):
            self.parca.append(" | ")
        if t == "dt":
            self.parca.append("\n")

    def handle_endtag(self, t):
        if t == "button":
            if self.dugme and self.dugme.pop():
                self.atla = max(0, self.atla - 1)
            return
        if t in ("td", "th"):
            self.hucre = max(0, self.hucre - 1)
        if t in ("style", "script", "svg", "nav"):
            self.atla = max(0, self.atla - 1)
        if t == "pre":
            self.pre = max(0, self.pre - 1)
        if t == "dt":
            self.parca.append(": ")

    def handle_data(self, d):
        if not self.atla:
            self.parca.append(d if self.pre else re.sub(r"\s+", " ", d))

    def sonuc(self):
        txt = "".join(self.parca)
        txt = re.sub(r"[ \t]+\n", "\n", txt)
        return re.sub(r"\n{3,}", "\n\n", txt).strip()


def metne(parca_html):
    p = Metin()
    p.feed(parca_html)
    return p.sonuc()


def kararlar_yukle(kaynak):
    try:
        return json.loads(blok(kaynak, "kb-kararlar-json"))
    except json.JSONDecodeError as e:
        hata("kararlar JSON'u okunamadı: %s" % e)


def metinde_anilan_maddeler(metin):
    """'Yol Haritası 19' ya da 'Yol Haritası 29–30' gibi anmalardaki madde numaralarını döndürür."""
    nolar = set()
    for a, b in re.findall(r"Yol Haritası (\d+)(?:\s*[–-]\s*(\d+))?", metin or ""):
        bas, son = int(a), int(b or a)
        nolar.update(range(bas, son + 1))
    return nolar


def ilgili_kararlar(kararlar, belge_kimligi, bolum_id):
    satirlar = []
    madde = int(bolum_id.split("-")[1]) if bolum_id.startswith("ozellik-") else None
    for k in kararlar.get("kararlar", []):
        gecerli = any(y.get("dosya") == belge_kimligi and y.get("id") == bolum_id for y in k.get("gecerli_yerler", []))
        if madde is not None and belge_kimligi == "yol-haritasi":
            gecerli = gecerli or madde in metinde_anilan_maddeler(k.get("gecerli_karar", "") + " " + k.get("not", ""))
        eski = [y for y in k.get("eski_sayilan", []) if y.get("dosya") == belge_kimligi and y.get("id") == bolum_id]
        if gecerli or eski:
            satir = "- KARAR %s (%s): %s" % (k["no"], k["konu"], k["gecerli_karar"])
            for y in eski:
                satir += "\n  ESKİ SAYILAN (uygulama): %s" % y["yer"]
            if k.get("not"):
                satir += "\n  NOT: %s" % k["not"]
            satirlar.append(satir)
    return satirlar


def ozellik(kaynak, no, tam):
    yol = blok(kaynak, BELGE_ID["yol"])
    m = re.search(r'<article class="feat" id="ozellik-%d"(.*?)</article>' % no, yol, re.S)
    if not m:
        hata("%d. madde bulunamadı (0-47 arası olmalı)" % no)
    art = m.group(0)
    bas = re.search(r'data-tag="([^"]*)" data-emek="([^"]*)" data-ucret="([^"]*)"', art)
    baslik = re.search(r"<h3>.*?</a>\s*(.*?)</h3>", art, re.S)
    ad = html.unescape(re.sub(r"<[^>]+>", "", baslik.group(1))).strip() if baslik else ""
    cikti = ["# %d. %s" % (no, ad)]
    if bas:
        cikti.append("Etiket: %s · Emek: %s · Ücret: %s" % bas.groups())
    pre = re.search(r'<pre id="(?:brif-%d|prompt-temel)"[^>]*>(.*?)</pre>' % no, art, re.S)
    if pre:
        govde = html.unescape(re.sub(r"<[^>]+>", "", pre.group(1)))
    else:
        govde = metne(art)
    if not tam:
        tut, atla = [], False
        for satir in govde.splitlines():
            if satir.startswith(("Araştırma bulguları:", "Kaynaklar:")):
                atla = True
                continue
            if atla and (satir.startswith("- ") and "http" in satir):
                continue
            atla = False
            tut.append(satir)
        govde = "\n".join(tut)
        govde += "\n\n(Araştırma bulguları ve kaynak linkleri atlandı; gerekirse --tam ekle.)"
    cikti.append(govde.strip())
    kr = ilgili_kararlar(kararlar_yukle(kaynak), "yol-haritasi", "ozellik-%d" % no)
    if kr:
        cikti.append("\n## Bu maddeyle ilgili ürün sahibi kararları (brifteki açık sorulardan ÖNCE gelir)")
        cikti.extend(kr)
    return "\n".join(cikti)


def liste(kaynak):
    yol = blok(kaynak, BELGE_ID["yol"])
    satirlar = []
    for m in re.finditer(r'<article class="feat" id="ozellik-(\d+)" data-n="\d+" data-tag="([^"]*)" data-emek="([^"]*)" data-ucret="([^"]*)".*?<h3>.*?</a>\s*(.*?)</h3>', yol, re.S):
        ad = html.unescape(re.sub(r"<[^>]+>", "", m.group(5))).strip()
        satirlar.append("%2s. %s  [%s · Emek: %s · %s]" % (m.group(1), ad, m.group(2), m.group(3), m.group(4)))
    return "\n".join(satirlar)


def bolum(kaynak, kimlik, belge):
    if belge not in BELGE_ID:
        hata("--belge yol | fiyat | uygulama olmalı")
    govde = blok(kaynak, BELGE_ID[belge])
    m = re.search(r'<section[^>]*\bid="%s"[^>]*>(.*?)</section>' % re.escape(kimlik), govde, re.S)
    if not m:
        ids = re.findall(r'<section[^>]*\bid="([^"]+)"', govde)
        hata("'%s' bölümü yok. Bu belgedeki bölümler: %s" % (kimlik, ", ".join(ids)))
    cikti = [metne(m.group(1))]
    kr = ilgili_kararlar(kararlar_yukle(kaynak), {"yol": "yol-haritasi"}.get(belge, belge), kimlik)
    if kr:
        cikti.append("\n## Bu bölümle ilgili ürün sahibi kararları")
        cikti.extend(kr)
    return "\n".join(cikti)


def kararlar_ozet(kaynak):
    k = kararlar_yukle(kaynak)
    cikti = ["# Öncelik kuralı"] + k.get("oncelik_kurali", []) + ["", "# Geçerli kararlar"]
    for x in k.get("kararlar", []):
        cikti.append("%s. %s: %s" % (x["no"], x["konu"], x["gecerli_karar"]))
        if x.get("not"):
            cikti.append("   Not: " + x["not"])
    cikti.append("\n# Küçük farklar (esas alınan)")
    for x in k.get("kucuk_farklar", []):
        cikti.append("- %s: %s" % (x["konu"], x["esas"]))
    return "\n".join(cikti)


def main(arg):
    dosya, tam, belge, kalan = None, False, "yol", []
    i = 0
    while i < len(arg):
        if arg[i] == "--dosya" and i + 1 < len(arg):
            dosya = arg[i + 1]; i += 2; continue
        if arg[i] == "--belge" and i + 1 < len(arg):
            belge = arg[i + 1]; i += 2; continue
        if arg[i] == "--tam":
            tam = True; i += 1; continue
        kalan.append(arg[i]); i += 1
    if not kalan:
        print(__doc__); return
    if not dosya:
        dosya = os.environ.get("KALAN_KAYNAK") or dosya_bul(os.environ.get("CLAUDE_PROJECT_DIR") or repo_koku(os.getcwd()))
    if not dosya or not os.path.isfile(dosya):
        hata("Birleşik kaynak dosyası bulunamadı. Repo içine koy (ör. docs/kalan-birlesik.html) ya da --dosya YOL ver.")
    with open(dosya, encoding="utf-8") as f:
        kaynak = f.read()
    komut = kalan[0]
    if komut == "ozellik" and len(kalan) > 1 and kalan[1].isdigit():
        print(ozellik(kaynak, int(kalan[1]), tam))
    elif komut == "kararlar":
        print(kararlar_ozet(kaynak))
    elif komut == "bolum" and len(kalan) > 1:
        print(bolum(kaynak, kalan[1], belge))
    elif komut == "liste":
        print(liste(kaynak))
    else:
        print(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
