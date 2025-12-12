import LocalAuthentication

class BiometricAuth {
    static let shared = BiometricAuth()
    
    func authenticate(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric auth is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Log in to Dance Sage"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    completion(success, error)
                }
            }
        } else {
            // Biometric not available, use passcode
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Log in to Dance Sage") { success, error in
                DispatchQueue.main.async {
                    completion(success, error)
                }
            }
        }
    }
}
