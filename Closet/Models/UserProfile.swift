import Foundation

/// The details captured at sign-up.
///
/// This is a local profile, not an account: there is no server, so nothing is
/// transmitted and nothing is verified. It exists so the app can greet the user
/// by name and so there is a record to migrate if a backend is added later.
/// See README for what turning this into a real account would involve.
struct UserProfile: Codable, Equatable {
    var name: String
    var email: String
    var signedUpAt: Date

    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    /// Deliberately permissive: something@something.tld. Anything stricter
    /// rejects addresses that are perfectly valid, and there's no server here
    /// to verify against anyway.
    static func isPlausibleEmail(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.contains(" "), trimmed.count >= 6 else { return false }
        let parts = trimmed.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty else { return false }
        let domain = parts[1]
        guard domain.contains("."), !domain.hasPrefix("."), !domain.hasSuffix(".") else { return false }
        return domain.split(separator: ".").allSatisfy { !$0.isEmpty }
    }

    static func isUsableName(_ raw: String) -> Bool {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }
}
