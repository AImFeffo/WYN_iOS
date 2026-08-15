import Foundation
import Supabase

/// Client Supabase condiviso da app ed estensione.
///
/// La sessione è persistita in un file dentro il container dell'App Group
/// (`AppGroupStorage`), così la Share Extension riusa la stessa sessione
/// dell'utente loggato nell'app.
enum SupabaseManager {
    static let client = SupabaseClient(
        supabaseURL: SupabaseConfig.url,
        supabaseKey: SupabaseConfig.anonKey,
        options: SupabaseClientOptions(
            auth: SupabaseClientOptions.AuthOptions(
                storage: AppGroupStorage(appGroup: SupabaseConfig.appGroup),
                storageKey: "wyn.session"
            )
        )
    )
}
