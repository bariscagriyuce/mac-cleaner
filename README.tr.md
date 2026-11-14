# YUCE Cleaner

[English](README.md) · **Türkçe** · [Português (Brasil)](README.pt-BR.md)

**Mac için YUCE Cleaner**; depolama ayarlarındaki gizemli **“Sistem Verileri”**nin içinde ne olduğunu gösteren ve disk alanını güvenle geri kazanmanıza yardım eden yerel bir macOS uygulamasıdır.

## Özellikler

- **Disk özeti:** Kullanılan ve boş alanı, her kategorinin ne kadar yer kapladığını gösterir.
- **Hızlı Temizlik:** Tek bir butonla yalnızca güvenli ve yeniden oluşturulabilen verileri siler: uygulama önbellekleri, günlükler, geliştirici araç önbellekleri, Xcode DerivedData / DeviceSupport, kullanılamayan simülatörler ve Çöp Kutusu. Kişisel verilere, uygulama ayarlarına ve Xcode arşivlerine hiç dokunmaz; açık uygulamaların önbelleklerini atlar.
- **13 kategori.** Her biri *Güvenle silinebilir*, *Gözden geçirerek silin* veya *Yalnızca bilgi* olarak işaretli:
  Uygulama önbellekleri · Günlükler ve çökme raporları · Xcode verileri · iOS simülatörleri · Geliştirici araç önbellekleri (npm, pip, uv, Gradle, Cargo, Maven, Go…) · Sanal makineler, Android ve Docker · iPhone/iPad yedekleri · Uygulama destek verileri · Mail ve Mesaj ekleri · İndirilenler · Çöp Kutusu · Time Machine yerel anlık görüntüleri · Sistem geçici dosyaları
- Her kategoride **Tümünü Seç / Seçili Olanları Sil** butonları. Sağ tıklayıp *Finder'da Göster* de diyebilirsiniz.
- **Klasör Gezgini:** Herhangi bir klasörü boyuta göre sıralar. Çift tıklayarak içine girip diski neyin doldurduğunu bulabilirsiniz.
- **Varsayılan olarak güvenli:** *Kalıcı Olarak Sil* seçmediğiniz sürece dosyalar Çöp Kutusuna taşınır, yani geri alınabilir. Ev klasörü, Belgeler, Masaüstü, `~/Library` ve `/System` gibi kritik klasörler korumalıdır, silinemez.
- **Diller:** Türkçe, İngilizce ve Brezilya Portekizcesi. Uygulama macOS dilinizi kullanır; dil desteklenmiyorsa İngilizce açılır.
- **Otomatik güncelleme:** Uygulama yeni sürümleri GitHub'dan denetler, sürüm notlarını gösterir ve güncellemeyi tek tıkla yükler. Her güncelleme, yüklenmeden önce geliştiricinin kod imzasıyla doğrulanır. *YUCE Cleaner › Güncellemeleri Denetle…* menüsünü de kullanabilir, otomatik denetimi aynı menüden kapatabilirsiniz.

## İndirme

1. [Sürümler sayfasından](https://github.com/bariscagriyuce/mac-cleaner/releases/latest) en yeni **`YUCE-Cleaner-x.y.z.dmg`** dosyasını indirin.
2. DMG'yi açın ve **YUCE Cleaner**'ı **Uygulamalar** klasörüne sürükleyin.
3. Uygulamalar klasöründen veya Launchpad'den açın.

Uygulama Developer ID ile imzalı ve Apple tarafından onaylıdır (notarized), bu yüzden güvenlik uyarısı olmadan açılır. Hem Apple silicon hem Intel Mac'lerde çalışır (macOS 14 veya üzeri).

## Gereksinimler

- macOS 14 Sonoma veya üzeri (Apple silicon veya Intel)
- Derlemek için Xcode veya Xcode Command Line Tools (`xcode-select --install`)

## Derleme ve çalıştırma

```bash
git clone https://github.com/bariscagriyuce/mac-cleaner.git
cd mac-cleaner
./build.sh
open "YUCE Cleaner.app"
```

Ardından `YUCE Cleaner.app` dosyasını Uygulamalar klasörüne sürükleyebilirsiniz.

İmzalı ve onaylı (notarized) bir DMG'yi kendiniz oluşturmak için `release.sh` dosyasının başındaki açıklamalara bakın.

## Tam Disk Erişimi (önerilir)

Çöp Kutusu, Mail verileri ve iPhone yedekleri gibi bazı konumlar macOS tarafından korunur. Bunları taramak için:

1. **Sistem Ayarları › Gizlilik ve Güvenlik › Tam Disk Erişimi** bölümünü açın
2. **+** düğmesine basıp **YUCE Cleaner**'ı ekleyin
3. Uygulamayı kapatıp yeniden açın

Uygulamadaki *Ayarları Aç* butonu sizi doğrudan oraya götürür.

## Dil

Dil, macOS'taki tercih edilen dillerinize göre seçilir (Sistem Ayarları › Genel › Dil ve Bölge):

| Sistem dili | Uygulama dili |
|---|---|
| Türkçe | Türkçe |
| Portekizce (her bölge) | Brezilya Portekizcesi |
| İngilizce | İngilizce |
| Diğer diller | İngilizce |

Yalnızca bu uygulama için ayrı bir dil de seçebilirsiniz: **Sistem Ayarları › Genel › Dil ve Bölge › Uygulamalar**.

## Proje yapısı

```
Sources/YUCECleaner.swift    Uygulama, tarama, silme mantığı ve SwiftUI ekranları
Sources/Updater.swift        Güncelleme denetimi ve yükleyici (GitHub Releases)
Sources/Localization.swift   Dil algılama ve çeviriler (tr, pt-BR)
build.sh                     .app paketini (universal) swiftc ile derler
release.sh                   DMG oluşturur, imzalar ve Apple onayına gönderir
```

Yeni bir dil eklemek için `Localization.swift` dosyasına bir sözlük ekleyin. Anahtarlar İngilizce metinlerdir.

## Sorumluluk reddi

Dosya silmek her zaman kendi sorumluluğunuzdadır. Kategori açıklamalarını okuyun, *Çöp Kutusuna Taşı* seçeneğini tercih edin ve önemli verilerinizin yedeğini alın.

Mac ve macOS, Apple Inc.'in ticari markalarıdır. YUCE Cleaner bağımsız bir uygulamadır; Apple ile bağlantılı değildir ve Apple tarafından onaylanmamıştır.
