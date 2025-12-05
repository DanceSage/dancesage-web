//
//  ContentView.swift
//  dancesage
//
//  Created by Abdu Radi on 12/5/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            Text("Dance Sage!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
