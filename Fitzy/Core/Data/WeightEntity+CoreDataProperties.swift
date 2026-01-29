//
//  WeightEntity+CoreDataProperties.swift
//  Fitzy
//
//  Created by Cagri Terzi on 29.01.2026.
//
//

public import Foundation
public import CoreData


public typealias WeightEntityCoreDataPropertiesSet = NSSet

extension WeightEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WeightEntity> {
        return NSFetchRequest<WeightEntity>(entityName: "WeightEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var day: Date?
    @NSManaged public var weightKg: Double
    @NSManaged public var photoFilename: String?
    @NSManaged public var note: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?

}

extension WeightEntity : Identifiable {

}
