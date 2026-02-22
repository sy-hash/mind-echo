import DSWaveformImage
import DSWaveformImageViews
import MindEchoAudio
import MindEchoCore
import SwiftData
import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var showTextEditor = false
    @State private var editingText = ""

    init(
        modelContext: ModelContext,
        audioRecorder: any AudioRecording,
        transcriptionService: any Transcribing = TranscriptionService()
    ) {
        _viewModel = State(initialValue: HomeViewModel(
            modelContext: modelContext,
            audioRecorder: audioRecorder,
            transcriptionService: transcriptionService
        ))
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
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

                            WaveformLiveCanvas(
                                samples: viewModel.audioLevels,
                                configuration: Waveform.Configuration(
                                    style: .striped(.init(color: .red, width: 3, spacing: 3)),
                                    damping: .init()
                                ),
                                shouldDrawSilencePadding: false
                            )
                            .frame(height: 80)
                            .accessibilityIdentifier("home.waveform")
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
                            VStack(spacing: 0) {
                                ForEach(entry.sortedRecordings) { recording in
                                    HStack {
                                        Text("#\(recording.sequenceNumber)")
                                            .font(.headline)
                                        Text(formatDuration(recording.duration))
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Button {
                                            viewModel.startTranscription(for: recording)
                                        } label: {
                                            Image(systemName: "text.bubble")
                                                .foregroundStyle(.blue)
                                        }
                                        .accessibilityIdentifier("home.transcribeButton.\(recording.sequenceNumber)")
                                        .padding(.trailing, 8)
                                        Image(systemName: viewModel.playingRecordingId == recording.id && viewModel.isPlaying ? "pause.fill" : "play.fill")
                                    }
                                    .padding(.vertical, 12)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if viewModel.playingRecordingId == recording.id && viewModel.isPlaying {
                                            viewModel.pausePlayback()
                                        } else {
                                            viewModel.playRecording(recording)
                                        }
                                    }
                                    .accessibilityElement(children: .contain)
                                    .accessibilityIdentifier("home.recordingRow.\(recording.sequenceNumber)")

                                    if recording.id != entry.sortedRecordings.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("home.recordingsList")
                        } else {
                            Spacer()
                        }
                    }
                    .padding()
                    .frame(minHeight: geometry.size.height)
                }
            }
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
            .sheet(isPresented: $viewModel.showTranscriptionSheet) {
                TranscriptionSheet(
                    sequenceNumber: viewModel.transcriptionTargetRecording?.sequenceNumber ?? 0,
                    state: viewModel.transcriptionState,
                    onDismiss: {
                        viewModel.dismissTranscription()
                    }
                )
                .accessibilityIdentifier("home.transcriptionSheet")
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
