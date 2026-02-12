import MindEchoAudio
import MindEchoCore
import SwiftData
import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var showTextEditor = false
    @State private var editingText = ""

    init(modelContext: ModelContext, audioRecorder: any AudioRecording) {
        _viewModel = State(initialValue: HomeViewModel(
            modelContext: modelContext,
            audioRecorder: audioRecorder
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Date display
                Text(DateHelper.displayString(for: DateHelper.today()))
                    .font(.title2)
                    .accessibilityIdentifier("home.dateLabel")

                Spacer()

                // Recording duration (shown when recording)
                if viewModel.isRecording {
                    Text(formatDuration(viewModel.recordingDuration))
                        .font(.system(.largeTitle, design: .monospaced))
                        .accessibilityIdentifier("home.recordingDuration")
                }

                // Recording controls
                HStack(spacing: 30) {
                    if viewModel.isRecording {
                        if viewModel.isRecordingPaused {
                            Button { viewModel.resumeRecording() } label: {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 50))
                            }
                            .accessibilityIdentifier("home.resumeButton")
                        } else {
                            Button { viewModel.pauseRecording() } label: {
                                Image(systemName: "pause.circle.fill")
                                    .font(.system(size: 50))
                            }
                            .accessibilityIdentifier("home.pauseButton")
                        }

                        Button { viewModel.stopRecording() } label: {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.red)
                        }
                        .accessibilityIdentifier("home.stopButton")
                    } else {
                        Button { viewModel.startRecording() } label: {
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 70))
                                .foregroundStyle(.red)
                        }
                        .accessibilityIdentifier("home.recordButton")
                    }
                }

                // Text input button
                Button {
                    editingText = viewModel.todayEntry?.sortedTextEntries.first?.content ?? ""
                    showTextEditor = true
                } label: {
                    Label("テキスト入力", systemImage: "square.and.pencil")
                }
                .accessibilityIdentifier("home.textInputButton")

                // Today's recordings list
                if let entry = viewModel.todayEntry, !entry.recordings.isEmpty {
                    List {
                        ForEach(entry.sortedRecordings) { recording in
                            Button {
                                if viewModel.playingRecordingId == recording.id && viewModel.isPlaying {
                                    viewModel.pausePlayback()
                                } else {
                                    viewModel.playRecording(recording)
                                }
                            } label: {
                                HStack {
                                    Text("#\(recording.sequenceNumber)")
                                        .font(.headline)
                                    Text(formatDuration(recording.duration))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Image(systemName: viewModel.playingRecordingId == recording.id && viewModel.isPlaying ? "pause.fill" : "play.fill")
                                }
                            }
                            .buttonStyle(.borderless)
                            .accessibilityIdentifier("home.recordingRow.\(recording.sequenceNumber)")
                        }
                    }
                    .accessibilityIdentifier("home.recordingsList")
                } else {
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("今日")
            .onAppear {
                viewModel.fetchTodayEntry()
            }
            .sheet(isPresented: $showTextEditor) {
                TextEditorSheet(
                    text: $editingText,
                    onSave: {
                        viewModel.saveText(editingText)
                        showTextEditor = false
                    },
                    onCancel: {
                        showTextEditor = false
                    }
                )
                .accessibilityIdentifier("home.textEditorSheet")
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
