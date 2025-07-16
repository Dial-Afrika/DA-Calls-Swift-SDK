//
//  utils.swift
//  DACalls
//
//  Created by Joseph Kangethe on 16/07/2025.
//

extension String {
    func capitalizingFirstLetter() -> String {
        prefix(1).uppercased() + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = capitalizingFirstLetter()
    }
}
