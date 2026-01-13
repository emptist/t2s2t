import CoreData
import SwiftUI

class DataController: ObservableObject {
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "T2S2T")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Sample Data for Preview
    @MainActor
    static var preview: DataController = {
        let controller = DataController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        // Create sample user
        let user = UserProfile(context: viewContext)
        user.id = UUID()
        user.name = "Sample User"
        user.targetLanguage = "es"
        user.nativeLanguage = "en"
        user.proficiencyLevel = "intermediate"
        user.createdAt = Date()
        
        // Create sample conversation
        let conversation = Conversation(context: viewContext)
        conversation.id = UUID()
        conversation.user = user
        conversation.startTime = Date().addingTimeInterval(-3600)
        conversation.endTime = Date()
        conversation.language = "es"
        conversation.topic = "Greetings"
        
        // Create sample progress
        let progress = ProgressEntry(context: viewContext)
        progress.id = UUID()
        progress.user = user
        progress.date = Date()
        progress.fluencyScore = 0.75
        progress.vocabularyScore = 0.68
        progress.grammarScore = 0.82
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save preview data: \(error)")
        }
        
        return controller
    }()
    
    // MARK: - Helper Methods
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    func delete(_ object: NSManagedObject) {
        container.viewContext.delete(object)
        save()
    }
    
    func fetchUserProfile() -> UserProfile? {
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let results = try container.viewContext.fetch(request)
            return results.first
        } catch {
            print("Failed to fetch user profile: \(error)")
            return nil
        }
    }
    
    func createUserProfile(name: String, targetLanguage: String, nativeLanguage: String, proficiency: String) -> UserProfile {
        let user = UserProfile(context: container.viewContext)
        user.id = UUID()
        user.name = name
        user.targetLanguage = targetLanguage
        user.nativeLanguage = nativeLanguage
        user.proficiencyLevel = proficiency
        user.createdAt = Date()
        
        save()
        return user
    }
}