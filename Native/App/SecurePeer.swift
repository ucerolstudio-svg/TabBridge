// SPDX-License-Identifier: GPL-3.0-only
import Foundation
import Security
import CryptoKit
import Network

struct PairedTablet: Codable {
    let securityVersion: Int
    let id: String
    let clientId: String
    let token: String
    let certificateSHA256: String

    static func decode(_ data: Data, client: String? = nil) throws -> Self {
        guard data.count <= 4096, let value = try? JSONDecoder().decode(Self.self, from: data),
              value.securityVersion == 1, UUID(uuidString: value.id) != nil,
              UUID(uuidString: value.clientId)?.uuidString.lowercased() == value.clientId,
              client == nil || value.clientId == client,
              decode32(value.token) != nil, decode32(value.certificateSHA256) != nil else { throw PairingError.invalidResponse }
        return value
    }
    static func fromADB(_ output: String, client: String) throws -> Self {
        let pattern = #"^Result: Bundle\[\{pairing=([A-Za-z0-9_-]{1,5500})\}\]$"#
        let ns = output as NSString
        guard output.utf8.count < 5600,
              let match = try NSRegularExpression(pattern: pattern).firstMatch(in: output, range: NSRange(location: 0, length: ns.length)),
              let data = decodeURL(ns.substring(with: match.range(at: 1))) else { throw PairingError.invalidResponse }
        return try decode(data, client: client)
    }
    static func decodeURL(_ text: String) -> Data? {
        let padded = text.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/") + String(repeating: "=", count: (4 - text.count % 4) % 4)
        return Data(base64Encoded: padded)
    }
    static func encodeURL(_ data: Data) -> String {
        data.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
    static func decode32(_ text: String) -> Data? {
        guard text.utf8.count == 43, let data = decodeURL(text), data.count == 32, encodeURL(data) == text else { return nil }
        return data
    }
    func matchesCertificate(_ der: Data) -> Bool {
        guard let expected = Self.decode32(certificateSHA256) else { return false }
        let actual = Data(SHA256.hash(data: der))
        return zip(actual, expected).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }
    var authenticationFrame: Data {
        let obj: [String: Any] = ["type": "authenticate", "securityVersion": 1, "clientId": clientId, "token": token]
        let body = try! JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys])
        var length = UInt32(body.count).bigEndian
        return withUnsafeBytes(of: &length) { Data($0) } + body
    }
    static func validAcknowledgement(_ data: Data) -> Bool {
        struct Ack: Decodable { let type: String; let securityVersion: Int }
        guard let value = try? JSONDecoder().decode(Ack.self, from: data) else { return false }
        return value.type == "authenticated" && value.securityVersion == 1
    }
    func parameters() -> NWParameters {
        let tls = NWProtocolTLS.Options()
        sec_protocol_options_set_min_tls_protocol_version(tls.securityProtocolOptions, .TLSv12)
        sec_protocol_options_set_verify_block(tls.securityProtocolOptions, { _, trust, complete in
            let reference = sec_trust_copy_ref(trust).takeRetainedValue()
            guard let chain = SecTrustCopyCertificateChain(reference) as? [SecCertificate], let leaf = chain.first else { complete(false); return }
            complete(self.matchesCertificate(SecCertificateCopyData(leaf) as Data))
        }, DispatchQueue.global(qos: .userInitiated))
        let tcp = NWProtocolTCP.Options(); tcp.noDelay = true
        return NWParameters(tls: tls, tcp: tcp)
    }
}

enum PairingError: LocalizedError {
    case invalidResponse, storage, notPaired
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Güvenli eşleştirme doğrulanamadı. Tablet uygulamasını Kur ve eşleştir ile güncelle."
        case .storage: return "Eşleştirme Mac Anahtar Zinciri’ne kaydedilemedi."
        case .notPaired: return "Bu tabletle bir kez USB üzerinden güvenli eşleştirme yap."
        }
    }
}

enum PeerStore {
    private static let service = "dev.tabbridge.mac.securepeers.v1"
    private static func query(_ account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
    }
    private static func read(_ account: String) throws -> Data? {
        var q = query(account); q[kSecReturnData as String] = true; q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw PairingError.storage }
        return data
    }
    private static func save(_ data: Data, account: String) throws {
        let q = query(account)
        let update = SecItemUpdate(q as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if update == errSecSuccess { return }
        guard update == errSecItemNotFound else { throw PairingError.storage }
        var added = q; added[kSecValueData as String] = data
        added[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        guard SecItemAdd(added as CFDictionary, nil) == errSecSuccess else { throw PairingError.storage }
    }
    static func clientId() throws -> String {
        if let data = try read("client-id"), let text = String(data: data, encoding: .utf8), UUID(uuidString: text)?.uuidString.lowercased() == text { return text }
        let text = UUID().uuidString.lowercased(); try save(Data(text.utf8), account: "client-id"); return text
    }
    static func tablet(_ id: String) throws -> PairedTablet {
        guard let data = try read("tablet-" + id.lowercased()) else { throw PairingError.notPaired }
        let tablet = try PairedTablet.decode(data)
        guard tablet.id.caseInsensitiveCompare(id) == .orderedSame else { throw PairingError.invalidResponse }
        return tablet
    }
    static func save(_ tablet: PairedTablet) throws {
        try save(JSONEncoder().encode(tablet), account: "tablet-" + tablet.id.lowercased())
    }
    static func forget(_ id: String) throws {
        let status = SecItemDelete(query("tablet-" + id.lowercased()) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw PairingError.storage }
    }
}
