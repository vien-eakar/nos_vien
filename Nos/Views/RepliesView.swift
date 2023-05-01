//
//  RepliesView.swift
//  Nos
//
//  Created by Matthew Lorentz on 2/14/23.
//

import SwiftUI
import SwiftUINavigation
import Dependencies

struct RepliesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var relayService: RelayService
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var currentUser: CurrentUser
    @Dependency(\.analytics) private var analytics

    @State private var reply = ""
    
    @State private var alert: AlertState<Never>?
    
    @State private var subscriptionIDs = [String]()
    
    var repliesRequest: FetchRequest<Event>
    /// All replies
    var replies: FetchedResults<Event> { repliesRequest.wrappedValue }
    
    var directReplies: [Event] {
        replies.filter { (reply: Event) in
            guard let eventReferences = reply.eventReferences?.array as? [EventReference] else {
                return false
            }
            
            let containsRootMarker = eventReferences.contains(where: { (eventReference: EventReference) in
                eventReference.type == .root
            })
            
            let referencesNoteAsRoot = eventReferences.contains(where: { (eventReference: EventReference) in
                eventReference.eventId == note.identifier && eventReference.type == .root
            })
            
            let containsReplyMarker = eventReferences.contains(where: { (eventReference: EventReference) in
                eventReference.type == .reply
            })
            
            let referencesNoteAsReply = eventReferences.contains(where: { (eventReference: EventReference) in
                eventReference.eventId == note.identifier && eventReference.type == .reply
            })
            
            // This is sloppy, but I'm writing it anyway in a rush.
            // TODO: make sure there isn't a #[0] event reference this is referring to
            let referencesNoteTheDeprecatedWay = eventReferences.last?.eventId == note.identifier
            
            return (referencesNoteAsRoot && !containsReplyMarker) ||
                referencesNoteAsReply ||
                (!containsRootMarker && !containsReplyMarker && referencesNoteTheDeprecatedWay)
        }
    }
    
    init(note: Event) {
        self.note = note
        self.repliesRequest = FetchRequest(fetchRequest: Event.allReplies(to: note))
    }
    
    var note: Event
    
    func subscribeToReplies() {
        Task(priority: .userInitiated) {
            // Close out stale requests
            if !subscriptionIDs.isEmpty {
                await relayService.removeSubscriptions(for: subscriptionIDs)
                subscriptionIDs.removeAll()
            }
            
            let eTags = ([note.identifier] + replies.map { $0.identifier }).compactMap { $0 }
            let filter = Filter(kinds: [.text, .like, .delete], eTags: eTags)
            let subID = await relayService.openSubscription(with: filter)
            subscriptionIDs.append(subID)
        }
    }
    
    var body: some View {
        VStack {
            ScrollView(.vertical) {
                VStack {
                    NoteButton(
                        note: note,
                        showFullMessage: true,
                        hideOutOfNetwork: false,
                        allowsPush: false,
                        showReplyCount: false
                    )                                
                    .padding(.top, 15)
                    
                    ForEach(directReplies.reversed()) { event in
                        ThreadView(root: event, allReplies: replies.reversed())
                    }
                }
                .padding(.bottom)
            }
            .padding(.top, 1)
            .nosNavigationBar(title: .thread)
            .onAppear {
                subscribeToReplies()
            }
            .refreshable {
                subscribeToReplies()
            }
            .onDisappear {
                Task(priority: .userInitiated) {
                    await relayService.removeSubscriptions(for: subscriptionIDs)
                    subscriptionIDs.removeAll()
                }
            }
            VStack {
                Spacer()
                VStack {
                    HStack(spacing: 10) {
                        if let author = currentUser.author {
                            AvatarView(imageUrl: author.profilePhotoURL, size: 35)
                        }
                        ExpandingTextFieldAndSubmitButton(
                            placeholder: Localized.Reply.postAReply.string,
                            reply: $reply
                        ) {
                            await postReply(reply)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color.cardBgBottom)
            .fixedSize(horizontal: false, vertical: true)
            .onAppear {
                analytics.showedThread()
            }
        }
        .background(Color.appBg)
    }
    
    func postReply(_ replyText: String) async {
        do {
            guard !replyText.isEmpty else {
                return
            }

            guard let keyPair = currentUser.keyPair else {
                alert = AlertState(title: {
                    TextState(Localized.error.string)
                }, message: {
                    TextState(Localized.youNeedToEnterAPrivateKeyBeforePosting.string)
                })
                return
            }
            
            var tags: [[String]] = [["p", note.author!.publicKey!.hex]]
            // If `note` is a reply to another root, tag that root
            if let rootNoteIdentifier = note.rootNote()?.identifier, rootNoteIdentifier != note.identifier {
                tags.append(["e", rootNoteIdentifier, "", EventReferenceMarker.root.rawValue])
                tags.append(["e", note.identifier!, "", EventReferenceMarker.reply.rawValue])
            } else {
                tags.append(["e", note.identifier!, "", EventReferenceMarker.root.rawValue])
            }
            
            // print("tags: \(tags)")
            let jsonEvent = JSONEvent(
                id: "",
                pubKey: keyPair.publicKeyHex,
                createdAt: Int64(Date().timeIntervalSince1970),
                kind: 1,
                tags: tags,
                content: replyText,
                signature: ""
            )
            try await relayService.publishToAll(event: jsonEvent, signingKey: keyPair, context: viewContext)
        } catch {
            alert = AlertState(title: {
                TextState(Localized.error.string)
            }, message: {
                TextState(error.localizedDescription)
            })
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this
            // function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
struct RepliesView_Previews: PreviewProvider {
    
    static var persistenceController = {
        let persistenceController = PersistenceController.preview
        KeyChain.save(key: KeyChain.keychainPrivateKey, data: Data(KeyFixture.alice.privateKeyHex.utf8))
        return persistenceController
    }()
    static var previewContext = persistenceController.container.viewContext
    static var emptyPersistenceController = PersistenceController.empty
    static var emptyPreviewContext = emptyPersistenceController.container.viewContext
    static var emptyRelayService = RelayService(persistenceController: emptyPersistenceController)
    static var relayService = RelayService(persistenceController: persistenceController)
    static var router = Router()

    static var currentUser: CurrentUser = {
        let currentUser = CurrentUser(persistenceController: persistenceController)
        currentUser.viewContext = previewContext
        currentUser.relayService = relayService
        Task { await currentUser.setKeyPair(KeyFixture.keyPair) }
        return currentUser
    }()
    
    static var shortNote: Event {
        let note = Event(context: previewContext)
        note.kind = 1
        note.createdAt = .now
        note.content = "Hello, world!"
        note.author = user
        return note
    }
    
    static var longNote: Event {
        let note = Event(context: previewContext)
        note.kind = 1
        note.createdAt = .now
        note.content = .loremIpsum(5)
        note.author = user
        return note
    }
    
    static var user: Author {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = "d0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e"
        return author
    }
    
    static var previews: some View {
        Group {
            VStack {
                RepliesView(note: shortNote)
            }
            VStack {
                RepliesView(note: longNote)
            }
        }
        .environment(\.managedObjectContext, previewContext)
        .environmentObject(emptyRelayService)
        .environmentObject(router)
        .environmentObject(currentUser)
        .padding()
        .background(Color.cardBackground)
    }
}
