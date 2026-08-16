import SwiftUI
import Photos

struct MediaRowView: View {
    let media: MediaAsset
    let manager: PhotoLibraryManager

    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .bottomTrailing) {
                    if media.isVideo {
                        Image(systemName: "play.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(Circle().fill(.black.opacity(0.55)))
                            .padding(4)
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(media.formattedSize)
                    .font(.headline)
                if let date = media.creationDate {
                    Text(date, format: .dateTime.day().month().year())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(media.isVideo ? "Video" : "Fotoğraf")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .task(id: media.id) {
            thumbnail = await manager.thumbnail(
                for: media.asset,
                size: CGSize(width: 128, height: 128)
            )
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnail {
            Image(uiImage: thumbnail)
                .resizable()
                .scaledToFill()
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay(ProgressView().scaleEffect(0.6))
        }
    }
}
