//
//  File.swift
//  
//
//  Created by Qiwei Li on 1/23/23.
//

import Foundation
import AppKit
import PluginInterface


public class NSPanelUtils: ObservableObject, NSPanelUtilsProtocol {
    public init() {}
    
    public func confirm(title: String, subtitle: String, confirmButtonText: String? = "Confirm", cancelButtonText: String? = "Cancel", alertStyle: NSAlert.Style? = .informational) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = subtitle
        if let alertStyle = alertStyle {
            alert.alertStyle = alertStyle
        }
        
        if let confirmButtonText = confirmButtonText {
            alert.addButton(withTitle: confirmButtonText)
        }
        
        if let cancelButtonText = cancelButtonText {
            alert.addButton(withTitle: cancelButtonText)
        }
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    public func alert(title: String, subtitle: String, okButtonText: String? = "OK", alertStyle: NSAlert.Style? = .critical) -> Void {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = subtitle
        if let alertStyle = alertStyle {
            alert.alertStyle = alertStyle
        }
        if let okButtonText = okButtonText {
            alert.addButton(withTitle: okButtonText)
        }
        alert.runModal()
    }
}
