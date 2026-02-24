import MindEchoAudio
import MindEchoCore
import SwiftData
import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var transcriptionTargetRecording: Recording?
    @State private var isRecordingModalPresented = false

    init(modelContext: ModelContext, audioRecorder: any AudioRecording) {
        _viewModel = State(initialValue: HomeViewModel(
            modelContext: modelContext,
            audioRecorder: audioRecorder
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date display
                    Text(DateHelper.displayString(for: DateHelper.today()))
                        .font(.title2)
                        .accessibilityIdentifier("home.dateLabel")

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
                                        transcriptionTargetRecording = recording
                                    } label: {
                                        Image(systemName: recording.hasTranscription ? "doc.text.fill" : "doc.text")
                                    }
                                    .accessibilityIdentifier("home.transcribeButton.\(recording.sequenceNumber)")
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
                                .accessibilityElement(children: .combine)
                                .accessibilityAddTraits(.isButton)
                                .accessibilityIdentifier("home.recordingRow.\(recording.sequenceNumber)")

                                if recording.id != entry.sortedRecordings.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("home.recordingsList")
                    }
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    isRecordingModalPresented = true
                } label: {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.red)
                }
                .accessibilityIdentifier("home.recordButton")
                .padding(.vertical)
            }
            .navigationTitle("今日")
            .onAppear {
                viewModel.fetchTodayEntry()
            }
            .sheet(isPresented: $isRecordingModalPresented, onDismiss: {
                if viewModel.isRecording {
                    viewModel.stopRecording()
                }
                viewModel.resetTranscriptionState()
                viewModel.fetchTodayEntry()
            }) {
                RecordingModalView(viewModel: viewModel)
            }
            .sheet(item: $transcriptionTargetRecording) { recording in
                TranscriptionView(recording: recording)
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
