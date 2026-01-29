//
//  UserEntity+CoreDataProperties.swift
//  Fitzy
//
//  Created by Cagri Terzi on 29.01.2026.
//
//

public import Foundation
public import CoreData


public typealias UserEntityCoreDataPropertiesSet = NSSet

extension UserEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var heightCm: Double
    @NSManaged public var targetWeightKg: Double
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?

}

extension UserEntity : Identifiable {

}
