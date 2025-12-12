import SwiftUI

struct LandingView: View {
    @Binding var showCamera: Bool
    
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
            
            Button(action: {
                showCamera = true
            }) {
                Text("START")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 200, height: 60)
                    .background(Color.blue)
                    .cornerRadius(30)
            }
            
            Spacer()
        }
    }
}
