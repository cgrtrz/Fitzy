import Foundation
import Combine
import CoreData
import SwiftUI
import os.log

@MainActor
final class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()

    // MARK: - Published state for UI
    @Published private(set) var user: UserEntity?
    @Published private(set) var todayEntry: WeightEntity?
    @Published private(set) var recentEntries: [WeightEntity] = []

    // MARK: - Core Data
    let container: NSPersistentContainer
    var viewContext: NSManagedObjectContext { container.viewContext }

    private let logger = Logger(subsystem: "com.fitzy.app", category: "CoreDataManager")

    // MARK: - Init
    init(inMemory: Bool = false) {
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
                #if DEBUG
                fatalError("Core Data load error: \(error)")
                #else
                self.logger.error("Core Data load error: \(error.localizedDescription)")
                #endif
            }
        }

        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.undoManager = nil

        // İlk yüklemeler
        refreshAll()
    }

    // MARK: - Refresh
    func refreshAll() {
        user = fetchUser()
        todayEntry = fetchEntry(for: Date())
        recentEntries = fetchRecentEntries(daysBack: 90) // grafiğe yetecek default
    }

    // MARK: - User
    func getOrCreateUser() -> UserEntity {
        if let user { return user }

        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.fetchLimit = 1

        if let existing = try? viewContext.fetch(request).first {
            self.user = existing
            return existing
        }

        let created = UserEntity(context: viewContext)
        created.id = UUID()
        created.heightCm = 170
        created.targetWeightKg = 70
        created.createdAt = Date()
        created.updatedAt = Date()

        save()
        self.user = created
        return created
    }

    func updateUser(heightCm: Double? = nil, targetWeightKg: Double? = nil) {
        let u = getOrCreateUser()
        if let heightCm { u.heightCm = heightCm }
        if let targetWeightKg { u.targetWeightKg = targetWeightKg }
        u.updatedAt = Date()
        save()
        self.user = u
    }

    // MARK: - Weight Entries

    /// Aynı gün kayıt varsa update eder, yoksa create eder.
    func upsertEntry(date: Date, weightKg: Double, photoFilename: String? = nil, note: String? = nil) -> WeightEntity {
        let day = Calendar.current.startOfDay(for: date)

        let entry = fetchEntry(forDay: day) ?? WeightEntity(context: viewContext)

        if entry.id == nil { entry.id = UUID() }
        entry.day = day
        entry.weightKg = weightKg
        if let photoFilename { entry.photoFilename = photoFilename }
        entry.note = note

        let now = Date()
        if entry.createdAt == nil { entry.createdAt = now }
        entry.updatedAt = now

        save()
        // Published state güncelle
        if Calendar.current.isDateInToday(day) {
            todayEntry = entry
        }
        recentEntries = fetchRecentEntries(daysBack: 90)

        return entry
    }

    func deleteEntry(_ entry: WeightEntity) {
        viewContext.delete(entry)
        save()
        refreshAll()
    }

    func deleteEntry(for date: Date) {
        if let e = fetchEntry(for: date) {
            deleteEntry(e)
        }
    }

    // MARK: - Fetch helpers

    func fetchUser() -> UserEntity? {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }

    func fetchEntry(for date: Date) -> WeightEntity? {
        let day = Calendar.current.startOfDay(for: date)
        return fetchEntry(forDay: day)
    }

    private func fetchEntry(forDay day: Date) -> WeightEntity? {
        let request: NSFetchRequest<WeightEntity> = WeightEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "day == %@", day as NSDate)
        return try? viewContext.fetch(request).first
    }

    func fetchRecentEntries(daysBack: Int) -> [WeightEntity] {
        let request: NSFetchRequest<WeightEntity> = WeightEntity.fetchRequest()

        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        let startDay = cal.startOfDay(for: start)

        request.predicate = NSPredicate(format: "day >= %@", startDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "day", ascending: true)]

        return (try? viewContext.fetch(request)) ?? []
    }

    // MARK: - Save

    func save() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            logger.error("Save failed: \(error.localizedDescription)")
            #if DEBUG
            assertionFailure("Core Data save failed: \(error)")
            #endif
        }
    }

    // MARK: - Background (opsiyon)
    func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        ctx.automaticallyMergesChangesFromParent = true
        ctx.undoManager = nil
        return ctx
    }
}
