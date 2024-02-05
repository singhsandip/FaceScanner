//
//  FacialAbnormalityType.swift
//  Face Scanner
//
//  Created by sandeepsing-maclaptop on 05/02/24.
//

import Foundation

enum FacialAbnormalityType {
    case wrinkle
    case pores
    case pigmentation

    var description: String {
        switch self {
        case .wrinkle:
            return "Wrinkle"
        case .pores:
            return "Pores"
        case .pigmentation:
            return "Pigmentation"
        }
    }
}
