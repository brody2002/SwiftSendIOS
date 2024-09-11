//
//  SurfTestView.swift
//  SwiftSend
//
//  Created by Brody on 9/11/24.
//
import OpenMeteoSdk
import SwiftUI

struct SurfTestView: View {
    
    
    
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/).onTapGesture {
            print("tapped")
        }
    }
}

#Preview {
    SurfTestView()
}

struct SurfAPI {
    let url: URL

    init(latitude: Double, longitude: Double) {
        // Initialize the URL dynamically based on input latitude and longitude
        self.url = URL(string: "https://marine-api.open-meteo.com/v1/marine?latitude=\(latitude)&longitude=\(longitude)&daily=wave_height_max,wave_direction_dominant,wave_period_max,wind_wave_height_max,wind_wave_direction_dominant,wind_wave_period_max,wind_wave_peak_period_max,swell_wave_height_max,swell_wave_direction_dominant,swell_wave_period_max,swell_wave_peak_period_max&timezone=America%2FLos_Angeles&format=flatbuffers")!
    }

    func fetchWeatherData() async throws {
        // Fetch the weather response
        let responses = try await WeatherApiResponse.fetch(url: url)

        // Process the first location. Add a loop for multiple locations
        guard let response = responses.first else {
            print("No response found")
            return
        }

        // Attributes for timezone and location
        let utcOffsetSeconds = response.utcOffsetSeconds
        let timezone = response.timezone
        let timezoneAbbreviation = response.timezoneAbbreviation
        let latitude = response.latitude
        let longitude = response.longitude

        // Extract daily weather data
        guard let daily = response.daily else {
            print("No daily data found")
            return
        }

        // Map the weather data
        let data = WeatherData(
            daily: .init(
                time: daily.getDateTime(offset: utcOffsetSeconds),
                waveHeightMax: daily.variables(at: 0)!.values,
                waveDirectionDominant: daily.variables(at: 1)!.values,
                wavePeriodMax: daily.variables(at: 2)!.values,
                windWaveHeightMax: daily.variables(at: 3)!.values,
                windWaveDirectionDominant: daily.variables(at: 4)!.values,
                windWavePeriodMax: daily.variables(at: 5)!.values,
                windWavePeakPeriodMax: daily.variables(at: 6)!.values,
                swellWaveHeightMax: daily.variables(at: 7)!.values,
                swellWaveDirectionDominant: daily.variables(at: 8)!.values,
                swellWavePeriodMax: daily.variables(at: 9)!.values,
                swellWavePeakPeriodMax: daily.variables(at: 10)!.values
            )
        )

        // Format and print data
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .gmt
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        for (i, date) in data.daily.time.enumerated() {
            print(dateFormatter.string(from: date))
            print(data.daily.waveHeightMax[i])
            print(data.daily.waveDirectionDominant[i])
            print(data.daily.wavePeriodMax[i])
            print(data.daily.windWaveHeightMax[i])
            print(data.daily.windWaveDirectionDominant[i])
            print(data.daily.windWavePeriodMax[i])
            print(data.daily.windWavePeakPeriodMax[i])
            print(data.daily.swellWaveHeightMax[i])
            print(data.daily.swellWaveDirectionDominant[i])
            print(data.daily.swellWavePeriodMax[i])
            print(data.daily.swellWavePeakPeriodMax[i])
        }
    }

    struct WeatherData {
        let daily: Daily

        struct Daily {
            let time: [Date]
            let waveHeightMax: [Float]
            let waveDirectionDominant: [Float]
            let wavePeriodMax: [Float]
            let windWaveHeightMax: [Float]
            let windWaveDirectionDominant: [Float]
            let windWavePeriodMax: [Float]
            let windWavePeakPeriodMax: [Float]
            let swellWaveHeightMax: [Float]
            let swellWaveDirectionDominant: [Float]
            let swellWavePeriodMax: [Float]
            let swellWavePeakPeriodMax: [Float]
        }
    }
}
