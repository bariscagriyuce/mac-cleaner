import SwiftUI
import AppKit

// MARK: - Yardımcılar

private let byteFormatter: ByteCountFormatter = {
    let f = ByteCountFormatter()
    f.countStyle = .file
    f.allowsNonnumericFormatting = false   // "Zero KB" yerine "0 KB"
    return f
}()
func fmt(_ b: Int64) -> String { byteFormatter.string(fromByteCount: max(b, 0)) }
func expand(_ p: String) -> String { (p as NSString).expandingTildeInPath }
func abbreviate(_ p: String) -> String {
    let h = NSHomeDirectory()
    return p.hasPrefix(h) ? "~" + p.dropFirst(h.count) : p
}

@discardableResult
func runProcess(_ exe: String, _ args: [String]) -> (status: Int32, output: String) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: exe)
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = pipe
    do { try p.run() } catch { return (-1, error.localizedDescription) }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return (p.terminationStatus, String(data: data, encoding: .utf8) ?? "")
}

func openFullDiskAccessSettings() {
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
        NSWorkspace.shared.open(url)
    }
}

// MARK: - Model

enum Safety {
    case safe, review, info
    var label: String {
        switch self {
        case .safe: return L("Safe to delete")
        case .review: return L("Review before deleting")
        case .info: return L("Info only")
        }
    }
    var color: Color {
        switch self {
        case .safe: return .green
        case .review: return .orange
        case .info: return .gray
        }
    }
}

enum Kind { case standard, simulators, trash, snapshots, backups }

struct Root {
    let path: String
    let listChildren: Bool
}

struct CategoryDef: Identifiable {
    let id: String
    let title: String
    let icon: String
    let detail: String
    let safety: Safety
    var kind: Kind = .standard
    let roots: [Root]
}

extension CategoryDef {
    static let all: [CategoryDef] = [
        CategoryDef(id: "caches", title: L("App Caches"), icon: "archivebox",
                    detail: L("Temporary cache files created by apps. If deleted, apps rebuild them when needed. It is best to quit the related apps first."),
                    safety: .safe, roots: [Root(path: "~/Library/Caches", listChildren: true)]),
        CategoryDef(id: "logs", title: L("Logs & Crash Reports"), icon: "doc.text",
                    detail: L("App logs and crash reports. Not useful except for troubleshooting."),
                    safety: .safe, roots: [Root(path: "~/Library/Logs", listChildren: true)]),
        CategoryDef(id: "xcode", title: L("Xcode Data"), icon: "hammer",
                    detail: L("DerivedData (build intermediates), device support files and archives. DerivedData and DeviceSupport are safe to delete; Archives may contain builds you submitted to the App Store."),
                    safety: .review, roots: [
                        Root(path: "~/Library/Developer/Xcode/DerivedData", listChildren: true),
                        Root(path: "~/Library/Developer/Xcode/iOS DeviceSupport", listChildren: true),
                        Root(path: "~/Library/Developer/Xcode/watchOS DeviceSupport", listChildren: true),
                        Root(path: "~/Library/Developer/Xcode/visionOS DeviceSupport", listChildren: true),
                        Root(path: "~/Library/Developer/Xcode/Archives", listChildren: true),
                        Root(path: "~/Library/Developer/Xcode/Products", listChildren: false),
                        Root(path: "~/Library/Developer/Xcode/CodingAssistant", listChildren: false),
                    ]),
        CategoryDef(id: "simulators", title: L("iOS Simulators"), icon: "iphone",
                    detail: L("Xcode simulator devices and caches. Deleted simulators can be recreated in Xcode (the app data inside them is lost)."),
                    safety: .review, kind: .simulators, roots: [
                        Root(path: "~/Library/Developer/CoreSimulator/Devices", listChildren: true),
                        Root(path: "~/Library/Developer/CoreSimulator/Caches", listChildren: false),
                    ]),
        CategoryDef(id: "dev", title: L("Developer Tool Caches"), icon: "terminal",
                    detail: L("Download caches of tools such as npm, pip, uv, Gradle, Cargo, Maven and Go. Re-downloaded when needed."),
                    safety: .safe, roots: [
                        Root(path: "~/.cache", listChildren: true),
                        Root(path: "~/.npm", listChildren: false),
                        Root(path: "~/.gradle/caches", listChildren: false),
                        Root(path: "~/.gradle/wrapper/dists", listChildren: false),
                        Root(path: "~/.cargo/registry", listChildren: false),
                        Root(path: "~/.m2/repository", listChildren: false),
                        Root(path: "~/go/pkg/mod", listChildren: false),
                        Root(path: "~/Library/pnpm/store", listChildren: false),
                        Root(path: "~/.pnpm-store", listChildren: false),
                        Root(path: "~/.yarn/berry/cache", listChildren: false),
                        Root(path: "~/.cocoapods/repos", listChildren: false),
                    ]),
        CategoryDef(id: "vms", title: L("Virtual Machines, Android & Docker"), icon: "shippingbox",
                    detail: L("Docker disk image, Android SDK / emulators and virtual machines. They take a lot of space but may contain important data; delete them if you don't use them."),
                    safety: .review, roots: [
                        Root(path: "~/Library/Containers/com.docker.docker/Data/vms", listChildren: false),
                        Root(path: "~/Library/Android/sdk", listChildren: true),
                        Root(path: "~/.android/avd", listChildren: true),
                        Root(path: "~/Parallels", listChildren: true),
                        Root(path: "~/Virtual Machines.localized", listChildren: true),
                        Root(path: "~/Library/Containers/com.utmapp.UTM/Data/Documents", listChildren: true),
                    ]),
        CategoryDef(id: "backups", title: L("iPhone / iPad Backups"), icon: "externaldrive.badge.timemachine",
                    detail: L("Local device backups made with Finder. Delete them if you have an iCloud backup or no longer use the device."),
                    safety: .review, kind: .backups, roots: [
                        Root(path: "~/Library/Application Support/MobileSync/Backup", listChildren: true),
                    ]),
        CategoryDef(id: "appsupport", title: L("App Support Data"), icon: "folder",
                    detail: L("App settings and data (games, browser profiles, etc.). Only delete folders of apps you no longer use or have uninstalled."),
                    safety: .review, roots: [
                        Root(path: "~/Library/Application Support", listChildren: true),
                        Root(path: "~/Library/Containers", listChildren: true),
                        Root(path: "~/Library/Group Containers", listChildren: true),
                    ]),
        CategoryDef(id: "attachments", title: L("Mail & Message Attachments"), icon: "paperclip",
                    detail: L("Attachments opened from Mail and photo/video attachments in Messages. Deleted message attachments disappear from conversations."),
                    safety: .review, roots: [
                        Root(path: "~/Library/Containers/com.apple.mail/Data/Library/Mail Downloads", listChildren: false),
                        Root(path: "~/Library/Messages/Attachments", listChildren: true),
                    ]),
        CategoryDef(id: "downloads", title: L("Downloads"), icon: "arrow.down.circle",
                    detail: L("Your Downloads folder. Installer files (.dmg, .pkg, .zip) are usually unnecessary after installation."),
                    safety: .review, roots: [Root(path: "~/Downloads", listChildren: true)]),
        CategoryDef(id: "trash", title: L("Trash"), icon: "trash",
                    detail: L("Files in the Trash still take up space. Emptying it frees space (cannot be undone)."),
                    safety: .safe, kind: .trash, roots: [Root(path: "~/.Trash", listChildren: true)]),
        CategoryDef(id: "snapshots", title: L("Time Machine Snapshots"), icon: "clock.arrow.circlepath",
                    detail: L("Local Time Machine snapshots can make up a large part of “System Data”. Deleting them requires an administrator password. macOS does not report their sizes."),
                    safety: .safe, kind: .snapshots, roots: []),
        CategoryDef(id: "system", title: L("System Temporary Files"), icon: "gearshape.2",
                    detail: L("Temporary files and swap space managed by macOS. Do not delete them manually; restarting your Mac clears most of them."),
                    safety: .info, roots: [
                        Root(path: "/private/var/folders", listChildren: false),
                        Root(path: "/private/var/vm", listChildren: false),
                    ]),
    ]
}

struct Entry: Identifiable, Hashable {
    let id: String
    let url: URL
    var name: String
    var detail: String
    var size: Int64 = -1          // -1 = hesaplanıyor
    var modified: Date? = nil
    var isDirectory: Bool = true
    var simulatorUDID: String? = nil
    var snapshotDate: String? = nil
}

// MARK: - Tarama

enum DiskSize {
    static let keys: Set<URLResourceKey> = [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey]
    static let skip: Set<String> = ["/System/Volumes", "/Volumes", "/dev", "/net", "/home"]

    static func of(_ url: URL) -> Int64 {
        guard let rv = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey]) else { return 0 }
        if rv.isSymbolicLink == true { return 0 }
        if rv.isDirectory != true { return Int64(rv.totalFileAllocatedSize ?? rv.fileAllocatedSize ?? 0) }
        if skip.contains(url.path) { return 0 }
        guard let en = FileManager.default.enumerator(at: url, includingPropertiesForKeys: Array(keys), options: [], errorHandler: { _, _ in true }) else { return 0 }
        var total: Int64 = 0
        for case let u as URL in en {
            if skip.contains(u.path) { en.skipDescendants(); continue }
            if let v = try? u.resourceValues(forKeys: keys), v.isRegularFile == true {
                total += Int64(v.totalFileAllocatedSize ?? v.fileAllocatedSize ?? 0)
            }
        }
        return total
    }
}

/// Boyutları sınırlı paralellikle hesaplar, her sonuç geldikçe ana iş parçacığında bildirir.
func computeSizes(_ urls: [URL], onResult: @escaping @MainActor (URL, Int64) -> Void) async {
    await withTaskGroup(of: (URL, Int64).self) { g in
        let maxConcurrent = 6
        var idx = 0
        while idx < min(maxConcurrent, urls.count) {
            let u = urls[idx]
            g.addTask { (u, DiskSize.of(u)) }
            idx += 1
        }
        while let (u, s) = await g.next() {
            if Task.isCancelled { g.cancelAll(); return }
            await onResult(u, s)
            if idx < urls.count {
                let u2 = urls[idx]
                g.addTask { (u2, DiskSize.of(u2)) }
                idx += 1
            }
        }
    }
}

enum Scanner {
    static let listKeys: [URLResourceKey] = [.contentModificationDateKey, .isDirectoryKey]
    static let ignored: Set<String> = [".DS_Store", ".localized"]

    static func listEntries(for def: CategoryDef) -> (entries: [Entry], denied: [String]) {
        var out: [Entry] = []
        var denied: [String] = []
        let fm = FileManager.default

        if def.kind == .snapshots {
            let r = runProcess("/usr/bin/tmutil", ["listlocalsnapshots", "/"])
            for line in r.output.split(separator: "\n") {
                let s = line.trimmingCharacters(in: .whitespaces)
                guard s.hasPrefix("com.apple.TimeMachine.") else { continue }
                let date = s.replacingOccurrences(of: "com.apple.TimeMachine.", with: "")
                    .replacingOccurrences(of: ".local", with: "")
                var e = Entry(id: s, url: URL(fileURLWithPath: "/"), name: s, detail: L("Local snapshot"), size: 0)
                e.isDirectory = false
                e.snapshotDate = date
                out.append(e)
            }
            return (out, denied)
        }

        var seen = Set<String>()
        for root in def.roots {
            let path = expand(root.path)
            let url = URL(fileURLWithPath: path)
            guard fm.fileExists(atPath: path) else { continue }
            if root.listChildren {
                do {
                    let kids = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: listKeys, options: [])
                    for k in kids where !ignored.contains(k.lastPathComponent) && !seen.contains(k.path) {
                        seen.insert(k.path)
                        out.append(makeEntry(k, kind: def.kind))
                    }
                } catch {
                    denied.append(abbreviate(path))
                }
            } else if !seen.contains(path) {
                seen.insert(path)
                var e = makeEntry(url, kind: def.kind)
                e.name = abbreviate(path)
                e.detail = ""
                out.append(e)
            }
        }
        return (out, denied)
    }

    static func makeEntry(_ url: URL, kind: Kind?) -> Entry {
        let rv = try? url.resourceValues(forKeys: Set(listKeys))
        var e = Entry(id: url.path, url: url, name: url.lastPathComponent,
                      detail: kind == nil ? "" : abbreviate(url.deletingLastPathComponent().path),
                      modified: rv?.contentModificationDate, isDirectory: rv?.isDirectory ?? false)
        if kind == .simulators, let d = NSDictionary(contentsOf: url.appendingPathComponent("device.plist")) {
            let name = d["name"] as? String ?? url.lastPathComponent
            let rt = (d["runtime"] as? String ?? "")
                .replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: "")
            let parts = rt.split(separator: "-")
            let runtime = parts.isEmpty ? rt : parts[0] + " " + parts.dropFirst().joined(separator: ".")
            e.name = runtime.isEmpty ? name : "\(name) (\(runtime))"
            e.detail = L("Simulator · %@", url.lastPathComponent)
            e.simulatorUDID = d["UDID"] as? String ?? url.lastPathComponent
        }
        if kind == .backups, let d = NSDictionary(contentsOf: url.appendingPathComponent("Info.plist")) {
            e.name = (d["Device Name"] as? String) ?? e.name
            if let date = d["Last Backup Date"] as? Date { e.modified = date }
            e.detail = L("Backup · %@", url.lastPathComponent)
        }
        return e
    }
}

// MARK: - Silme

enum Remover {
    static let protectedPaths: Set<String> = {
        let h = NSHomeDirectory()
        var s: Set<String> = ["/", "/System", "/Library", "/Applications", "/Users", "/private", "/usr", "/bin",
                              "/sbin", "/etc", "/var", "/opt", "/cores", "/Volumes", "/tmp"]
        for p in ["", "/Library", "/Documents", "/Desktop", "/Downloads", "/Pictures", "/Movies", "/Music",
                  "/Applications", "/Library/Application Support", "/Library/Caches", "/Library/Containers",
                  "/Library/Group Containers", "/Library/Preferences", "/Library/Mobile Documents",
                  "/Library/CloudStorage", "/Library/Keychains", "/.Trash"] {
            s.insert(h + p)
        }
        return s
    }()

    static func isProtected(_ url: URL) -> Bool {
        let p = url.standardizedFileURL.path
        return protectedPaths.contains(p) || p.hasPrefix("/System/") || p.hasPrefix("/usr/") || p.hasPrefix("/bin/") || p.hasPrefix("/sbin/")
    }

    /// Hataların listesini döndürür.
    static func remove(_ entries: [Entry], permanent: Bool) -> [String] {
        var errors: [String] = []
        let fm = FileManager.default

        let snaps = entries.compactMap(\.snapshotDate).filter { $0.allSatisfy { $0.isNumber || $0 == "-" } }
        if !snaps.isEmpty {
            let cmd = snaps.map { "/usr/bin/tmutil deletelocalsnapshots \($0)" }.joined(separator: "; ")
            let r = runProcess("/usr/bin/osascript", ["-e", "do shell script \"\(cmd)\" with administrator privileges"])
            if r.status != 0 { errors.append(L("Snapshots: %@", r.output.trimmingCharacters(in: .whitespacesAndNewlines))) }
        }

        for e in entries where e.snapshotDate == nil {
            if isProtected(e.url) {
                errors.append(L("%@: skipped because it is a protected system folder.", e.name))
                continue
            }
            if let udid = e.simulatorUDID, runProcess("/usr/bin/xcrun", ["simctl", "delete", udid]).status == 0 {
                continue
            }
            do {
                if permanent { try fm.removeItem(at: e.url) }
                else { try fm.trashItem(at: e.url, resultingItemURL: nil) }
            } catch {
                errors.append("\(e.name): \(error.localizedDescription)")
            }
        }
        return errors
    }

    static func emptyTrash() -> [String] {
        let trash = URL(fileURLWithPath: expand("~/.Trash"))
        let fm = FileManager.default
        guard let kids = try? fm.contentsOfDirectory(at: trash, includingPropertiesForKeys: nil) else {
            let r = runProcess("/usr/bin/osascript", ["-e", "tell application \"Finder\" to empty trash"])
            return r.status == 0 ? [] : [L("Could not empty the Trash: %@", r.output)]
        }
        var errors: [String] = []
        for k in kids {
            do { try fm.removeItem(at: k) } catch { errors.append("\(k.lastPathComponent): \(error.localizedDescription)") }
        }
        return errors
    }
}

// MARK: - Durum

@MainActor @Observable
final class CategoryState: Identifiable {
    let def: CategoryDef
    var entries: [Entry] = []
    var selection = Set<String>()
    var denied: [String] = []
    var scanning = false
    var scanned = false
    var progress = 0

    nonisolated var id: String { def.id }
    init(def: CategoryDef) { self.def = def }

    var total: Int64 { entries.reduce(0) { $0 + max($1.size, 0) } }
    var selectedEntries: [Entry] { entries.filter { selection.contains($0.id) } }
    var selectedSize: Int64 { selectedEntries.reduce(0) { $0 + max($1.size, 0) } }
}

@MainActor @Observable
final class AppModel {
    var categories: [CategoryState] = CategoryDef.all.map { CategoryState(def: $0) }
    var diskTotal: Int64 = 0
    var diskFree: Int64 = 0
    var scanningAll = false
    var errors: [String] = []

    init() { refreshDisk() }

    func category(_ id: String) -> CategoryState? { categories.first { $0.id == id } }

    func refreshDisk() {
        let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey]
        if let v = try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(forKeys: keys) {
            diskTotal = Int64(v.volumeTotalCapacity ?? 0)
            diskFree = v.volumeAvailableCapacityForImportantUsage ?? Int64(v.volumeAvailableCapacity ?? 0)
        }
    }

    func scan(_ c: CategoryState) async {
        guard !c.scanning else { return }
        c.scanning = true
        c.selection = []
        c.progress = 0
        let def = c.def
        let result = await Task.detached { Scanner.listEntries(for: def) }.value
        c.entries = result.entries
        c.denied = result.denied
        if def.kind != .snapshots {
            let index = Dictionary(uniqueKeysWithValues: result.entries.enumerated().map { ($1.id, $0) })
            await computeSizes(result.entries.map(\.url)) { url, size in
                if let i = index[url.path], i < c.entries.count, c.entries[i].id == url.path {
                    c.entries[i].size = size
                    c.progress += 1
                }
            }
        }
        c.entries.sort { $0.size > $1.size }
        c.scanning = false
        c.scanned = true
    }

    func scanAll() async {
        scanningAll = true
        for c in categories { await scan(c) }
        scanningAll = false
        refreshDisk()
    }

    // MARK: Hızlı (güvenli) temizlik

    static let safeCleanCategories = ["caches", "logs", "dev", "xcode", "trash"]
    var safeCleaning = false
    var cleanResult: String? = nil

    /// Toplu temizlikte otomatik silinmesi güvenli olan öğe mi?
    func isAutoCleanable(_ e: Entry, in def: CategoryDef, running: Set<String>) -> Bool {
        guard e.size > 0 else { return false }
        switch def.id {
        case "caches":
            // Apple sistem önbelleklerine ve şu an açık uygulamaların önbelleklerine dokunma.
            return !e.name.hasPrefix("com.apple.") && !running.contains(e.name)
        case "logs", "dev":
            return true
        case "xcode":
            // Yalnızca yeniden oluşturulabilenler; Archives hariç.
            let p = e.url.path
            return p.contains("/DerivedData/") || p.contains(" DeviceSupport/") || p.hasSuffix("/Xcode/Products")
        default:
            return false
        }
    }

    private func ensureScanned(_ c: CategoryState) async {
        while c.scanning { try? await Task.sleep(nanoseconds: 150_000_000) }
        if !c.scanned { await scan(c) }
    }

    /// Güvenli temizlikte silinecek öğeleri toplar (gerekirse önce tarar).
    func collectSafeItems() async -> [Entry] {
        let running = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
        var out: [Entry] = []
        for id in Self.safeCleanCategories {
            guard let c = category(id) else { continue }
            await ensureScanned(c)
            if id == "trash" { continue }
            out += c.entries.filter { isAutoCleanable($0, in: c.def, running: running) }
        }
        return out
    }

    func runSafeClean(_ items: [Entry]) async {
        safeCleaning = true
        let planned = items.reduce(Int64(0)) { $0 + max($1.size, 0) } + (category("trash")?.total ?? 0)
        let errs = await Task.detached { () -> [String] in
            var e = Remover.remove(items, permanent: true)
            e += Remover.emptyTrash()
            _ = runProcess("/usr/bin/xcrun", ["simctl", "delete", "unavailable"])
            return e
        }.value
        for id in Self.safeCleanCategories + ["simulators"] {
            if let c = category(id), c.scanned || id != "simulators" { c.scanned = false; await scan(c) }
        }
        refreshDisk()
        var msg = L("About %@ cleaned.\nCurrent free space: %@.", fmt(planned), fmt(diskFree))
        if !errs.isEmpty {
            msg += L("\n\n%ld items were skipped because they are in use or protected.", errs.count)
        }
        cleanResult = msg
        safeCleaning = false
    }

    func remove(_ entries: [Entry], permanent: Bool, from c: CategoryState?) async {
        let errs = await Task.detached { Remover.remove(entries, permanent: permanent) }.value
        await afterChange(errs, rescan: c)
    }

    func emptyTrash() async {
        let errs = await Task.detached { Remover.emptyTrash() }.value
        await afterChange(errs, rescan: category("trash"))
    }

    private func afterChange(_ errs: [String], rescan c: CategoryState?) async {
        errors = errs
        if let t = category("trash"), t !== c { t.scanned = false; t.entries = [] }
        refreshDisk()
        if let c { await scan(c) }
        refreshDisk()
    }
}

@MainActor @Observable
final class ExplorerModel {
    var current = URL(fileURLWithPath: NSHomeDirectory())
    var entries: [Entry] = []
    var selection = Set<String>()
    var scanning = false
    var denied = false
    var progress = 0
    private var task: Task<Void, Never>?
    private var loaded = false

    var total: Int64 { entries.reduce(0) { $0 + max($1.size, 0) } }

    func loadIfNeeded() { if !loaded { reload() } }

    func open(_ url: URL) {
        current = url.standardizedFileURL
        reload()
    }

    func reload() {
        loaded = true
        task?.cancel()
        selection = []
        let url = current
        task = Task {
            scanning = true
            denied = false
            progress = 0
            entries = []
            let listed: [Entry]? = await Task.detached {
                guard let kids = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: Scanner.listKeys, options: []) else { return nil }
                return kids.filter { !Scanner.ignored.contains($0.lastPathComponent) }.map { Scanner.makeEntry($0, kind: nil) }
            }.value
            guard !Task.isCancelled else { return }
            guard let listed else { denied = true; scanning = false; return }
            entries = listed
            let index = Dictionary(uniqueKeysWithValues: listed.enumerated().map { ($1.id, $0) })
            await computeSizes(listed.map(\.url)) { u, s in
                guard self.current == url, let i = index[u.path], i < self.entries.count, self.entries[i].id == u.path else { return }
                self.entries[i].size = s
                self.progress += 1
            }
            guard !Task.isCancelled else { return }
            entries.sort { $0.size > $1.size }
            scanning = false
        }
    }
}

// MARK: - Uygulama

@main
struct YUCECleanerApp: App {
    @State private var model = AppModel()
    @State private var explorer = ExplorerModel()
    @State private var updater = Updater()

    var body: some Scene {
        WindowGroup("YUCE Cleaner") {
            ContentView()
                .environment(model)
                .environment(explorer)
                .environment(updater)
                .modifier(UpdateAlerts())
                .task { updater.checkOnLaunch() }
                .frame(minWidth: 1000, minHeight: 640)
        }
        .commands { UpdateCommands(updater: updater) }
    }
}

enum SidebarItem: Hashable { case overview, explorer, category(String) }

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @State private var selection: SidebarItem? = .overview

    var body: some View {
        @Bindable var model = model
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    Label(L("Overview"), systemImage: "chart.pie").tag(SidebarItem.overview)
                    Label(L("Folder Explorer"), systemImage: "folder.badge.gearshape").tag(SidebarItem.explorer)
                }
                Section(L("Categories")) {
                    ForEach(model.categories) { c in
                        HStack {
                            Label(c.def.title, systemImage: c.def.icon)
                            Spacer()
                            if c.scanning {
                                ProgressView().controlSize(.small)
                            } else if c.scanned && c.def.kind != .snapshots {
                                Text(fmt(c.total)).font(.caption).monospacedDigit().foregroundStyle(.secondary)
                            }
                        }
                        .tag(SidebarItem.category(c.id))
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 270, ideal: 300)
        } detail: {
            switch selection {
            case .explorer:
                ExplorerView()
            case .category(let id):
                if let c = model.category(id) { CategoryView(cat: c).id(id) }
            default:
                OverviewView(selection: $selection)
            }
        }
        .alert(L("Some items could not be deleted"), isPresented: Binding(get: { !model.errors.isEmpty }, set: { if !$0 { model.errors = [] } })) {
            Button(L("OK")) { model.errors = [] }
            Button(L("Full Disk Access Settings")) { openFullDiskAccessSettings(); model.errors = [] }
        } message: {
            Text(model.errors.prefix(8).joined(separator: "\n") + (model.errors.count > 8 ? L("\n… and %ld more errors", model.errors.count - 8) : ""))
        }
        .alert(L("Cleanup complete"), isPresented: Binding(get: { model.cleanResult != nil }, set: { if !$0 { model.cleanResult = nil } })) {
            Button(L("OK")) { model.cleanResult = nil }
        } message: {
            Text(model.cleanResult ?? "")
        }
    }
}

struct SafeCleanCard: View {
    @Environment(AppModel.self) private var model
    @State private var pending: [Entry] = []
    @State private var preparing = false
    @State private var showConfirm = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "sparkles").font(.system(size: 34)).foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 4) {
                Text(L("Quick Clean")).font(.title2.bold())
                Text(L("One click deletes only safe items: app caches, logs, developer caches, Xcode DerivedData / DeviceSupport, unavailable simulators and the Trash. It does not touch personal data, app settings or Xcode archives."))
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button {
                preparing = true
                Task {
                    pending = await model.collectSafeItems()
                    preparing = false
                    showConfirm = true
                }
            } label: {
                Label(preparing ? L("Calculating…") : model.safeCleaning ? L("Cleaning…") : L("Clean Safe Items"),
                      systemImage: "trash.circle.fill")
                    .padding(.horizontal, 6)
            }
            .buttonStyle(.borderedProminent).tint(.green).controlSize(.large)
            .disabled(preparing || model.safeCleaning || model.scanningAll)
            if preparing || model.safeCleaning { ProgressView().controlSize(.small) }
        }
        .padding()
        .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.green.opacity(0.3)))
        .confirmationDialog(L("Clean about %@?", fmt(totalSize)), isPresented: $showConfirm, titleVisibility: .visible) {
            Button(L("Clean")) { let items = pending; Task { await model.runSafeClean(items) } }
            Button(L("Cancel"), role: .cancel) {}
        } message: {
            Text(summary)
        }
    }

    var trashSize: Int64 { model.category("trash")?.total ?? 0 }
    var totalSize: Int64 { pending.reduce(0) { $0 + max($1.size, 0) } + trashSize }

    var summary: String {
        var lines: [String] = []
        for id in AppModel.safeCleanCategories where id != "trash" {
            guard let c = model.category(id) else { continue }
            let items = pending.filter { e in c.entries.contains { $0.id == e.id } }
            if !items.isEmpty {
                lines.append(L("• %@: %@ (%ld items)", c.def.title, fmt(items.reduce(0) { $0 + max($1.size, 0) }), items.count))
            }
        }
        lines.append(trashSize > 0 ? L("• Trash will be emptied: %@", fmt(trashSize)) : L("• Trash will be emptied"))
        return lines.joined(separator: "\n")
            + "\n\n" + L("These items are deleted permanently (apps recreate all of them when needed). Caches of running apps are skipped; quit your browsers for best results.")
    }
}

// MARK: - Özet

struct OverviewView: View {
    @Environment(AppModel.self) private var model
    @Binding var selection: SidebarItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                UpdateBanner()
                Text(L("Disk Status")).font(.largeTitle.bold())

                let used = max(model.diskTotal - model.diskFree, 0)
                let frac = model.diskTotal > 0 ? Double(used) / Double(model.diskTotal) : 0
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: frac).tint(frac > 0.9 ? .red : frac > 0.75 ? .orange : .accentColor)
                    HStack {
                        Text(L("Used: %@", fmt(used)))
                        Spacer()
                        Text(L("Free: %@", fmt(model.diskFree))).bold()
                        Spacer()
                        Text(L("Total: %@", fmt(model.diskTotal)))
                    }
                    .font(.callout).monospacedDigit()
                }
                .padding()
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))

                SafeCleanCard()

                HStack {
                    Button {
                        Task { await model.scanAll() }
                    } label: {
                        Label(model.scanningAll ? L("Scanning…") : L("Scan All Categories"), systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    .disabled(model.scanningAll)
                    if model.scanningAll { ProgressView().controlSize(.small) }
                    Spacer()
                    let safe = model.categories.filter { $0.def.safety == .safe }.reduce(Int64(0)) { $0 + $1.total }
                    let review = model.categories.filter { $0.def.safety == .review }.reduce(Int64(0)) { $0 + $1.total }
                    VStack(alignment: .trailing) {
                        Text(L("Safe to clean: %@", fmt(safe))).foregroundStyle(.green).bold()
                        Text(L("To review: %@", fmt(review))).foregroundStyle(.orange)
                    }
                    .monospacedDigit()
                }

                VStack(spacing: 0) {
                    let maxSize = max(model.categories.map(\.total).max() ?? 1, 1)
                    ForEach(model.categories.sorted { $0.total > $1.total }) { c in
                        Button { selection = .category(c.id) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: c.def.icon).frame(width: 24).foregroundStyle(Color.accentColor)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(c.def.title)
                                    HStack(spacing: 4) {
                                        Circle().fill(c.def.safety.color).frame(width: 7, height: 7)
                                        Text(c.def.safety.label).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                SizeBar(fraction: Double(c.total) / Double(maxSize), color: c.def.safety.color).frame(width: 140)
                                Group {
                                    if c.scanning { ProgressView().controlSize(.small) }
                                    else if !c.scanned { Text("—").foregroundStyle(.secondary) }
                                    else if c.def.kind == .snapshots { Text(L("%ld items", c.entries.count)) }
                                    else { Text(fmt(c.total)) }
                                }
                                .frame(width: 90, alignment: .trailing).monospacedDigit()
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 8).padding(.horizontal, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))

                GroupBox(L("What is “System Data”?")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("macOS shows everything that does not fit a category such as documents, apps or photos as “System Data”: caches, logs, Time Machine snapshots, Xcode and simulator data, device backups, virtual machine images, app support files and swap space."))
                        Text(L("Deleted files are moved to the Trash first; empty it from the Trash category to free space. Give the app Full Disk Access so it can read some folders."))
                            .foregroundStyle(.secondary)
                        Button(L("Open Full Disk Access Settings")) { openFullDiskAccessSettings() }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                }

                VersionFooter()
            }
            .padding(24)
        }
        .onAppear { model.refreshDisk() }
    }
}

struct SizeBar: View {
    var fraction: Double
    var color: Color = .accentColor
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule().fill(color.gradient).frame(width: max(geo.size.width * min(max(fraction, 0), 1), fraction > 0 ? 3 : 0))
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Dosya tablosu (ortak)

struct EntryTable: View {
    var entries: [Entry]
    @Binding var selection: Set<String>
    var selectable: Bool
    var showReveal: Bool = true
    var onOpen: ((Entry) -> Void)? = nil
    var onDelete: (Set<String>) -> Void
    @State private var sortOrder = [KeyPathComparator(\Entry.size, order: .reverse)]

    var sorted: [Entry] { entries.sorted(using: sortOrder) }

    var body: some View {
        let maxSize = max(entries.map(\.size).max() ?? 1, 1)
        Table(sorted, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("") { (e: Entry) in
                Toggle("", isOn: Binding(
                    get: { selection.contains(e.id) },
                    set: { on in if on { selection.insert(e.id) } else { selection.remove(e.id) } }))
                .labelsHidden()
                .disabled(!selectable)
            }
            .width(22)
            TableColumn(L("Name"), value: \Entry.name) { (e: Entry) in
                HStack(spacing: 8) {
                    if e.snapshotDate != nil {
                        Image(systemName: "clock.arrow.circlepath").frame(width: 20)
                    } else {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: e.url.path)).resizable().frame(width: 20, height: 20)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(e.name).lineLimit(1)
                        if !e.detail.isEmpty {
                            Text(e.detail).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                        }
                    }
                }
            }
            TableColumn(L("Size"), value: \Entry.size) { (e: Entry) in
                HStack {
                    if e.snapshotDate != nil { Text("—").foregroundStyle(.secondary) }
                    else if e.size < 0 { ProgressView().controlSize(.mini) }
                    else { Text(fmt(e.size)).monospacedDigit() }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 80, ideal: 95, max: 120)
            TableColumn(L("Share")) { (e: Entry) in
                SizeBar(fraction: Double(max(e.size, 0)) / Double(maxSize))
            }
            .width(min: 60, ideal: 110, max: 160)
            TableColumn(L("Modified")) { (e: Entry) in
                Text(e.modified.map { $0.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(AppLanguage.current.locale)) } ?? "—").foregroundStyle(.secondary)
            }
            .width(min: 80, ideal: 105, max: 130)
        }
        .contextMenu(forSelectionType: String.self) { ids in
            if showReveal {
                Button(L("Show in Finder")) {
                    let urls = entries.filter { ids.contains($0.id) }.map(\.url)
                    NSWorkspace.shared.activateFileViewerSelecting(urls)
                }
            }
            if selectable {
                Button(L("Delete…"), role: .destructive) { onDelete(ids) }
            }
        } primaryAction: { ids in
            if let id = ids.first, let e = entries.first(where: { $0.id == id }) { onOpen?(e) }
        }
    }
}

struct DeniedBanner: View {
    var paths: [String]
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "lock.fill").foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(L("Some folders could not be read: %@", paths.joined(separator: ", "))).bold()
                Text(L("Add YUCE Cleaner in System Settings › Privacy & Security › Full Disk Access, then reopen the app."))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(L("Open Settings")) { openFullDiskAccessSettings() }
        }
        .padding(10)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal).padding(.bottom, 8)
    }
}

// MARK: - Kategori ekranı

struct CategoryView: View {
    @Environment(AppModel.self) private var model
    @Bindable var cat: CategoryState
    @State private var pendingDelete: [Entry] = []
    @State private var showConfirm = false
    @State private var showEmptyTrash = false
    @State private var working = false

    var deletable: Bool { cat.def.safety != .info }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if !cat.denied.isEmpty { DeniedBanner(paths: cat.denied) }
            footer
            if cat.scanned && cat.entries.isEmpty && !cat.scanning {
                ContentUnavailableView(cat.def.kind == .snapshots ? L("No snapshots") : L("Looks clean"),
                                       systemImage: "checkmark.seal",
                                       description: Text(L("Nothing to delete was found in this category.")))
            } else {
                EntryTable(entries: cat.entries, selection: $cat.selection, selectable: deletable,
                           showReveal: cat.def.kind != .snapshots,
                           onOpen: { e in NSWorkspace.shared.activateFileViewerSelecting([e.url]) },
                           onDelete: { ids in askDelete(cat.entries.filter { ids.contains($0.id) }) })
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task { if !cat.scanned { await model.scan(cat) } }
        .confirmationDialog(confirmTitle, isPresented: $showConfirm, titleVisibility: .visible) {
            if cat.def.kind == .trash || cat.def.kind == .snapshots {
                Button(L("Delete Permanently"), role: .destructive) { performDelete(permanent: true) }
            } else {
                Button(L("Move to Trash")) { performDelete(permanent: false) }
                Button(L("Delete Permanently (cannot be undone)"), role: .destructive) { performDelete(permanent: true) }
            }
            Button(L("Cancel"), role: .cancel) {}
        } message: {
            Text(confirmMessage)
        }
        .confirmationDialog(L("Empty the Trash?"), isPresented: $showEmptyTrash, titleVisibility: .visible) {
            Button(L("Empty Trash"), role: .destructive) {
                working = true
                Task { await model.emptyTrash(); working = false }
            }
            Button(L("Cancel"), role: .cancel) {}
        } message: {
            Text(L("All items in the Trash (%@) will be deleted permanently. This cannot be undone.", fmt(cat.total)))
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: cat.def.icon).font(.title).foregroundStyle(Color.accentColor)
                Text(cat.def.title).font(.largeTitle.bold())
                Text(cat.def.safety.label)
                    .font(.caption.bold()).padding(.horizontal, 8).padding(.vertical, 3)
                    .background(cat.def.safety.color.opacity(0.2), in: Capsule())
                    .foregroundStyle(cat.def.safety.color)
                Spacer()
                if cat.def.kind != .snapshots {
                    Text(fmt(cat.total)).font(.title2.bold()).monospacedDigit()
                }
            }
            Text(cat.def.detail).foregroundStyle(.secondary).lineLimit(3)
            HStack {
                Button { Task { await model.scan(cat) } } label: { Label(L("Rescan"), systemImage: "arrow.clockwise") }
                    .disabled(cat.scanning)
                if cat.def.kind == .simulators {
                    Button {
                        working = true
                        Task {
                            let r = await Task.detached { runProcess("/usr/bin/xcrun", ["simctl", "delete", "unavailable"]) }.value
                            if r.status != 0 { model.errors = ["simctl: \(r.output)"] }
                            working = false
                            await model.scan(cat)
                            model.refreshDisk()
                        }
                    } label: { Label(L("Delete Unavailable Simulators"), systemImage: "iphone.slash") }
                }
                if cat.def.kind == .trash {
                    Button(role: .destructive) { showEmptyTrash = true } label: { Label(L("Empty Trash"), systemImage: "trash.slash") }
                        .disabled(cat.entries.isEmpty && cat.denied.isEmpty)
                }
                if cat.scanning {
                    ProgressView().controlSize(.small)
                    Text(L("Calculating… %ld/%ld", cat.progress, cat.entries.count)).font(.caption).foregroundStyle(.secondary)
                }
                if working { ProgressView().controlSize(.small); Text(L("Working…")).font(.caption) }
            }
        }
        .padding()
    }

    var footer: some View {
        HStack {
            if deletable {
                let allSelected = !cat.entries.isEmpty && cat.selection.count == cat.entries.count
                Button {
                    cat.selection = allSelected ? [] : Set(cat.entries.map(\.id))
                } label: {
                    Label(allSelected ? L("Deselect All") : L("Select All"),
                          systemImage: allSelected ? "square" : "checkmark.square.fill")
                }
                .controlSize(.large)
                .disabled(cat.entries.isEmpty)
                Text(L("%ld / %ld items selected · %@", cat.selection.count, cat.entries.count, fmt(cat.selectedSize)))
                    .monospacedDigit().foregroundStyle(.secondary)
                Spacer()
                Button(role: .destructive) { askDelete(cat.selectedEntries) } label: {
                    Label(L("Delete Selected"), systemImage: "trash")
                }
                .buttonStyle(.borderedProminent).tint(.red).controlSize(.large)
                .disabled(cat.selection.isEmpty || working)
            } else {
                Image(systemName: "info.circle")
                Text(L("This category is managed by macOS and shown for information only. Restarting clears most of it."))
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(.bar)
    }

    var confirmTitle: String {
        L("Delete %ld items? (%@)", pendingDelete.count, fmt(pendingDelete.reduce(0) { $0 + max($1.size, 0) }))
    }

    var confirmMessage: String {
        let names = pendingDelete.prefix(6).map(\.name).joined(separator: "\n")
        let more = pendingDelete.count > 6 ? L("\n… and %ld more items", pendingDelete.count - 6) : ""
        switch cat.def.kind {
        case .trash: return names + more + "\n\n" + L("These items will be deleted permanently.")
        case .snapshots: return names + more + "\n\n" + L("Your administrator password will be requested. Snapshots are deleted permanently.")
        case .simulators: return names + more + "\n\n" + L("Simulators are deleted permanently with `xcrun simctl delete`; other items are handled with the method you choose.")
        default: return names + more + "\n\n" + L("Items moved to the Trash can be restored, but you need to empty the Trash to free space.")
        }
    }

    func askDelete(_ entries: [Entry]) {
        guard !entries.isEmpty, deletable else { return }
        pendingDelete = entries
        showConfirm = true
    }

    func performDelete(permanent: Bool) {
        let items = pendingDelete
        working = true
        Task {
            await model.remove(items, permanent: permanent, from: cat)
            working = false
        }
    }
}

// MARK: - Klasör gezgini

struct ExplorerView: View {
    @Environment(AppModel.self) private var model
    @Environment(ExplorerModel.self) private var ex
    @State private var pendingDelete: [Entry] = []
    @State private var showConfirm = false
    @State private var working = false

    var body: some View {
        @Bindable var ex = ex
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(L("Folder Explorer")).font(.largeTitle.bold())
                    Spacer()
                    Text(fmt(ex.total)).font(.title2.bold()).monospacedDigit()
                }
                Text(L("Lists the contents of any folder sorted by size. Double-click a folder to open it."))
                    .foregroundStyle(.secondary)
                HStack {
                    Button { ex.open(ex.current.deletingLastPathComponent()) } label: { Image(systemName: "chevron.up") }
                        .disabled(ex.current.path == "/")
                        .help(L("Parent folder"))
                    Text(abbreviate(ex.current.path)).font(.body.monospaced()).lineLimit(1).truncationMode(.middle)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
                    Spacer()
                    Button(L("Home")) { ex.open(URL(fileURLWithPath: NSHomeDirectory())) }
                    Button(L("Library")) { ex.open(URL(fileURLWithPath: expand("~/Library"))) }
                    Button(L("Disk (/)")) { ex.open(URL(fileURLWithPath: "/")) }
                    Button(L("Choose Folder…")) { pickFolder() }
                    Button { ex.reload() } label: { Image(systemName: "arrow.clockwise") }.help(L("Rescan"))
                }
                if ex.scanning {
                    HStack {
                        ProgressView().controlSize(.small)
                        Text(L("Calculating… %ld/%ld", ex.progress, ex.entries.count)).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding()

            if ex.denied {
                DeniedBanner(paths: [abbreviate(ex.current.path)])
                Spacer()
            } else {
                EntryTable(entries: ex.entries, selection: $ex.selection, selectable: true,
                           onOpen: { e in
                               if e.isDirectory && e.url.pathExtension.isEmpty { ex.open(e.url) }
                               else { NSWorkspace.shared.activateFileViewerSelecting([e.url]) }
                           },
                           onDelete: { ids in askDelete(ex.entries.filter { ids.contains($0.id) }) })
            }

            HStack {
                let allSelected = !ex.entries.isEmpty && ex.selection.count == ex.entries.count
                Button {
                    ex.selection = allSelected ? [] : Set(ex.entries.map(\.id))
                } label: {
                    Label(allSelected ? L("Deselect All") : L("Select All"),
                          systemImage: allSelected ? "square" : "checkmark.square.fill")
                }
                .disabled(ex.entries.isEmpty)
                Spacer()
                let sel = ex.entries.filter { ex.selection.contains($0.id) }
                Text(L("%ld items selected · %@", sel.count, fmt(sel.reduce(0) { $0 + max($1.size, 0) }))).monospacedDigit().foregroundStyle(.secondary)
                Button(role: .destructive) { askDelete(sel) } label: { Label(L("Delete Selected"), systemImage: "trash") }
                    .buttonStyle(.borderedProminent).tint(.red)
                    .disabled(sel.isEmpty || working)
            }
            .padding()
            .background(.bar)
        }
        .onAppear { ex.loadIfNeeded() }
        .confirmationDialog(L("Delete %ld items?", pendingDelete.count), isPresented: $showConfirm, titleVisibility: .visible) {
            Button(L("Move to Trash")) { performDelete(permanent: false) }
            Button(L("Delete Permanently (cannot be undone)"), role: .destructive) { performDelete(permanent: true) }
            Button(L("Cancel"), role: .cancel) {}
        } message: {
            Text(pendingDelete.prefix(6).map(\.name).joined(separator: "\n")
                 + (pendingDelete.count > 6 ? L("\n… and %ld more items", pendingDelete.count - 6) : "")
                 + L("\n\nTotal: %@", fmt(pendingDelete.reduce(0) { $0 + max($1.size, 0) })))
        }
    }

    func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.directoryURL = ex.current
        if panel.runModal() == .OK, let url = panel.url { ex.open(url) }
    }

    func askDelete(_ entries: [Entry]) {
        guard !entries.isEmpty else { return }
        pendingDelete = entries
        showConfirm = true
    }

    func performDelete(permanent: Bool) {
        let items = pendingDelete
        working = true
        Task {
            await model.remove(items, permanent: permanent, from: nil)
            ex.reload()
            working = false
        }
    }
}
