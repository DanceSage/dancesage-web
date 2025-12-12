import SwiftUI

struct LandingView: View {
    @Binding var showCamera: Bool
    @State private var showVideoPicker = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            
            Text("Dance Sage")
                .font(.system(size: 36, weight: .bold))
            
            Spacer()
            
            // Live Camera Button
            Button(action: {
                showCamera = true
            }) {
                Text("RECORD LIVE")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 250, height: 60)
                    .background(Color.blue)
                    .cornerRadius(30)
            }
            
            // Upload Video Button
            Button(action: {
                showVideoPicker = true
            }) {
                Text("UPLOAD VIDEO")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 250, height: 60)
                    .background(Color.green)
                    .cornerRadius(30)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showVideoPicker) {
            VideoPicker()
        }
    }
}
