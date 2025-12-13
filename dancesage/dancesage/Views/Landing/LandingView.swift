import SwiftUI

struct LandingView: View {
    @Binding var showCamera: Bool
    @State private var showVideoPicker = false
    @State private var selectedVideoURL: URL?
    @State private var showVideoProcessing = false
    @State private var showRecordings = false
    
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
            
            // My Recordings Button
            Button(action: {
                showRecordings = true
            }) {
                Text("MY RECORDINGS")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 250, height: 60)
                    .background(Color.purple)
                    .cornerRadius(30)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showVideoPicker) {
            VideoPicker(selectedVideoURL: $selectedVideoURL)
        }
        .sheet(isPresented: $showVideoProcessing) {
            if let url = selectedVideoURL {
                VideoProcessingView(videoURL: url)
            }
        }
        .sheet(isPresented: $showRecordings) {
            RecordingsListView()
        }
        .onChange(of: selectedVideoURL) { oldValue, newValue in
            if newValue != nil {
                showVideoProcessing = true
            }
        }
    }
}
