//
//  File.swift
//  SwiftSend
//
//  Created by Brody on 9/4/24.
//

import Foundation
import SwiftUI



struct Env {
    static func load() {
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil) else {
            print(".env file not found")
            return
        }

        do {
            let contents = try String(contentsOfFile: path)
            let lines = contents.split(whereSeparator: \.isNewline)
            
            for line in lines {
                let parts = line.split(separator: "=", maxSplits: 1).map { String($0) }
                if parts.count == 2 {
                    
                    // parts[1] = key itself
                    // 1 = the value to overwrite previous key if changed
                    setenv(parts[0], parts[1], 1)
                }
            }
        } catch {
            print("Error loading .env file: \(error)")
        }
    }
    
    static func get(_ key: String) -> String? {
        return ProcessInfo.processInfo.environment[key]
    }
}
