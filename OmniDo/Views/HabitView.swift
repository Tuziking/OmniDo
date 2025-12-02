import SwiftUI

struct AtmosphericHabitView: View {
    @ObservedObject var viewModel: PaperDoViewModel
    
    // --- 状态管理 ---
    @State private var showAddHabitModal = false
    @State private var newHabitName = ""
    
    var body: some View {
        ZStack(alignment: .top) {
            // 1. 全局背景色 (统一)
            Color(red: 0.99, green: 0.99, blue: 0.99).ignoresSafeArea()
            
            // 主容器 (限制最大宽度，居中布局)
            VStack(alignment: .leading, spacing: 0) {
                
                // 2. Header 区域 (统一风格)
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Habits")
                            .font(.system(size: 24, weight: .bold, design: .serif)) // 统一 Serif
                            .foregroundColor(.black)
                        
                        Text("Build consistency")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                            .tracking(0.5)
                    }
                    
                    Spacer()
                    
                    // "New Habit" 按钮 (统一胶囊风格)
                    Button(action: {
                        newHabitName = ""
                        withAnimation(.spring()) { showAddHabitModal = true }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("New Habit")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 32) // 统一边距
                .padding(.vertical, 24)
                
                // 3. 习惯列表
                if viewModel.habits.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "leaf")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.2))
                        Text("No habits yet. Start small.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        // 统一 Grid 布局参数
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 20)], spacing: 20) {
                            ForEach(viewModel.habits) { habit in
                                AtmosphericHabitCard(habit: habit, viewModel: viewModel)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            // 模拟删除逻辑
                                            if let index = viewModel.habits.firstIndex(where: { $0.id == habit.id }) {
                                                withAnimation { viewModel.habits.remove(at: index) }
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                    }
                }
            }
            .frame(maxWidth: 1000) // 限制最大宽度
            .frame(maxHeight: .infinity)
            .zIndex(1)
            
            // 4. 自定义模态弹窗
            if showAddHabitModal {
                HabitModernInputAlert(
                    isPresented: $showAddHabitModal,
                    title: "New Habit",
                    placeholder: "E.g. Meditation",
                    text: $newHabitName,
                    actionButtonText: "Start",
                    onCommit: {
                        if !newHabitName.isEmpty {
                            let newHabit = Habit(name: newHabitName, records: [:])
                            viewModel.habits.append(newHabit)
                            newHabitName = ""
                        }
                    }
                )
            }
        }
    }
}

// --- 习惯卡片 (风格优化) ---
struct AtmosphericHabitCard: View {
    let habit: Habit
    @ObservedObject var viewModel: PaperDoViewModel
    
    @State private var currentMonth = Date()
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    let weekDays = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 1. 卡片头部：名称 + 统计 + 月份切换
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.system(size: 16, weight: .bold)) // 稍微调小一点，更精致
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        Text("\(habit.records.count) days")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // 独立的迷你月份切换器 (更极简)
                HStack(spacing: 8) {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Text(monthFormatter.string(from: currentMonth))
                        .font(.system(size: 12, weight: .semibold))
                        .frame(minWidth: 60, alignment: .center)
                    
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(4)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
            
            Divider().opacity(0.3)
            
            // 2. 日历网格
            VStack(spacing: 8) { // 间距更紧凑
                // 星期表头
                LazyVGrid(columns: columns) {
                    ForEach(weekDays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                
                // 日期格子
                LazyVGrid(columns: columns, spacing: 8) {
                    let days = daysInMonth()
                    let offset = firstWeekday()
                    let totalSlots = 42 // 固定显示 6 行 (7 * 6 = 42)
                    
                    // 空白填充 + 日期 + 尾部空白填充，统一在循环中处理
                    ForEach(0..<totalSlots, id: \.self) { index in
                        if index < offset || index >= offset + days.count {
                            // 占位符，保持对齐
                            Color.clear.frame(width: 28, height: 28)
                        } else {
                            let date = days[index - offset]
                            let isCompleted = isHabitCompleted(date: date)
                            let isToday = Calendar.current.isDateInToday(date)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    viewModel.toggleHabit(habitId: habit.id, date: date)
                                }
                            }) {
                                ZStack {
                                    // 圆形背景
                                    Circle()
                                        .fill(isCompleted ? Color.black : (isToday ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05)))
                                        .frame(width: 28, height: 28) // 稍微缩小
                                        // 如果是今天且未完成，加个边框
                                        .overlay(
                                            Circle()
                                                .stroke(isToday && !isCompleted ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                                        )
                                    
                                    // 日期数字
                                    Text("\(Calendar.current.component(.day, from: date))")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(isCompleted ? .white : (isToday ? .blue : .gray))
                                }
                            }
                            .buttonStyle(HabitScaleButtonStyle())
                        }
                    }
                }
            }
        }
        .padding(20) // 统一内边距
        .background(Color.white)
        .cornerRadius(20) // 统一圆角
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5) // 更轻柔的阴影
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.02), lineWidth: 1)
        )
    }
    
    // --- 内部逻辑 helper ---
    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    var monthFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f
    }
    
    func isHabitCompleted(date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: date)
        return habit.records[key] == true
    }
    
    func daysInMonth() -> [Date] {
        guard let range = Calendar.current.range(of: .day, in: .month, for: currentMonth) else { return [] }
        let components = Calendar.current.dateComponents([.year, .month], from: currentMonth)
        return range.compactMap { day -> Date? in
            var dateComponents = components
            dateComponents.day = day
            return Calendar.current.date(from: dateComponents)
        }
    }
    
    func firstWeekday() -> Int {
        let components = Calendar.current.dateComponents([.year, .month], from: currentMonth)
        guard let firstDay = Calendar.current.date(from: components) else { return 0 }
        return Calendar.current.component(.weekday, from: firstDay) - 1
    }
}

// --- 通用按钮缩放效果 ---
struct HabitScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// --- 美化后的输入弹窗 (与 ProjectView 统一) ---
struct HabitModernInputAlert: View {
    @Binding var isPresented: Bool
    let title: String
    let placeholder: String
    @Binding var text: String
    var actionButtonText: String = "Confirm"
    let onCommit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.2).ignoresSafeArea() // 统一遮罩透明度
                .onTapGesture { withAnimation(.spring()) { isPresented = false } }
            
            VStack(spacing: 20) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .serif)) // 统一 Serif
                    .foregroundColor(.black)
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 15))
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(white: 0.97))
                    .cornerRadius(10)
                    .onSubmit {
                        onCommit()
                        withAnimation(.spring()) { isPresented = false }
                    }
                
                HStack(spacing: 12) {
                    Button(action: { withAnimation(.spring()) { isPresented = false } }) {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        onCommit()
                        withAnimation(.spring()) { isPresented = false }
                    }) {
                        Text(actionButtonText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            .frame(width: 320)
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
        .zIndex(100)
    }
}
