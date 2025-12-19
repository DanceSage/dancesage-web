import SwiftUI

struct LandingView: View {
    @Binding var showCamera: Bool
    @Binding var selectedMode: DanceMode  // Add this binding
    @State private var showVideoPicker = false
    @State private var selectedVideoURL: URL?
    @State private var showVideoProcessing = false
    @State private var showRecordings = false
    @State private var showModeSelection = false
    
    enum DanceMode {
        case styling  // Single person
        case partner  // Two people
    }
    
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
                showModeSelection = true
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
        .sheet(isPresented: $showModeSelection) {
            ModeSelectionView(
                selectedMode: $selectedMode,
                onModeSelected: {
                    showModeSelection = false
                    showCamera = true
                }
            )
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

// MARK: - Mode Selection View (same as before)
struct ModeSelectionView: View {
    @Binding var selectedMode: LandingView.DanceMode
    let onModeSelected: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Select Mode")
                .font(.system(size: 32, weight: .bold))
                .padding(.top, 50)
            
            Spacer()
            
            // Styling Mode (Single Person)
            Button(action: {
                selectedMode = .styling
                onModeSelected()
            }) {
                VStack(spacing: 15) {
                    Image(systemName: "figure.dance")
                        .font(.system(size: 60))
                    
                    Text("STYLING")
                        .font(.system(size: 24, weight: .semibold))
                    
                    Text("Single dancer")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .foregroundColor(.white)
                .frame(width: 280, height: 200)
                .background(Color.green)
                .cornerRadius(20)
            }
            
            // Partner Mode (Two People)
            Button(action: {
                selectedMode = .partner
                onModeSelected()
            }) {
                VStack(spacing: 15) {
                    HStack(spacing: 10) {
                        Image(systemName: "figure.dance")
                            .font(.system(size: 50))
                        Image(systemName: "figure.dance")
                            .font(.system(size: 50))
                    }
                    
                    Text("PARTNER")
                        .font(.system(size: 24, weight: .semibold))
                    
                    Text("Two dancers")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .foregroundColor(.white)
                .frame(width: 280, height: 200)
                .background(Color.blue)
                .cornerRadius(20)
            }
            
            Spacer()
            
            // Cancel Button
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .font(.system(size: 18))
                    .foregroundColor(.red)
            }
            .padding(.bottom, 30)
        }
    }
}
