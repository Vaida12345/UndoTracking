//
//  Extensions.swift
//  UndoTracking
//
//  Created by Vaida on 12/30/24.
//

import Foundation


extension UndoManager {
    
    /// Sets the name of the action associated with the Undo or Redo command.
    @available(*, deprecated, renamed: "setActionName")
    public func actionName(_ title: LocalizedStringResource) {
        self.setActionName(title)
    }
    
}
