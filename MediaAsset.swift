import Foundation
import Photos

struct MediaAsset: Identifiable, Hashable {
    let id: String
    let asset: PHAsset
    let sizeBytes: Int64

    var isVideo: Bool { asset.mediaType == .video }
    var creationDate: Date? { asset.creationDate }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: MediaAsset, rhs: MediaAsset) -> Bool { lhs.id == rhs.id }
}

enum MediaSortOrder: String, CaseIterable, Identifiable {
    case sizeAscending, sizeDescending, dateNewest, dateOldest
    var id: String { rawValue }

    var label: String {
        switch self {
        case .sizeAscending:  return "Boyut ↑ (küçük → büyük)"
        case .sizeDescending: return "Boyut ↓ (büyük → küçük)"
        case .dateNewest:     return "Yeniden eskiye"
        case .dateOldest:     return "Eskiden yeniye"
        }
    }
}

enum MediaFilter: String, CaseIterable, Identifiable {
    case all, photos, videos
    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:    return "Tümü"
        case .photos: return "Fotoğraflar"
        case .videos: return "Videolar"
        }
    }
}
