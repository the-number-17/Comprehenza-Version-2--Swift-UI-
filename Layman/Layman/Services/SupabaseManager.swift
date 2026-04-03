import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        let secrets = SupabaseManager.loadSecrets()
        let url = URL(string: secrets.url)!
        
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: secrets.anonKey,
            options: .init(
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
        )
    }
    
    private static func loadSecrets() -> (url: String, anonKey: String) {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let url = dict["SUPABASE_URL"] as? String,
              let key = dict["SUPABASE_ANON_KEY"] as? String else {
            fatalError("Missing Secrets.plist or required keys. See README for setup instructions.")
        }
        return (url, key)
    }
}
