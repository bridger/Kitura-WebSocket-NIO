/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import XCTest
import Foundation
import Dispatch

import LoggerAPI
@testable import KituraWebSocket
import Socket

class BasicTests: KituraTest {

    static var allTests: [(String, (BasicTests) -> () throws -> Void)] {
        return [
            ("testBinaryLongMessage", testBinaryLongMessage),
            ("testBinaryMediumMessage", testBinaryMediumMessage),
            ("testBinaryShortMessage", testBinaryShortMessage),
            ("testGracefullClose", testGracefullClose),
            ("testPing", testPing),
            ("testPingWithText", testPingWithText),
            ("testServerRequest", testServerRequest),
            ("testSuccessfulUpgrade", testSuccessfulUpgrade),
            ("testSuccessfulRemove", testSuccessfulRemove),
            ("testTextLongMessage", testTextLongMessage),
            ("testTextMediumMessage", testTextMediumMessage),
            ("testTextShortMessage", testTextShortMessage),
            ("testTextShortMessageWithQueryParams", testTextShortMessageWithQueryParams),
            ("testNullCharacter", testNullCharacter),
            ("testUserDefinedCloseCode", testUserDefinedCloseCode),
            ("testUserCloseMessage", testUserCloseMessage)
        ]
    }

    func testBinaryLongMessage() {
        register(closeReason: .noReasonCodeSent)

        var bytes = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e]
        let binaryPayload = NSMutableData(bytes: &bytes, length: bytes.count)
        repeat {
            binaryPayload.append(binaryPayload.bytes, length: binaryPayload.length)
        } while binaryPayload.length < 100000
        binaryPayload.append(&bytes, length: bytes.count)

        performServerTest (asyncTasks: { expectation in
            self.performTest(framesToSend: [(true, self.opcodeBinary, binaryPayload)],
                             expectedFrames: [(true, self.opcodeBinary, binaryPayload)],
                             expectation: expectation)
            }, { expectation in
                self.performTest(framesToSend: [(true, self.opcodeBinary, binaryPayload)],
                                 expectedFrames: [(true, self.opcodeBinary, binaryPayload)],
                                 expectation: expectation, negotiateCompression: true, compressed: true)
            }, { expectation in
                self.performTest(framesToSend: [(true, self.opcodeBinary, binaryPayload)],
                                 expectedFrames: [(true, self.opcodeBinary, binaryPayload)],
                                 expectation: expectation, negotiateCompression: true, compressed: false)
            })
    }

    func testBinaryMediumMessage() {
        register(closeReason: .noReasonCodeSent)


        var bytes = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e]
        let binaryPayload = NSMutableData(bytes: &bytes, length: bytes.count)
        repeat {
            binaryPayload.append(binaryPayload.bytes, length: binaryPayload.length)
        } while binaryPayload.length < 1000

        performServerTest (asyncTasks: { expectation in
            self.performTest(framesToSend: [(true, self.opcodeBinary, binaryPayload)],
                             expectedFrames: [(true, self.opcodeBinary, binaryPayload)],
                             expectation: expectation)
            }, { expectation in
                self.performTest(framesToSend: [(true, self.opcodeBinary, binaryPayload)],
                                 expectedFrames: [(true, self.opcodeBinary, binaryPayload)],
                                 expectation: expectation, negotiateCompression: true, compressed: true)
            }, { expectation in
                self.performTest(framesToSend: [(true, self.opcodeBinary, binaryPayload)],
                                 expectedFrames: [(true, self.opcodeBinary, binaryPayload)],
                                 expectation: expectation, negotiateCompression: true, compressed: false)
            })
    }

    func testBinaryShortMessage() {
        register(closeReason: .noReasonCodeSent)

        var bytes = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e]
        let binaryPayload = NSMutableData(bytes: &bytes, length: bytes.count)

        performServerTest (asyncTasks: { expectation in
            self.performTest(framesToSend: [(true, self.opcodeBinary, binaryPayload)],
                             expectedFrames: [(true, self.opcodeBinary, binaryPayload)],
                             expectation: expectation)
            }, { expectation in
                self.performTest(framesToSend: [(true, self.opcodeBinary, binaryPayload)],
                                 expectedFrames: [(true, self.opcodeBinary, binaryPayload)],
                                 expectation: expectation, negotiateCompression: true, compressed: true)
            }, { expectation in
                self.performTest(framesToSend: [(true, self.opcodeBinary, binaryPayload)],
                                 expectedFrames: [(true, self.opcodeBinary, binaryPayload)],
                                 expectation: expectation, negotiateCompression: true, compressed: false)
            })
    }

    func testGracefullClose() {
        register(closeReason: .normal)

        performServerTest { expectation in
            let sendPayload = self.payload(closeReasonCode: .normal)
            self.performTest(framesToSend: [(true, self.opcodeClose, sendPayload)],
                             expectedFrames: [(true, self.opcodeClose, sendPayload)],
                             expectation: expectation)
        }
    }

    func testPing() {
        register(closeReason: .noReasonCodeSent)

        performServerTest { expectation in
            let pingPayload = NSData()
            self.performTest(framesToSend: [(true, self.opcodePing, pingPayload)],
                             expectedFrames: [(true, self.opcodePong, pingPayload)],
                             expectation: expectation)
        }
    }

    func testPingWithText() {
        register(closeReason: .noReasonCodeSent)

        performServerTest { expectation in
            let pingPayload = self.payload(text: "Testing, testing 1,2,3")
            self.performTest(framesToSend: [(true, self.opcodePing, pingPayload)],
                             expectedFrames: [(true, self.opcodePong, pingPayload)],
                             expectation: expectation)
        }
    }

    func testServerRequest() {
        register(closeReason: .noReasonCodeSent, testServerRequest: true)

        performServerTest { expectation in
            let connected = DispatchSemaphore(value: 0)
            guard let _ = self.sendUpgradeRequest(toPath: self.servicePath, usingKey: self.secWebKey, semaphore: connected) else { return }
            connected.wait()

            sleep(3)       // Wait a bit for the WebSocketService to test the ServerRequest

            expectation.fulfill()
        }
    }

    func testSuccessfulRemove() {
        register(closeReason: .noReasonCodeSent)

        performServerTest { expectation in
            let upgraded = DispatchSemaphore(value: 0)
            guard let _ = self.sendUpgradeRequest(toPath: self.servicePath, usingKey: self.secWebKey, semaphore: upgraded) else { return }
            upgraded.wait()
            WebSocket.unregister(path: self.servicePath)
            let upgradeFailed = DispatchSemaphore(value: 0)
            guard let _ = self.sendUpgradeRequest(toPath: self.servicePath, usingKey: self.secWebKey, semaphore: upgradeFailed, errorMessage: "No service has been registered for the path /wstester") else { return }
            upgradeFailed.wait()
            expectation.fulfill()
        }
    }

    func testSuccessfulUpgrade() {
        register(closeReason: .noReasonCodeSent) //with NIOWebSocket, the Websocket handler cannot be added to a listening server
        performServerTest(asyncTasks: { expectation in
            self.register(closeReason: .noReasonCodeSent)
            let upgraded = DispatchSemaphore(value: 0)
            guard let _ = self.sendUpgradeRequest(toPath: self.servicePath, usingKey: self.secWebKey, semaphore: upgraded) else { return }
            upgraded.wait()
            expectation.fulfill()
        }, { expectation in
            let upgraded = DispatchSemaphore(value: 0)
            WebSocket.unregister(path: self.servicePathNoSlash)
            self.register(onPath: self.servicePathNoSlash, closeReason: .noReasonCodeSent)
            guard let _ = self.sendUpgradeRequest(toPath: self.servicePath, usingKey: self.secWebKey, semaphore: upgraded) else { return }
            upgraded.wait()
            expectation.fulfill()
        })
    }

    func testTextLongMessage() {
        register(closeReason: .noReasonCodeSent)

        var text = "Testing, testing 1, 2, 3."
        repeat {
            text += " " + text
        } while text.count < 100000
        let textPayload = self.payload(text: text)

        performServerTest (asyncTasks: { expectation in
            self.performTest(framesToSend: [(true, self.opcodeText, textPayload)],
                             expectedFrames: [(true, self.opcodeText, textPayload)],
                             expectation: expectation)
            }, { expectation in
                self.performTest(framesToSend: [(true, self.opcodeText, textPayload)],
                                 expectedFrames: [(true, self.opcodeText, textPayload)],
                                 expectation: expectation, negotiateCompression: true, compressed: true)
            }, { expectation in
                self.performTest(framesToSend: [(true, self.opcodeText, textPayload)],
                                 expectedFrames: [(true, self.opcodeText, textPayload)],
                                 expectation: expectation, negotiateCompression: true, compressed: false)
            })
    }

    func testTextMediumMessage() {
        register(closeReason: .noReasonCodeSent)

        var text = ""
        repeat {
            text += "Testing, testing 1,2,3. "
        } while text.count < 1000
        let textPayload = self.payload(text: text)

        performServerTest(asyncTasks: { expectation in
            self.performTest(framesToSend: [(true, self.opcodeText, textPayload)],
                             expectedFrames: [(true, self.opcodeText, textPayload)],
                             expectation: expectation)
            }, { expectation in
                self.performTest(framesToSend: [(true, self.opcodeText, textPayload)],
                                 expectedFrames: [(true, self.opcodeText, textPayload)],
                                 expectation: expectation, negotiateCompression: true, compressed: true)
            }, { expectation in
                self.performTest(framesToSend: [(true, self.opcodeText, textPayload)],
                                 expectedFrames: [(true, self.opcodeText, textPayload)],
                                 expectation: expectation, negotiateCompression: true, compressed: false)
            })
    }

    func testTextShortMessage() {
        register(closeReason: .noReasonCodeSent)

        let textPayload = self.payload(text: "Testing, testing 1,2,3")

        performServerTest(asyncTasks: { expectation in
            self.performTest(framesToSend: [(true, self.opcodeText, textPayload)],
                             expectedFrames: [(true, self.opcodeText, textPayload)],
                             expectation: expectation)
            }, { expectation in
                self.performTest(framesToSend: [(true, self.opcodeText, textPayload)],
                                 expectedFrames: [(true, self.opcodeText, textPayload)],
                                 expectation: expectation, negotiateCompression: true, compressed: true)
            }, { expectation in
                self.performTest(framesToSend: [(true, self.opcodeText, textPayload)],
                                 expectedFrames: [(true, self.opcodeText, textPayload)],
                                 expectation: expectation, negotiateCompression: true, compressed: false)
            })
    }

    func testTextShortMessageWithQueryParams() {
        register(closeReason: .noReasonCodeSent, testQueryParams: true)
        let textPayload = self.payload(text: "Keys and Values: ")
        let expectedPayload = self.payload(text: "Keys and Values: p1,p2 and v1,v2")
        performServerTest(asyncTasks: { expectation in
            self.performTest(onPath: "/wstester?p1=v1&p2=v2", framesToSend: [(true, self.opcodeText, textPayload)],
                             expectedFrames: [(true, self.opcodeText, expectedPayload)],
                             expectation: expectation)
        })
    }

    func testUserDefinedCloseCode() {
        register(closeReason: .userDefined(65535))

        performServerTest { expectation in

            let closePayload = self.payload(closeReasonCode: .userDefined(65535))
            let returnPayload = self.payload(closeReasonCode: .userDefined(65535))

            self.performTest(framesToSend: [(true, self.opcodeClose, closePayload)],
                             expectedFrames: [(true, self.opcodeClose, returnPayload)],
                             expectation: expectation)
        }
    }

    func testUserCloseMessage() {
        register(closeReason: .normal)

        performServerTest { expectation in
            let testString = "Testing, 1,2,3"
            let dataPayload = testString.data(using: String.Encoding.utf8)!
            let payload = NSMutableData()
            let closeReasonCode = self.payload(closeReasonCode: .normal)
            payload.append(closeReasonCode.bytes, length: closeReasonCode.length)
            payload.append(dataPayload)

            self.performTest(framesToSend: [(true, self.opcodeClose, payload)],
                             expectedFrames: [(true, self.opcodeClose, payload)],
                             expectation: expectation)
        }
    }

    func testNullCharacter() {
        register(closeReason: .noReasonCodeSent)

        performServerTest { expectation in
            let textPayload = self.payload(text: "\u{00}")
            self.performTest(framesToSend: [(true, self.opcodeText, textPayload)],
                             expectedFrames: [(true, self.opcodeText, textPayload)],
                             expectation: expectation)
        }
    }
}
