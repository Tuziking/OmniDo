import SwiftUI
import Combine

// --- 数据模型 (Models) ---

struct TodoItem: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var deadline: Date
    var completed: Bool
}

struct TaskColumn: Identifiable, Codable {
    var id: String
    var title: String
    var colorHex: String
}

struct ProjectTask: Identifiable, Codable {
    var id: UUID = UUID()
    var content: String
    var columnId: String // "todo", "doing", "done"
}

struct Project: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var tasks: [ProjectTask]
}

struct Habit: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var records: [String: Bool] // Key format: "YYYY-MM-DD"
}

// [修改] 灵感笔记模型：新增 title 和 colorName
struct InspirationNote: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String       // 标题
    var content: String     // 内容 (Markdown)
    var date: Date
    var tag: String         // 标签
    var colorName: String   // 颜色名 (e.g., "blue", "orange")
}

// --- 视图模型 (ViewModel) ---

class PaperDoViewModel: ObservableObject {
    // 视图状态
    @Published var currentView: String = "tasks"
    @Published var showImmersiveMode: Bool = false
    @Published var immersiveDate: Date = Date()
    
    // 数据状态
    @Published var todos: [TodoItem] = [] {
        didSet { save(todos, key: "sketch_todos") }
    }
    
    @Published var projects: [Project] = [] {
        didSet { save(projects, key: "sketch_projects") }
    }
    
    @Published var habits: [Habit] = [] {
        didSet { save(habits, key: "sketch_habits") }
    }
    
    // 灵感数据
    @Published var inspirations: [InspirationNote] = [] {
        didSet { save(inspirations, key: "sketch_inspirations") }
    }
    
    init() {
        loadData()
    }
    
    // --- 持久化逻辑 ---
    func loadData() {
        // 加载待办
        if let data = UserDefaults.standard.data(forKey: "sketch_todos"),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            todos = decoded
        } else {
            todos = [
                TodoItem(title: "阅读设计心理学", deadline: Date().addingTimeInterval(86400), completed: false),
                TodoItem(title: "整理桌面", deadline: Date().addingTimeInterval(3600), completed: true)
            ]
        }
        
        // 加载项目
        if let data = UserDefaults.standard.data(forKey: "sketch_projects"),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            projects = decoded
        } else {
            projects = [
                Project(name: "App Design", tasks: [
                    ProjectTask(content: "绘制线框图", columnId: "todo"),
                    ProjectTask(content: "确定配色", columnId: "doing"),
                    ProjectTask(content: "竞品分析", columnId: "done")
                ])
            ]
        }
        
        // 加载习惯
        if let data = UserDefaults.standard.data(forKey: "sketch_habits"),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        } else {
            habits = [
                Habit(name: "冥想", records: [:]),
                Habit(name: "阅读", records: [:])
            ]
        }
        
        // [修改] 加载灵感 (包含新字段)
        if let data = UserDefaults.standard.data(forKey: "sketch_inspirations"),
           let decoded = try? JSONDecoder().decode([InspirationNote].self, from: data) {
            inspirations = decoded
        } else {
            inspirations = [
                InspirationNote(
                    title: "极简设计原则",
                    content: "设计核心在于**留白**与*呼吸感*。",
                    date: Date(),
                    tag: "Design",
                    colorName: "purple"
                ),
                InspirationNote(
                    title: "Swift Data",
                    content: "下次尝试使用 `SwiftData` 替代 UserDefaults。",
                    date: Date().addingTimeInterval(-86400),
                    tag: "Dev",
                    colorName: "blue"
                )
            ]
        }
    }
    
    func save<T: Encodable>(_ data: T, key: String) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    // ... (Todo, Project, Habit 逻辑保持不变，省略以节省空间) ...
    // --- 待办逻辑 (Global Todos) ---
    func toggleTodo(_ id: UUID) {
        if let idx = todos.firstIndex(where: { $0.id == id }) {
            todos[idx].completed.toggle()
        }
    }
    
    func deleteTodo(_ id: UUID) {
        todos.removeAll(where: { $0.id == id })
    }
    
    func addTodo(title: String, date: Date) {
        todos.append(TodoItem(title: title, deadline: date, completed: false))
    }
    
    // --- 项目逻辑 (Projects) ---
    func addProject(name: String) {
        let newProject = Project(name: name, tasks: [])
        projects.append(newProject)
    }
    
    func deleteProject(id: UUID) {
        projects.removeAll(where: { $0.id == id })
    }
    
    func renameProject(id: UUID, newName: String) {
        if let idx = projects.firstIndex(where: { $0.id == id }) {
            projects[idx].name = newName
        }
    }
    
    // --- 项目内卡片逻辑 (Project Tasks) ---
    func addProjectTask(projectID: UUID, content: String, columnId: String) {
        if let idx = projects.firstIndex(where: { $0.id == projectID }) {
            let newTask = ProjectTask(content: content, columnId: columnId)
            projects[idx].tasks.append(newTask)
        }
    }
    
    func deleteProjectTask(projectID: UUID, taskID: UUID) {
        if let idx = projects.firstIndex(where: { $0.id == projectID }) {
            projects[idx].tasks.removeAll(where: { $0.id == taskID })
        }
    }
    
    func updateProjectTask(projectID: UUID, taskID: UUID, newContent: String) {
        if let pIdx = projects.firstIndex(where: { $0.id == projectID }),
           let tIdx = projects[pIdx].tasks.firstIndex(where: { $0.id == taskID }) {
            projects[pIdx].tasks[tIdx].content = newContent
        }
    }
    
    func moveProjectTask(projectID: UUID, taskID: UUID, toColumn: String) {
        if let pIdx = projects.firstIndex(where: { $0.id == projectID }),
           let tIdx = projects[pIdx].tasks.firstIndex(where: { $0.id == taskID }) {
            projects[pIdx].tasks[tIdx].columnId = toColumn
        }
    }
    
    // --- 习惯逻辑 (Habits) ---
    func toggleHabit(habitId: UUID, date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: date)
        
        if let idx = habits.firstIndex(where: { $0.id == habitId }) {
            if habits[idx].records[key] == true {
                habits[idx].records.removeValue(forKey: key)
            } else {
                habits[idx].records[key] = true
            }
        }
    }

    // --- [修改] 灵感逻辑 (Inspirations) ---
    func addInspiration(title: String, content: String, tag: String, colorName: String) {
        let note = InspirationNote(
            title: title,
            content: content,
            date: Date(),
            tag: tag,
            colorName: colorName
        )
        inspirations.insert(note, at: 0)
    }
    
    func deleteInspiration(id: UUID) {
        inspirations.removeAll(where: { $0.id == id })
    }
    
    func updateInspiration(id: UUID, title: String, content: String, tag: String, colorName: String) {
        if let idx = inspirations.firstIndex(where: { $0.id == id }) {
            inspirations[idx].title = title
            inspirations[idx].content = content
            inspirations[idx].tag = tag
            inspirations[idx].colorName = colorName
        }
    }
}
