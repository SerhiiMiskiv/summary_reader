//
//  ChapterPlayerView.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 13.04.2025.
//

import SwiftUI
import ComposableArchitecture

// MARK: - Chapter Player View

struct ChapterPlayerView: View {
    @Bindable var store: StoreOf<ChapterPlayerFeature>
    
    let coverImage: UIImage

    var body: some View {
        VStack(spacing: 24) {
            Image(uiImage: coverImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 280)
                .cornerRadius(16)
                .shadow(radius: 6)
            
            Text(store.currentChapter.title)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)

            Text(store.currentChapter.text)
                .font(.body)
                .multilineTextAlignment(.leading)
            
            ProgressSlider(store: store)
            Controls(store: store)
        }
        .padding()
        .onDisappear {
            store.send(.stop)
        }
    }
}

// MARK: - Controls

private struct Controls: View {
    @Bindable var store: StoreOf<ChapterPlayerFeature>

    var body: some View {
        VStack(spacing: 12) {
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
                        
            HStack(spacing: 32) {
                Button(action: {
                    store.send(.previousChapter)
                }) {
                    Image(systemName: "backward.fill")
                }

                Button(action: {
                    store.send(.skipBackward)
                }) {
                    Image(systemName: "gobackward.5")
                }

                Button(action: {
                    store.send(store.isPlaying ? .pause : .play)
                }) {
                    Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                }

                Button(action: {
                    store.send(.skipForward)
                }) {
                    Image(systemName: "goforward.10")
                }

                Button(action: {
                    store.send(.nextChapter)
                }) {
                    Image(systemName: "forward.fill")
                }
            }
            .font(.largeTitle)
            .padding(.top, 24)
        }
    }
}

// MARK: - Playback Rate Button

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

// MARK: - Progress Slider

private struct ProgressSlider: View {
    @Bindable var store: StoreOf<ChapterPlayerFeature>
    
    @State private var isSeeking = false
    @State private var seekPosition: TimeInterval = 0
    
    var body: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: {
                        isSeeking ? seekPosition : store.state.playbackTime
                    },
                    set: {
                        seekPosition = $0
                    }
                ),
                in: 0...store.state.duration,
                onEditingChanged: { editing in
                    isSeeking = editing
                    if !editing {
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
