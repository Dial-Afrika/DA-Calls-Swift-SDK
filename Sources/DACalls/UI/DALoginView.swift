import SwiftUI
import Combine
import Foundation

/// Login view for SIP authentication
public struct DALoginView: View {
    @StateObject private var viewModel = DALoginViewModel()
    
    /// Completion handler called when login is complete
    public var onLoginComplete: ((Bool) -> Void)?
    
    /// Public initializer
    public init(onLoginComplete: ((Bool) -> Void)? = nil) {
        self.onLoginComplete = onLoginComplete
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Login to DialAfrika")
                    .font(.title)
                    .bold()
                
                Text("Enter your SIP credentials to connect")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Form fields
            VStack(spacing: 16) {
                TextField("Username", text: $viewModel.username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Domain", text: $viewModel.domain)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                
                Picker("Transport", selection: $viewModel.transportType) {
                    Text("TLS").tag(DATransportType.tls)
                    Text("TCP").tag(DATransportType.tcp)
                    Text("UDP").tag(DATransportType.udp)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Error message
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            
            // Login button
            Button(action: {
                Task {
                    await viewModel.login()
                }
            }) {
                if viewModel.isLoggingIn {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Login")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(viewModel.isLoggingIn || !viewModel.isFormValid)
            .opacity(viewModel.isFormValid ? 1.0 : 0.6)
        }
        .padding()
        .onReceive(viewModel.$loginResult) { result in
            if let success = result {
                onLoginComplete?(success)
            }
        }
    }
}

/// View model for the login view
public class DALoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var domain: String = ""
    @Published var transportType: DATransportType = .tls
    @Published var errorMessage: String = ""
    @Published var isLoggingIn: Bool = false
    @Published var loginResult: Bool?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        setupValidation()
    }
    
    var isFormValid: Bool {
        !username.isEmpty && !password.isEmpty && !domain.isEmpty
    }
    
    private func setupValidation() {
        // Reset error message when form fields change
        Publishers.CombineLatest3($username, $password, $domain)
            .map { _ in "" }
            .assign(to: &$errorMessage)
    }
    
    @MainActor
    func login() async {
        guard isFormValid else { return }
        
        isLoggingIn = true
        errorMessage = ""
        loginResult = nil
        
        let credentials = DAAuthService.Credentials(
            username: username,
            password: password,
            domain: domain,
            transportType: transportType
        )
        
        let result = await DACalls.shared.authService.login(with: credentials)
        
        isLoggingIn = false
        
        switch result {
        case .success:
            loginResult = true
        case .failure(let error):
            switch error {
            case .loginFailed(let message):
                errorMessage = "Login failed: \(message)"
            case .notInitialized:
                errorMessage = "SDK not initialized"
            default:
                errorMessage = "Login error: \(error.localizedDescription)"
            }
            loginResult = false
        }
    }
}

#Preview {
    DALoginView()
}
