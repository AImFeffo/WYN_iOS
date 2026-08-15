import SwiftUI

struct RegisterView: View {
    @Environment(AuthViewModel.self) private var auth
    @Binding var showRegister: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isSubmitting = false

    private var canSubmit: Bool {
        !email.isEmpty && password.count >= 6 && !isSubmitting
    }

    var body: some View {
        AuthScaffold(subtitle: "Crea il tuo account") {
            VStack(spacing: 12) {
                WYNTextField(
                    placeholder: "Email",
                    text: $email,
                    keyboard: .emailAddress,
                    textContentType: .username
                )
                WYNTextField(
                    placeholder: "Password (min 6 caratteri)",
                    text: $password,
                    isSecure: true,
                    textContentType: .newPassword
                )

                if let successMessage {
                    Text(successMessage)
                        .font(.body(14))
                        .foregroundStyle(Category.salute.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let errorMessage {
                    Text(errorMessage)
                        .font(.body(14))
                        .foregroundStyle(Color.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(action: submit) {
                    if isSubmitting {
                        ProgressView().tint(Color.surface)
                    } else {
                        Text("Registrati").monoLabel(size: 13, weight: .semibold)
                    }
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: canSubmit))
                .disabled(!canSubmit)
                .padding(.top, 4)
            }

            Button {
                showRegister = false
            } label: {
                Text("Hai già un account? **Accedi**")
                    .font(.body(14))
                    .foregroundStyle(Color.ink2)
            }
            .padding(.top, 8)
        }
    }

    private func submit() {
        errorMessage = nil
        successMessage = nil
        isSubmitting = true
        Task {
            do {
                try await auth.signUp(email: email.trimmed, password: password)
                // Conferma email disattivata: la sessione parte subito.
                // Mostriamo comunque il messaggio di successo (§4) prima del redirect.
                successMessage = "Account creato! Ti stiamo portando al feed…"
                // authStateChanges instraderà al feed automaticamente.
            } catch {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}
