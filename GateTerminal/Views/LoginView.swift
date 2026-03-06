import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: LoginViewModel?
    @State private var showPassword = false
    @State private var showServerUrl = false
    @FocusState private var focusedField: Field?

    enum Field { case email, password, server }

    var body: some View {
        let vm = viewModel ?? makeVM()

        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 100)

                Text("Gate Terminal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.primary)

                Text("Interchange Login")
                    .font(.body)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .padding(.top, 8)

                Spacer().frame(height: 48)

                VStack(spacing: 12) {
                    TextField("Email", text: Binding(get: { vm.email }, set: { vm.email = $0 }))
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }

                    HStack {
                        Group {
                            if showPassword {
                                TextField("Password", text: Binding(get: { vm.password }, set: { vm.password = $0 }))
                            } else {
                                SecureField("Password", text: Binding(get: { vm.password }, set: { vm.password = $0 }))
                            }
                        }
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.done)
                        .onSubmit { doLogin(vm) }

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(AppColors.onSurfaceVariant)
                        }
                    }

                    Button {
                        showServerUrl.toggle()
                    } label: {
                        Text(showServerUrl ? "Hide server settings" : "Server settings")
                            .font(.caption)
                    }

                    if showServerUrl {
                        TextField("Server URL", text: Binding(get: { vm.serverUrl }, set: { vm.serverUrl = $0 }))
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .keyboardType(.URL)
                            .focused($focusedField, equals: .server)
                    }

                    if let error = vm.error {
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.white)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(AppColors.error.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Button {
                        doLogin(vm)
                    } label: {
                        if vm.isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        } else {
                            Text("Sign In")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.isLoading)
                    .padding(.top, 12)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .background(AppColors.background)
        .onAppear {
            if viewModel == nil {
                viewModel = makeVM()
            }
        }
    }

    private func makeVM() -> LoginViewModel {
        let vm = LoginViewModel(authService: appState.authService, shortcutPreferences: appState.shortcutPreferences)
        viewModel = vm
        return vm
    }

    private func doLogin(_ vm: LoginViewModel) {
        Task {
            focusedField = nil
            _ = await vm.login()
        }
    }
}
