import MindEchoAudio
import MindEchoCore
import SwiftData
import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var transcriptionTargetRecording: Recording?
    @State private var isRecordingModalPresented = false
    @State private var shareItems: [Any]?

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
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("#\(recording.sequenceNumber)")
                                            .font(.headline)
                                        Text(formatTime(recording.recordedAt))
                                            .foregroundStyle(.secondary)
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
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if viewModel.playingRecordingId == recording.id && viewModel.isPlaying {
                                            viewModel.pausePlayback()
                                        } else {
                                            viewModel.playRecording(recording)
                                        }
                                    }

                                    if let summary = recording.summary {
                                        Text(summary)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                            .accessibilityIdentifier("home.summary.\(recording.sequenceNumber)")
                                    } else if let transcription = recording.transcription {
                                        Text(transcription)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                            .accessibilityIdentifier("home.transcription.\(recording.sequenceNumber)")
                                    }
                                }
                                .padding(.vertical, 12)
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if viewModel.todayEntry != nil && !(viewModel.todayEntry?.recordings.isEmpty ?? true) {
                        Menu {
                            Button {
                                exportAndShareAudio()
                            } label: {
                                Label("音声を共有", systemImage: "waveform")
                            }
                            .accessibilityIdentifier("home.shareAudioButton")

                            Button {
                                exportAndShareTranscript()
                            } label: {
                                Label("テキストを共有", systemImage: "doc.text")
                            }
                            .accessibilityIdentifier("home.shareTranscriptButton")
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityIdentifier("home.shareButton")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { shareItems != nil },
                set: { if !$0 { shareItems = nil } }
            )) {
                if let items = shareItems {
                    ShareSheet(activityItems: items)
                }
            }
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

    private func exportAndShareAudio() {
        Task {
            do {
                let url = try await viewModel.exportForSharing()
                shareItems = [url]
            } catch {
                // Handle error silently for now
            }
        }
    }

    private func exportAndShareTranscript() {
        do {
            let text = try viewModel.exportTranscriptForSharing()
            shareItems = [text]
        } catch {
            // Handle error silently for now
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
