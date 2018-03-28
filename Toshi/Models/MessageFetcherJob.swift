// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import Foundation
import PromiseKit

class MessageFetcherJob: NSObject {

    private let TAG = "[MessageFetcherJob]"

    private var timer: Timer?

    // MARK: injected dependencies
    private let networkManager: TSNetworkManager
    private let messageReceiver: OWSMessageReceiver
    private let signalService: OWSSignalService

    init(messageReceiver: OWSMessageReceiver, networkManager: TSNetworkManager, signalService: OWSSignalService) {
        self.messageReceiver = messageReceiver
        self.networkManager = networkManager
        self.signalService = signalService
    }

    @discardableResult public func run(completion: (() -> Void)? = nil) -> Promise<Void> {

        let promise = self.fetchUndeliveredMessages().then { (envelopes: [OWSSignalServiceProtosEnvelope], more: Bool) -> Promise<Void> in
            for envelope in envelopes {
                self.messageReceiver.handleReceivedEnvelope(envelope)
                self.acknowledgeDelivery(envelope: envelope)
            }

            if more {
                return self.run()
            } else {
                // All finished

                completion?()
                return Promise(value: ())
            }
        }

        promise.retainUntilComplete()

        return promise
    }

//    @objc func run() -> AnyPromise {
//        return AnyPromise(run())
//    }

    private func parseMessagesResponse(responseObject: Any?) -> (envelopes: [OWSSignalServiceProtosEnvelope], more: Bool)? {
        guard let responseObject = responseObject else {
            return nil
        }

        guard let responseDict = responseObject as? [String: Any] else {
            return nil
        }

        guard let messageDicts = responseDict["messages"] as? [[String: Any]] else {
            return nil
        }

        let moreMessages = { () -> Bool in
            if let responseMore = responseDict["more"] as? Bool {
                return responseMore
            } else {
                return false
            }
        }()

        let envelopes = messageDicts.map { buildEnvelope(messageDict: $0) }.filter { $0 != nil }.map { $0! }

        return (
            envelopes: envelopes,
            more: moreMessages
        )
    }

    private func buildEnvelope(messageDict: [String: Any]) -> OWSSignalServiceProtosEnvelope? {
        let builder = OWSSignalServiceProtosEnvelopeBuilder()

        guard let typeInt = messageDict["type"] as? Int32 else { return nil }
        guard let type = OWSSignalServiceProtosEnvelopeType(rawValue: typeInt) else { return nil }

        builder.setType(type)

        if let relay = messageDict["relay"] as? String {
            builder.setRelay(relay)
        }

        guard let timestamp = messageDict["timestamp"] as? UInt64 else { return nil }
        builder.setTimestamp(timestamp)

        guard let source = messageDict["source"] as? String else { return nil }
        builder.setSource(source)

        guard let sourceDevice = messageDict["sourceDevice"] as? UInt32 else { return nil }
        builder.setSourceDevice(sourceDevice)

        if let encodedLegacyMessage = messageDict["message"] as? String {
            if let legacyMessage = Data(base64Encoded: encodedLegacyMessage) {
                builder.setLegacyMessage(legacyMessage)
            }
        }

        if let encodedContent = messageDict["content"] as? String {
            if let content = Data(base64Encoded: encodedContent) {
                builder.setContent(content)
            }
        }

        return builder.build()
    }

    private func fetchUndeliveredMessages() -> Promise<(envelopes: [OWSSignalServiceProtosEnvelope], more: Bool)> {
        return Promise { fulfill, reject in
            let messagesRequest = OWSGetMessagesRequest()

            self.networkManager.makeRequest(
                messagesRequest,
                success: { (_: URLSessionDataTask?, responseObject: Any?) -> Void in
                    guard let (envelopes, more) = self.parseMessagesResponse(responseObject: responseObject) else {
                        return reject(OWSErrorMakeUnableToProcessServerResponseError())
                    }

                    fulfill((envelopes: envelopes, more: more))
                },
                failure: { (_: URLSessionDataTask?, error: Error?) in
                    guard let error = error else {
                        return reject(OWSErrorMakeUnableToProcessServerResponseError())
                    }

                    reject(error)
            })
        }
    }

    private func acknowledgeDelivery(envelope: OWSSignalServiceProtosEnvelope) {
        let request = OWSAcknowledgeMessageDeliveryRequest(source: envelope.source, timestamp: envelope.timestamp)
        self.networkManager.makeRequest(request,
                                        success: { _, _ -> Void in },
                                        failure: { _, _ in })
    }
}

public extension Promise {
    /**
     * Sometimes there isn't a straight forward candidate to retain a promise, in that case we tell the
     * promise to self retain, until it completes to avoid the risk it's GC'd before completion.
     */
    func retainUntilComplete() {
        // Unfortunately, there is (currently) no way to surpress the
        // compiler warning: "Variable 'retainCycle' was written to, but never read"
        var retainCycle: Promise<T>? = self
        self.always {
            retainCycle = nil
        }
    }
}
