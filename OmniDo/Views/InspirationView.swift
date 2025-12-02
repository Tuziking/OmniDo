import SwiftUI
import MarkdownUI

// --- 1. Color Themes & Helpers ---
struct TagTheme: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
}

let colorThemes: [TagTheme] = [
    TagTheme(name: "Orange", color: .orange),
    TagTheme(name: "Blue", color: .blue),
    TagTheme(name: "Purple", color: .purple),
    TagTheme(name: "Red", color: .red),
    TagTheme(name: "Green", color: .green),
    TagTheme(name: "Pink", color: .pink),
    TagTheme(name: "Mint", color: .mint),
    TagTheme(name: "Gray", color: .gray)
]

fileprivate func getColorByName(_ name: String) -> Color {
    if let match = colorThemes.first(where: { $0.name.lowercased() == name.lowercased() }) {
        return match.color
    }
    return .gray
}

// --- Main View ---
struct InspirationView: View {
    @ObservedObject var viewModel: PaperDoViewModel
    
    @State private var selectedNoteID: UUID? = nil
    @State private var showAddNoteAlert = false
    
    // States for new note creation
    @State private var newNoteTitle = ""
    @State private var newNoteContent = ""
    @State private var newNoteTag = "Idea"
    @State private var newNoteColorName = "Orange"
    
    // 统一网格布局参数
    let columns = [GridItem(.adaptive(minimum: 320, maximum: 400), spacing: 20)]
    
    var body: some View {
        ZStack(alignment: .top) {
            // 1. 全局背景色 (统一为纯白，消除与顶部导航栏的色差)
            Color.white.ignoresSafeArea()
            
            // --- Routing Logic ---
            if let noteID = selectedNoteID,
               let note = viewModel.inspirations.first(where: { $0.id == noteID }) {
                
                // 详情页也限制宽度，保持一致的阅读体验
                InspirationDetailView(
                    note: note,
                    viewModel: viewModel,
                    onClose: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedNoteID = nil
                        }
                    }
                )
                .frame(maxWidth: 1000)
                .frame(maxHeight: .infinity)
                // [Fix] 恢复 opacity 组合，确保进入和退出时都有平滑的渐变消失效果
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(2)
                
            } else {
                
                // 3. List/Grid View (现在包含 Header 和 Grid，整体可滚动)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        // Header (统一风格，随 ScrollView 滚动)
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Inspiration")
                                    .font(.system(size: 24, weight: .bold, design: .serif)) // 统一 Serif
                                    .foregroundColor(.black)
                                
                                Text("Capture fragmented thoughts")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.gray)
                                    .tracking(0.5)
                            }
                            
                            Spacer()
                            
                            // "New Note" Button (统一黑色胶囊风格)
                            Button(action: {
                                resetNewNoteStates()
                                withAnimation(.spring()) { showAddNoteAlert = true }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("New Note")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.black)
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal, 24) // [Fix] 调整为 24 以便更好地与顶部 Logo 对齐
                        .padding(.top, 24)
                        .padding(.bottom, 32) // 增加 Header 与内容的间距
                        
                        // Grid Content
                        LazyVGrid(columns: columns, spacing: 20) {
                            // 现有卡片
                            ForEach(viewModel.inspirations) { note in
                                InspirationCard(note: note, viewModel: viewModel)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedNoteID = note.id }
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            withAnimation { viewModel.deleteInspiration(id: note.id) }
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                            
                            // [New] 虚线添加按钮卡片
                            Button(action: {
                                resetNewNoteStates()
                                withAnimation(.spring()) { showAddNoteAlert = true }
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 24, weight: .regular))
                                        .foregroundColor(.gray.opacity(0.4))
                                    
                                    Text("Create New Idea")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 220) // 保持与其他卡片一致的高度
                                .background(Color.gray.opacity(0.02))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 6])) // 虚线边框
                                        .foregroundColor(.gray.opacity(0.15))
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal, 24) // [Fix] 调整为 24 保持对其
                        .padding(.bottom, 80)
                    }
                }
                .frame(maxWidth: 1000) // 限制最大宽度
                .frame(maxHeight: .infinity)
                .transition(.opacity)
                .zIndex(1)
            }
            
            // --- Custom Modal Alert (Overlay) ---
            if showAddNoteAlert {
                InspirationInputAlert(
                    isPresented: $showAddNoteAlert,
                    title: $newNoteTitle,
                    content: $newNoteContent,
                    tag: $newNoteTag,
                    colorName: $newNoteColorName,
                    onCommit: {
                        if !newNoteTitle.isEmpty {
                            viewModel.addInspiration(
                                title: newNoteTitle,
                                content: newNoteContent.isEmpty ? "Write something..." : newNoteContent,
                                tag: newNoteTag,
                                colorName: newNoteColorName
                            )
                            resetNewNoteStates()
                        }
                    }
                )
            }
        }
    }
    
    // Helper to reset states
    private func resetNewNoteStates() {
        newNoteTitle = ""
        newNoteContent = ""
        newNoteTag = "Idea"
        newNoteColorName = "Orange"
    }
}

// --- Detail/Edit View ---
// ... (DetailView, Card, Alert code remains the same as previous context, no changes needed there)
struct InspirationDetailView: View {
    let note: InspirationNote
    @ObservedObject var viewModel: PaperDoViewModel
    let onClose: () -> Void
    
    @State private var title: String
    @State private var content: String
    @State private var tag: String
    @State private var colorName: String
    @State private var showColorPicker = false // 控制颜色悬浮窗显示
    
    init(note: InspirationNote, viewModel: PaperDoViewModel, onClose: @escaping () -> Void) {
        self.note = note
        self.viewModel = viewModel
        self.onClose = onClose
        _title = State(initialValue: note.title)
        _content = State(initialValue: note.content)
        _tag = State(initialValue: note.tag)
        _colorName = State(initialValue: note.colorName)
    }
    
    var currentColor: Color { getColorByName(colorName) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Toolbar
            HStack {
                Button(action: {
                    viewModel.updateInspiration(id: note.id, title: title, content: content, tag: tag, colorName: colorName)
                    onClose()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold))
                        Text("Back").font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.black.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(20) // 统一胶囊风格
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Spacer()
                
                // --- Tools: Color & Tag ---
                HStack(spacing: 12) {
                    // Color Picker Trigger (Custom Popover logic)
                    Button(action: { withAnimation { showColorPicker.toggle() } }) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(currentColor)
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                            
                            Text(colorName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.black.opacity(0.8))
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray.opacity(0.5))
                                .rotationEffect(showColorPicker ? .degrees(180) : .degrees(0))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        .overlay(Capsule().stroke(currentColor.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .popover(isPresented: $showColorPicker, arrowEdge: .bottom) {
                        // 自定义颜色选择器 Popover
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(colorThemes) { theme in
                                    Button {
                                        colorName = theme.name
                                        showColorPicker = false
                                    } label: {
                                        Circle()
                                            .fill(theme.color)
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.black.opacity(0.2), lineWidth: colorName == theme.name ? 2 : 0)
                                            )
                                            .shadow(color: theme.color.opacity(0.3), radius: 2, x: 0, y: 2)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                        .background(Color.white)
                        .frame(height: 60)
                    }
                    
                    // Tag Text Input
                    HStack(spacing: 4) {
                        Image(systemName: "tag")
                            .font(.system(size: 12))
                            .foregroundColor(currentColor.opacity(0.7))
                        
                        TextField("Tag", text: $tag)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.black.opacity(0.8))
                            .frame(width: 80)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                .fixedSize()
                
                Spacer()
                
                Button(action: {
                    viewModel.updateInspiration(id: note.id, title: title, content: content, tag: tag, colorName: colorName)
                }) {
                    Text("Save")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor((content != note.content || title != note.title || tag != note.tag || colorName != note.colorName) ? .white : .gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background((content != note.content || title != note.title || tag != note.tag || colorName != note.colorName) ? Color.blue : Color.gray.opacity(0.1))
                        .cornerRadius(20) // 胶囊
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.leading, 16)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(Color.white) // [Fix] 统一为纯白背景
            .overlay(Divider(), alignment: .bottom)
            
            // 2. Title Section
            TextField("Enter Title Here", text: $title)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(.black)
                .textFieldStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .padding(.bottom, 12)
                .background(Color.white)
            
            Divider()
            
            // 3. Split View Area
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Left: Editor
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("Type using Markdown...")
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(24)
                                .font(.system(size: 15))
                        }
                        TextEditor(text: $content)
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundColor(.black.opacity(0.8))
                            .padding(20)
                            .scrollContentBackground(.hidden)
                    }
                    .frame(width: geometry.size.width * 0.5)
                    .background(Color.white)
                    
                    Divider()
                    
                    // Right: Preview
                    VStack(alignment: .leading, spacing: 0) {
                        Text(title.isEmpty ? "Untitled" : title)
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(.black)
                            .padding(.horizontal, 40)
                            .padding(.top, 32)
                            .padding(.bottom, 8)
                        
                        ScrollView {
                            Markdown(content)
                                .markdownTheme(.gitHub)
                                .markdownBlockStyle(\.codeBlock) { configuration in
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        configuration.label
                                            .font(.system(.footnote, design: .monospaced))
                                            .padding(16)
                                            .environment(\.colorScheme, .dark)
                                    }
                                    .background(Color(red: 30/255, green: 30/255, blue: 30/255))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                    .padding(.bottom, 12)
                                }
                                .markdownTextStyle {
                                    ForegroundColor(Color.black.opacity(0.85))
                                    FontSize(16)
                                    FontFamilyVariant(.monospaced)
                                }
                                .padding(.horizontal, 40)
                                .padding(.bottom, 40)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(width: geometry.size.width * 0.5)
                    .background(Color.white) // [Fix] 统一为纯白，消除预览区的灰色感
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: -5, y: 0)
    }
}

// --- Card Component (Supports Inline Edit & Visual Color Picker) ---
struct InspirationCard: View {
    let note: InspirationNote
    @ObservedObject var viewModel: PaperDoViewModel
    
    @State private var showColorPicker = false // 独立控制卡片的颜色弹窗
    
    var noteColor: Color { getColorByName(note.colorName) }
    
    var previewText: String {
        let stripped = note.content
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "`", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return stripped
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                // --- Inline Edit: Color & Tag (Button + Popover) ---
                Button(action: { showColorPicker.toggle() }) {
                    HStack(spacing: 6) {
                        Circle().fill(noteColor).frame(width: 6, height: 6)
                        Text(note.tag.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black.opacity(0.7))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain) // Prevent triggering parent tap
                .popover(isPresented: $showColorPicker, arrowEdge: .bottom) {
                    // 使用与详情页一致的色卡 Popover
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(colorThemes) { theme in
                                Button {
                                    viewModel.updateInspiration(
                                        id: note.id,
                                        title: note.title,
                                        content: note.content,
                                        tag: note.tag,
                                        colorName: theme.name // Update color immediately
                                    )
                                    showColorPicker = false
                                } label: {
                                    Circle()
                                        .fill(theme.color)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black.opacity(0.2), lineWidth: note.colorName == theme.name ? 2 : 0)
                                        )
                                        .shadow(color: theme.color.opacity(0.3), radius: 2, x: 0, y: 2)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                    .background(Color.white)
                    .frame(height: 60)
                }
                
                Spacer()
                
                Text(note.date, style: .date)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(noteColor.opacity(0.08))
            
            Divider().opacity(0.3)
            
            VStack(alignment: .leading, spacing: 8) {
                // --- Inline Edit: Title ---
                TextField("Title", text: Binding(
                    get: { note.title },
                    set: { newVal in
                        viewModel.updateInspiration(id: note.id, title: newVal, content: note.content, tag: note.tag, colorName: note.colorName)
                    }
                ))
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundColor(.black)
                .textFieldStyle(.plain)
                .lineLimit(1)
                
                Text(previewText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.black.opacity(0.7))
                    .lineSpacing(4)
                    .lineLimit(5)
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            
            Spacer(minLength: 0)
            
            HStack {
                Spacer()
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 10))
                    .foregroundColor(.gray.opacity(0.3))
            }
            .padding(12)
        }
        .frame(minHeight: 220)
        .background(Color.white)
        .cornerRadius(20) // 统一圆角 16 -> 20
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.03), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

// --- Button Style ---
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// --- Modern Input Alert (统一风格) ---
struct InspirationInputAlert: View {
    @Binding var isPresented: Bool
    @Binding var title: String
    @Binding var content: String
    @Binding var tag: String
    @Binding var colorName: String
    
    var actionButtonText: String = "Confirm"
    let onCommit: () -> Void
    
    var currentColor: Color { getColorByName(colorName) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.2).ignoresSafeArea() // 统一透明度
                .onTapGesture { withAnimation(.spring()) { isPresented = false } }
            
            VStack(spacing: 24) {
                Text("New Inspiration")
                    .font(.system(size: 20, weight: .bold, design: .serif)) // 统一字体
                    .foregroundColor(.black)
                
                VStack(spacing: 16) {
                    TextField("Title", text: $title)
                        .font(.system(size: 16, weight: .semibold))
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(red: 0.96, green: 0.96, blue: 0.97))
                        .cornerRadius(12)
                    
                    // --- 直观的横向颜色选择 ---
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Color")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(colorThemes) { theme in
                                    Button {
                                        colorName = theme.name
                                    } label: {
                                        Circle()
                                            .fill(theme.color)
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.black.opacity(0.5), lineWidth: colorName == theme.name ? 2 : 0)
                                            )
                                            .shadow(color: theme.color.opacity(0.3), radius: 2, x: 0, y: 2)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    TextField("Tag (e.g. Idea)", text: $tag)
                        .font(.system(size: 15, weight: .medium))
                        .textFieldStyle(.plain)
                        .padding(12) // 统一 padding
                        .background(Color(red: 0.96, green: 0.96, blue: 0.97))
                        .cornerRadius(10)
                    
                    TextField("Short content or description...", text: $content)
                        .font(.system(size: 15)) // 统一字号
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(red: 0.96, green: 0.96, blue: 0.97))
                        .cornerRadius(10)
                        .onSubmit {
                            onCommit()
                            withAnimation(.spring()) { isPresented = false }
                        }
                }
                
                HStack(spacing: 16) {
                    Button(action: { withAnimation(.spring()) { isPresented = false } }) {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10) // 统一 padding
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
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
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            .frame(width: 340) // 稍微加宽适配颜色选择
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
        .zIndex(100)
    }
}
