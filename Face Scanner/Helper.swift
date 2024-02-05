//
//  Helper.swift
//  Face Scanner
//
//  Created by sandeepsing-maclaptop on 05/02/24.
//

import Foundation
import UIKit

extension UIViewController {
    func showAlert(title: String, message: String, dismissAfter delay: TimeInterval = 2.0) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        present(alertController, animated: true, completion: nil)

        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            alertController.dismiss(animated: true, completion: nil)
        }
    }
}
