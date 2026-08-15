import SwiftUI

@main
struct WYNApp: App {
    @State private var auth = AuthViewModel()
    @State private var theme = ThemeManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(theme)
                .preferredColorScheme(theme.colorScheme)
                .tint(Color.ink)
        }
    }
}

/// Instrada tra autenticazione e app in base allo stato della sessione.
struct RootView: View {
    @Environment(AuthViewModel.self) private var auth

    var body: some View {
        Group {
            if auth.isLoading {
                LaunchView()
            } else if auth.isAuthenticated {
                RootTabView()
            } else {
                AuthContainerView()
            }
        }
        #if DEBUG
        .task {
            // Hook solo per verifica automatizzata (launch arg). Non usato in produzione.
            if CommandLine.arguments.contains("-uitest-login"), !auth.isAuthenticated {
                try? await auth.signIn(email: "feffo-demo@wyn.app", password: "demo123456")
            }
        }
        #endif
    }
}

/// Schermata di avvio minimale mentre determiniamo la sessione.
struct LaunchView: View {
    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            Text("WYN")
                .font(.heading(48, weight: .semibold))
                .tracking(-1.2)
                .foregroundStyle(Color.ink)
        }
    }
}
