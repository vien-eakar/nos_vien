//
//  SocialGraph.swift
//  Nos
//
//  Created by Matthew Lorentz on 4/18/23.
//

import Foundation
import CoreData
import Logger

/// A representation of the people a given user follows and the people they follow designed to cache this data in 
/// memory and make it fast to access. This class watches the database for changes to the social graph and updates 
/// itself accordingly.
@MainActor class SocialGraph: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    
    // MARK: Public interface 
    
    var inNetworkKeys: [HexadecimalString] {
        [user.hexadecimalPublicKey!] + Array(oneHopKeys) + Array(twoHopKeys)
    }
    
    var followedKeys: [HexadecimalString] {
        [user.hexadecimalPublicKey!] + Array(oneHopKeys) 
    }
    
    func contains(_ key: HexadecimalString?) -> Bool {
        guard let key else {
            return false
        }
        
        return twoHopKeys.contains(key) || oneHopKeys.contains(key) || user.hexadecimalPublicKey == key
    }
    
    // MARK: - Private properties
    
    private let user: Author
    private let context: NSManagedObjectContext
    
    private var userWatcher: NSFetchedResultsController<Author>
    private var oneHopWatcher: NSFetchedResultsController<Author>
    
    private(set) var oneHopKeys: Set<HexadecimalString>
    private(set) var twoHopKeys: Set<HexadecimalString>
    
    private var oneHopAuthors: [HexadecimalString: Author]
    private var twoHopReferences: [HexadecimalString: Int]

    init(userKey: HexadecimalString, context: NSManagedObjectContext) async {
        self.user = await context.perform {
            try! Author.findOrCreate(by: userKey, context: context)
        }
        self.context = context
        self.oneHopKeys = Set()
        self.twoHopKeys = Set()
        self.oneHopAuthors = [:]
        self.twoHopReferences = [:]
        
        userWatcher = NSFetchedResultsController(
            fetchRequest: Author.request(by: userKey),
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: "SocialGraph.userWatcher"
        )
        oneHopWatcher = NSFetchedResultsController(
            fetchRequest: Author.oneHopRequest(for: user),
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: "SocialGraph.oneHopWatcher"
        )
        
        super.init()
        
        userWatcher.delegate = self
        try! userWatcher.performFetch()
        oneHopWatcher.delegate = self
        try! oneHopWatcher.performFetch()
        oneHopWatcher.fetchedObjects?.forEach {
            process(followed: $0)
        }
    }
    
    // MARK: - Processing Changes
    
    private func process(followed author: Author) {
        guard let authorKey = author.hexadecimalPublicKey else {
            Log.error("SocialGraph cannot process followed author with no key")
            return
        }
        
        oneHopAuthors[authorKey] = author
        oneHopKeys.insert(authorKey)
        author.follows?.forEach { 
            if let follow = $0 as? Follow,
                let followedKey = follow.destination?.hexadecimalPublicKey {
                twoHopKeys.insert(followedKey)
                var referenceCount = twoHopReferences[followedKey] ?? 0
                referenceCount += 1
                twoHopReferences[followedKey] = referenceCount
            }
        }
    }
    
    private func process(unfollowed author: Author) {
        guard let authorKey = author.hexadecimalPublicKey else {
            Log.error("SocialGraph cannot process unfollowed author with no key")
            return
        }
        
        oneHopAuthors.removeValue(forKey: authorKey)
        oneHopKeys.remove(authorKey)
        author.follows?.forEach { 
            if let follow = $0 as? Follow,
                let followedKey = follow.destination?.hexadecimalPublicKey {
                let referenceCount = twoHopReferences[followedKey] ?? 1
                if referenceCount <= 1 {
                    twoHopKeys.remove(followedKey)
                    twoHopReferences.removeValue(forKey: followedKey)
                }
            }
        }
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    nonisolated func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>, 
        didChange anObject: Any, 
        at indexPath: IndexPath?, 
        for type: NSFetchedResultsChangeType, 
        newIndexPath: IndexPath?
    ) {
        guard let author = anObject as? Author else {
            return
        }
        
        Task { @MainActor in
            if controller === oneHopWatcher {
                switch type {
                case .insert:
                    process(followed: author)
                case .delete:
                    process(unfollowed: author)
                case .update:
                    process(unfollowed: author)
                    process(followed: author)
                case .move:
                    return
                @unknown default:
                    return
                }
            }
        }
    }
}
