//
//  PhotoStoreError.swift
//  Fitzy
//
//  Created by Cagri Terzi on 29.01.2026.
//


import Foundation
import UIKit
import os.log

enum PhotoStoreError: Error {
    case couldNotCreateDirectory
    case invalidImageData
    case writeFailed
}

final class PhotoStore {
    static let shared = PhotoStore()

    private let logger = Logger(subsystem: "com.fitzy.app", category: "PhotoStore")

    // Klasör adları
    private let photosFolderName = "FitzyPhotos"

    // Dosya adları
    private func photoName(for id: UUID) -> String { "\(id.uuidString).jpg" }
    private func thumbName(for id: UUID) -> String { "\(id.uuidString)_thumb.jpg" }

    // MARK: - Public API

    /// Kaydeder ve Core Data'da saklamak üzere filename döner (örn: "<uuid>.jpg")
    func saveJPEG(image: UIImage,
                  for entryID: UUID,
                  quality: CGFloat = 0.85,
                  alsoSaveThumbnail: Bool = true,
                  thumbnailMaxPixel: CGFloat = 320) throws -> String {

        try ensureDirectoryExists()

        let filename = photoName(for: entryID)
        let fileURL = url(for: filename)

        guard let data = image.jpegData(compressionQuality: quality) else {
            throw PhotoStoreError.invalidImageData
        }

        do {
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            logger.error("Write photo failed: \(error.localizedDescription)")
            throw PhotoStoreError.writeFailed
        }

        if alsoSaveThumbnail {
            let thumb = image.resizedMaintainingAspectRatio(maxPixel: thumbnailMaxPixel)
            _ = try? saveThumbnailJPEG(image: thumb, for: entryID, quality: 0.8)
        }

        return filename
    }

    /// Thumbnail'ı ayrı dosya olarak kaydeder: "<uuid>_thumb.jpg"
    func saveThumbnailJPEG(image: UIImage,
                           for entryID: UUID,
                           quality: CGFloat = 0.8) throws -> String {
        try ensureDirectoryExists()

        let filename = thumbName(for: entryID)
        let fileURL = url(for: filename)

        guard let data = image.jpegData(compressionQuality: quality) else {
            throw PhotoStoreError.invalidImageData
        }

        do {
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            logger.error("Write thumbnail failed: \(error.localizedDescription)")
            throw PhotoStoreError.writeFailed
        }

        return filename
    }

    func loadImage(filename: String) -> UIImage? {
        let fileURL = url(for: filename)
        return UIImage(contentsOfFile: fileURL.path)
    }

    /// entry id ile direkt yüklemek istersen
    func loadImage(for entryID: UUID) -> UIImage? {
        loadImage(filename: photoName(for: entryID))
    }

    func loadThumbnail(for entryID: UUID) -> UIImage? {
        loadImage(filename: thumbName(for: entryID))
    }

    func delete(filename: String) {
        let fileURL = url(for: filename)
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            // dosya yoksa vb. sorun etmeyelim
            logger.debug("Delete failed (ignored): \(error.localizedDescription)")
        }
    }

    /// Entry silerken hem foto hem thumb temizlemek için
    func deleteAll(for entryID: UUID, storedFilename: String? = nil) {
        if let storedFilename {
            delete(filename: storedFilename)
        } else {
            delete(filename: photoName(for: entryID))
        }
        delete(filename: thumbName(for: entryID))
    }

    /// Debug/yardım: foto klasörünün url'si
    func photosDirectoryURL() throws -> URL {
        try ensureDirectoryExists()
        return try directoryURL()
    }

    // MARK: - Internals

    private func directoryURL() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return base.appendingPathComponent(photosFolderName, isDirectory: true)
    }

    private func url(for filename: String) -> URL {
        // directoryURL() throw ettiği için burada "best effort" yapıyoruz
        // init zamanı directory henüz yoksa da create etmeyi save tarafında yapıyoruz
        let base = (try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? FileManager.default.temporaryDirectory

        let dir = base.appendingPathComponent(photosFolderName, isDirectory: true)
        return dir.appendingPathComponent(filename, isDirectory: false)
    }

    private func ensureDirectoryExists() throws {
        let dir = try directoryURL()
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir)

        if exists {
            if isDir.boolValue { return }
            // aynı isimli dosya varsa silip klasör açalım
            try? FileManager.default.removeItem(at: dir)
        }

        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        } catch {
            logger.error("Could not create photos dir: \(error.localizedDescription)")
            throw PhotoStoreError.couldNotCreateDirectory
        }
    }
}

// MARK: - UIImage helpers

private extension UIImage {
    /// En büyük kenarı maxPixel olacak şekilde oranı bozmadan küçültür (thumbnail için)
    func resizedMaintainingAspectRatio(maxPixel: CGFloat) -> UIImage {
        let size = self.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxPixel else { return self }

        let scale = maxPixel / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1 // thumbnail için yeterli; ister 0 yapıp ekran scale kullanabilirsin
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)

        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
