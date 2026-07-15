//
//  AvatarThumbnail.swift
//  Matchbook
//
//  Created by Maksym Vitovych on 15.07.2026.
//

import SwiftUI

/// The circular avatar itself: the picked photo cropped to a circle, or a dashed "+" slot when
/// there isn't one yet.
struct AvatarThumbnail: View {
    let avatarData: Data?

    var body: some View {
        content
            .frame(width: 96, height: 96)
            .clipShape(Circle())
    }

    @ViewBuilder
    private var content: some View {
        if let avatarData, let image = UIImage(data: avatarData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Circle()
                    .fill(Color.cardSurface)
                Circle()
                    .strokeBorder(
                        Color.hairline,
                        style: StrokeStyle(lineWidth: 2, dash: [6, 5])
                    )
                Image(.plus)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(Color.brandGreen)
            }
        }
    }
}

