import SwiftUI
import UniformTypeIdentifiers

struct JobEditorView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var job: Job
    @State private var draft: ScheduleDraft
    @State private var choosingDirectory = false
    let isNew: Bool

    init(job: Job, isNew: Bool) {
        _job = State(initialValue: job)
        _draft = State(initialValue: ScheduleDraft(job.schedule))
        self.isNew = isNew
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $job.name, prompt: Text("Back Up Notes"))
            }
            Section {
                TextField("Command", text: $job.command, prompt: Text("rsync -a ~/Notes /Volumes/Backup"), axis: .vertical)
                    .labelsHidden()
                    .multilineTextAlignment(.leading)
                    .font(.body.monospaced())
                    .lineLimit(4...12)
                LabeledContent("Working Directory") {
                    HStack(spacing: 8) {
                        Text(job.workingDirectory)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(.secondary)
                        Button("Choose…") { choosingDirectory = true }
                    }
                }
            } header: {
                Text("Command")
            } footer: {
                Text("Runs with zsh -c. Homebrew, mise, and ~/.local/bin are on PATH.")
                    .foregroundStyle(.secondary)
            }
            Section {
                Picker("Repeat", selection: $draft.kind) {
                    ForEach(ScheduleDraft.Kind.allCases) { Text($0.title).tag($0) }
                }
                switch draft.kind {
                case .interval:
                    Picker("Every", selection: $draft.intervalMinutes) {
                        ForEach(Schedule.intervalOptions, id: \.self) { Text(Schedule.durationLabel($0)).tag($0) }
                    }
                case .daily:
                    DatePicker("Time", selection: time, displayedComponents: .hourAndMinute)
                case .weekly:
                    LabeledContent("On") { WeekdayPicker(draft: $draft) }
                    DatePicker("Time", selection: time, displayedComponents: .hourAndMinute)
                }
                Picker("Start Within", selection: $job.startWithinHours) {
                    Text("Any time").tag(Int?.none)
                    ForEach(Job.startWithinOptions, id: \.self) { Text(Schedule.durationLabel($0 * 60)).tag(Int?.some($0)) }
                }
            } header: {
                Text("Schedule")
            } footer: {
                Text(nextRunText)
                    .foregroundStyle(.secondary)
            }
            Section {
                Toggle("Enabled", isOn: $job.isEnabled)
            }
        }
        .formStyle(.grouped)
        .frame(width: 520)
        .navigationTitle(isNew ? "New Job" : "Edit Job")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isNew ? "Add Job" : "Save") {
                    model.save(candidate)
                    dismiss()
                }
                .disabled(!candidate.isValid)
            }
        }
        .fileImporter(isPresented: $choosingDirectory, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result {
                job.workingDirectory = Job.abbreviatedPath(url.path(percentEncoded: false), home: model.home)
            }
        }
    }

    private var candidate: Job {
        var candidate = job
        candidate.name = job.name.trimmingCharacters(in: .whitespacesAndNewlines)
        candidate.schedule = draft.schedule
        return candidate
    }

    private var time: Binding<Date> {
        Binding(get: { draft.time() }, set: { draft.setTime($0) })
    }

    private var nextRunText: String {
        guard candidate.schedule.isValid else { return "Choose at least one day." }
        guard let next = candidate.schedule.nextRun(after: Date()) else { return "" }
        let text = "Next run \(Schedule.describe(next)). Jobs run when your Mac is awake or on power, and wait while it sleeps on battery. Sundial doesn't need to be open."
        guard let hours = candidate.startWithinHours else { return text }
        return text + " Runs that would start more than \(Schedule.durationLabel(hours * 60)) late, such as after sleep, are skipped."
    }
}

struct WeekdayPicker: View {
    @Binding var draft: ScheduleDraft

    var body: some View {
        let calendar = Calendar.current
        HStack(spacing: 4) {
            ForEach(Schedule.orderedWeekdays(calendar: calendar), id: \.self) { weekday in
                Toggle(
                    calendar.shortWeekdaySymbols[weekday - 1],
                    isOn: Binding(get: { draft.weekdays.contains(weekday) }, set: { _ in draft.toggle(weekday: weekday) })
                )
                .toggleStyle(.button)
                .help(calendar.weekdaySymbols[weekday - 1])
            }
        }
    }
}
