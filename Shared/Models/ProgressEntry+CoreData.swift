import Foundation
import CoreData

@objc(ProgressEntry)
public class ProgressEntry: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var fluencyScore: Double
    @NSManaged public var grammarScore: Double
    @NSManaged public var vocabularyScore: Double
    @NSManaged public var totalPracticeMinutes: Int32
    @NSManaged public var user: UserProfile?
}

extension ProgressEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProgressEntry> {
        return NSFetchRequest<ProgressEntry>(entityName: "ProgressEntry")
    }
    
    var overallScore: Double {
        return (fluencyScore + grammarScore + vocabularyScore) / 3.0
    }
    
    var formattedDate: String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}