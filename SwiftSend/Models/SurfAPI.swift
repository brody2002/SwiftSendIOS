//
//  SurfAPI.swift
//  SwiftSend
//
//  Created by Brody on 9/11/24.
//

import Foundation
import OpenMeteoSdk

struct SurfAPI {
    let url: URL

    init(latitude: Double, longitude: Double) {
        self.url = URL(string:  "https://marine-api.open-meteo.com/v1/marine?latitude=37.7749&longitude=-122.4194&daily=wave_height_max,wave_direction_dominant,wave_period_max,wind_wave_height_max,wind_wave_direction_dominant,wind_wave_period_max,wind_wave_peak_period_max,swell_wave_height_max,swell_wave_direction_dominant,swell_wave_period_max,swell_wave_peak_period_max&length_unit=imperial&wind_speed_unit=mph&timezone=America%2FLos_Angeles&format=flatbuffers")!
    }

    func fetchWeatherData() async throws -> WeatherData? {
        let responses = try await WeatherApiResponse.fetch(url: url)

        guard let response = responses.first else {
            print("No response found")
            return nil
        }

        let utcOffsetSeconds = response.utcOffsetSeconds

        guard let daily = response.daily else {
            print("No daily data found")
            return nil
        }

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

        return data
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
