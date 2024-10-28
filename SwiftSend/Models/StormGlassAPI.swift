//
//  StormGlassAPI.swift
//  SwiftSend
//
//  Created by Brody on 9/12/24.
//
import Foundation


struct StormGlassAPI{
    
    let lat : Double
    let lng : Double
    let startDate : String
    
    init(lat: Double, lng: Double, startDate: String) {
        self.lat = lat
        self.lng = lng
        self.startDate = startDate
    }
    
    // Function to load .env file
    func loadEnvFile() -> [String: String] {
        var envDict = [String: String]()
        
        if let path = Bundle.main.path(forResource: ".env", ofType: nil) {
            do {
                let content = try String(contentsOfFile: path)
                let lines = content.split(separator: "\n")
                
                for line in lines {
                    let parts = line.split(separator: "=")
                    if parts.count == 2 {
                        let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                        let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                        envDict[key] = value
                    }
                }
            } catch {
                print("Error loading .env file")
            }
        }
        
        return envDict
    }


    


    func fetchTideData() async throws -> [[String: Any]]? {
            // Load the API key from the .env file
            let envVars = loadEnvFile()
            guard let apiKey = envVars["STORMGLASS_API_KEY"] else {
                print("API key not found")
                return nil
            }
            
            // Build the API request URL
            let urlString = "https://api.stormglass.io/v2/tide/extremes/point?lat=\(self.lat)&lng=\(self.lng)&start=\(self.startDate)"
            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                return nil
            }
            
            // Create URL request
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue(apiKey, forHTTPHeaderField: "Authorization")
            
            // Perform the API request using async/await
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check for valid HTTP response status
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Invalid response from server")
                print("STORM API error code: \(response)")
                return nil
            }
            
            // Parse the JSON response
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let tideData = jsonResponse["data"] as? [[String: Any]] {
                    
//                    print("\n\n\nTIDE DATA: \(tideData)\n\n\n")
                    
                   return tideData
                    
                } else {
                    print("Invalid JSON structure")
                    return nil
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                throw error
            }
        }
}
        
