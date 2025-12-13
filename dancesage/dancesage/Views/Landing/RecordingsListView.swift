import SwiftUI

struct RecordingsListView: View {
    @State private var recordings: [DanceRecording] = []
    @State private var selectedRecording: DanceRecording?
    @State private var showPlayback = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                if recordings.isEmpty {
                    VStack {
                        Text("No recordings yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Start recording to save your dances")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(recordings) { recording in
                            Button(action: {
                                selectedRecording = recording
                                showPlayback = true
                            }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(recording.name)
                                        .font(.headline)
                                    HStack {
                                        Text("\(recording.frameCount) frames")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text(recording.timestamp, style: .date)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteRecording)
                    }
                }
            }
            .navigationTitle("My Recordings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadRecordings()
            }
            .fullScreenCover(isPresented: $showPlayback) {
                if let recording = selectedRecording {
                    SkeletonPlaybackView(keypoints: recording.keypoints, allowSave: true)
                }
            }
        }
    }
    
    func loadRecordings() {
        guard let data = UserDefaults.standard.data(forKey: "savedDances"),
              let loaded = try? JSONDecoder().decode([DanceRecording].self, from: data) else {
            recordings = []
            return
        }
        recordings = loaded
    }
    
    func deleteRecording(at offsets: IndexSet) {
        recordings.remove(atOffsets: offsets)
        
        do {
            let data = try JSONEncoder().encode(recordings)
            UserDefaults.standard.set(data, forKey: "savedDances")
            print("✅ Recording deleted")
        } catch {
            print("❌ Failed to delete: \(error)")
        }
    }
}
