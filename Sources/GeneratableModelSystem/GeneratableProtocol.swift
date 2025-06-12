//
//  GeneratableProtocol.swift
//  Llama Tools Mac
//
//  Created by Morisson Marcel on 10/06/25.
//

import Foundation
import SwiftUI

public protocol GeneratableProtocol: Codable {
    static var description: String { get }
    static var scheme: [String: GuideDescriptor] { get }
}

public extension GeneratableProtocol {
    static var jsonDescription: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let json = try? encoder.encode(scheme)
        let string = String(data: json ?? Data(), encoding: String.Encoding.utf8) ?? ""
        return string
    }
}
