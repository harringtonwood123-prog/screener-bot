import SwiftUI

/// Name and email, captured before the app can be used.
///
/// Stored on the device only — there is no server to send it to. The fields are
/// validated for shape, not existence: nothing can verify an address here.
struct SignUpStep: View {
    var onSignUp: (String, String) -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var showErrors = false
    @FocusState private var focused: Field?

    private enum Field { case name, email }

    private var nameIsValid: Bool { UserProfile.isUsableName(name) }
    private var emailIsValid: Bool { UserProfile.isPlausibleEmail(email) }
    private var canContinue: Bool { nameIsValid && emailIsValid }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                LogoMark(size: 56)
                    .padding(.bottom, Theme.Space.loose)

                Text("Create your account")
                    .font(Theme.display(30))
                    .foregroundStyle(Theme.ink)

                Text("So we can save your closet and greet you properly.")
                    .font(Theme.body)
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.top, 6)

                VStack(spacing: Theme.Space.normal) {
                    field(
                        title: "Name",
                        placeholder: "Alex Morgan",
                        text: $name,
                        field: .name,
                        isValid: nameIsValid,
                        error: "Please enter your name.",
                        contentType: .name,
                        keyboard: .default,
                        submit: .next
                    )

                    field(
                        title: "Email",
                        placeholder: "alex@example.com",
                        text: $email,
                        field: .email,
                        isValid: emailIsValid,
                        error: "That doesn't look like an email address.",
                        contentType: .emailAddress,
                        keyboard: .emailAddress,
                        submit: .done
                    )
                }
                .padding(.top, Theme.Space.section)

                HStack(alignment: .top, spacing: Theme.Space.snug) {
                    Image(systemName: "iphone.and.arrow.forward.inward")
                        .font(.caption)
                        .foregroundStyle(Theme.positive)
                        .frame(width: 18)
                    Text("Your details stay on this iPhone. There's no server, so nothing is uploaded and no password is needed.")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, Theme.Space.loose)

                Button {
                    showErrors = true
                    guard canContinue else { return }
                    focused = nil
                    onSignUp(name, email)
                } label: {
                    Text("Continue")
                        .primaryAction()
                        .opacity(canContinue ? 1 : 0.5)
                }
                .padding(.top, Theme.Space.section)
            }
            .padding(.horizontal, Theme.Space.loose)
            .padding(.vertical, Theme.Space.section)
        }
        .scrollDismissesKeyboard(.interactively)
        .onSubmit {
            switch focused {
            case .name: focused = .email
            default: focused = nil
            }
        }
    }

    @ViewBuilder
    private func field(
        title: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        isValid: Bool,
        error: String,
        contentType: UITextContentType,
        keyboard: UIKeyboardType,
        submit: SubmitLabel
    ) -> some View {
        // Only complain once they've tried to continue, or left a filled field
        // in a bad state. Nagging while someone is mid-word is unpleasant.
        let showsError = showErrors && !isValid

        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSoft)

            TextField(placeholder, text: text)
                .font(Theme.body)
                .foregroundStyle(Theme.ink)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .autocorrectionDisabled()
                .submitLabel(submit)
                .focused($focused, equals: field)
                .padding(.horizontal, Theme.Space.normal)
                .padding(.vertical, 14)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                        .strokeBorder(
                            showsError ? Theme.critical
                                : (focused == field ? Theme.accent : Theme.hairline),
                            lineWidth: focused == field || showsError ? 2 : 1
                        )
                )

            if showsError {
                Text(error)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.critical)
            }
        }
    }
}
