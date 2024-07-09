import XCTest

class NIP19EntityTests: XCTestCase {
    /// Example taken from [NIP-19](https://github.com/nostr-protocol/nips/blob/master/19.md)
    @MainActor func test_nprofile() throws {
        // swiftlint:disable:next line_length
        let nprofile = "nprofile1qqsrhuxx8l9ex335q7he0f09aej04zpazpl0ne2cgukyawd24mayt8gpp4mhxue69uhhytnc9e3k7mgpz4mhxue69uhkg6nzv9ejuumpv34kytnrdaksjlyr9p"

        let entity = try NIP19Entity.decode(bech32String: nprofile)
        switch entity {
        case .nprofile(let publicKey, let relays):
            XCTAssertEqual(publicKey, "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d")
            XCTAssertEqual(relays.count, 2)
            let firstRelay = try XCTUnwrap(relays.first)
            XCTAssertEqual(firstRelay, "wss://r.x.com")
            let secondRelay = try XCTUnwrap(relays.last)
            XCTAssertEqual(secondRelay, "wss://djbas.sadkb.com")
        default:
            XCTFail("Expected to get a nprofile")
        }
    }

    // swiftlint:disable line_length
    /// Example taken from [#1231](https://github.com/planetary-social/nos/issues/1231), which points to
    /// [this note](https://njump.me/nevent1qqsqq0wah49rd6hjpezm275vys8pu6l5lcqddj9mz8cwrwf3m00k56gzyqalp33lewf5vdq847t6te0wvnags0gs0mu72kz8938tn24wlfze6a2cs3x)
    @MainActor func test_nevent() throws {
        let nevent = "nevent1qyt8wumn8ghj7un9d3shjtnddaehgu3wwp6kytcpz9mhxue69uhkummnw3ezumrpdejz7qg4waehxw309aex2mrp0yhxgctdw4eju6t09uq3wamnwvaz7tmjv4kxz7fwwpexjmtpdshxuet59uq32amnwvaz7tmwdaehgu3wdau8gu3wv3jhvtcpr4mhxue69uhkummnw3ezucnfw33k76twv4ezuum0vd5kzmp0qyv8wumn8ghj7mn0wd68ytnxd46zuamf0ghxy6t69uq3jamnwvaz7tmjv4kxz7fwwdhx7un59eek7cmfv9kz7qghwaehxw309aex2mrp0yhxummnw3ezucnpdejz7qg3waehxw309ahx7um5wgh8w6twv5hsqg9p8569xea0fgnv0zuqnt3wsk5mu9j6xal7ten6332pg9r5h8g32gl7wn5w"
        // swiftlint:enable line_length

        let entity = try NIP19Entity.decode(bech32String: nevent)
        switch entity {
        case .nevent(let eventID, let relays, let publicKey, let kind):
            XCTAssertEqual(eventID, "a13d345367af4a26c78b809ae2e85a9be165a377fe5e67a8c54141474b9d1152")

            XCTAssertEqual(relays.count, 10)
            let firstRelay = try XCTUnwrap(relays.first)
            XCTAssertEqual(firstRelay, "wss://relay.mostr.pub/")
            let secondRelay = try XCTUnwrap(relays.last)
            XCTAssertEqual(secondRelay, "wss://nostr.wine/")

            XCTAssertNil(publicKey)
            XCTAssertNil(kind)
        default:
            XCTFail("Expected to get a nevent")
        }
    }

    /// Example taken from note1ypppzcue3svj2p0l80vp4lf52j3xmykn8yzjdv3gnq2sm4ljp5qqrqp9hd
    @MainActor func test_nevent_2() throws {
        // swiftlint:disable:next line_length
        let nevent = "nevent1qydhwumn8ghj7emvv4shxmmwv96x7u3wv3jhvtmjv4kxz7gprpmhxue69uhkummnv3exjan99eshqup0wfjkccteqyt8wumn8ghj7un9d3shjtnddaehgu3wwp6kytcpzamhxue69uhhyetvv9ujuurjd9kkzmpwdejhgtcpr9mhxue69uhhyetvv9ujuumwdae8gtnnda3kjctv9uq32amnwvaz7tmjv4kxz7fwv3sk6atn9e5k7tcprdmhxue69uhkummnw3e8gctvdvhxummnw3erztnrdakj7qpq38c7tac2uhqvqvxnv5d9mrq4km46pf232v9at473watm6597vucq4rru2q"

        let entity = try NIP19Entity.decode(bech32String: nevent)
        switch entity {
        case .nevent(let eventID, let relays, let publicKey, let kind):
            XCTAssertEqual(eventID, "89f1e5f70ae5c0c030d3651a5d8c15b6eba0a551530bd5d7d17757bd50be6730")

            XCTAssertEqual(relays.count, 7)
            let firstRelay = try XCTUnwrap(relays.first)
            XCTAssertEqual(firstRelay, "wss://gleasonator.dev/relay")
            let secondRelay = try XCTUnwrap(relays.last)
            XCTAssertEqual(secondRelay, "wss://nostrtalk.nostr1.com/")

            XCTAssertNil(publicKey)
            XCTAssertNil(kind)
        default:
            XCTFail("Expected to get a nevent")
        }
    }

    // From note12h0l6emckxgdfjnl3pfvyss4gp03yta7k0n9uwghywksksyfr9ws8q6war
    @MainActor func test_naddr() throws {
        // swiftlint:disable:next line_length
        let naddr = "naddr1qqjrsdf4xs6nvdrz95unsery956rswrx95unxvee94skvvp5xymkgwfcx9snyqg3waehxw309ahx7um5wgh8w6twv5hsygx0gknt5ymr44ldyyaq0rn3p5jpzkh8y8ymg773a06ytr4wldxz55psgqqqwense4rlem"

        let entity = try NIP19Entity.decode(bech32String: naddr)
        switch entity {
        case .naddr(let eventID, let relays, let eventPublicKey, let kind):
            XCTAssertEqual(eventID, "38353534353634622d393864642d343838662d393333392d616630343137643938316132")
            XCTAssertEqual(relays.count, 1)
            let firstRelay = try XCTUnwrap(relays.first)
            XCTAssertEqual(firstRelay, "wss://nostr.wine/")
            XCTAssertEqual(eventPublicKey, "cf45a6ba1363ad7ed213a078e710d24115ae721c9b47bd1ebf4458eaefb4c2a5")
            XCTAssertEqual(kind, 30_311)
        default:
            XCTFail("Expected to get a naddr")
        }
    }

    // From note1xsems9u6xqfxl3hd3z4u4yr67vvf3g6w5l5vxwl8vqwcp0kgm2hsg3zf2w
    @MainActor func test_naddr_2() throws {
        // swiftlint:disable:next line_length
        let naddr = "naddr1qvzqqqrujgpzp75cf0tahv5z7plpdeaws7ex52nmnwgtwfr2g3m37r844evqrr6jqyghwumn8ghj7vf5xqhxvdm69e5k7tcpzdmhxue69uhhqatjwpkx2urpvuhx2ue0qythwumn8ghj7un9d3shjtnswf5k6ctv9ehx2ap0qy2hwumn8ghj7un9d3shjtnyv9kh2uewd9hj7qg6waehxw309ac8junpd45kgtnxd9shg6npvchxxmmd9uq3xamnwvaz7tmjv4kxz7fwvcmh5tnfduhsz9thwden5te0wfjkccte9ejhs6t59ec82c30qyf8wumn8ghj7un9d3shjtn5dahkcue0qy88wumn8ghj7mn0wvhxcmmv9uqpqvenx56njvpnxqcrsdf4xqcrwdqufrevn"

        let entity = try NIP19Entity.decode(bech32String: naddr)
        switch entity {
        case .naddr(let eventID, let relays, let eventPublicKey, let kind):
            XCTAssertEqual(eventID, "33333535393033303038353530303734")
            XCTAssertEqual(relays.count, 9)
            let firstRelay = try XCTUnwrap(relays.first)
            XCTAssertEqual(firstRelay, "wss://140.f7z.io/")
            XCTAssertEqual(eventPublicKey, "fa984bd7dbb282f07e16e7ae87b26a2a7b9b90b7246a44771f0cf5ae58018f52")
            XCTAssertEqual(kind, 31_890)
        default:
            XCTFail("Expected to get a naddr")
        }
    }
}
