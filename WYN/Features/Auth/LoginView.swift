import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var auth
    @Binding var showRegister: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    private var canSubmit: Bool {
        !email.isEmpty && password.count >= 6 && !isSubmitting
    }

    var body: some View {
        AuthScaffold(subtitle: "Bentornato") {
            VStack(spacing: 12) {
                WYNTextField(
                    placeholder: "Email",
                    text: $email,
                    keyboard: .emailAddress,
                    textContentType: .username
                )
                WYNTextField(
                    placeholder: "Password",
                    text: $password,
                    isSecure: true,
                    textContentType: .password
                )

                if let errorMessage {
                    Text(errorMessage)
                        .font(.body(14))
                        .foregroundStyle(Color.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 2)
                }

                Button(action: submit) {
                    if isSubmitting {
                        ProgressView().tint(Color.surface)
                    } else {
                        Text("Accedi").monoLabel(size: 13, weight: .semibold)
                    }
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: canSubmit))
                .disabled(!canSubmit)
                .padding(.top, 4)
            }

            Button {
                showRegister = true
            } label: {
                Text("Non hai un account? **Registrati**")
                    .font(.body(14))
                    .foregroundStyle(Color.ink2)
            }
            .padding(.top, 8)
        }
    }

    private func submit() {
        errorMessage = nil
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                try await auth.signIn(email: email.trimmed, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
