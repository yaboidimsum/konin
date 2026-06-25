//
//  Chapter.swift
//  Konin
//

import Foundation

enum Chapter: String, CaseIterable, Codable, Equatable {
    case krotoszyn = "Krotoszyn"
    case kozmin = "Koźmin"
    case jarocin = "Jarocin"
    case tunnel = "Tunnel"
    case konin = "Konin"
    case zolkiew = "Żółkiew"
    
    var title: String {
        switch self {
        case .krotoszyn: return "Chapter 1 — Krotoszyn"
        case .kozmin: return "Chapter 2 — Koźmin"
        case .jarocin: return "Chapter 3 — Jarocin"
        case .tunnel: return "The Tunnel"
        case .konin: return "Chapter 4 — Konin"
        case .zolkiew: return "Final Destination — Żółkiew"
        }
    }
    
    var actTitle: String {
        switch self {
        case .krotoszyn: return "Chapter 1 — Krotoszyn"
        case .kozmin: return "Chapter 2: Koźmin"
        case .jarocin: return "Chapter 3: Jarocin"
        case .tunnel: return "The Tunnel"
        case .konin: return "Chapter 4: Konin"
        case .zolkiew: return "Final Destination — Żółkiew"
        }
    }
    
    var storyHeader: String {
        switch self {
        case .krotoszyn: return "September 1st, 1939"
        case .kozmin: return "Chapter 2 — Koźmin"
        case .jarocin: return "Chapter 3 — Jarocin"
        case .tunnel: return "The Tunnel"
        case .konin: return "Chapter 4 — Konin"
        case .zolkiew: return "Final Destination — Żółkiew"
        }
    }
    
    var storyParagraphs: [String] {
        switch self {
        case .krotoszyn:
            return [
                "Germany has broken through Poland's western frontier.",
                "Blitzkrieg tactics have shattered the front lines, leaving Polish forces with little choice but to retreat",
                "Across the country, evacuation trains depart toward the south, carrying the last hope of escape",
                "May God protect the souls of those left behind."
            ]
        case .kozmin:
            return [
                "We reached Koźmin, but the skies are turning gray.",
                "Reports say the Luftwaffe is targeting infrastructure. The rails ahead are damaged.",
                "I must watch the tracks closely and switch between lanes to avoid derailment.",
                "The families behind me are counting on this train to keep moving."
            ]
        case .jarocin:
            return [
                "Jarocin is behind us, but the air raid sirens are wailing.",
                "The Luftwaffe is above. They are hunting anything that moves on the tracks.",
                "If we hear the planes diving, I must duck and take cover in the cabin.",
                "The heat of the furnace, the scream of the engines... we are running out of time."
            ]
        case .tunnel:
            return [
                "Ahead lies the dark tunnel.",
                "It is a narrow passage through the hills.",
                "Inside, there will be no light, only the rumble of the engine and the echo of the rails.",
                "We must go through it to reach Konin."
            ]
        case .konin:
            return [
                "The tunnel is behind us...",
                "The air is quiet now.",
                "The clouds have parted, and the sky is filled with a soft, warm light.",
                "No sirens. No bombs. The rails are perfect.",
                "We have made it past the danger. Konin is ahead."
            ]
        case .zolkiew:
            return [
                "We have arrived at Żółkiew.",
                "The station is silent.",
                "The passengers are stepping off the carriages, their faces calm.",
                "The long journey is over."
            ]
        }
    }
    
    var next: Chapter? {
        switch self {
        case .krotoszyn: return .kozmin
        case .kozmin: return .jarocin
        case .jarocin: return .tunnel
        case .tunnel: return .konin
        case .konin: return .zolkiew
        case .zolkiew: return nil
        }
    }
    
    // Gameplay balance variables
    var coalDecayRate: Double {
        switch self {
        case .krotoszyn: return 1.2 // slow decay
        case .kozmin: return 1.8    // normal decay
        case .jarocin: return 2.5   // fast decay
        case .tunnel: return 1.5    // normal
        case .konin, .zolkiew: return 0.0 // no coal decay
        }
    }
    
    var obstacleSpawnInterval: TimeInterval {
        switch self {
        case .krotoszyn: return 9999.0 // none
        case .kozmin: return 6.0      // normal obstacles
        case .jarocin: return 4.0     // frequent obstacles
        case .tunnel: return 9999.0   // none
        case .konin, .zolkiew: return 9999.0 // none
        }
    }
    
    var airRaidSpawnInterval: TimeInterval {
        switch self {
        case .krotoszyn, .kozmin: return 9999.0 // none
        case .jarocin: return 4.5                // air raids
        case .tunnel: return 9999.0             // none
        case .konin, .zolkiew: return 9999.0    // none
        }
    }
    
    var targetDistance: Double {
        switch self {
        case .krotoszyn: return 320.0
        case .kozmin: return 480.0
        case .jarocin: return 1280.0
        case .tunnel: return 360.0
        case .konin: return 500.0
        case .zolkiew: return 0.0 // instant arrival/credits
        }
    }
}
