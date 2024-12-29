//
//  Extensions.swift
//  UndoTracking
//
//  Created by Vaida on 12/30/24.
//

import Foundation


extension LocalizedStringResource {
    
    /// Creates the localized String.
    func localized() -> String {
        var copy = self
        copy.locale = .current
        return String(localized: copy)
    }
    
}


extension UndoManager {
    
    /// Sets the name of the action associated with the Undo or Redo command.
    public func actionName(_ title: LocalizedStringResource) {
        self.setActionName(title.localized())
    }
    
}
