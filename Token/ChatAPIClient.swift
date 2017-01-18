import UIKit
import Networking
import SweetFoundation

public class ChatAPIClient: NSObject {

    public var cereal: Cereal

    public var networking: Networking

    public var address: String {
        return self.cereal.address
    }

    public var baseURL: URL

    public lazy var storageManager: TSStorageManager = {
        return TSStorageManager.shared()
    }()

    public init(cereal: Cereal) {
        self.cereal = cereal
        self.baseURL = URL(string: "https://token-chat-service.herokuapp.com")!
        self.networking = Networking(baseURL: self.baseURL.absoluteString)
    }

    public func registerUserIfNeeded() {
        let parameters = UserBootstrapParameter(storageManager: self.storageManager, timestamp: Int(Date().timeIntervalSince1970), ethereumAddress: self.address)

        let message = parameters.stringForSigning()
        let signature = self.cereal.sign(message: message)
        parameters.signature = "0x\(signature)"

        guard let signedParameters = parameters.signedParametersDictionary() else { fatalError("Missing signature!") }

        self.networking.PUT("/v1/accounts/bootstrap", parameterType: .json, parameters: signedParameters) { (JSON, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("Registered user with address: \(self.address)")

                TSStorageManager.storeServerToken(DeviceSpecificPassword, signalingKey: parameters.signalingKey)

                let auth = self.authToken(for: self.address, password: DeviceSpecificPassword)
                self.networking.setAuthorizationHeader(headerValue: auth)
            }
        }
    }

    func authToken(for address: String, password: String) -> String {
        return "Basic \("\(address):\(password)".data(using: .utf8)!.base64EncodedString())"
    }
}
