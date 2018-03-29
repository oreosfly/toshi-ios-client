// Copyright (c) 2017 Token Browser, Inc
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
@testable import Toshi

// MARK: - Robot to deal with the how does it work screen which explains how login in works.

protocol HowDoesItWorkScreenRobot: BasicRobot { }

// MARK: Buttons which can be selected on the how does it work screen

enum HowDoesItWorkScreenButton {
    case
    back

    var accessibilityLabel: String {
        switch self {
        case .back:
            return Localized.back_action_title
        }
    }
}

// MARK: - Default Implementation

extension HowDoesItWorkScreenRobot {
    
    // MARK: - Actions
    
    @discardableResult
    func select(button: HowDoesItWorkScreenButton,
                file: StaticString = #file,
                line: UInt = #line) -> HowDoesItWorkScreenRobot {
        tapButtonWith(accessibilityLabel: button.accessibilityLabel,
                      file: file,
                      line: line)
        
        return self
    }
    
    // MARK: - Validators
    
    @discardableResult
    func validateOnHowDoesItWorkScreen(file: StaticString = #file, line: UInt = #line) -> HowDoesItWorkScreenRobot {
        confirmViewVisibleWith(accessibilityLabel: Localized.passphrase_sign_in_explanation_title,
                               file: file,
                               line: line)
        return self
    }
    
    @discardableResult
    func validateOffHowDoesItWorkScreen(file: StaticString = #file, line: UInt = #line) -> HowDoesItWorkScreenRobot {
        confirmViewGoneWith(accessibilityLabel: Localized.passphrase_sign_in_explanation_title,
                            file: file,
                            line: line)
        
        return self
    }
}
