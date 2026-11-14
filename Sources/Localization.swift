import Foundation

/// Desteklenen diller. Sistem dili bunlardan biri değilse İngilizce kullanılır.
enum AppLanguage: String {
    case en
    case tr
    case ptBR = "pt-BR"

    static let current: AppLanguage = {
        // Test için: YUCE_LANG=tr|en|pt-BR
        if let forced = ProcessInfo.processInfo.environment["YUCE_LANG"], let l = AppLanguage(rawValue: forced) {
            return l
        }
        // Kullanıcının tercih ettiği diller sırayla denenir (Sistem Ayarları › Genel › Dil ve Bölge
        // ya da uygulamaya özel dil ayarı).
        for id in Locale.preferredLanguages {
            let code = id.lowercased()
            if code.hasPrefix("tr") { return .tr }
            if code.hasPrefix("pt") { return .ptBR }
            if code.hasPrefix("en") { return .en }
        }
        return .en
    }()

    var locale: Locale {
        switch self {
        case .en: return Locale(identifier: "en_US")
        case .tr: return Locale(identifier: "tr_TR")
        case .ptBR: return Locale(identifier: "pt_BR")
        }
    }
}

/// Çeviri: anahtar İngilizce metnin kendisidir.
func L(_ key: String) -> String {
    switch AppLanguage.current {
    case .en: return key
    case .tr: return trStrings[key] ?? key
    case .ptBR: return ptBRStrings[key] ?? key
    }
}

/// Biçimlendirmeli çeviri (%@, %ld).
func L(_ key: String, _ args: CVarArg...) -> String {
    String(format: L(key), locale: AppLanguage.current.locale, arguments: args)
}

// MARK: - Türkçe

let trStrings: [String: String] = [
    // Güvenlik etiketleri
    "Safe to delete": "Güvenle silinebilir",
    "Review before deleting": "Gözden geçirerek silin",
    "Info only": "Yalnızca bilgi",

    // Kategoriler
    "App Caches": "Uygulama Önbellekleri",
    "Temporary cache files created by apps. If deleted, apps rebuild them when needed. It is best to quit the related apps first.":
        "Uygulamaların geçici önbellek dosyaları. Silinirse uygulamalar gerektiğinde yeniden oluşturur. Silmeden önce ilgili uygulamaları kapatmanız önerilir.",
    "Logs & Crash Reports": "Günlükler ve Çökme Raporları",
    "App logs and crash reports. Not useful except for troubleshooting.":
        "Uygulama günlükleri ve çökme raporları. Sorun gidermek dışında işe yaramazlar.",
    "Xcode Data": "Xcode Verileri",
    "DerivedData (build intermediates), device support files and archives. DerivedData and DeviceSupport are safe to delete; Archives may contain builds you submitted to the App Store.":
        "DerivedData (derleme ara dosyaları), cihaz destek dosyaları ve arşivler. DerivedData ve DeviceSupport güvenle silinir; Archives içinde App Store'a gönderdiğiniz derlemeler olabilir.",
    "iOS Simulators": "iOS Simülatörleri",
    "Xcode simulator devices and caches. Deleted simulators can be recreated in Xcode (the app data inside them is lost).":
        "Xcode simülatör cihazları ve önbellekleri. Silinen simülatörler Xcode'dan yeniden oluşturulabilir (içlerindeki uygulama verileri gider).",
    "Developer Tool Caches": "Geliştirici Araç Önbellekleri",
    "Download caches of tools such as npm, pip, uv, Gradle, Cargo, Maven and Go. Re-downloaded when needed.":
        "npm, pip, uv, Gradle, Cargo, Maven, Go gibi araçların indirme önbellekleri. Silinirse gerektiğinde yeniden indirilir.",
    "Virtual Machines, Android & Docker": "Sanal Makineler, Android ve Docker",
    "Docker disk image, Android SDK / emulators and virtual machines. They take a lot of space but may contain important data; delete them if you don't use them.":
        "Docker disk imajı, Android SDK / emülatörler ve sanal makineler. Çok yer kaplarlar ama içlerinde önemli veriler olabilir; kullanmıyorsanız silin.",
    "iPhone / iPad Backups": "iPhone / iPad Yedekleri",
    "Local device backups made with Finder. Delete them if you have an iCloud backup or no longer use the device.":
        "Finder ile alınan yerel cihaz yedekleri. iCloud yedeğiniz varsa veya cihazı artık kullanmıyorsanız silebilirsiniz.",
    "App Support Data": "Uygulama Destek Verileri",
    "App settings and data (games, browser profiles, etc.). Only delete folders of apps you no longer use or have uninstalled.":
        "Uygulamaların ayarları ve verileri (oyunlar, tarayıcı profilleri vb.). Yalnızca artık kullanmadığınız veya kaldırdığınız uygulamaların klasörlerini silin.",
    "Mail & Message Attachments": "Mail ve Mesaj Ekleri",
    "Attachments opened from Mail and photo/video attachments in Messages. Deleted message attachments disappear from conversations.":
        "Mail'den açılan ekler ve Mesajlar'daki fotoğraf/video ekleri. Mesaj ekleri silinirse sohbette görünmez olur.",
    "Downloads": "İndirilenler",
    "Your Downloads folder. Installer files (.dmg, .pkg, .zip) are usually unnecessary after installation.":
        "İndirilenler klasörü. Kurulum dosyaları (.dmg, .pkg, .zip) genellikle kurulumdan sonra gereksizdir.",
    "Trash": "Çöp Kutusu",
    "Files in the Trash still take up space. Emptying it frees space (cannot be undone).":
        "Çöp Kutusundaki dosyalar hâlâ yer kaplar. Boşaltınca yer açılır (geri alınamaz).",
    "Time Machine Snapshots": "Time Machine Anlık Görüntüleri",
    "Local Time Machine snapshots can make up a large part of “System Data”. Deleting them requires an administrator password. macOS does not report their sizes.":
        "Yerel Time Machine anlık görüntüleri “Sistem Verileri”nin büyük bir kısmını oluşturabilir. Silmek için yönetici parolası istenir. macOS boyutlarını göstermez.",
    "System Temporary Files": "Sistem Geçici Dosyaları",
    "Temporary files and swap space managed by macOS. Do not delete them manually; restarting your Mac clears most of them.":
        "macOS'un yönettiği geçici dosyalar ve takas (swap) alanı. Elle silinmemeli; Mac'i yeniden başlatmak bunların çoğunu temizler.",

    // Tarama / silme
    "Local snapshot": "Yerel anlık görüntü",
    "Simulator · %@": "Simülatör · %@",
    "Backup · %@": "Yedek · %@",
    "%@: skipped because it is a protected system folder.": "%@: korumalı bir sistem klasörü olduğu için atlandı.",
    "Snapshots: %@": "Anlık görüntüler: %@",
    "Could not empty the Trash: %@": "Çöp Kutusu boşaltılamadı: %@",
    "About %@ cleaned.\nCurrent free space: %@.": "Yaklaşık %@ temizlendi.\nŞu anki boş alan: %@.",
    "\n\n%ld items were skipped because they are in use or protected.": "\n\n%ld öğe kullanımda veya korumalı olduğu için atlandı.",

    // Kenar çubuğu ve uyarılar
    "Overview": "Özet",
    "Folder Explorer": "Klasör Gezgini",
    "Categories": "Kategoriler",
    "Some items could not be deleted": "Bazı öğeler silinemedi",
    "OK": "Tamam",
    "Full Disk Access Settings": "Tam Disk Erişimi Ayarları",
    "\n… and %ld more errors": "\n… ve %ld hata daha",
    "Cleanup complete": "Temizlik tamamlandı",

    // Hızlı temizlik
    "Quick Clean": "Hızlı Temizlik",
    "One click deletes only safe items: app caches, logs, developer caches, Xcode DerivedData / DeviceSupport, unavailable simulators and the Trash. It does not touch personal data, app settings or Xcode archives.":
        "Tek tıkla yalnızca güvenli olanları siler: uygulama önbellekleri, günlükler, geliştirici önbellekleri, Xcode DerivedData / DeviceSupport, kullanılamayan simülatörler ve Çöp Kutusu. Kişisel verilere, uygulama ayarlarına ve Xcode arşivlerine dokunmaz.",
    "Calculating…": "Hesaplanıyor…",
    "Cleaning…": "Temizleniyor…",
    "Clean Safe Items": "Güvenli Olanları Temizle",
    "Clean about %@?": "Yaklaşık %@ temizlensin mi?",
    "Clean": "Temizle",
    "Cancel": "Vazgeç",
    "• %@: %@ (%ld items)": "• %@: %@ (%ld öğe)",
    "• Trash will be emptied": "• Çöp Kutusu boşaltılacak",
    "• Trash will be emptied: %@": "• Çöp Kutusu boşaltılacak: %@",
    "These items are deleted permanently (apps recreate all of them when needed). Caches of running apps are skipped; quit your browsers for best results.":
        "Bu öğeler kalıcı olarak silinir (hepsi uygulamalar tarafından gerektiğinde yeniden oluşturulur). Açık uygulamaların önbellekleri atlanır; en iyi sonuç için tarayıcıları kapatın.",

    // Özet
    "Disk Status": "Disk Durumu",
    "Used: %@": "Kullanılan: %@",
    "Free: %@": "Boş: %@",
    "Total: %@": "Toplam: %@",
    "Scanning…": "Taranıyor…",
    "Scan All Categories": "Tüm Kategorileri Tara",
    "Safe to clean: %@": "Güvenle temizlenebilir: %@",
    "To review: %@": "Gözden geçirilecek: %@",
    "%ld items": "%ld adet",
    "What is “System Data”?": "“Sistem Verileri” nedir?",
    "macOS shows everything that does not fit a category such as documents, apps or photos as “System Data”: caches, logs, Time Machine snapshots, Xcode and simulator data, device backups, virtual machine images, app support files and swap space.":
        "macOS, belge/uygulama/fotoğraf gibi bir kategoriye girmeyen her şeyi “Sistem Verileri” olarak gösterir: önbellekler, günlükler, Time Machine anlık görüntüleri, Xcode ve simülatör verileri, cihaz yedekleri, sanal makine imajları, uygulama destek dosyaları ve takas alanı.",
    "Deleted files are moved to the Trash first; empty it from the Trash category to free space. Give the app Full Disk Access so it can read some folders.":
        "Silinen dosyalar önce Çöp Kutusuna taşınır; yer açmak için sonra Çöp Kutusu kategorisinden boşaltın. Bazı klasörleri okuyabilmek için uygulamaya Tam Disk Erişimi verin.",
    "Open Full Disk Access Settings": "Tam Disk Erişimi Ayarlarını Aç",

    // Tablo
    "Name": "Ad",
    "Size": "Boyut",
    "Share": "Oran",
    "Modified": "Değiştirilme",
    "Show in Finder": "Finder'da Göster",
    "Delete…": "Sil…",
    "Some folders could not be read: %@": "Bazı klasörler okunamadı: %@",
    "Add YUCE Cleaner in System Settings › Privacy & Security › Full Disk Access, then reopen the app.":
        "Sistem Ayarları › Gizlilik ve Güvenlik › Tam Disk Erişimi bölümünden YUCE Cleaner'ı ekleyip uygulamayı yeniden açın.",
    "Open Settings": "Ayarları Aç",

    // Kategori ekranı
    "No snapshots": "Anlık görüntü yok",
    "Looks clean": "Temiz görünüyor",
    "Nothing to delete was found in this category.": "Bu kategoride silinecek bir şey bulunamadı.",
    "Delete Permanently": "Kalıcı Olarak Sil",
    "Move to Trash": "Çöp Kutusuna Taşı",
    "Delete Permanently (cannot be undone)": "Kalıcı Olarak Sil (geri alınamaz)",
    "Empty the Trash?": "Çöp Kutusu boşaltılsın mı?",
    "Empty Trash": "Çöp Kutusunu Boşalt",
    "All items in the Trash (%@) will be deleted permanently. This cannot be undone.":
        "Çöp Kutusundaki tüm öğeler (%@) kalıcı olarak silinecek. Bu işlem geri alınamaz.",
    "Rescan": "Yeniden Tara",
    "Delete Unavailable Simulators": "Kullanılamayan Simülatörleri Sil",
    "Calculating… %ld/%ld": "Hesaplanıyor… %ld/%ld",
    "Working…": "İşleniyor…",
    "Select All": "Tümünü Seç",
    "Deselect All": "Seçimi Kaldır",
    "%ld / %ld items selected · %@": "%ld / %ld öğe seçili · %@",
    "Delete Selected": "Seçili Olanları Sil",
    "This category is managed by macOS and shown for information only. Restarting clears most of it.":
        "Bu kategori macOS tarafından yönetilir ve yalnızca bilgi amaçlı gösterilir. Yeniden başlatmak çoğunu temizler.",
    "Delete %ld items? (%@)": "%ld öğe silinsin mi? (%@)",
    "\n… and %ld more items": "\n… ve %ld öğe daha",
    "These items will be deleted permanently.": "Bu öğeler kalıcı olarak silinecek.",
    "Your administrator password will be requested. Snapshots are deleted permanently.":
        "Yönetici parolanız istenecek. Anlık görüntüler kalıcı olarak silinir.",
    "Simulators are deleted permanently with `xcrun simctl delete`; other items are handled with the method you choose.":
        "Simülatörler `xcrun simctl delete` ile kalıcı olarak silinir; diğer öğeler seçtiğiniz yönteme göre işlenir.",
    "Items moved to the Trash can be restored, but you need to empty the Trash to free space.":
        "Çöp Kutusuna taşınanlar geri alınabilir, ancak yer açmak için Çöp Kutusunu boşaltmanız gerekir.",

    // Klasör gezgini
    "Lists the contents of any folder sorted by size. Double-click a folder to open it.":
        "Herhangi bir klasörün içindekileri boyuta göre sıralar. Bir klasöre girmek için çift tıklayın.",
    "Parent folder": "Üst klasör",
    "Home": "Ev",
    "Library": "Kitaplık",
    "Disk (/)": "Disk (/)",
    "Choose Folder…": "Klasör Seç…",
    "%ld items selected · %@": "%ld öğe seçildi · %@",
    "Delete %ld items?": "%ld öğe silinsin mi?",
    "\n\nTotal: %@": "\n\nToplam: %@",

    // Güncellemeler
    "Check for Updates…": "Güncellemeleri Denetle…",
    "Automatically Check for Updates": "Güncellemeleri Otomatik Denetle",
    "A new version of YUCE Cleaner is available!": "YUCE Cleaner'ın yeni bir sürümü var!",
    "YUCE Cleaner %@ is available — you have %@. Would you like to install it now?":
        "YUCE Cleaner %@ yayınlandı; sizdeki sürüm %@. Şimdi yüklemek ister misiniz?",
    "Release Notes": "Sürüm Notları",
    "Skip This Version": "Bu Sürümü Atla",
    "Remind Me Later": "Daha Sonra Hatırlat",
    "Install and Relaunch": "Yükle ve Yeniden Başlat",
    "Downloading… %ld%%": "İndiriliyor… %%%ld",
    "Installing…": "Yükleniyor…",
    "View on GitHub": "GitHub'da Görüntüle",
    "You're up to date!": "Uygulamanız güncel!",
    "YUCE Cleaner %@ is the latest version.": "YUCE Cleaner %@ en son sürüm.",
    "Update failed": "Güncelleme başarısız",
    "Open Download Page": "İndirme Sayfasını Aç",
    "Install the update manually": "Güncellemeyi elle yükleyin",
    "Could not reach the update server.": "Güncelleme sunucusuna ulaşılamadı.",
    "Could not open the downloaded update.": "İndirilen güncelleme açılamadı.",
    "The downloaded update is not signed by the developer, so it was not installed.":
        "İndirilen güncelleme geliştirici tarafından imzalanmamış, bu yüzden yüklenmedi.",
    "The downloaded version is not newer than the installed one.": "İndirilen sürüm, yüklü olandan daha yeni değil.",
    "Could not prepare the update: %@": "Güncelleme hazırlanamadı: %@",
    "The app could not be replaced automatically. The new version has been opened; drag it into the Applications folder.":
        "Uygulama otomatik olarak değiştirilemedi. Yeni sürüm açıldı; onu Uygulamalar klasörüne sürükleyin.",
    "YUCE Cleaner %@ is available.": "YUCE Cleaner %@ yayınlandı.",
    "Update…": "Güncelle…",
    "Version %@": "Sürüm %@",
    "Checking…": "Denetleniyor…",
]

// MARK: - Português (Brasil)

let ptBRStrings: [String: String] = [
    "Safe to delete": "Pode apagar com segurança",
    "Review before deleting": "Revise antes de apagar",
    "Info only": "Apenas informativo",

    "App Caches": "Caches de Apps",
    "Temporary cache files created by apps. If deleted, apps rebuild them when needed. It is best to quit the related apps first.":
        "Arquivos temporários de cache criados pelos apps. Se forem apagados, os apps os recriam quando necessário. É melhor fechar os apps relacionados antes.",
    "Logs & Crash Reports": "Logs e Relatórios de Falhas",
    "App logs and crash reports. Not useful except for troubleshooting.":
        "Logs de apps e relatórios de falhas. Só são úteis para solucionar problemas.",
    "Xcode Data": "Dados do Xcode",
    "DerivedData (build intermediates), device support files and archives. DerivedData and DeviceSupport are safe to delete; Archives may contain builds you submitted to the App Store.":
        "DerivedData (arquivos intermediários de compilação), arquivos de suporte a dispositivos e Archives. DerivedData e DeviceSupport podem ser apagados com segurança; Archives pode conter builds enviados à App Store.",
    "iOS Simulators": "Simuladores iOS",
    "Xcode simulator devices and caches. Deleted simulators can be recreated in Xcode (the app data inside them is lost).":
        "Dispositivos e caches dos simuladores do Xcode. Simuladores apagados podem ser recriados no Xcode (os dados dos apps dentro deles são perdidos).",
    "Developer Tool Caches": "Caches de Ferramentas de Desenvolvimento",
    "Download caches of tools such as npm, pip, uv, Gradle, Cargo, Maven and Go. Re-downloaded when needed.":
        "Caches de download de ferramentas como npm, pip, uv, Gradle, Cargo, Maven e Go. São baixados novamente quando necessário.",
    "Virtual Machines, Android & Docker": "Máquinas Virtuais, Android e Docker",
    "Docker disk image, Android SDK / emulators and virtual machines. They take a lot of space but may contain important data; delete them if you don't use them.":
        "Imagem de disco do Docker, Android SDK / emuladores e máquinas virtuais. Ocupam muito espaço, mas podem conter dados importantes; apague-os se não os usa.",
    "iPhone / iPad Backups": "Backups de iPhone / iPad",
    "Local device backups made with Finder. Delete them if you have an iCloud backup or no longer use the device.":
        "Backups locais de dispositivos feitos pelo Finder. Apague-os se você tem backup no iCloud ou não usa mais o dispositivo.",
    "App Support Data": "Dados de Suporte de Apps",
    "App settings and data (games, browser profiles, etc.). Only delete folders of apps you no longer use or have uninstalled.":
        "Configurações e dados de apps (jogos, perfis de navegador etc.). Apague apenas as pastas de apps que você não usa mais ou desinstalou.",
    "Mail & Message Attachments": "Anexos do Mail e Mensagens",
    "Attachments opened from Mail and photo/video attachments in Messages. Deleted message attachments disappear from conversations.":
        "Anexos abertos no Mail e fotos/vídeos anexados no Mensagens. Anexos de mensagens apagados somem das conversas.",
    "Downloads": "Downloads",
    "Your Downloads folder. Installer files (.dmg, .pkg, .zip) are usually unnecessary after installation.":
        "Sua pasta Downloads. Arquivos de instalação (.dmg, .pkg, .zip) geralmente são desnecessários após a instalação.",
    "Trash": "Lixeira",
    "Files in the Trash still take up space. Emptying it frees space (cannot be undone).":
        "Os arquivos na Lixeira ainda ocupam espaço. Esvaziá-la libera espaço (não pode ser desfeito).",
    "Time Machine Snapshots": "Snapshots do Time Machine",
    "Local Time Machine snapshots can make up a large part of “System Data”. Deleting them requires an administrator password. macOS does not report their sizes.":
        "Snapshots locais do Time Machine podem representar grande parte de “Dados do Sistema”. Apagá-los exige a senha de administrador. O macOS não informa seus tamanhos.",
    "System Temporary Files": "Arquivos Temporários do Sistema",
    "Temporary files and swap space managed by macOS. Do not delete them manually; restarting your Mac clears most of them.":
        "Arquivos temporários e espaço de swap gerenciados pelo macOS. Não os apague manualmente; reiniciar o Mac limpa a maior parte deles.",

    "Local snapshot": "Snapshot local",
    "Simulator · %@": "Simulador · %@",
    "Backup · %@": "Backup · %@",
    "%@: skipped because it is a protected system folder.": "%@: ignorado por ser uma pasta protegida do sistema.",
    "Snapshots: %@": "Snapshots: %@",
    "Could not empty the Trash: %@": "Não foi possível esvaziar a Lixeira: %@",
    "About %@ cleaned.\nCurrent free space: %@.": "Cerca de %@ limpos.\nEspaço livre atual: %@.",
    "\n\n%ld items were skipped because they are in use or protected.": "\n\n%ld itens foram ignorados por estarem em uso ou protegidos.",

    "Overview": "Visão Geral",
    "Folder Explorer": "Explorador de Pastas",
    "Categories": "Categorias",
    "Some items could not be deleted": "Alguns itens não puderam ser apagados",
    "OK": "OK",
    "Full Disk Access Settings": "Ajustes de Acesso Total ao Disco",
    "\n… and %ld more errors": "\n… e mais %ld erros",
    "Cleanup complete": "Limpeza concluída",

    "Quick Clean": "Limpeza Rápida",
    "One click deletes only safe items: app caches, logs, developer caches, Xcode DerivedData / DeviceSupport, unavailable simulators and the Trash. It does not touch personal data, app settings or Xcode archives.":
        "Com um clique, apaga apenas itens seguros: caches de apps, logs, caches de desenvolvimento, DerivedData / DeviceSupport do Xcode, simuladores indisponíveis e a Lixeira. Não mexe em dados pessoais, configurações de apps nem nos Archives do Xcode.",
    "Calculating…": "Calculando…",
    "Cleaning…": "Limpando…",
    "Clean Safe Items": "Limpar Itens Seguros",
    "Clean about %@?": "Limpar cerca de %@?",
    "Clean": "Limpar",
    "Cancel": "Cancelar",
    "• %@: %@ (%ld items)": "• %@: %@ (%ld itens)",
    "• Trash will be emptied": "• A Lixeira será esvaziada",
    "• Trash will be emptied: %@": "• A Lixeira será esvaziada: %@",
    "These items are deleted permanently (apps recreate all of them when needed). Caches of running apps are skipped; quit your browsers for best results.":
        "Estes itens são apagados permanentemente (os apps recriam todos quando necessário). Caches de apps abertos são ignorados; feche os navegadores para melhores resultados.",

    "Disk Status": "Status do Disco",
    "Used: %@": "Usado: %@",
    "Free: %@": "Livre: %@",
    "Total: %@": "Total: %@",
    "Scanning…": "Analisando…",
    "Scan All Categories": "Analisar Todas as Categorias",
    "Safe to clean: %@": "Seguro para limpar: %@",
    "To review: %@": "Para revisar: %@",
    "%ld items": "%ld itens",
    "What is “System Data”?": "O que são “Dados do Sistema”?",
    "macOS shows everything that does not fit a category such as documents, apps or photos as “System Data”: caches, logs, Time Machine snapshots, Xcode and simulator data, device backups, virtual machine images, app support files and swap space.":
        "O macOS mostra como “Dados do Sistema” tudo o que não se encaixa em categorias como documentos, apps ou fotos: caches, logs, snapshots do Time Machine, dados do Xcode e dos simuladores, backups de dispositivos, imagens de máquinas virtuais, arquivos de suporte de apps e espaço de swap.",
    "Deleted files are moved to the Trash first; empty it from the Trash category to free space. Give the app Full Disk Access so it can read some folders.":
        "Os arquivos apagados vão primeiro para a Lixeira; esvazie-a na categoria Lixeira para liberar espaço. Dê Acesso Total ao Disco ao app para que ele possa ler algumas pastas.",
    "Open Full Disk Access Settings": "Abrir Ajustes de Acesso Total ao Disco",

    "Name": "Nome",
    "Size": "Tamanho",
    "Share": "Proporção",
    "Modified": "Modificado",
    "Show in Finder": "Mostrar no Finder",
    "Delete…": "Apagar…",
    "Some folders could not be read: %@": "Algumas pastas não puderam ser lidas: %@",
    "Add YUCE Cleaner in System Settings › Privacy & Security › Full Disk Access, then reopen the app.":
        "Adicione o YUCE Cleaner em Ajustes do Sistema › Privacidade e Segurança › Acesso Total ao Disco e abra o app novamente.",
    "Open Settings": "Abrir Ajustes",

    "No snapshots": "Nenhum snapshot",
    "Looks clean": "Tudo limpo",
    "Nothing to delete was found in this category.": "Nada para apagar foi encontrado nesta categoria.",
    "Delete Permanently": "Apagar Permanentemente",
    "Move to Trash": "Mover para a Lixeira",
    "Delete Permanently (cannot be undone)": "Apagar Permanentemente (não pode ser desfeito)",
    "Empty the Trash?": "Esvaziar a Lixeira?",
    "Empty Trash": "Esvaziar Lixeira",
    "All items in the Trash (%@) will be deleted permanently. This cannot be undone.":
        "Todos os itens da Lixeira (%@) serão apagados permanentemente. Isso não pode ser desfeito.",
    "Rescan": "Analisar Novamente",
    "Delete Unavailable Simulators": "Apagar Simuladores Indisponíveis",
    "Calculating… %ld/%ld": "Calculando… %ld/%ld",
    "Working…": "Processando…",
    "Select All": "Selecionar Tudo",
    "Deselect All": "Desmarcar Tudo",
    "%ld / %ld items selected · %@": "%ld / %ld itens selecionados · %@",
    "Delete Selected": "Apagar Selecionados",
    "This category is managed by macOS and shown for information only. Restarting clears most of it.":
        "Esta categoria é gerenciada pelo macOS e exibida apenas para informação. Reiniciar limpa a maior parte dela.",
    "Delete %ld items? (%@)": "Apagar %ld itens? (%@)",
    "\n… and %ld more items": "\n… e mais %ld itens",
    "These items will be deleted permanently.": "Estes itens serão apagados permanentemente.",
    "Your administrator password will be requested. Snapshots are deleted permanently.":
        "Sua senha de administrador será solicitada. Os snapshots são apagados permanentemente.",
    "Simulators are deleted permanently with `xcrun simctl delete`; other items are handled with the method you choose.":
        "Os simuladores são apagados permanentemente com `xcrun simctl delete`; os demais itens seguem o método escolhido.",
    "Items moved to the Trash can be restored, but you need to empty the Trash to free space.":
        "Itens movidos para a Lixeira podem ser restaurados, mas é preciso esvaziar a Lixeira para liberar espaço.",

    "Lists the contents of any folder sorted by size. Double-click a folder to open it.":
        "Lista o conteúdo de qualquer pasta ordenado por tamanho. Clique duas vezes em uma pasta para abri-la.",
    "Parent folder": "Pasta superior",
    "Home": "Início",
    "Library": "Biblioteca",
    "Disk (/)": "Disco (/)",
    "Choose Folder…": "Escolher Pasta…",
    "%ld items selected · %@": "%ld itens selecionados · %@",
    "Delete %ld items?": "Apagar %ld itens?",
    "\n\nTotal: %@": "\n\nTotal: %@",

    "Check for Updates…": "Verificar Atualizações…",
    "Automatically Check for Updates": "Verificar Atualizações Automaticamente",
    "A new version of YUCE Cleaner is available!": "Uma nova versão do YUCE Cleaner está disponível!",
    "YUCE Cleaner %@ is available — you have %@. Would you like to install it now?":
        "O YUCE Cleaner %@ está disponível — você tem a versão %@. Deseja instalá-lo agora?",
    "Release Notes": "Notas da Versão",
    "Skip This Version": "Ignorar Esta Versão",
    "Remind Me Later": "Lembrar Mais Tarde",
    "Install and Relaunch": "Instalar e Reabrir",
    "Downloading… %ld%%": "Baixando… %ld%%",
    "Installing…": "Instalando…",
    "View on GitHub": "Ver no GitHub",
    "You're up to date!": "Você está atualizado!",
    "YUCE Cleaner %@ is the latest version.": "O YUCE Cleaner %@ é a versão mais recente.",
    "Update failed": "Falha na atualização",
    "Open Download Page": "Abrir Página de Download",
    "Install the update manually": "Instale a atualização manualmente",
    "Could not reach the update server.": "Não foi possível acessar o servidor de atualizações.",
    "Could not open the downloaded update.": "Não foi possível abrir a atualização baixada.",
    "The downloaded update is not signed by the developer, so it was not installed.":
        "A atualização baixada não está assinada pelo desenvolvedor, por isso não foi instalada.",
    "The downloaded version is not newer than the installed one.": "A versão baixada não é mais recente que a instalada.",
    "Could not prepare the update: %@": "Não foi possível preparar a atualização: %@",
    "The app could not be replaced automatically. The new version has been opened; drag it into the Applications folder.":
        "Não foi possível substituir o app automaticamente. A nova versão foi aberta; arraste-a para a pasta Aplicativos.",
    "YUCE Cleaner %@ is available.": "O YUCE Cleaner %@ está disponível.",
    "Update…": "Atualizar…",
    "Version %@": "Versão %@",
    "Checking…": "Verificando…",
]
