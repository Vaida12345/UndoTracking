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
        String(localized: self)
    }
    
}


extension UndoManager {
    
    /// Sets the name of the action associated with the Undo or Redo command.
    public func actionName(_ title: LocalizedStringResource) {
        self.setActionName(title.localized())
    }
    
}
