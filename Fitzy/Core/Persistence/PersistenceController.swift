//
//  PersistenceController.swift
//  Fitzy
//
//  Created by Cagri Terzi on 29.01.2026.
//


import CoreData
import Foundation
import os.log

final class PersistenceController {
    static let shared = PersistenceController()

    /// SwiftUI previews / Canvas için in-memory store
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)

        let viewContext = controller.container.viewContext

        // Seed preview data (opsiyonel)
        let user = UserEntity(context: viewContext)
        user.id = UUID()
        user.heightCm = 178
        user.targetWeightKg = 72
        user.createdAt = Date()
        user.updatedAt = Date()

        // Son 10 gün demo weight
        let cal = Calendar.current
        for i in 0..<10 {
            let e = WeightEntity(context: viewContext)
            e.id = UUID()
            e.day = cal.startOfDay(for: cal.date(byAdding: .day, value: -i, to: Date())!)
            e.weightKg = 75.0 - Double(i) * 0.2
            e.note = (i % 3 == 0) ? "Felt good" : nil
            e.createdAt = Date()
            e.updatedAt = Date()
        }

        do {
            try viewContext.save()
        } catch {
            assertionFailure("Preview seed save failed: \(error)")
        }
        return controller
    }()

    let container: NSPersistentContainer
    private let logger = Logger(subsystem: "com.fitzy.app", category: "CoreData")

    /// - Parameter inMemory: true ise store RAM'de tutulur (Preview için ideal)
    init(inMemory: Bool = false) {
        // ✅ Model adı: FitzyDataModel
        container = NSPersistentContainer(name: "FitzyDataModel")

        if inMemory {
            let desc = NSPersistentStoreDescription()
            desc.type = NSInMemoryStoreType
            desc.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [desc]
        }

        container.loadPersistentStores { [weak self] _, error in
            guard let self else { return }
            if let error {
                // Debug'da hızlı yakala, release'de logla
                #if DEBUG
                fatalError("Unresolved Core Data error: \(error)")
                #else
                self.logger.error("Core Data store load failed: \(error.localizedDescription)")
                #endif
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.shouldDeleteInaccessibleFaults = true

        // (İstersen) performans için:
        container.viewContext.undoManager = nil
    }

    // MARK: - Save helpers

    func save(context: NSManagedObjectContext? = nil) {
        let ctx = context ?? container.viewContext
        guard ctx.hasChanges else { return }

        do {
            try ctx.save()
        } catch {
            #if DEBUG
            logger.error("Core Data save failed: \(error.localizedDescription)")
            assertionFailure("Core Data save failed: \(error)")
            #else
            logger.error("Core Data save failed: \(error.localizedDescription)")
            #endif
        }
    }

    /// Background context (import, batch işleri vb.)
    func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        ctx.automaticallyMergesChangesFromParent = true
        ctx.undoManager = nil
        return ctx
    }
}