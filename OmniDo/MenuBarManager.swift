import SwiftUI
import AppKit

// --- 菜单栏管理器 ---
// 负责在 macOS 顶部菜单栏显示图标，并处理点击事件
class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem!
    private var viewModel: PaperDoViewModel
    
    init(viewModel: PaperDoViewModel) {
        self.viewModel = viewModel
        super.init()
        // 在主线程延迟初始化，确保 UI 环境就绪
        DispatchQueue.main.async {
            self.setupMenuBar()
        }
    }
    
    private func setupMenuBar() {
        // 创建不定长的状态栏项目
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // 设置图标 (这里使用 SF Symbol，你可以换成自己的 App 图标)
            button.image = NSImage(systemSymbolName: "star", accessibilityDescription: "Omni DO")
            // 设置点击事件的目标和动作
            button.target = self
            button.action = #selector(handleMouseClick(_:))
            // 关键：告诉系统我们不仅想监听默认点击，还要监听右键抬起
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    // 处理点击事件分发
    @objc private func handleMouseClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // --- 右键：显示未来 DDL 菜单 ---
            showDeadlinesMenu()
        } else {
            // --- 左键：打开/激活主窗口 ---
            activateMainWindow()
        }
    }
    
    private func showDeadlinesMenu() {
        let menu = NSMenu()
        
        // 1. 获取并排序未来的未完成任务
        let now = Date()
        let futureTasks = viewModel.todos
            .filter { !$0.completed && $0.deadline > now }
            .sorted { $0.deadline < $1.deadline }
            .prefix(8) // 限制显示最近 8 个，避免菜单过长
        
        // 2. 构建菜单标题
        let titleItem = NSMenuItem(title: "Upcoming Deadlines", action: nil, keyEquivalent: "")
        // 加粗标题字体
        titleItem.attributedTitle = NSAttributedString(
            string: "Upcoming Deadlines",
            attributes: [.font: NSFont.boldSystemFont(ofSize: 13)]
        )
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        
        // 3. 构建任务列表项
        if futureTasks.isEmpty {
            let emptyItem = NSMenuItem(title: "No upcoming deadlines 🎉", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd HH:mm"
            
            for task in futureTasks {
                // 计算剩余时间
                let timeLeft = task.deadline.timeIntervalSince(now)
                let hoursLeft = Int(timeLeft / 3600)
                let daysLeft = hoursLeft / 24
                
                var timeDisplay = ""
                if daysLeft > 0 {
                    timeDisplay = "\(daysLeft)d left"
                } else {
                    timeDisplay = "\(hoursLeft)h left"
                }
                
                // 截断过长的标题
                let title = task.title.count > 25 ? String(task.title.prefix(25)) + "..." : task.title
                
                let item = NSMenuItem(title: "\(title)  (\(timeDisplay))", action: #selector(activateMainWindow), keyEquivalent: "")
                item.target = self
                menu.addItem(item)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 4. 添加退出选项
        let quitItem = NSMenuItem(title: "Quit Omni DO", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        // 5. 弹出菜单
        statusItem.menu = menu // 临时关联菜单
        statusItem.button?.performClick(nil) // 触发系统菜单弹出逻辑
        statusItem.menu = nil // 弹出后立即断开关联，否则下次点击（包括左键）都会直接弹出菜单
    }
    
    @objc private func activateMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        // 尝试找到并前置第一个窗口
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
