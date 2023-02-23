import SwiftUI
import InputMethodKit

extension CantoneseIMEInputController {

        override func recognizedEvents(_ sender: Any!) -> Int {
                let masks: NSEvent.EventTypeMask = [.keyDown]
                return Int(masks.rawValue)
        }

        override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
                let modifiers = event.modifierFlags
                let shouldIgnoreCurrentEvent: Bool = modifiers.contains(.command) || modifiers.contains(.option)
                guard !shouldIgnoreCurrentEvent else { return false }
                guard let client: IMKTextInput = sender as? IMKTextInput else { return false }
                currentOrigin = client.position
                let currentClientID = currentClient?.uniqueClientIdentifierString()
                let clientID = client.uniqueClientIdentifierString()
                if clientID != currentClientID {
                        currentClient = client
                }
                let isShifting: Bool = modifiers == .shift
                switch event.keyCode.representative {
                case .arrow(let direction):
                        switch direction {
                        case .up:
                                guard isBufferState else { return false }
                                displayObject.decreaseHighlightedIndex()
                                return true
                        case .down:
                                guard isBufferState else { return false }
                                displayObject.increaseHighlightedIndex()
                                return true
                        case .left:
                                return false
                        case .right:
                                return false
                        }
                case .number(let number):
                        let index: Int = number == 0 ? 9 : (number - 1)
                        if isBufferState {
                                guard let selectedItem = displayObject.candidates.fetch(index) else { return true }
                                let text = selectedItem.text
                                client.insert(text)
                                aftercareSelection(selectedItem)
                                return true
                        } else {
                                let text: String = KeyCode.shiftingSymbol(of: number)
                                client.insert(text)
                                return true
                        }
                case .keypadNumber(_):
                        return true
                case .punctuation(let punctuationKey):
                        guard candidates.isEmpty else {
                                switch punctuationKey {
                                case .bracketLeft, .comma, .minus:
                                        updateDisplayingCandidates(.previousPage)
                                        return true
                                case .bracketRight, .period, .equal:
                                        updateDisplayingCandidates(.nextPage)
                                        return true
                                default:
                                        return true
                                }
                        }
                        passBuffer()
                        if isShifting {
                                if let symbol = punctuationKey.instantShiftingSymbol {
                                        client.insert(symbol)
                                } else {
                                        bufferText = punctuationKey.shiftingKeyText
                                }
                        } else {
                                if let symbol = punctuationKey.instantSymbol {
                                        client.insert(symbol)
                                } else {
                                        bufferText = punctuationKey.keyText
                                }
                        }
                        return true
                case .alphabet(let letter):
                        let text: String = isShifting ? letter.uppercased() : letter
                        bufferText += text
                        return true
                case .separator:
                        guard isBufferState else { return false }
                        bufferText += "'"
                        return true
                case .return:
                        guard isBufferState else { return false }
                        passBuffer()
                        return true
                case .backspace:
                        guard isBufferState else { return false }
                        bufferText = String(bufferText.dropLast())
                        return true
                case .escapeClear:
                        guard isBufferState else { return false }
                        bufferText = .empty
                        return true
                case .space:
                        if candidates.isEmpty {
                                passBuffer()
                                client.insert(" ")
                                return true
                        } else {
                                let index = displayObject.highlightedIndex
                                guard let selectedItem = displayObject.candidates.fetch(index) else { return true }
                                let text = selectedItem.text
                                client.insert(text)
                                aftercareSelection(selectedItem)
                                return true
                        }
                case .tab:
                        guard isBufferState else { return false }
                        displayObject.increaseHighlightedIndex()
                        return true
                case .previousPage:
                        guard isBufferState else { return false }
                        updateDisplayingCandidates(.previousPage)
                        return true
                case .nextPage:
                        guard isBufferState else { return false }
                        updateDisplayingCandidates(.nextPage)
                        return true
                case .other:
                        switch event.keyCode {
                        case KeyCode.Special.VK_HOME:
                                let shouldJump2FirstPage: Bool = !(candidates.isEmpty)
                                guard shouldJump2FirstPage else { return false }
                                updateDisplayingCandidates(.establish)
                                return true
                        default:
                                return false
                        }
                }
        }

        private func passBuffer() {
                guard isBufferState else { return }
                let text: String = bufferText
                currentClient?.insert(text)
                bufferText = .empty
        }

        private func aftercareSelection(_ candidate: Candidate) {
                guard let firstBufferCharacter = bufferText.first else { return }
                guard firstBufferCharacter.isBasicLatinLetter else {
                        bufferText = .empty
                        return
                }
                switch firstBufferCharacter {
                case "r", "v", "x", "q":
                        if bufferText.count <= candidate.input.count + 1 {
                                bufferText = .empty
                        } else {
                                let first: String = String(bufferText.first!)
                                let tail = bufferText.dropFirst(candidate.input.count + 1)
                                bufferText = first + tail
                        }
                default:
                        let bufferTextLength: Int = bufferText.count
                        let candidateInputText: String = {
                                let converted: String = candidate.input.replacingOccurrences(of: "(4|5|6)", with: "RR", options: .regularExpression)
                                return converted
                        }()
                        let inputCount: Int = {
                                let candidateInputCount: Int = candidateInputText.count
                                guard bufferTextLength > 2 else { return candidateInputCount }
                                guard candidateInputText.contains("jyu") else { return candidateInputCount }
                                let suffixCount: Int = max(0, bufferTextLength - candidateInputCount)
                                let leading = bufferText.dropLast(suffixCount)
                                let modifiedLeading = leading.replacingOccurrences(of: "(c|d|h|j|l|s|z)yu(n|t)", with: "RRRR", options: .regularExpression)
                                        .replacingOccurrences(of: "^(g|k|n|t)?yu(n|t)", with: "RRRR", options: .regularExpression)
                                        .replacingOccurrences(of: "(?<!c|j|s|z)yu(?!k|m|ng)", with: "jyu", options: .regularExpression)
                                return candidateInputCount - (modifiedLeading.count - leading.count)
                        }()
                        let difference: Int = bufferTextLength - inputCount
                        guard difference > 0 else {
                                bufferText = .empty
                                return
                        }
                        let leading = bufferText.dropLast(difference)
                        let filtered = leading.filter({ !$0.isSeparator })
                        var tail: String.SubSequence = {
                                if filtered.count == leading.count {
                                        return bufferText.dropFirst(inputCount)
                                } else {
                                        let separatorsCount: Int = leading.count - filtered.count
                                        return bufferText.dropFirst(inputCount + separatorsCount)
                                }
                        }()
                        while tail.hasPrefix("'") {
                                tail = tail.dropFirst()
                        }
                        bufferText = String(tail)
                }
        }
}
