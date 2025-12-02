import SwiftUI
import Combine

// --- 主入口 (Main Entry) ---

struct ContentView: View {
    // 初始化 ViewModel，它会自动管理所有数据
    @StateObject var viewModel = PaperDoViewModel()
    
    var body: some View {
        ZStack {
            // [新增] 全局纯白背景，确保整个 App 看起来是一体的
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航栏
                AtmosphericHeaderView(currentView: $viewModel.currentView)
                    .background(Color.white) // 确保导航栏本身是不透明的白色
                    // [修改] 添加极淡的阴影，使导航栏微微悬浮，与下方内容自然区分
                    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                    .zIndex(1) // 确保阴影盖在内容之上
                
                // 主内容滚动区
                Group {
                    if viewModel.currentView == "inspiration" {
                        // 灵感界面自带 ScrollView
                        InspirationView(viewModel: viewModel)
                    } else if viewModel.currentView == "projects" {
                        // Project View 自带复杂的滚动逻辑
                        AtmosphericProjectView(viewModel: viewModel)
                    } else {
                        // Tasks 和 Habits
                        ScrollView {
                            VStack(spacing: 40) {
                                if viewModel.currentView == "tasks" {
                                    AtmosphericTaskView(viewModel: viewModel)
                                } else if viewModel.currentView == "habits" {
                                    AtmosphericHabitView(viewModel: viewModel)
                                }
                            }
                            .padding(.top, 24) // 调整顶部间距
                            .padding(.bottom, 60)
                            .padding(.horizontal, 0) // [修改] 移除水平内边距，让内容（如分割线）能撑满
                            .frame(maxWidth: 1100)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                // [重点修改] 移除原来的浅灰背景，改为纯白，消除割裂感
                .background(Color.white)
            }
            
            // 沉浸式专注模式覆盖层
            if viewModel.showImmersiveMode {
                ImmersiveDayView(viewModel: viewModel, date: viewModel.immersiveDate, isPresented: $viewModel.showImmersiveMode)
                    .zIndex(100)
                    .transition(.opacity.animation(.easeInOut))
            }
        }
        .frame(minWidth: 1200, minHeight: 700)
    }
}

// --- 顶部导航栏组件 ---

struct AtmosphericHeaderView: View {
    @Binding var currentView: String
    
    var body: some View {
        HStack(alignment: .center) {
            // 左侧 Logo
            Text("Omni DO.")
                .font(.system(size: 24, weight: .heavy, design: .serif))
                .foregroundColor(.black)
            
            Spacer()
            
            // 中间导航按钮组
            HStack(spacing: 32) {
                TabButton(title: "Tasks", id: "tasks", current: $currentView)
                TabButton(title: "Projects", id: "projects", current: $currentView)
                TabButton(title: "Habits", id: "habits", current: $currentView)
                TabButton(title: "Inspiration", id: "inspiration", current: $currentView)
            }
            
            Spacer()
            
            // [修改] 右侧区域
            // 移除了原本没用的“搜索”和“用户”按钮。
            // 为了让中间的导航按钮视觉上保持绝对居中，这里放一个与左侧 Logo 一模一样但隐形的 Text 作为占位符。
            Text("Omni DO.")
                .font(.system(size: 24, weight: .heavy, design: .serif))
                .foregroundColor(.clear) // 隐形
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 24)
    }
}

// --- 导航按钮组件 ---

struct TabButton: View {
    let title: String
    let id: String
    @Binding var current: String
    
    var isActive: Bool { current == id }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                current = id
            }
        }) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: isActive ? .bold : .medium))
                    .foregroundColor(isActive ? .black : .gray)
                
                // 选中指示点
                if isActive {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 5, height: 5)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 5, height: 5)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
