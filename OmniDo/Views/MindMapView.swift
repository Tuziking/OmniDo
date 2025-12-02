import SwiftUI

struct MindMapView: View {
    @ObservedObject var viewModel: PaperDoViewModel
    let projectID: UUID
    
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    // 连线绘制
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景网格 (可选)
                Color(white: 0.98).ignoresSafeArea()
                
                // 画布内容
                if let project = viewModel.projects.first(where: { $0.id == projectID }) {
                    ZStack {
                        // 1. 绘制连线
                        ForEach(project.tasks) { task in
                            if let children = task.childrenIDs {
                                ForEach(children, id: \.self) { childID in
                                    if let child = project.tasks.first(where: { $0.id == childID }) {
                                        Path { path in
                                            let start = CGPoint(x: (task.x ?? 0) + 100, y: (task.y ?? 0) + 25) // 节点中心 (假设宽200高50)
                                            let end = CGPoint(x: (child.x ?? 0) + 100, y: (child.y ?? 0) + 25)
                                            
                                            path.move(to: start)
                                            // 贝塞尔曲线连接
                                            let control1 = CGPoint(x: start.x + 100, y: start.y)
                                            let control2 = CGPoint(x: end.x - 100, y: end.y)
                                            path.addCurve(to: end, control1: control1, control2: control2)
                                        }
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                    }
                                }
                            }
                        }
                        
                        // 2. 绘制节点
                        ForEach(project.tasks) { task in
                            MindMapNodeView(
                                task: task,
                                onDragEnd: { newX, newY in
                                    viewModel.updateTaskPosition(projectID: projectID, taskID: task.id, x: newX, y: newY)
                                },
                                onAddChild: {
                                    viewModel.addChildTask(projectID: projectID, parentID: task.id, content: "New Idea")
                                },
                                onStatusChange: { status in
                                    viewModel.moveProjectTask(projectID: projectID, taskID: task.id, toColumn: status)
                                }
                            )
                            .position(x: (task.x ?? 0) + 100, y: (task.y ?? 0) + 25) // 定位中心点
                        }
                    }
                    .offset(offset)
                    .scaleEffect(scale)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(width: lastOffset.width + value.translation.width, height: lastOffset.height + value.translation.height)
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    // 简单的缩放手势 (Mac上可能需要触控板)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                            }
                    )
                }
            }
            .clipShape(Rectangle())
        }
    }
}

struct MindMapNodeView: View {
    let task: ProjectTask
    let onDragEnd: (Double, Double) -> Void
    let onAddChild: () -> Void
    let onStatusChange: (String) -> Void
    
    @State private var dragOffset: CGSize = .zero
    
    var statusColor: Color {
        switch task.columnId {
        case "todo": return .blue
        case "doing": return .orange
        case "done": return .green
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(task.content)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 200, height: 50)
        .background(Color.white)
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
        .offset(dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let currentX = task.x ?? 0
                    let currentY = task.y ?? 0
                    onDragEnd(currentX + value.translation.width, currentY + value.translation.height)
                    dragOffset = .zero
                }
        )
        .contextMenu {
            Button("Add Child Node") { onAddChild() }
            Divider()
            Button("Mark as To Do") { onStatusChange("todo") }
            Button("Mark as In Progress") { onStatusChange("doing") }
            Button("Mark as Done") { onStatusChange("done") }
        }
    }
}
