//
//  ChapterPlayerView.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 13.04.2025.
//

import SwiftUI
import ComposableArchitecture

struct ChapterPlayerView: View {
    @Bindable var store: StoreOf<ChapterPlayerFeature>

    @State private var isSeeking = false
    @State private var seekPosition: TimeInterval = 0

    var onPreviousTapped: () -> Void = {}
    var onNextTapped: () -> Void = {}

    var body: some View {
        VStack(spacing: 24) {
            Text(store.chapter.title)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)

            Text(store.chapter.text)
                .font(.body)
                .multilineTextAlignment(.leading)

            VStack(spacing: 12) {
                Text("Playback: \(Int(store.playbackTime))s")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                HStack(spacing: 32) {
                    Button(action: onPreviousTapped) {
                        Image(systemName: "backward.fill")
                    }

                    Button(action: {
                        store.send(.skipBackwardTapped)
                    }) {
                        Image(systemName: "gobackward.5")
                    }

                    Button(action: {
                        store.send(store.isPlaying ? .pauseTapped : .playTapped)
                    }) {
                        Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                    }

                    Button(action: {
                        store.send(.skipForwardTapped)
                    }) {
                        Image(systemName: "goforward.10")
                    }

                    Button(action: onNextTapped) {
                        Image(systemName: "forward.fill")
                    }
                }
                .font(.title2)

                HStack(spacing: 12) {
                    ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { rate in
                        PlaybackRateButton(
                            rate: rate,
                            selectedRate: store.state.playbackRate,
                            action: { store.send(.setRate(rate)) }
                        )
                    }
                }
                .padding(.top, 12)
            }

            Spacer()

            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: {
                            isSeeking ? seekPosition : store.state.playbackTime
                        },
                        set: { seekPosition = $0 }
                    ),
                    in: 0...(store.state.duration > 0 ? store.state.duration : 100),
                    onEditingChanged: { editing in
                        isSeeking = editing
                        if editing {
                            store.send(.pauseTapped)
                        } else {
                            store.send(.seek(to: seekPosition))
                        }
                    }
                )

                HStack {
                    Text(formatTime(isSeeking ? seekPosition : store.state.playbackTime))
                    Spacer()
                    Text(store.state.duration > 0 ? formatTime(store.state.duration) : "--:--")
                }
                .font(.footnote)
                .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .padding()
        .navigationTitle("Now Playing")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            store.send(.pauseTapped)
        }
    }
}

private struct PlaybackRateButton: View {
    let rate: Double
    let selectedRate: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(rate.formattedRate + "x")
                .fontWeight(rate == selectedRate ? .bold : .regular)
                .foregroundColor(rate == selectedRate ? .white : .accentColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(rate == selectedRate ? Color.accentColor : Color(.systemGray5))
                )
        }
    }
}

private extension Double {
    var formattedRate: String {
        self == rounded() ? String(format: "%.0f", self) : String(self)
    }
}

private func formatTime(_ seconds: TimeInterval) -> String {
    let minutes = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return String(format: "%d:%02d", minutes, secs)
}
