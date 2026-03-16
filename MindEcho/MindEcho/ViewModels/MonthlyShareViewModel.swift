import Foundation
import MindEchoCore
import Observation
import SwiftData

@Observable
@MainActor
class MonthlyShareViewModel {
    enum ExportState: Equatable {
        case idle
        case exporting(current: Int, total: Int)
        case done([URL])
        case failure(String)
    }

    struct AvailableMonth: Identifiable, Equatable {
        let year: Int
        let month: Int
        let entryCount: Int
        let recordingCount: Int

        var id: String { String(format: "%04d%02d", year, month) }

        var displayString: String {
            // "2026年3月（5件）" のような文字列を表示用に構築
            // DateHelper.monthDisplayString を利用するため Date に変換
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 15  // 月の中頃を指定（正午換算はしない）
            let date = Calendar.current.date(from: components) ?? Date()
            let monthStr = DateHelper.monthDisplayString(for: date)
            return "\(monthStr)（\(entryCount)件）"
        }
    }

    var availableMonths: [AvailableMonth] = []
    var selectedMonth: AvailableMonth?
    var selectedFormat: MonthlyShareFormat = .pdf
    var exportState: ExportState = .idle

    private let modelContext: ModelContext
    private let exportService: ExportServiceImpl

    init(modelContext: ModelContext, exportService: ExportServiceImpl = ExportServiceImpl()) {
        self.modelContext = modelContext
        self.exportService = exportService
    }

    // MARK: - Data Loading

    func fetchAvailableMonths() {
        let descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let allEntries = (try? modelContext.fetch(descriptor)) ?? []

        // year-month でグループ化
        var groupedByMonth: [String: (year: Int, month: Int, entries: [JournalEntry])] = [:]
        let cal = Calendar.current

        for entry in allEntries {
            let comps = cal.dateComponents([.year, .month], from: entry.date)
            guard let year = comps.year, let month = comps.month else { continue }
            let key = String(format: "%04d%02d", year, month)
            if groupedByMonth[key] == nil {
                groupedByMonth[key] = (year: year, month: month, entries: [])
            }
            groupedByMonth[key]?.entries.append(entry)
        }

        // 降順ソートして AvailableMonth に変換
        availableMonths = groupedByMonth.values
            .sorted { a, b in
                if a.year != b.year { return a.year > b.year }
                return a.month > b.month
            }
            .map { group in
                let totalRecordings = group.entries.reduce(0) { $0 + $1.recordings.count }
                return AvailableMonth(
                    year: group.year,
                    month: group.month,
                    entryCount: group.entries.count,
                    recordingCount: totalRecordings
                )
            }
    }

    // MARK: - Export

    func exportMonth() async {
        guard let selectedMonth else { return }

        let yearMonth = selectedMonth.id  // "yyyyMM"
        let batchDir = FilePathManager.exportBatchDirectory(for: yearMonth)

        // 対象月のエントリを取得（日付昇順）
        let cal = Calendar.current
        var startComps = DateComponents()
        startComps.year = selectedMonth.year
        startComps.month = selectedMonth.month
        startComps.day = 1
        guard let firstDay = cal.date(from: startComps) else {
            exportState = .failure("月の開始日を計算できませんでした。")
            return
        }
        let (rangeStart, rangeEnd) = DateHelper.monthRange(for: firstDay, calendar: cal)

        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate {
                $0.date >= rangeStart && $0.date <= rangeEnd
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let entries = (try? modelContext.fetch(descriptor)) ?? []

        // 録音がある（音声: 録音あり / テキスト・PDF: 書き起こしあり）エントリのみ対象
        let targetEntries = entries.filter { entry in
            switch selectedFormat {
            case .audio:
                return !entry.recordings.isEmpty
            case .text, .pdf:
                return entry.recordings.contains { $0.transcription != nil && !($0.transcription!.isEmpty) }
            }
        }

        guard !targetEntries.isEmpty else {
            exportState = .failure("選択した月に共有できるデータがありません。")
            return
        }

        exportState = .exporting(current: 0, total: targetEntries.count)

        do {
            try FilePathManager.ensureDirectoryExists(batchDir)
        } catch {
            exportState = .failure("出力ディレクトリの作成に失敗しました: \(error.localizedDescription)")
            return
        }

        var exportedURLs: [URL] = []

        for (index, entry) in targetEntries.enumerated() {
            exportState = .exporting(current: index + 1, total: targetEntries.count)

            do {
                let url: URL
                switch selectedFormat {
                case .audio:
                    url = try await exportService.exportMergedAudio(entry: entry, to: batchDir)
                case .text:
                    url = try exportService.exportCombinedTranscript(entry: entry, to: batchDir)
                case .pdf:
                    url = try exportService.exportDailyPDF(entry: entry, to: batchDir)
                }
                exportedURLs.append(url)
            } catch {
                // 個別エントリのエクスポート失敗はスキップして続行
                continue
            }
        }

        if exportedURLs.isEmpty {
            exportState = .failure("ファイルの生成に失敗しました。")
        } else {
            exportState = .done(exportedURLs)
        }
    }

    func resetExportState() {
        exportState = .idle
    }
}
