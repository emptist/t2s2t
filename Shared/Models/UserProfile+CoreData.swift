import Foundation
import CoreData

@objc(UserProfile)
public class UserProfile: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var targetLanguage: String?
    @NSManaged public var nativeLanguage: String?
    @NSManaged public var proficiencyLevel: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var conversations: Set<Conversation>?
    @NSManaged public var progressEntries: Set<ProgressEntry>?
}

extension UserProfile {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfile> {
        return NSFetchRequest<UserProfile>(entityName: "UserProfile")
    }
    
    @objc(addConversationsObject:)
    @NSManaged public func addToConversations(_ value: Conversation)
    
    @objc(removeConversationsObject:)
    @NSManaged public func removeFromConversations(_ value: Conversation)
    
    @objc(addConversations:)
    @NSManaged public func addToConversations(_ values: Set<Conversation>)
    
    @objc(removeConversations:)
    @NSManaged public func removeFromConversations(_ values: Set<Conversation>)
    
    @objc(addProgressEntriesObject:)
    @NSManaged public func addToProgressEntries(_ value: ProgressEntry)
    
    @objc(removeProgressEntriesObject:)
    @NSManaged public func removeFromProgressEntries(_ value: ProgressEntry)
    
    @objc(addProgressEntries:)
    @NSManaged public func addToProgressEntries(_ values: Set<ProgressEntry>)
    
    @objc(removeProgressEntries:)
    @NSManaged public func removeFromProgressEntries(_ values: Set<ProgressEntry>)
}