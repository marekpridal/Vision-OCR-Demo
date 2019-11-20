//
//  RecognizedKeyValue.swift
//  airbank-ocr-demo
//
//  Created by Marek Přidal on 20/11/2019.
//  Copyright © 2019 Marek Přidal. All rights reserved.
//

import Foundation
import Vision

struct RecognizedKeyValue {
    enum Alignment {
        case vertical
        case horizontal
    }
    
    enum DocumentElement: String, CaseIterable {
        case surname = "SURNAME"
        case givenNames = "GIVEN NAMES"
        case dateOfBirth = "DATE OF BIRTH"
        case documentNo = "DOCUMENT NO."
        case placeOfBirth = "PLACE OF BIRTH"
        case nationality = "NATIONALITY"
        case dateOfIssue = "DATE OF ISSUE"
        case dateOfExpiry = "DATE OF EXPIRY"
        case sex = "SEX"
    }
    
    let key: String
    let keyTextObservation: VNRecognizedTextObservation
    
    var keyPosition: VNRectangleObservation? {
        try? keyTextObservation.topCandidates(10).first(where: { $0.string == key })?.boundingBox(for: Range<String.Index>.init(uncheckedBounds: (key.startIndex, key.endIndex)))
    }
    var alignment: Alignment {
        key.contains("SURNAME") || key.contains("GIVEN NAMES") || key.contains("DOCUMENT NO.") ? .horizontal : .vertical
    }
    var documentElement: DocumentElement? {
        DocumentElement(rawValue: key)
    }

    var value: String?
    var valueTextObservation: VNRecognizedTextObservation?
}
