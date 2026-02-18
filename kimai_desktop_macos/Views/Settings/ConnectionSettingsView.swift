import SwiftUI

struct ConnectionSettingsView: View {
    @Environment(AppState.self) private var appState

    @State private var serverURL: String = ""
    @State private var apiToken: String = ""
    @State private var testResult: TestResult?
    @State private var isTesting = false

    enum TestResult {
        case success
        case failure(String)
    }

    var body: some View {
        Form {
            Section {
                TextField("URL сервера", text: $serverURL, prompt: Text("https://kimai.example.com"))
                    .textFieldStyle(.roundedBorder)

                SecureField("API-токен", text: $apiToken, prompt: Text("Ваш API-токен Kimai"))
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("Сервер Kimai")
            }

            Section {
                HStack {
                    Button("Проверить подключение") {
                        Task { await testConnection() }
                    }
                    .disabled(serverURL.isEmpty || apiToken.isEmpty || isTesting)

                    if isTesting {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Spacer()

                    if let testResult {
                        testResultView(testResult)
                    }
                }

                Button("Сохранить") {
                    saveCredentials()
                }
                .disabled(serverURL.isEmpty || apiToken.isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            serverURL = KeychainService.baseURL ?? ""
            apiToken = KeychainService.apiToken ?? ""
        }
    }

    @ViewBuilder
    private func testResultView(_ result: TestResult) -> some View {
        switch result {
        case .success:
            Label("Подключено", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failure(let message):
            Label(message, systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
                .lineLimit(1)
        }
    }

    private func normalizeURL(_ raw: String) -> String {
        var url = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        // Strip /api suffix if user included it
        if url.hasSuffix("/api") {
            url = String(url.dropLast(4))
        }

        // Upgrade http to https
        if url.hasPrefix("http://") {
            url = "https://" + url.dropFirst(7)
        }

        // Add https:// if no scheme
        if !url.hasPrefix("https://") {
            url = "https://" + url
        }

        return url
    }

    private func saveCredentials() {
        let cleanURL = normalizeURL(serverURL)
        KeychainService.baseURL = cleanURL
        KeychainService.apiToken = apiToken.trimmingCharacters(in: .whitespacesAndNewlines)

        appState.startPolling()
    }

    private func testConnection() async {
        isTesting = true
        defer { isTesting = false }

        let cleanURL = normalizeURL(serverURL)

        // Temporarily save for testing
        let oldURL = KeychainService.baseURL
        let oldToken = KeychainService.apiToken
        KeychainService.baseURL = cleanURL
        KeychainService.apiToken = apiToken.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            _ = try await appState.testConnection()
            testResult = .success
        } catch {
            testResult = .failure(error.localizedDescription)
            // Restore old values on failure
            KeychainService.baseURL = oldURL
            KeychainService.apiToken = oldToken
        }
    }
}
