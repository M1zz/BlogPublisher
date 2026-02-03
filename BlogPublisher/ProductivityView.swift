import SwiftUI
import UserNotifications

// MARK: - Ideas View
struct IdeasView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var newIdeaTitle = ""
    @State private var newIdeaDescription = ""
    @State private var newIdeaPriority: IdeaPriority = .medium
    @State private var showNewIdeaForm = false
    @State private var selectedIdea: Idea?
    @State private var filterStatus: IdeaStatus?

    var filteredIdeas: [Idea] {
        if let status = filterStatus {
            return appState.ideas.filter { $0.status == status }
        }
        return appState.ideas
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("아이디어 저장소")
                    .font(.title2.bold())

                Spacer()

                Button {
                    showNewIdeaForm.toggle()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)

                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Filter Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "전체", isSelected: filterStatus == nil) {
                        filterStatus = nil
                    }
                    ForEach(IdeaStatus.allCases, id: \.self) { status in
                        FilterChip(title: status.rawValue, isSelected: filterStatus == status) {
                            filterStatus = status
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Divider()

            // Content
            if showNewIdeaForm {
                NewIdeaForm(
                    title: $newIdeaTitle,
                    description: $newIdeaDescription,
                    priority: $newIdeaPriority,
                    onSave: {
                        appState.createIdea(
                            title: newIdeaTitle,
                            description: newIdeaDescription,
                            priority: newIdeaPriority
                        )
                        resetForm()
                    },
                    onCancel: {
                        resetForm()
                    }
                )
                Divider()
            }

            if filteredIdeas.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("아이디어를 기록해보세요")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("떠오르는 블로그 주제를 빠르게 저장하세요")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredIdeas) { idea in
                        IdeaRow(idea: idea, onConvert: {
                            appState.convertIdeaToPost(idea)
                            dismiss()
                        })
                        .contextMenu {
                            ideaContextMenu(for: idea)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            appState.deleteIdea(filteredIdeas[index])
                        }
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
    }

    func resetForm() {
        showNewIdeaForm = false
        newIdeaTitle = ""
        newIdeaDescription = ""
        newIdeaPriority = .medium
    }

    @ViewBuilder
    func ideaContextMenu(for idea: Idea) -> some View {
        Button("글로 변환") {
            appState.convertIdeaToPost(idea)
            dismiss()
        }

        Divider()

        Menu("상태 변경") {
            ForEach(IdeaStatus.allCases, id: \.self) { status in
                Button(status.rawValue) {
                    var updated = idea
                    updated.status = status
                    appState.updateIdea(updated)
                }
            }
        }

        Menu("우선순위") {
            ForEach(IdeaPriority.allCases, id: \.self) { priority in
                Button(priority.rawValue) {
                    var updated = idea
                    updated.priority = priority
                    appState.updateIdea(updated)
                }
            }
        }

        Divider()

        Button("삭제", role: .destructive) {
            appState.deleteIdea(idea)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                .foregroundColor(isSelected ? .white : .blue)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct NewIdeaForm: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var priority: IdeaPriority
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            TextField("아이디어 제목", text: $title)
                .textFieldStyle(.roundedBorder)

            TextField("설명 (선택)", text: $description)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text("우선순위")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("", selection: $priority) {
                    ForEach(IdeaPriority.allCases, id: \.self) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)

                Spacer()

                Button("취소") {
                    onCancel()
                }
                .buttonStyle(.bordered)

                Button("저장") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
    }
}

struct IdeaRow: View {
    let idea: Idea
    let onConvert: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Priority indicator
            Circle()
                .fill(idea.priority.color)
                .frame(width: 8, height: 8)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(idea.title)
                        .font(.headline)

                    Spacer()

                    Image(systemName: idea.status.icon)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                if !idea.description.isEmpty {
                    Text(idea.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    Text(idea.status.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)

                    Spacer()

                    Text(idea.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            // Convert button
            Button {
                onConvert()
            } label: {
                Image(systemName: "arrow.right.circle")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .help("글로 변환")
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Pomodoro Timer View
struct PomodoroTimerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDuration = 25

    let durations = [15, 25, 45, 60]

    var timeString: String {
        let minutes = appState.pomodoroTimeRemaining / 60
        let seconds = appState.pomodoroTimeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        let total = Double(selectedDuration * 60)
        return 1 - (Double(appState.pomodoroTimeRemaining) / total)
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(.red)
                Text("포모도로 타이머")
                    .font(.title2.bold())
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Spacer()

            // Timer Display
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.red.opacity(0.2), lineWidth: 12)

                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                // Time display
                VStack(spacing: 8) {
                    Text(timeString)
                        .font(.system(size: 56, weight: .bold, design: .monospaced))

                    Text("세션 #\(appState.pomodoroSessionCount + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 220, height: 220)

            // Duration picker (only when not running)
            if !appState.pomodoroIsRunning && appState.pomodoroTimeRemaining == selectedDuration * 60 {
                HStack(spacing: 12) {
                    ForEach(durations, id: \.self) { duration in
                        Button {
                            selectedDuration = duration
                            appState.pomodoroTimeRemaining = duration * 60
                        } label: {
                            Text("\(duration)분")
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedDuration == duration ? Color.red : Color.red.opacity(0.1))
                                .foregroundColor(selectedDuration == duration ? .white : .red)
                                .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Controls
            HStack(spacing: 24) {
                // Reset
                Button {
                    appState.resetPomodoro()
                    appState.pomodoroTimeRemaining = selectedDuration * 60
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                }
                .buttonStyle(.bordered)
                .disabled(!appState.pomodoroIsRunning && appState.pomodoroTimeRemaining == selectedDuration * 60)

                // Play/Pause
                Button {
                    if appState.pomodoroIsRunning {
                        appState.pausePomodoro()
                    } else {
                        appState.startPomodoro(minutes: selectedDuration)
                    }
                } label: {
                    Image(systemName: appState.pomodoroIsRunning ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                        .frame(width: 60, height: 60)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                // Skip (placeholder)
                Button {
                    appState.resetPomodoro()
                    appState.pomodoroTimeRemaining = selectedDuration * 60
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                }
                .buttonStyle(.bordered)
            }

            // Session history
            HStack(spacing: 8) {
                Text("오늘 완료:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(0..<min(appState.pomodoroSessionCount, 8), id: \.self) { _ in
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }

                if appState.pomodoroSessionCount == 0 {
                    Text("아직 없음")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Tips
            VStack(spacing: 4) {
                Text("집중 글쓰기 팁")
                    .font(.caption.bold())
                Text("타이머가 끝날 때까지 글쓰기에만 집중하세요")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .frame(width: 350, height: 500)
        .onAppear {
            requestNotificationPermission()
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}

// MARK: - Schedule Publish View
struct SchedulePublishView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var selectedPlatforms: Set<UUID> = []

    var availablePlatforms: [PlatformConfig] {
        appState.selectedProject?.platforms.filter { $0.isEnabled } ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(.blue)
                Text("발행 예약")
                    .font(.title2.bold())
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Current post
                    if let post = appState.selectedPost {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("예약할 글")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(post.title)
                                .font(.headline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                    }

                    // Date picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("발행 일시")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        DatePicker(
                            "",
                            selection: $selectedDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)

                    // Platform selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("발행 플랫폼")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(availablePlatforms) { platform in
                            HStack {
                                Image(systemName: platform.platformType.icon)
                                    .foregroundStyle(platform.platformType.color)
                                Text(platform.name)
                                Spacer()
                                if selectedPlatforms.contains(platform.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding()
                            .background(
                                selectedPlatforms.contains(platform.id)
                                    ? Color.blue.opacity(0.1)
                                    : Color(nsColor: .controlBackgroundColor)
                            )
                            .cornerRadius(8)
                            .onTapGesture {
                                if selectedPlatforms.contains(platform.id) {
                                    selectedPlatforms.remove(platform.id)
                                } else {
                                    selectedPlatforms.insert(platform.id)
                                }
                            }
                        }
                    }

                    // Schedule button
                    Button {
                        schedulePost()
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("예약하기")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedPlatforms.isEmpty)
                    .padding(.top)

                    // Scheduled list
                    if !appState.scheduledPublishes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("예약된 발행")
                                .font(.headline)

                            ForEach(appState.scheduledPublishes.filter { $0.status == .pending }) { schedule in
                                ScheduleRow(schedule: schedule) {
                                    appState.cancelSchedule(schedule)
                                }
                            }
                        }
                        .padding(.top)
                    }
                }
                .padding()
            }
        }
        .frame(width: 450, height: 600)
    }

    func schedulePost() {
        guard let postId = appState.selectedPost?.id else { return }
        appState.schedulePublish(
            postId: postId,
            platformIds: Array(selectedPlatforms),
            at: selectedDate
        )
        dismiss()
    }
}

struct ScheduleRow: View {
    let schedule: ScheduledPublish
    let onCancel: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.scheduledAt, style: .date)
                    .font(.subheadline)
                Text(schedule.scheduledAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(schedule.status.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)

            Button {
                onCancel()
            } label: {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Quick Idea Capture (Floating Window)
struct QuickIdeaCaptureView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var ideaText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("빠른 아이디어")
                    .font(.headline)
                Spacer()
            }

            TextField("아이디어를 입력하세요...", text: $ideaText)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit {
                    saveIdea()
                }

            HStack {
                Spacer()
                Button("취소") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape)

                Button("저장") {
                    saveIdea()
                }
                .buttonStyle(.borderedProminent)
                .disabled(ideaText.isEmpty)
                .keyboardShortcut(.return)
            }
        }
        .padding()
        .frame(width: 350)
        .onAppear {
            isFocused = true
        }
    }

    func saveIdea() {
        guard !ideaText.isEmpty else { return }
        appState.createIdea(title: ideaText)
        dismiss()
    }
}
