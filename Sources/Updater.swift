import SwiftUI
import AppKit
import Security

// MARK: - Configuration

enum UpdateConfig {
    /// GitHub repository whose latest release is checked.
    static let repo = "bariscagriyuce/mac-cleaner"
    /// Apple Developer Team ID that every update must be signed with.
    static let teamID = "MPRDU9BAS3"
    static let checkInterval: TimeInterval = 6 * 3600

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }
    static var bundleID: String { Bundle.main.bundleIdentifier ?? "com.bariscagriyuce.yucecleaner" }
}

struct ReleaseInfo: Equatable {
    let version: String
    let notes: String
    let pageURL: URL
    let dmgURL: URL
}

/// "1.10.0" > "1.9.2"
func isVersion(_ a: String, newerThan b: String) -> Bool {
    func parts(_ s: String) -> [Int] { s.split(separator: ".").map { Int($0.filter(\.isNumber)) ?? 0 } }
    let pa = parts(a), pb = parts(b)
    for i in 0..<max(pa.count, pb.count) {
        let x = i < pa.count ? pa[i] : 0
        let y = i < pb.count ? pb[i] : 0
        if x != y { return x > y }
    }
    return false
}

enum UpdateError: LocalizedError {
    case message(String)
    case notReplaceable
    var errorDescription: String? {
        switch self {
        case .message(let m): return m
        case .notReplaceable: return L("The app could not be replaced automatically. The new version has been opened; drag it into the Applications folder.")
        }
    }
}

// MARK: - Checking & downloading

enum UpdateService {
    static func fetchLatest() async throws -> ReleaseInfo? {
        var req = URLRequest(url: URL(string: "https://api.github.com/repos/\(UpdateConfig.repo)/releases/latest")!)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.setValue("YUCE-Cleaner/\(UpdateConfig.currentVersion)", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 20
        req.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw UpdateError.message(L("Could not reach the update server."))
        }
        struct Asset: Decodable { let name: String; let browser_download_url: URL }
        struct Release: Decodable { let tag_name: String; let body: String?; let html_url: URL; let assets: [Asset] }
        let r = try JSONDecoder().decode(Release.self, from: data)
        guard let dmg = r.assets.first(where: { $0.name.lowercased().hasSuffix(".dmg") }) else { return nil }
        let version = r.tag_name.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
        return ReleaseInfo(version: version, notes: r.body ?? "", pageURL: r.html_url, dmgURL: dmg.browser_download_url)
    }

    static func download(_ url: URL, progress: @escaping (Double) -> Void) async throws -> URL {
        let delegate = DownloadDelegate(progress: progress)
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        return try await withCheckedThrowingContinuation { cont in
            delegate.continuation = cont
            session.downloadTask(with: url).resume()
        }
    }
}

private final class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let progress: (Double) -> Void
    var continuation: CheckedContinuation<URL, Error>?

    init(progress: @escaping (Double) -> Void) { self.progress = progress }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 { progress(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)) }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard (downloadTask.response as? HTTPURLResponse)?.statusCode == 200 else {
            finish(.failure(UpdateError.message(L("Could not reach the update server."))))
            return
        }
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("YUCE-Cleaner-update-\(UUID().uuidString).dmg")
        do {
            try FileManager.default.moveItem(at: location, to: dest)
            finish(.success(dest))
        } catch {
            finish(.failure(error))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error { finish(.failure(error)) }
    }

    private func finish(_ result: Result<URL, Error>) {
        guard let c = continuation else { return }
        continuation = nil
        c.resume(with: result)
    }
}

// MARK: - Verifying & installing

enum UpdateInstaller {
    /// Developer ID Application certificate issued to our team.
    static var requirement: String {
        "anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] exists"
        + " and certificate leaf[field.1.2.840.113635.100.6.1.13] exists"
        + " and certificate leaf[subject.OU] = \"\(UpdateConfig.teamID)\""
    }

    /// Checks the code signature and bundle identifier; returns the bundle's version.
    static func verify(_ app: URL, expectedBundleID: String) throws -> String {
        var code: SecStaticCode?
        var req: SecRequirement?
        guard SecStaticCodeCreateWithPath(app as CFURL, [], &code) == errSecSuccess, let code,
              SecRequirementCreateWithString(requirement as CFString, [], &req) == errSecSuccess, let req else {
            throw UpdateError.message(L("The downloaded update is not signed by the developer, so it was not installed."))
        }
        let flags = SecCSFlags(rawValue: kSecCSCheckAllArchitectures | kSecCSStrictValidate | kSecCSCheckNestedCode)
        guard SecStaticCodeCheckValidity(code, flags, req) == errSecSuccess else {
            throw UpdateError.message(L("The downloaded update is not signed by the developer, so it was not installed."))
        }
        guard let bundle = Bundle(url: app), bundle.bundleIdentifier == expectedBundleID else {
            throw UpdateError.message(L("The downloaded update is not signed by the developer, so it was not installed."))
        }
        return bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    static func canReplace(_ currentApp: URL) -> Bool {
        let fm = FileManager.default
        let parent = currentApp.deletingLastPathComponent().path
        return currentApp.pathExtension == "app"
            && !currentApp.path.contains("/AppTranslocation/")
            && !currentApp.path.hasPrefix("/Volumes/")
            && fm.isWritableFile(atPath: parent)
            && fm.isWritableFile(atPath: currentApp.path)
    }

    /// Mounts the DMG, verifies the app inside and copies it next to the running app.
    static func stage(dmg: URL, currentApp: URL, expectedBundleID: String, currentVersion: String) throws -> (staged: URL, target: URL) {
        guard canReplace(currentApp) else { throw UpdateError.notReplaceable }
        let fm = FileManager.default
        let mount = fm.temporaryDirectory.appendingPathComponent("yuce-update-\(UUID().uuidString)")
        try fm.createDirectory(at: mount, withIntermediateDirectories: true)
        let attach = runProcess("/usr/bin/hdiutil", ["attach", dmg.path, "-nobrowse", "-readonly", "-noautoopen", "-mountpoint", mount.path])
        guard attach.status == 0 else {
            try? fm.removeItem(at: mount)
            throw UpdateError.message(L("Could not open the downloaded update."))
        }
        defer {
            runProcess("/usr/bin/hdiutil", ["detach", mount.path, "-force"])
            try? fm.removeItem(at: mount)
        }

        guard let app = try fm.contentsOfDirectory(at: mount, includingPropertiesForKeys: nil)
            .first(where: { $0.pathExtension == "app" }) else {
            throw UpdateError.message(L("Could not open the downloaded update."))
        }
        let newVersion = try verify(app, expectedBundleID: expectedBundleID)
        guard isVersion(newVersion, newerThan: currentVersion) else {
            throw UpdateError.message(L("The downloaded version is not newer than the installed one."))
        }

        let parent = currentApp.deletingLastPathComponent()
        let staged = parent.appendingPathComponent(".yuce-update-\(UUID().uuidString.prefix(8)).app")
        let copy = runProcess("/usr/bin/ditto", [app.path, staged.path])
        guard copy.status == 0 else {
            try? fm.removeItem(at: staged)
            throw UpdateError.message(L("Could not prepare the update: %@", copy.output))
        }
        do {
            _ = try verify(staged, expectedBundleID: expectedBundleID)   // the copy must still be intact
        } catch {
            try? fm.removeItem(at: staged)
            throw error
        }
        return (staged, parent.appendingPathComponent(app.lastPathComponent))
    }

    /// Starts a helper that waits for this process to quit, swaps the bundles and relaunches.
    /// If anything fails, the previous version is put back.
    static func swapAndRelaunch(staged: URL, target: URL, current: URL, pid: Int32 = ProcessInfo.processInfo.processIdentifier) throws {
        let script = """
        while kill -0 "$APP_PID" 2>/dev/null; do sleep 0.2; done
        BACKUP="$CURRENT.yuce-backup"
        rm -rf "$BACKUP"
        mv "$CURRENT" "$BACKUP" || exit 1
        if [ "$TARGET" != "$CURRENT" ] && [ -e "$TARGET" ]; then rm -rf "$TARGET"; fi
        if mv "$STAGED" "$TARGET"; then
          rm -rf "$BACKUP"
          xattr -dr com.apple.quarantine "$TARGET" 2>/dev/null
          [ -z "$NO_RELAUNCH" ] && open "$TARGET"
        else
          mv "$BACKUP" "$CURRENT"
          rm -rf "$STAGED"
          [ -z "$NO_RELAUNCH" ] && open "$CURRENT"
        fi
        """
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/sh")
        p.arguments = ["-c", script]
        var env = ["APP_PID": String(pid), "CURRENT": current.path, "TARGET": target.path, "STAGED": staged.path,
                   "PATH": "/usr/bin:/bin:/usr/sbin:/sbin"]
        if ProcessInfo.processInfo.environment["YUCE_NO_RELAUNCH"] != nil { env["NO_RELAUNCH"] = "1" }
        p.environment = env
        try p.run()
    }
}

// MARK: - State

@MainActor @Observable
final class Updater {
    enum Phase: Equatable {
        case idle, checking, downloading, installing
        case upToDate
        case failed(String)
        case manualInstall
    }

    var phase: Phase = .idle
    var release: ReleaseInfo?
    var progress: Double = 0
    var showSheet = false

    private let defaults = UserDefaults.standard

    var autoCheck: Bool {
        get { defaults.object(forKey: "autoCheckUpdates") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "autoCheckUpdates") }
    }

    /// A newer release that the user has not skipped.
    var availableRelease: ReleaseInfo? {
        guard let r = release, isVersion(r.version, newerThan: UpdateConfig.currentVersion),
              defaults.string(forKey: "skippedVersion") != r.version else { return nil }
        return r
    }

    var isBusy: Bool { phase == .checking || phase == .downloading || phase == .installing }

    func checkOnLaunch() {
        guard autoCheck else { return }
        if let last = defaults.object(forKey: "lastUpdateCheck") as? Date,
           Date().timeIntervalSince(last) < UpdateConfig.checkInterval { return }
        Task { await check(manual: false) }
    }

    func check(manual: Bool) async {
        guard !isBusy else { return }
        if manual { defaults.removeObject(forKey: "skippedVersion") }
        phase = .checking
        do {
            let latest = try await UpdateService.fetchLatest()
            defaults.set(Date(), forKey: "lastUpdateCheck")
            release = latest
            if availableRelease != nil {
                phase = .idle
                showSheet = true
            } else {
                phase = manual ? .upToDate : .idle
            }
        } catch {
            phase = manual ? .failed(error.localizedDescription) : .idle
        }
    }

    func skip() {
        if let r = release { defaults.set(r.version, forKey: "skippedVersion") }
        showSheet = false
    }

    func later() { showSheet = false }

    func install() async {
        guard let r = release, !isBusy else { return }
        phase = .downloading
        progress = 0
        let dmg: URL
        do {
            dmg = try await UpdateService.download(r.dmgURL) { p in
                Task { @MainActor in self.progress = p }
            }
        } catch {
            phase = .failed(error.localizedDescription)
            return
        }

        phase = .installing
        let current = Bundle.main.bundleURL
        let bundleID = UpdateConfig.bundleID
        let version = UpdateConfig.currentVersion
        do {
            let result = try await Task.detached {
                try UpdateInstaller.stage(dmg: dmg, currentApp: current, expectedBundleID: bundleID, currentVersion: version)
            }.value
            try UpdateInstaller.swapAndRelaunch(staged: result.staged, target: result.target, current: current)
            try? FileManager.default.removeItem(at: dmg)
            NSApp.terminate(nil)
        } catch UpdateError.notReplaceable {
            // e.g. running from a read-only location: let the user drag the new version in.
            NSWorkspace.shared.open(dmg)
            showSheet = false
            phase = .manualInstall
        } catch {
            try? FileManager.default.removeItem(at: dmg)
            phase = .failed(error.localizedDescription)
        }
    }

    /// Release notes are written in several languages separated by "---"; show the user's language.
    var localizedNotes: String {
        guard let notes = release?.notes, !notes.isEmpty else { return "" }
        let sections = notes.components(separatedBy: "\n---\n")
        let marker: String
        switch AppLanguage.current {
        case .en: marker = "**English**"
        case .tr: marker = "**Türkçe**"
        case .ptBR: marker = "**Português"
        }
        return (sections.first { $0.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(marker) } ?? notes)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Views

struct UpdateSheet: View {
    @Environment(Updater.self) private var updater

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("A new version of YUCE Cleaner is available!")).font(.title3.bold())
                    Text(L("YUCE Cleaner %@ is available — you have %@. Would you like to install it now?",
                           updater.release?.version ?? "", UpdateConfig.currentVersion))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack {
                Text(L("Release Notes")).font(.headline)
                Spacer()
                if let url = updater.release?.pageURL {
                    Link(L("View on GitHub"), destination: url).font(.callout)
                }
            }
            ScrollView {
                Text((try? AttributedString(markdown: updater.localizedNotes,
                                            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                     ?? AttributedString(updater.localizedNotes))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(10)
            }
            .frame(height: 200)
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))

            switch updater.phase {
            case .downloading:
                ProgressView(value: updater.progress) {
                    Text(L("Downloading… %ld%%", Int(updater.progress * 100))).font(.caption)
                }
            case .installing:
                HStack { ProgressView().controlSize(.small); Text(L("Installing…")).font(.caption) }
            default:
                EmptyView()
            }

            HStack {
                Button(L("Skip This Version")) { updater.skip() }
                Spacer()
                Button(L("Remind Me Later")) { updater.later() }
                    .keyboardShortcut(.cancelAction)
                Button(L("Install and Relaunch")) { Task { await updater.install() } }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
            .disabled(updater.isBusy)
        }
        .padding(20)
        .frame(width: 600)
        .interactiveDismissDisabled(updater.isBusy)
    }
}

/// Alerts for manual checks and failures, attached to the main window.
struct UpdateAlerts: ViewModifier {
    @Environment(Updater.self) private var updater

    func body(content: Content) -> some View {
        @Bindable var updater = updater
        content
            .sheet(isPresented: $updater.showSheet) { UpdateSheet() }
            .alert(L("You're up to date!"), isPresented: Binding(
                get: { updater.phase == .upToDate }, set: { if !$0 { updater.phase = .idle } })) {
                Button(L("OK")) { updater.phase = .idle }
            } message: {
                Text(L("YUCE Cleaner %@ is the latest version.", UpdateConfig.currentVersion))
            }
            .alert(L("Update failed"), isPresented: Binding(
                get: { if case .failed = updater.phase { return true } else { return false } },
                set: { if !$0 { updater.phase = .idle } })) {
                Button(L("OK")) { updater.phase = .idle }
                Button(L("Open Download Page")) {
                    NSWorkspace.shared.open(updater.release?.pageURL
                        ?? URL(string: "https://github.com/\(UpdateConfig.repo)/releases/latest")!)
                    updater.phase = .idle
                }
            } message: {
                if case .failed(let msg) = updater.phase { Text(msg) }
            }
            .alert(L("Install the update manually"), isPresented: Binding(
                get: { updater.phase == .manualInstall }, set: { if !$0 { updater.phase = .idle } })) {
                Button(L("OK")) { updater.phase = .idle }
            } message: {
                Text(UpdateError.notReplaceable.localizedDescription)
            }
    }
}

/// Banner shown on the overview screen when an update is waiting.
struct UpdateBanner: View {
    @Environment(Updater.self) private var updater

    var body: some View {
        if let r = updater.availableRelease {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill").font(.title2).foregroundStyle(Color.accentColor)
                Text(L("YUCE Cleaner %@ is available.", r.version)).bold()
                Spacer()
                Button(L("Update…")) { updater.showSheet = true }
                    .buttonStyle(.borderedProminent)
            }
            .padding(12)
            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        }
    }
}

/// "Version 1.2.0 · Check for Updates" line at the bottom of the overview.
struct VersionFooter: View {
    @Environment(Updater.self) private var updater

    var body: some View {
        HStack(spacing: 8) {
            Text(L("Version %@", UpdateConfig.currentVersion)).foregroundStyle(.secondary)
            Text("·").foregroundStyle(.tertiary)
            Button(updater.phase == .checking ? L("Checking…") : L("Check for Updates…")) {
                Task { await updater.check(manual: true) }
            }
            .buttonStyle(.link)
            .disabled(updater.isBusy)
        }
        .font(.callout)
        .frame(maxWidth: .infinity)
    }
}

/// App menu items: "Check for Updates…" and the automatic-check toggle.
struct UpdateCommands: Commands {
    let updater: Updater

    var body: some Commands {
        CommandGroup(after: .appInfo) {
            Button(L("Check for Updates…")) { Task { await updater.check(manual: true) } }
                .disabled(updater.isBusy)
            Toggle(L("Automatically Check for Updates"), isOn: Binding(
                get: { updater.autoCheck }, set: { updater.autoCheck = $0 }))
        }
    }
}
