//
//  CameraView.swift
//  CameraFilter
//
//  Created by Іван Богоносюк on 04.07.2023.
//

import SwiftUI

struct CameraView: View {
    @StateObject private var camera = CameraModel()

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            if let image = camera.image {
                Image(uiImage: image)
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    Spacer()

                    Button(action: camera.changeFilter) {
                        Image(systemName: "camera.filters")
                            .font(.largeTitle)
                            .foregroundColor(.black)
                            .padding()
                            .background {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 70, height: 70)
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 25)
            }
        }
        .onAppear(perform: camera.checkAuthorization)
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
