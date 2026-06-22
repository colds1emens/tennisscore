import SwiftUI

/// Редактор составов двух команд: имена игроков, добавить/убрать,
/// быстрые размеры (1v1…6v6), перемещение игроков между командами и swap.
/// Команды от 1 до 6 игроков, размеры могут быть неравными.
struct RosterEditor: View {
    @Binding var playersA: [String]
    @Binding var playersB: [String]
    let theme: CourtTheme
    /// Показывать кнопки перемещения игрока в другую команду (для смены составов между играми).
    var allowMoving = false

    private let maxPlayers = 6

    var body: some View {
        VStack(spacing: 14) {
            quickRow
            teamCard(title: "Team A", players: $playersA, other: $playersB, moveSymbol: "arrow.down")
            teamCard(title: "Team B", players: $playersB, other: $playersA, moveSymbol: "arrow.up")
        }
    }

    // MARK: - Быстрые размеры и swap

    private var quickRow: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(1...maxPlayers, id: \.self) { n in
                        let active = playersA.count == n && playersB.count == n
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                playersA = resize(playersA, to: n)
                                playersB = resize(playersB, to: n)
                            }
                            Haptics.selection()
                        } label: {
                            Text("\(n)v\(n)")
                                .font(.system(.footnote, design: .rounded).weight(.bold))
                                .foregroundStyle(active ? theme.onAccent : theme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(active ? theme.accent : theme.cardFill))
                                .overlay(Capsule().strokeBorder(theme.cardStroke, lineWidth: active ? 0 : 1))
                        }
                        .buttonStyle(SpringPressStyle())
                        .accessibilityLabel("\(n) versus \(n)")
                    }
                }
            }
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    swap(&playersA, &playersB)
                }
                Haptics.selection()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(theme.textPrimary)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(theme.cardFill))
                    .overlay(Circle().strokeBorder(theme.cardStroke, lineWidth: 1))
            }
            .buttonStyle(SpringPressStyle())
            .accessibilityLabel("Swap the two teams")
        }
    }

    // MARK: - Карточка команды

    private func teamCard(title: String, players: Binding<[String]>, other: Binding<[String]>, moveSymbol: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                Text("\(players.wrappedValue.count) player\(players.wrappedValue.count == 1 ? "" : "s")")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
            }

            ForEach(players.wrappedValue.indices, id: \.self) { index in
                HStack(spacing: 8) {
                    Text("\(index + 1)")
                        .font(.system(.footnote, design: .rounded).weight(.bold).monospacedDigit())
                        .foregroundStyle(theme.textSecondary)
                        .frame(width: 16)

                    TextField(
                        "",
                        text: players[index],
                        prompt: Text("Player \(index + 1)").foregroundStyle(theme.textSecondary.opacity(0.6))
                    )
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(theme.textPrimary)
                    .tint(theme.accent)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(theme.cardFill))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(theme.cardStroke, lineWidth: 1))

                    if allowMoving {
                        iconButton(moveSymbol, enabled: other.wrappedValue.count < maxPlayers) {
                            movePlayer(at: index, from: players, to: other)
                        }
                        .accessibilityLabel("Move \(players.wrappedValue[index].isEmpty ? "player \(index + 1)" : players.wrappedValue[index]) to the other team")
                    }

                    iconButton("minus.circle", enabled: players.wrappedValue.count > 1) {
                        withAnimation(.spring(response: 0.3)) {
                            players.wrappedValue.remove(at: index)
                        }
                        Haptics.warning()
                    }
                    .accessibilityLabel("Remove player \(index + 1)")
                }
            }

            if players.wrappedValue.count < maxPlayers {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        players.wrappedValue.append("")
                    }
                    Haptics.selection()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add player")
                            .font(.system(.footnote, design: .rounded).weight(.semibold))
                    }
                    .foregroundStyle(theme.accent)
                    .brightness(0.2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(SpringPressStyle())
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(theme.cardFill.opacity(0.5)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(theme.cardStroke, lineWidth: 1))
    }

    private func iconButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(enabled ? theme.textSecondary : theme.textSecondary.opacity(0.25))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(SpringPressStyle())
        .disabled(!enabled)
    }

    // MARK: - Логика

    private func resize(_ arr: [String], to n: Int) -> [String] {
        if arr.count == n { return arr }
        if arr.count > n { return Array(arr.prefix(n)) }
        return arr + Array(repeating: "", count: n - arr.count)
    }

    private func movePlayer(at index: Int, from source: Binding<[String]>, to dest: Binding<[String]>) {
        guard source.wrappedValue.indices.contains(index),
              source.wrappedValue.count > 1,
              dest.wrappedValue.count < maxPlayers
        else { return }
        let player = source.wrappedValue[index]
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            source.wrappedValue.remove(at: index)
            dest.wrappedValue.append(player)
        }
        Haptics.selection()
    }
}
