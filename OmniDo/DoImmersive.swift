//
//  OminiDoImmersive.swift
//  TODO
//
//  Created by BOBO on 2025/11/25.
//

import SwiftUI
import Combine

struct ImmersiveDayView: View {
    @ObservedObject var viewModel: PaperDoViewModel
    let date: Date
    @Binding var isPresented: Bool
    @State private var currentTime = Date()
    @State private var useAnalogClock = true
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color(white: 0.98).ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(.black.opacity(0.4))
                            .padding(24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
                
                VStack(spacing: 32) {
                    Group {
                        if useAnalogClock {
                            AnalogClock(currentTime: currentTime)
                                .frame(width: 300, height: 300)
                        } else {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(currentTime, formatter: hourFormatter)
                                    .font(.system(size: 130, weight: .black, design: .rounded))
                                    .foregroundColor(.black)
                                Text(":")
                                    .font(.system(size: 80, weight: .light))
                                    .foregroundColor(.gray.opacity(0.6))
                                    .offset(y: -25)
                                Text(currentTime, formatter: minuteFormatter)
                                    .font(.system(size: 90, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                Text(currentTime, formatter: secondFormatter)
                                    .font(.system(size: 40, weight: .medium, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .padding(.leading, 10)
                            }
                            .frame(height: 300)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            useAnalogClock.toggle()
                        }
                    }
                    
                    Text(date, formatter: fullDateFormatter)
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .textCase(.uppercase)
                        .tracking(4)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                GeometryReader { geometry in
                    let cardWidth = (geometry.size.width - 40 - 120) / 2
                    
                    HStack(alignment: .top, spacing: 40) {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(spacing: 8) {
                                Circle().fill(Color.black).frame(width: 6, height: 6)
                                Text("PENDING")
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(2)
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            
                            let todos = viewModel.todos.filter {
                                !$0.completed && Calendar.current.isDate($0.deadline, inSameDayAs: date)
                            }
                            
                            if todos.isEmpty {
                                Text("No pending tasks.")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray.opacity(0.4))
                                    .italic()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 20)
                            } else {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(todos) { todo in
                                            HStack(alignment: .top, spacing: 12) {
                                                Image(systemName: "circle")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.black)
                                                    .onTapGesture { viewModel.toggleTodo(todo.id) }
                                                    .padding(.top, 2)
                                                Text(todo.title)
                                                    .font(.system(size: 18, weight: .regular))
                                                    .foregroundColor(.black)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    }
                                }
                                .frame(maxHeight: 200)
                            }
                        }
                        .padding(32)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .frame(height: 320, alignment: .top)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 8)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(spacing: 8) {
                                Circle().fill(Color.green).frame(width: 6, height: 6)
                                Text("COMPLETED")
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(2)
                                    .foregroundColor(.gray)
                            }
                            
                            let dones = viewModel.todos.filter {
                                $0.completed && Calendar.current.isDate($0.deadline, inSameDayAs: date)
                            }
                            
                            if dones.isEmpty {
                                Text("Start working.")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray.opacity(0.4))
                                    .italic()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 20)
                            } else {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(dones) { todo in
                                            HStack(alignment: .top, spacing: 12) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.green.opacity(0.6))
                                                    .onTapGesture { viewModel.toggleTodo(todo.id) }
                                                    .padding(.top, 2)
                                                Text(todo.title)
                                                    .font(.system(size: 18, weight: .regular))
                                                    .strikethrough()
                                                    .foregroundColor(.gray.opacity(0.6))
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    }
                                }
                                .frame(maxHeight: 200)
                            }
                        }
                        .padding(32)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .frame(height: 320, alignment: .top)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 8)
                    }
                    .padding(.horizontal, 60)
                }
                .frame(height: 300)
                .padding(.bottom, 60)
            }
        }
        .onReceive(timer) { input in
            currentTime = input
        }
    }
    
    var hourFormatter: DateFormatter { let f = DateFormatter(); f.dateFormat = "HH"; return f }
    var minuteFormatter: DateFormatter { let f = DateFormatter(); f.dateFormat = "mm"; return f }
    var secondFormatter: DateFormatter { let f = DateFormatter(); f.dateFormat = "ss"; return f }
    var fullDateFormatter: DateFormatter { let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d"; return f }
}
