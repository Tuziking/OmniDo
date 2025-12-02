import SwiftUI

// --- 1. 使用 AppDelegate 确保生命周期稳定 ---
class AppDelegate: NSObject, NSApplicationDelegate {
    // 强引用持有 MenuBarManager，防止被释放
    var menuBarManager: MenuBarManager?
}

@main
struct OmniDoApp: App {
    // 2. 绑定 AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // 3. 初始化 ViewModel
    @StateObject var viewModel = PaperDoViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .onAppear {
                    // 4. 当主窗口加载时，初始化菜单栏管理器
                    // 我们将它赋值给 appDelegate，确保它不会随着 View 的刷新而丢失
                    if appDelegate.menuBarManager == nil {
                        appDelegate.menuBarManager = MenuBarManager(viewModel: viewModel)
                    }
                }
        }
        // 隐藏窗口标题栏，实现沉浸式白底
        .windowStyle(.hiddenTitleBar)
    }
}
