import Foundation

/// 月間共有時の出力形式
public enum MonthlyShareFormat: String, CaseIterable, Identifiable, Sendable {
    case pdf
    case audio
    case text

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .pdf: "PDF"
        case .audio: "音声"
        case .text: "テキスト"
        }
    }

    public var description: String {
        switch self {
        case .pdf: "日別の書き起こしをPDFで出力"
        case .audio: "日別のマージ音声ファイルを出力"
        case .text: "日別のテキストファイルを出力"
        }
    }
}
