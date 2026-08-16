import Foundation
import Photos
import UIKit

@Observable
final class PhotoLibraryManager {
    var assets: [MediaAsset] = []
    var authorizationStatus: PHAuthorizationStatus = .notDetermined
    var isLoading = false
    var errorMessage: String?

    private let imageManager = PHCachingImageManager()

    init() {
        self.authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run { self.authorizationStatus = status }
        if status == .authorized || status == .limited {
            await loadAssets()
        }
    }

    func loadAssets() async {
        await MainActor.run { self.isLoading = true }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let fetchResult = PHAsset.fetchAssets(with: options)
        var loaded: [MediaAsset] = []
        loaded.reserveCapacity(fetchResult.count)

        fetchResult.enumerateObjects { asset, _, _ in
            let size = Self.sizeOfAsset(asset)
            loaded.append(MediaAsset(id: asset.localIdentifier, asset: asset, sizeBytes: size))
        }

        await MainActor.run {
            self.assets = loaded
            self.isLoading = false
        }
    }

    /// PHAssetResource fileSize KVC hack. Kişisel/geliştirme kullanımı için OK,
    /// App Store review'da bazen soru işareti olabilir.
    static func sizeOfAsset(_ asset: PHAsset) -> Int64 {
        let resources = PHAssetResource.assetResources(for: asset)
        return resources.reduce(0) { sum, res in
            if let size = res.value(forKey: "fileSize") as? Int64 {
                return sum + size
            }
            if let num = res.value(forKey: "fileSize") as? NSNumber {
                return sum + num.int64Value
            }
            return sum
        }
    }

    func delete(_ mediaAssets: [MediaAsset]) async {
        let phAssets = mediaAssets.map { $0.asset }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(phAssets as NSFastEnumeration)
            }
            await loadAssets()
        } catch {
            await MainActor.run {
                self.errorMessage = "Silme iptal edildi veya başarısız: \(error.localizedDescription)"
            }
        }
    }

    func thumbnail(for asset: PHAsset, size: CGSize) async -> UIImage? {
        await withCheckedContinuation { cont in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = true
            options.resizeMode = .fast

            var didResume = false
            imageManager.requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded && !didResume {
                    didResume = true
                    cont.resume(returning: image)
                }
            }
        }
    }
}
