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
                  Button(action: {
                      store.send(.pauseTapped)
                  }) {
                      Image(systemName: "pause.fill")
                  }

                  Button(action: {
                      store.send(.playTapped)
                  }) {
                      Image(systemName: "play.fill")
                  }

                  Button(action: {
                      store.send(.stopTapped)
                  }) {
                      Image(systemName: "stop.fill")
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
