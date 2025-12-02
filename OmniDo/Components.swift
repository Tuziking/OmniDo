//
//  OminiDoComponents.swift
//  TODO
//
//  Created by BOBO on 2025/11/25.
//

import SwiftUI

// --- 大气风格修饰符 ---

struct AtmosphericCard: ViewModifier {
    var padding: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.02), radius: 1, x: 0, y: 1)
    }
}

struct AtmosphericButtonStyle: ButtonStyle {
    var primary: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(primary ? Color.black : Color.white)
            .foregroundColor(primary ? .white : .black)
            .cornerRadius(12)
            .shadow(color: primary ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: primary ? 8 : 4, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func atmosphericCard(padding: CGFloat = 20) -> some View {
        self.modifier(AtmosphericCard(padding: padding))
    }
}

// --- 模拟时钟组件 ---

struct AnalogClock: View {
    var currentTime: Date
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let radius = min(width, height) / 2
            
            ZStack {
                Circle().fill(Color.white).shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                ForEach(0..<4) { i in
                    Rectangle().fill(Color.black.opacity(0.8)).frame(width: 4, height: 15).offset(y: -radius + 10).rotationEffect(.degrees(Double(i) * 90))
                }
                ForEach(0..<12) { i in
                    if i % 3 != 0 { Rectangle().fill(Color.gray.opacity(0.5)).frame(width: 2, height: 10).offset(y: -radius + 10).rotationEffect(.degrees(Double(i) * 30)) }
                }
                Rectangle().fill(Color.black).frame(width: 6, height: radius * 0.5).cornerRadius(3).offset(y: -radius * 0.25).rotationEffect(Angle(degrees: Double(Calendar.current.component(.hour, from: currentTime)) * 30 + Double(Calendar.current.component(.minute, from: currentTime)) * 0.5))
                Rectangle().fill(Color.black).frame(width: 4, height: radius * 0.7).cornerRadius(2).offset(y: -radius * 0.35).rotationEffect(Angle(degrees: Double(Calendar.current.component(.minute, from: currentTime)) * 6 + Double(Calendar.current.component(.second, from: currentTime)) * 0.1))
                Rectangle().fill(Color.red).frame(width: 2, height: radius * 0.8).cornerRadius(1).offset(y: -radius * 0.4).rotationEffect(Angle(degrees: Double(Calendar.current.component(.second, from: currentTime)) * 6))
                Circle().fill(Color.black).frame(width: 12, height: 12)
                Circle().fill(Color.white).frame(width: 4, height: 4)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// --- 自定义日历选择器 ---

struct CustomDatePicker: View {
    @Binding var selectedDate: Date
    @State private var monthToDisplay: Date
    @State private var selectionMode: SelectionMode = .date
    enum SelectionMode { case date; case time }
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        self._monthToDisplay = State(initialValue: selectedDate.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { withAnimation { selectionMode = .date } }) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text(selectedDate, style: .date)
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(selectionMode == .date ? .black : .gray)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(selectionMode == .date ? Color.gray.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: { withAnimation { selectionMode = .time } }) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text(selectedDate, style: .time)
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(selectionMode == .time ? .black : .gray)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(selectionMode == .time ? Color.gray.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            if selectionMode == .date {
                VStack(spacing: 12) {
                    HStack {
                        Text(monthFormatter.string(from: monthToDisplay)).font(.system(size: 16, weight: .bold))
                        Spacer()
                        HStack(spacing: 16) {
                            Button(action: { changeMonth(by: -1) }) { Image(systemName: "chevron.left").font(.system(size: 14, weight: .bold)).foregroundColor(.black) }.buttonStyle(.plain)
                            Button(action: { changeMonth(by: 1) }) { Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundColor(.black) }.buttonStyle(.plain)
                        }
                    }
                    
                    VStack(spacing: 8) {
                        HStack {
                            ForEach(["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"], id: \.self) { day in
                                Text(day).font(.system(size: 12, weight: .bold)).foregroundColor(.gray.opacity(0.5)).frame(maxWidth: .infinity)
                            }
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            let days = daysInMonth()
                            let offset = firstWeekday()
                            
                            ForEach(0..<offset, id: \.self) { _ in Color.clear }
                            
                            ForEach(days, id: \.self) { date in
                                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                                let isToday = Calendar.current.isDateInToday(date)
                                
                                Button(action: {
                                    let currentComponents = Calendar.current.dateComponents([.hour, .minute], from: selectedDate)
                                    var newComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
                                    newComponents.hour = currentComponents.hour
                                    newComponents.minute = currentComponents.minute
                                    
                                    if let newDate = Calendar.current.date(from: newComponents) {
                                        selectedDate = newDate
                                        monthToDisplay = newDate
                                    }
                                }) {
                                    Text("\(Calendar.current.component(.day, from: date))")
                                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                        .frame(width: 32, height: 32)
                                        .background(isSelected ? Color.black : Color.clear)
                                        .foregroundColor(isSelected ? .white : (isToday ? .black : .gray))
                                        .clipShape(Circle())
                                        .overlay(isToday && !isSelected ? Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1) : nil)
                                        .contentShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hour").font(.system(size: 12, weight: .bold)).foregroundColor(.gray)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                            ForEach(0..<24) { hour in
                                let currentHour = Calendar.current.component(.hour, from: selectedDate)
                                Button(action: {
                                    var components = Calendar.current.dateComponents([.year, .month, .day, .minute], from: selectedDate)
                                    components.hour = hour
                                    if let newDate = Calendar.current.date(from: components) { selectedDate = newDate }
                                }) {
                                    Text("\(hour)").font(.system(size: 12, weight: hour == currentHour ? .bold : .medium)).frame(height: 28).frame(maxWidth: .infinity).background(hour == currentHour ? Color.black : Color.gray.opacity(0.05)).foregroundColor(hour == currentHour ? .white : .black).cornerRadius(6)
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Minute").font(.system(size: 12, weight: .bold)).foregroundColor(.gray)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                            ForEach(0..<12) { i in
                                let minute = i * 5
                                let currentMinute = Calendar.current.component(.minute, from: selectedDate)
                                let isSelected = (currentMinute >= minute && currentMinute < minute + 5)
                                Button(action: {
                                    var components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: selectedDate)
                                    components.minute = minute
                                    if let newDate = Calendar.current.date(from: components) { selectedDate = newDate }
                                }) {
                                    Text(String(format: "%02d", minute)).font(.system(size: 12, weight: isSelected ? .bold : .medium)).frame(height: 28).frame(maxWidth: .infinity).background(isSelected ? Color.black : Color.gray.opacity(0.05)).foregroundColor(isSelected ? .white : .black).cornerRadius(6)
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: monthToDisplay) {
            monthToDisplay = newDate
        }
    }
    
    func daysInMonth() -> [Date] {
        guard let range = Calendar.current.range(of: .day, in: .month, for: monthToDisplay) else { return [] }
        let components = Calendar.current.dateComponents([.year, .month], from: monthToDisplay)
        return range.compactMap { day -> Date? in
            var dateComponents = components
            dateComponents.day = day
            return Calendar.current.date(from: dateComponents)
        }
    }
    
    func firstWeekday() -> Int {
        let components = Calendar.current.dateComponents([.year, .month], from: monthToDisplay)
        guard let firstDay = Calendar.current.date(from: components) else { return 0 }
        return Calendar.current.component(.weekday, from: firstDay) - 1
    }
    
    var monthFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }
}
