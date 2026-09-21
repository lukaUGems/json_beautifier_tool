import Cocoa
import WebKit
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    var window: NSWindow!
    var webView: WKWebView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let frame = NSRect(x: 0, y: 0, width: 1040, height: 680)
        window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "JSON Viewer"
        window.titlebarAppearsTransparent = false
        window.center()
        window.setFrameAutosaveName("JSONViewerMainWindow")
        window.minSize = NSSize(width: 640, height: 420)

        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "saveFile")
        webView = WKWebView(frame: frame, configuration: config)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.width, .height]
        window.contentView = webView

        // Load the bundled UI; fall back to embedded copy if missing.
        if let url = Bundle.main.url(forResource: "ui", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            webView.loadHTMLString("<h2 style='font-family:sans-serif;padding:40px'>UI resource missing.</h2>", baseURL: nil)
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // Open external http(s) links in the default browser instead of inside the app.
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url,
           url.scheme == "http" || url.scheme == "https" {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    // Receive a save request from the web UI and show the native save panel.
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "saveFile",
              let dict = message.body as? [String: Any] else { return }
        let content = dict["content"] as? String ?? ""
        let suggested = dict["name"] as? String ?? "formatted.json"

        let panel = NSSavePanel()
        panel.title = "Save JSON"
        panel.nameFieldStringValue = suggested
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        if #available(macOS 11.0, *), let jsonType = UTType(filenameExtension: "json") {
            panel.allowedContentTypes = [jsonType]
        }

        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let url = panel.url else {
                self?.notifySaveResult(saved: false, name: "")
                return
            }
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
                self?.notifySaveResult(saved: true, name: url.lastPathComponent)
            } catch {
                self?.notifySaveResult(saved: false, name: error.localizedDescription)
            }
        }
    }

    private func notifySaveResult(saved: Bool, name: String) {
        let escaped = name
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        let js = "window.onNativeSaved && window.onNativeSaved(\(saved), '\(escaped)')"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)

// Minimal menu so Cmd+Q, Cmd+C/V/X/A, Cmd+W work natively.
let mainMenu = NSMenu()
let appMenuItem = NSMenuItem()
mainMenu.addItem(appMenuItem)
let appMenu = NSMenu()
appMenu.addItem(withTitle: "About JSON Viewer", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
appMenu.addItem(NSMenuItem.separator())
appMenu.addItem(withTitle: "Hide JSON Viewer", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
appMenu.addItem(withTitle: "Quit JSON Viewer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
appMenuItem.submenu = appMenu

// Edit menu (enables copy/paste/select-all in the web view).
let editMenuItem = NSMenuItem()
mainMenu.addItem(editMenuItem)
let editMenu = NSMenu(title: "Edit")
editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
editMenu.addItem(NSMenuItem.separator())
editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
editMenuItem.submenu = editMenu

let windowMenuItem = NSMenuItem()
mainMenu.addItem(windowMenuItem)
let windowMenu = NSMenu(title: "Window")
windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
windowMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
windowMenuItem.submenu = windowMenu

app.mainMenu = mainMenu

let delegate = AppDelegate()
app.delegate = delegate
app.run()
