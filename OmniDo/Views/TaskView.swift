import SwiftUI

// 主视图：包含 Header, 模式切换, 以及对 ModernDatePicker 的调用
struct AtmosphericTaskView: View {
    @ObservedObject var viewModel: PaperDoViewModel
    
    // --- 状态 ---
    @State private var newTaskTitle = ""
    @State private var newTaskDate = Date()
    @State private var showDatePicker = false
    
    // 视图模式状态 (默认改为 Timeline)
    @State private var isTimelineMode = true
    
    // 日历模式专用状态
    @State private var browsingMonth = Date()
    @State private var selectedDate = Date()
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            
            // 1. 全局背景色 (强制纯白并忽略安全区域)
            Color.white.ignoresSafeArea()
            
            // --- 1. 主内容层 ---
            VStack(alignment: .center, spacing: 0) { // 整体居中
                
                // 顶部 Header (固定在顶部)
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(isTimelineMode ? "Timeline" : "Calendar")
                                .font(.system(size: 24, weight: .bold, design: .serif))
                                .foregroundColor(.black)
                                .id(isTimelineMode ? "Timeline" : "Calendar")
                                .transition(.opacity)
                            
                            // 副标题
                            Text(isTimelineMode ? "Upcoming" : browsingMonth.formatted(.dateTime.month().year()))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    // 右侧控制区
                    HStack(spacing: 12) {
                        
                        // 视图切换
                        HStack(spacing: 0) {
                            ViewModeButton(icon: "calendar", isSelected: !isTimelineMode) {
                                withAnimation(.spring(response: 0.3)) { isTimelineMode = false }
                            }
                            ViewModeButton(icon: "list.bullet", isSelected: isTimelineMode) {
                                withAnimation(.spring(response: 0.3)) { isTimelineMode = true }
                            }
                        }
                        .padding(3)
                        .background(Color(white: 0.96))
                        .cornerRadius(10)
                        
                        // 快速添加栏
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.leading, 8)
                            
                            TextField("New task...", text: $newTaskTitle)
                                .font(.system(size: 13))
                                .textFieldStyle(.plain)
                                .frame(width: 120)
                                .onSubmit { addTask() }
                            
                            // 日期选择触发器
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) { showDatePicker.toggle() }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                    Text(newTaskDate, style: .time)
                                }
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(showDatePicker ? .white : .gray)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(showDatePicker ? Color.black : Color.gray.opacity(0.1))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            
                            // 添加按钮
                            Button(action: addTask) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(newTaskTitle.isEmpty ? Color.gray.opacity(0.3) : Color.black)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .disabled(newTaskTitle.isEmpty)
                            .padding(.trailing, 4)
                        }
                        .padding(4)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.1), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 24)
                .frame(maxWidth: 1000)
                .background(Color.white)
                .zIndex(1)
                
                // 内容区域
                ZStack(alignment: .topLeading) {
                    if isTimelineMode {
                        TimelineLayoutView(viewModel: viewModel)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    } else {
                        CalendarLayoutView(
                            viewModel: viewModel,
                            browsingMonth: $browsingMonth,
                            selectedDate: $selectedDate
                        )
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: 1000)
                .frame(maxHeight: .infinity)
                .background(Color.white)
                .zIndex(0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            
            // --- 2. 遮罩层 ---
            if showDatePicker {
                Color.black.opacity(0.05)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) { showDatePicker = false }
                    }
                    .zIndex(10)
                
                ModernDatePicker(selection: $newTaskDate) {
                    withAnimation(.spring()) { showDatePicker = false }
                }
                .padding(.top, 80)
                .padding(.trailing, 24)
                .transition(.scale(scale: 0.95, anchor: .topTrailing).combined(with: .opacity))
                .zIndex(11)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
    
    func addTask() {
        if !newTaskTitle.isEmpty {
            withAnimation {
                viewModel.addTodo(title: newTaskTitle, date: newTaskDate)
                newTaskTitle = ""
            }
        }
    }
}

// 辅助组件：视图切换按钮
struct ViewModeButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .black : .gray)
                .frame(width: 32, height: 28)
                .background(isSelected ? Color.white : Color.clear)
                .cornerRadius(7)
                .shadow(color: isSelected ? Color.black.opacity(0.1) : .clear, radius: 1, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// ==========================================
// MARK: - Timeline Layout (Focus Future Edition)
// ==========================================

struct TimelineLayoutView: View {
    @ObservedObject var viewModel: PaperDoViewModel
    
    // 状态：控制历史记录是否展开
    @State private var showHistory = false
    
    // --- 数据处理 ---
    
    // 原始分组数据
    private var allGroups: [(date: Date, tasks: [TodoItem])] {
        let sortedTasks = viewModel.todos.sorted { $0.deadline < $1.deadline }
        let grouped = Dictionary(grouping: sortedTasks) { task -> Date in
            Calendar.current.startOfDay(for: task.deadline)
        }
        return grouped.sorted { $0.key < $1.key }.map { (date: $0.key, tasks: $0.value) }
    }
    
    // 拆分：过去 vs 未来 (以今天零点为界)
    private var splitGroups: (past: [(Date, [TodoItem])], upcoming: [(Date, [TodoItem])]) {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        
        let past = allGroups.filter { $0.date < startOfToday }
        let upcoming = allGroups.filter { $0.date >= startOfToday }
        
        return (past, upcoming)
    }
    
    var body: some View {
        let data = splitGroups
        
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) { // 使用 0 间距，由内部控制 padding
                    
                    // 1. 顶部空状态 (如果没有未来任务)
                    if data.upcoming.isEmpty && data.past.isEmpty {
                        emptyStateView
                    }
                    
                    // 2. 历史区域 (Past)
                    if !data.past.isEmpty {
                        VStack(spacing: 20) {
                            // 历史折叠开关
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    showHistory.toggle()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.arrow.circlepath")
                                    Text(showHistory ? "Hide History" : "Show History")
                                    
                                    // 统计过去任务数量
                                    let count = data.past.reduce(0) { $0 + $1.1.count }
                                    Text("(\(count))")
                                        .opacity(0.6)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .rotationEffect(.degrees(showHistory ? 180 : 0))
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                            .padding(.bottom, showHistory ? 10 : 0)
                            
                            // 展开的历史列表
                            if showHistory {
                                LazyVStack(spacing: 40) {
                                    ForEach(data.past, id: \.0) { group in
                                        TimelineGroupView(
                                            group: group,
                                            isPast: true,
                                            viewModel: viewModel
                                        )
                                        .opacity(0.6) // 过去任务稍微淡化
                                        .saturation(0.5) // 降低饱和度
                                    }
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                                
                                // 分割线：过去与现在的界限
                                Divider()
                                    .padding(.vertical, 20)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 24)
                    }
                    
                    // 3. 未来区域 (Upcoming)
                    LazyVStack(spacing: 40) {
                        ForEach(data.upcoming, id: \.0) { group in
                            TimelineGroupView(
                                group: group,
                                isPast: false,
                                viewModel: viewModel
                            )
                            .id(group.0) // 锚点 ID
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, data.past.isEmpty ? 24 : 0) // 如果没有历史，顶部留白
                    .padding(.bottom, 100)
                }
            }
            .onAppear {
                // 视图加载时，自动滚动到第一个即将到来的日期
                if let firstUpcoming = data.upcoming.first?.0 {
                    //稍微延迟一点以等待布局完成
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring) {
                            proxy.scrollTo(firstUpcoming, anchor: .top)
                        }
                    }
                }
            }
        }
        .background(Color.white)
    }
    
    // 空状态视图
    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wind")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.15))
            Text("All clear. Enjoy your day!")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

// ==========================================
// MARK: - Subcomponent: Timeline Group
// ==========================================

struct TimelineGroupView: View {
    let group: (date: Date, tasks: [TodoItem])
    let isPast: Bool
    @ObservedObject var viewModel: PaperDoViewModel
    
    // 判断是否是今天
    var isToday: Bool { Calendar.current.isDateInToday(group.date) }
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // 1. 左侧日期列
            VStack(alignment: .trailing, spacing: 4) {
                // 月份
                Text(monthAbbrevFormatter.string(from: group.date).uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isToday ? .blue : .gray)
                    .tracking(1)
                
                // 日期数字
                Text("\(Calendar.current.component(.day, from: group.date))")
                    .font(.system(size: 28, weight: isToday ? .heavy : .bold)) // 今天字体更粗
                    .foregroundColor(isToday ? .blue : .black)
                    .scaleEffect(isToday ? 1.1 : 1.0, anchor: .trailing) // 今天稍微放大
                
                // 星期几
                Text(weekdayFormatter.string(from: group.date))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isToday ? .blue.opacity(0.6) : .gray.opacity(0.6))
            }
            .frame(width: 50)
            .padding(.top, 2)
            
            // 2. 时间轴装饰
            VStack(spacing: 0) {
                // 节点圆圈
                ZStack {
                    if isToday {
                        // 今天的呼吸光晕效果
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 18, height: 18)
                    }
                    Circle()
                        .fill(isToday ? Color.blue : (isPast ? Color.gray.opacity(0.3) : Color.black))
                        .frame(width: isToday ? 10 : 8, height: isToday ? 10 : 8)
                }
                .frame(width: 18, height: 18)
                .padding(.top, 10) // 对齐第一行任务中心
                
                // 竖线 (只有当有后续内容时才延伸)
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                isToday ? Color.blue.opacity(0.5) : Color.gray.opacity(0.2),
                                Color.gray.opacity(0.1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2)
                    .padding(.top, 4)
            }
            
            // 3. 任务列表
            VStack(spacing: 16) {
                // 今天的特殊标头 "TODAY"
                if isToday {
                    HStack {
                        Text("TODAY")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(2)
                            .foregroundColor(.blue.opacity(0.8))
                        
                        VStack { Divider().background(Color.blue) }
                    }
                    .padding(.bottom, 4)
                }
                
                ForEach(group.tasks) { task in
                    TimelineTaskRow(todo: task, viewModel: viewModel)
                }
            }
            .padding(.top, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // Formatters
    var monthAbbrevFormatter: DateFormatter { let f = DateFormatter(); f.dateFormat = "MMM"; return f }
    var weekdayFormatter: DateFormatter { let f = DateFormatter(); f.dateFormat = "EEE"; return f }
}

// --- Timeline 专用任务行 (显示倒计时和具体时间) ---
struct TimelineTaskRow: View {
    let todo: TodoItem
    @ObservedObject var viewModel: PaperDoViewModel
    
    // 计算剩余时间逻辑 (精确到小时/分钟)
    private var timeStatus: (text: String, color: Color, icon: String) {
        let now = Date()
        let diff = todo.deadline.timeIntervalSince(now)
        
        if todo.completed {
            return ("Done", .gray.opacity(0.5), "checkmark.circle.fill")
        }
        
        if diff < 0 {
            // 已过期
            let absDiff = abs(diff)
            let days = Int(absDiff / 86400)
            let hours = Int((absDiff.truncatingRemainder(dividingBy: 86400)) / 3600)
            
            var text = "Overdue"
            if days > 0 {
                text += " \(days)d \(hours)h"
            } else if hours > 0 {
                text += " \(hours)h"
            } else {
                let mins = Int(absDiff / 60)
                text += " \(max(1, mins))m"
            }
            return (text, .red, "exclamationmark.circle.fill")
        } else if diff < 3600 {
            // 少于1小时
            let mins = Int(diff / 60)
            return ("\(max(1, mins))m left", .orange, "hourglass")
        } else if diff < 86400 {
            // 少于24小时 (显示 小时 和 分钟)
            let hours = Int(diff / 3600)
            let mins = Int((diff.truncatingRemainder(dividingBy: 3600)) / 60)
            if hours > 0 {
                return ("\(hours)h \(mins)m left", .blue, "clock")
            } else {
                return ("\(mins)m left", .orange, "hourglass")
            }
        } else {
            // 超过1天 (显示 天 和 小时)
            let days = Int(diff / 86400)
            let hours = Int((diff.truncatingRemainder(dividingBy: 86400)) / 3600)
            return ("\(days)d \(hours)h left", .gray, "calendar")
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // 勾选按钮
            Button(action: { withAnimation(.spring(response: 0.3)) { viewModel.toggleTodo(todo.id) } }) {
                Image(systemName: todo.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(todo.completed ? .gray.opacity(0.5) : (timeStatus.color == .red ? .red : .black.opacity(0.8)))
            }
            .buttonStyle(.plain)
            
            // 任务内容区
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.system(size: 16, weight: .medium))
                    .strikethrough(todo.completed)
                    .foregroundColor(todo.completed ? .gray.opacity(0.6) : .black)
                
                HStack(spacing: 10) {
                    // 具体 DDL 时间 (例如 14:30)
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text(todo.deadline, style: .time)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    
                    // 倒计时胶囊
                    HStack(spacing: 4) {
                        Image(systemName: timeStatus.icon)
                            .font(.system(size: 10))
                        Text(timeStatus.text)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(timeStatus.color.opacity(0.1))
                    .foregroundColor(timeStatus.color)
                    .cornerRadius(6)
                }
            }
            
            Spacer()
            
            // 删除按钮
            Button(action: { withAnimation { viewModel.deleteTodo(todo.id) } }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray.opacity(0.3))
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(todo.completed ? Color.gray.opacity(0.1) : (timeStatus.color == .red ? Color.red.opacity(0.2) : Color.gray.opacity(0.1)), lineWidth: 1)
        )
    }
}


// ==========================================
// MARK: - Calendar Layout (保持原样)
// ==========================================

struct CalendarLayoutView: View {
    @ObservedObject var viewModel: PaperDoViewModel
    @Binding var browsingMonth: Date
    @Binding var selectedDate: Date
    
    var tasksForSelectedDate: [TodoItem] {
        viewModel.todos.filter { Calendar.current.isDate($0.deadline, inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                
                // 日历区域
                VStack(spacing: 24) {
                    HStack {
                        Spacer()
                        HStack(spacing: 24) {
                            Button(action: { changeMonth(by: -1) }) { Image(systemName: "arrow.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.black.opacity(0.7)) }.buttonStyle(.plain)
                            Text(monthFormatter.string(from: browsingMonth)).font(.system(size: 16, weight: .bold)).foregroundColor(.black)
                            Button(action: { changeMonth(by: 1) }) { Image(systemName: "arrow.right").font(.system(size: 16, weight: .semibold)).foregroundColor(.black.opacity(0.7)) }.buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    
                    HStack {
                        ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                            Text(day).font(.system(size: 11, weight: .bold)).foregroundColor(.gray.opacity(0.5)).frame(maxWidth: .infinity)
                        }
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                        let days = daysInMonth()
                        let offset = firstWeekday()
                        ForEach(0..<offset, id: \.self) { _ in Color.clear }
                        ForEach(days, id: \.self) { date in
                            CalendarDayCell(
                                date: date,
                                isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                isToday: Calendar.current.isDateInToday(date),
                                tasksCount: tasksCountForDate(date),
                                onTap: { withAnimation { selectedDate = date } }
                            )
                        }
                    }
                }
                .padding(.horizontal, 4)
                
                Divider().opacity(0.5)
                
                // 任务列表
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(dateHeaderFormatter.string(from: selectedDate)).font(.system(size: 18, weight: .bold)).foregroundColor(.black)
                        Spacer()
                        if !tasksForSelectedDate.isEmpty {
                            Text("\(tasksForSelectedDate.count) Tasks").font(.system(size: 12, weight: .bold)).foregroundColor(.gray)
                        }
                    }
                    
                    if tasksForSelectedDate.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "cup.and.saucer").font(.system(size: 32)).foregroundColor(.gray.opacity(0.15))
                                Text("No plans yet.").font(.system(size: 14)).foregroundColor(.gray.opacity(0.4))
                            }
                            Spacer()
                        }
                        .padding(.vertical, 48)
                    } else {
                        ForEach(tasksForSelectedDate) { todo in
                            // 复用通用的 TaskRow 或者也可以用 TimelineTaskRow
                            TimelineTaskRow(todo: todo, viewModel: viewModel)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 60)
        }
        .background(Color.white)
    }
    
    // ... 辅助函数 ...
    func changeMonth(by value: Int) { if let newDate = Calendar.current.date(byAdding: .month, value: value, to: browsingMonth) { browsingMonth = newDate } }
    func tasksCountForDate(_ date: Date) -> Int { viewModel.todos.filter { !$0.completed && Calendar.current.isDate($0.deadline, inSameDayAs: date) }.count }
    func daysInMonth() -> [Date] {
        guard let range = Calendar.current.range(of: .day, in: .month, for: browsingMonth) else { return [] }
        let components = Calendar.current.dateComponents([.year, .month], from: browsingMonth)
        return range.compactMap { day -> Date? in var dateComponents = components; dateComponents.day = day; return Calendar.current.date(from: dateComponents) }
    }
    func firstWeekday() -> Int {
        let components = Calendar.current.dateComponents([.year, .month], from: browsingMonth)
        guard let firstDay = Calendar.current.date(from: components) else { return 0 }
        return Calendar.current.component(.weekday, from: firstDay) - 1
    }
    var monthFormatter: DateFormatter { let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f }
    var dateHeaderFormatter: DateFormatter { let f = DateFormatter(); f.dateStyle = .full; return f }
}

// 独立的日历格子组件 (保持不变)
struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let tasksCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 14, weight: isSelected ? .bold : (isToday ? .bold : .regular)))
                    .foregroundColor(isSelected ? .white : (isToday ? .blue : .black))
                
                if tasksCount > 0 {
                    Circle().fill(isSelected ? .white : (tasksCount > 2 ? Color.red : Color.black))
                        .frame(width: 4, height: 4)
                } else {
                    Color.clear.frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 44)
            .background(isSelected ? Color.black : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isToday && !isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// --- [整合 & 优化] 日期选择器容器 ---
// 调整了整体高度和内边距，使其更加紧凑
struct ModernDatePicker: View {
    @Binding var selection: Date
    var onDone: () -> Void
    
    @State private var viewMode: DatePickerMode = .date
    
    enum DatePickerMode {
        case date, time
    }
    
    var body: some View {
        VStack(spacing: 16) { // 间距 20 -> 16
            // 顶部切换栏
            HStack(spacing: 0) {
                Button(action: { withAnimation { viewMode = .date } }) {
                    VStack(spacing: 4) {
                        Text(selection, style: .date)
                            .font(.system(size: 13, weight: viewMode == .date ? .bold : .medium))
                            .foregroundColor(viewMode == .date ? .black : .gray)
                        
                        Capsule()
                            .fill(viewMode == .date ? Color.black : Color.clear)
                            .frame(height: 2)
                            .frame(width: 40)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                
                Button(action: { withAnimation { viewMode = .time } }) {
                    VStack(spacing: 4) {
                        Text(selection, style: .time)
                            .font(.system(size: 13, weight: viewMode == .time ? .bold : .medium))
                            .foregroundColor(viewMode == .time ? .black : .gray)
                        
                        Capsule()
                            .fill(viewMode == .time ? Color.black : Color.clear)
                            .frame(height: 2)
                            .frame(width: 40)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
            
            Divider()
            
            // 内容区域
            Group {
                if viewMode == .date {
                    AtmosphericCalendar(selection: $selection)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
                    AtmosphericClock(selection: $selection)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            // [优化] 高度从 380 减少到 310
            .frame(height: 250)
            
            // 底部按钮
            Button(action: onDone) {
                Text("Done")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10) // 12 -> 10
                    .background(Color.black)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(16) // 24 -> 16
        .frame(width: 300) // 宽度 340 -> 300
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.15), radius: 30, x: 0, y: 10)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.1), lineWidth: 1))
    }
}

// --- [优化] 紧凑型日历组件 ---
struct AtmosphericCalendar: View {
    @Binding var selection: Date
    @State private var currentMonth: Date
    
    init(selection: Binding<Date>) {
        self._selection = selection
        self._currentMonth = State(initialValue: selection.wrappedValue)
    }
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(spacing: 12) { // 间距 16 -> 12
            // 月份切换
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left").font(.system(size: 12, weight: .bold))
                }.buttonStyle(.plain).foregroundColor(.black)
                
                Spacer()
                
                Text(monthFormatter.string(from: currentMonth))
                    .font(.system(size: 14, weight: .bold, design: .serif))
                
                Spacer()
                
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                }.buttonStyle(.plain).foregroundColor(.black)
            }
            .padding(.horizontal, 4)
            
            // 星期头
            HStack {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 日期网格
            LazyVGrid(columns: columns, spacing: 4) { // 行间距 8 -> 4
                let days = daysInMonth()
                let offset = firstWeekday()
                let totalSlots = 42
                
                ForEach(0..<totalSlots, id: \.self) { index in
                    if index < offset || index >= offset + days.count {
                        Color.clear.frame(width: 28, height: 28) // 尺寸 32 -> 28
                    } else {
                        let date = days[index - offset]
                        let isSelected = Calendar.current.isDate(date, inSameDayAs: selection)
                        let isToday = Calendar.current.isDateInToday(date)
                        
                        Button(action: {
                            // 保持时间部分不变
                            let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: selection)
                            var newDate = Calendar.current.startOfDay(for: date)
                            newDate = Calendar.current.date(byAdding: .hour, value: timeComponents.hour ?? 0, to: newDate)!
                            newDate = Calendar.current.date(byAdding: .minute, value: timeComponents.minute ?? 0, to: newDate)!
                            withAnimation(.spring(response: 0.3)) { selection = newDate }
                        }) {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                                .foregroundColor(isSelected ? .white : (isToday ? .blue : .black))
                                .frame(width: 28, height: 28) // 尺寸 32 -> 28
                                .background(isSelected ? Color.black : Color.clear)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(isToday && !isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
    
    // 日历辅助函数
    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
        }
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
    
    var monthFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }
}

// --- [优化] 紧凑型时间选择器 ---
struct AtmosphericClock: View {
    @Binding var selection: Date
    
    let hours = Array(0...23)
    let minutes = Array(stride(from: 0, to: 60, by: 5))
    
    // [配置] 更加紧凑的尺寸
    let itemHeight: CGFloat = 32 // 40 -> 32
    let visibleItems: Int = 5    // 总高度 160
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 1. 标题层
            HStack(spacing: 0) {
                Text("Hour")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                
                Text("")
                    .frame(width: 20)
                
                Text("Minute")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 20)
            .padding(.bottom, 8)
            
            // 2. 滚轮区域
            HStack(spacing: 0) {
                WheelPickerColumn(
                    items: hours,
                    selection: Binding(
                        get: { Calendar.current.component(.hour, from: selection) },
                        set: { h in updateTime(hour: h) }
                    ),
                    itemHeight: itemHeight,
                    visibleItems: visibleItems
                )
                
                // 冒号
                Text(":")
                    .font(.system(size: 24, weight: .bold))
                    .frame(width: 20)
                    .offset(y: -2)
                
                WheelPickerColumn(
                    items: minutes,
                    selection: Binding(
                        get: {
                            let m = Calendar.current.component(.minute, from: selection)
                            return (m / 5) * 5
                        },
                        set: { m in updateTime(minute: m) }
                    ),
                    itemHeight: itemHeight,
                    visibleItems: visibleItems
                )
            }
            .frame(height: itemHeight * CGFloat(visibleItems))
            // 3. 选中框覆盖层
            .overlay(
                VStack(spacing: 0) {
                    Divider().background(Color.black)
                    Color.clear.frame(height: itemHeight)
                    Divider().background(Color.black)
                }
                .padding(.horizontal, 30)
                .allowsHitTesting(false)
            )
            
            Spacer()
        }
        .padding(.top, 20) // 给上面一点空间
    }
    
    func updateTime(hour: Int? = nil, minute: Int? = nil) {
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: selection)
        if let h = hour { components.hour = h }
        if let m = minute { components.minute = m }
        if let newDate = Calendar.current.date(from: components) {
            selection = newDate
        }
    }
}

// --- [重构] 现代原生滚轮组件 (逻辑不变，参数适配) ---
struct WheelPickerColumn: View {
    let items: [Int]
    @Binding var selection: Int
    let itemHeight: CGFloat
    let visibleItems: Int
    
    @State private var scrollID: Int?
    
    var body: some View {
        GeometryReader { geometry in
            let verticalPadding = (geometry.size.height - itemHeight) / 2
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: verticalPadding)
                    
                    ForEach(items, id: \.self) { item in
                        Text(String(format: "%02d", item))
                            .font(.system(
                                size: scrollID == item ? 20 : 14, // 字体微调：22/16 -> 20/14
                                weight: scrollID == item ? .bold : .regular
                            ))
                            .foregroundColor(scrollID == item ? .black : .gray.opacity(0.4))
                            .frame(height: itemHeight)
                            .frame(maxWidth: .infinity)
                            .id(item)
                            .onTapGesture {
                                withAnimation(.spring) {
                                    scrollID = item
                                }
                            }
                    }
                    
                    Color.clear.frame(height: verticalPadding)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrollID, anchor: .center)
            .onChange(of: scrollID) {
                if let val = scrollID {
                    selection = val
                }
            }
            .onChange(of: selection) { newValue in
                if scrollID != newValue {
                    withAnimation {
                        scrollID = newValue
                    }
                }
            }
            .onAppear {
                scrollID = selection
            }
        }
        .frame(height: itemHeight * CGFloat(visibleItems))
        .contentShape(Rectangle())
    }
}
