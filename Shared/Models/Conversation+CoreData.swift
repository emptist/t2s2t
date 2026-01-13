import Foundation
import CoreData

@objc(Conversation)
public class Conversation: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var language: String?
    @NSManaged public var topic: String?
    @NSManaged public var transcript: Data?
    @NSManaged public var feedbackSummary: String?
    @NSManaged public var fluencyScore: Double
    @NSManaged public var user: UserProfile?
}

extension Conversation {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Conversation> {
        return NSFetchRequest<Conversation>(entityName: "Conversation")
    }
    
    var duration: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }
    
    var transcriptText: String? {
        guard let data = transcript else { return nil }
        return String(data: data, encoding: .utf8)
    }
}