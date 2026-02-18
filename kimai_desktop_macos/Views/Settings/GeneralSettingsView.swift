import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage("refreshInterval") private var refreshInterval: Double = Constants.Defaults.refreshInterval
    @AppStorage("showTimerInMenuBar") private var showTimerInMenuBar = true
    @AppStorage("recentTimesheetsCount") private var recentTimesheetsCount = Constants.Defaults.recentTimesheetsCount
    @AppStorage("currencySuffix") private var currencySuffix = Constants.Defaults.currencySuffix

    var body: some View {
        Form {
            Section {
                Picker("Интервал обновления", selection: $refreshInterval) {
                    Text("15 секунд").tag(15.0)
                    Text("30 секунд").tag(30.0)
                    Text("1 минута").tag(60.0)
                    Text("5 минут").tag(300.0)
                }

                Toggle("Показывать таймер в строке меню", isOn: $showTimerInMenuBar)
            } header: {
                Text("Опрос сервера")
            }

            Section {
                Picker("Количество недавних записей", selection: $recentTimesheetsCount) {
                    Text("3").tag(3)
                    Text("5").tag(5)
                    Text("10").tag(10)
                }

                TextField("Постфикс валюты", text: $currencySuffix)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("Отображение")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
