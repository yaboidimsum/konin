//
//  Chapter.swift
//  Konin
//

import Foundation

enum Chapter: String, CaseIterable, Codable, Equatable {
    case prolog = "Prolog"
    case krotoszyn = "Krotoszyn"
    case kozmin = "Koźmin"
    case jarocin = "Jarocin"
    case tunnel = "Tunnel"
    case konin = "Konin"
    case zolkiew = "Żółkiew"
    
    var isGhostSegment: Bool {
        switch self {
        case .tunnel, .konin, .zolkiew: return true
        default: return false
        }
    }

    typealias CaptionRange = (min: Double, max: Double, text: String)

    // === UPDATED CAPTION RANGES BASED ON YOUR FIXED STORY FLOW ===
    var captionRanges: [CaptionRange] {
        switch self {
        case .prolog:
            return [
                (0.0, 5.0, "Opening radio on the desk broadcasting that Germany has surrounded Krotoszyn.\nPositioning: low camera angle, with the radio in front of the window and fighter plane silhouettes outside."),
                (5.0, 10.0, "Prologue 2: The Station Master bursts into the crew room, breathing heavily."),
                (10.0, 15.0, "Prologue 3: Slam! The door swings open. The Station Master shouts: \"We must evacuate the passengers immediately! Bring every citizen in this town to flee south!\""),
                (15.0, 20.0, "Prologue 4: MC runs outside into the chaos. Transition scene to the passenger boarding process."),
                (20.0, 25.0, "Prologue 5: \"All ready, Sir!\" the MC calls out to the Station Master. \"Please keep this train and every soul inside safe.\""),
                (25.0, 30.0, "Prologue 6: The train accelerates away from the peron. Moments later, a massive bomb explosion obliterates the station behind them.")
            ]
        case .krotoszyn:
            return [
                (0.0, 6.0, "SM Krotoszyn: \"Welcome, Conductor! Thank heavens you made it. We just received word that the origin station has been completely bombed behind you.\""),
                (6.0, 12.0, "MC: \"Dear God... the destruction happened right as we pulled away. What are our orders now?\""),
                (12.0, 18.0, "SM Krotoszyn: \"I am taking over your journey from here to guide you safely until you reach Koźmin Station. Keep your steam steady and follow my signals!\"")
            ]
        case .kozmin:
            return [
                (0.0, 5.0, "SM Koźmin: \"All clear for departure from Koźmin, Driver. Your train is refueled and ready to head out toward Jarocin.\""),
                (5.0, 10.0, "MC: \"Understood, Station Master. Thank you for the coal. I will maintain maximum speed.\""),
                (10.0, 16.0, "SM Koźmin: \"Safe travels, my friend. Once you get closer, an officer from Jarocin Station will patch into your radio and guide you through their territory.\"")
            ]
        case .jarocin:
            return [
                (0.0, 6.0, "SM Jarocin (Radio): \"Train from the North, welcome to Jarocin airspace. Do not stop at the Jarocin platform! Repeat, do not stop!\""),
                (6.0, 11.0, "MC: \"Station Master? My passengers need a secure perimeter, we were told this was a clearance point!\""),
                (11.0, 17.0, "SM Jarocin (Radio): \"The situation here is completely unstable! Enemy bombers are already circling directly above the clouds. Push through the station immediately!\"")
            ]
        case .tunnel:
            return [] // Limbo tunnel scene. Silence and heartbeat mechanics only.
        case .konin:
            return [
                (0.0, 5.0, "SM Konin (Radio): \"Train from the North, you are moving incredibly fast. Konin has prepared a peaceful resting place for all of you... Why don't you stop?\""),
                (5.0, 10.0, "MC: \"Forgive me, Station Master! I cannot stop in Konin! The carriages are full of terrified passengers from the Jarocin bombing. I must bring them to Żółkiew as quickly as possible!\""),
                (10.0, 15.0, "SM Konin (Radio): \"The bombing in Jarocin... Ah. So you haven't even realized that you are in the exact same carriage as them, Driver? Very well... keep moving until the rails run out.\""),
                (15.0, 20.0, "MC: \"What...? What do you mean by that, Sir? Hello? Station Master?!\"")
            ]
        case .zolkiew:
            return [
                (0.0, 5.0, "MC: \"Sir... We have finally reached the final destination. Please help my passengers in the back, they must be exhausted...\""),
                (5.0, 10.0, "SM Żółkiew: \"There are no exhausted passengers here, young man. Your train is entirely empty.\""),
                (10.0, 15.0, "MC: \"Empty? That's impossible! I locked the carriage doors myself! I... I can still hear the echoes of their voices!\""),
                (15.0, 20.0, "SM Żółkiew: \"Take a look at your cabin window. Look at your own reflection.\""),
                (20.0, 25.0, "MC: \"Wait... My chest... is torn open? Since when has my uniform been drenched in blood...? Why didn't I feel any of this until now...?\""),
                (25.0, 30.0, "SM Żółkiew: \"Because your soul refused to die in Jarocin, Driver. The bomb claimed your life and your passengers' lives in an instant. Yet, your determination was so fierce, your spirit kept driving this train right through the boundary of death.\""),
                (30.0, 35.0, "MC: \"So... I am also... dead along with them... ever since Jarocin...?\""),
                (35.0, 40.0, "SM Żółkiew: \"Yes. But you did not fail. You brought them all safely to a place of peace. Your duty is honorably fulfilled, Driver. Now, shut down the engine and rest among them.\"")
            ]
        }
    }
    
    var title: String {
        switch self {
        case .prolog: return "Prologue"
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
        case .prolog: return "Prologue"
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
        case .prolog: return "Prologue"
        case .krotoszyn: return "September 1st, 1939"
        case .kozmin: return "Chapter 2 — Koźmin"
        case .jarocin: return "Chapter 3 — Jarocin"
        case .tunnel: return "The Tunnel"
        case .konin: return "Chapter 4 — Konin"
        case .zolkiew: return "Final Destination — Żółkiew"
        }
    }
    
    // === BLACK INTERMISSION SCREEN TRANSITION TEXTS ===
    var storyParagraphs: [String] {
        switch self {
        case .prolog: return [
            "Before the rails carried us south, there was only the sound of distant thunder.",
            "John Patrekov had spent his life driving trains through quiet Polish towns, believing the tracks would always lead home.",
            "Then the war reached the horizon, and every station became a place of farewell.",
            "This is where his journey begins."
        ]
        case .krotoszyn:
            return [
                "It started with faint, distorted news on the border radio. We thought the smoke on the western horizon was normal.",
                "Until suddenly, the skies above Krotoszyn turned a violent, burning red.",
                "Today, my schedule is no longer about commuting daily workers...",
                "It is a desperate sprint to outrun death itself."
            ]
        case .kozmin:
            return [
                "Krotoszyn has collapsed into mere ashes behind us.",
                "This train feels far heavier now. Not because of the weight of the coal in the furnace...",
                "But due to the hundreds of silent, weeping eyes staring out from the back carriages.",
                "Koźmin lies ahead... hopefully, this town will grant them a momentary room to breathe."
            ]
        case .jarocin:
            return [
                "Leaving the false tranquility of Koźmin behind, Jarocin stands as our next stop.",
                "For some reason, an ominous dread settles deep within my chest tonight.",
                "The night air feels entirely too cold... and far too quiet.",
                "The scream of the engines echoes... we are running out of time."
            ]
        case .tunnel:
            return [
                "The explosion back at Jarocin was deafening. My head rings violently and everything has abruptly plunged into pitch black.",
                "Yet, it feels strange... I no longer feel any pain, the roar of the engine is gone, and the passengers are completely quiet.",
                "There is only the endless silence of this long tunnel.",
                "I must remain focused. I must keep the locomotive furnace burning at all costs."
            ]
        case .konin:
            return [
                "This dark tunnel felt impossibly long, until a blinding, radiant light finally welcomed us into Konin.",
                "This town is clean... entirely too pristine for a war zone.",
                "No black smoke, no artillery craters, no soldiers.",
                "It almost feels like... a beautiful dream."
            ]
        case .zolkiew:
            return [
                "The tracks have reached their absolute end here in Żółkiew.",
                "How strange... my hands feel completely weightless as I pull the brakes, as if I am no longer touching iron.",
                "But that doesn't matter anymore...",
                "What matters is that we have all made it to the end safely."
            ]
        }
    }
    
    var next: Chapter? {
        switch self {
        case .prolog: return .krotoszyn
        case .krotoszyn: return .kozmin
        case .kozmin: return .jarocin
        case .jarocin: return .tunnel
        case .tunnel: return .konin
        case .konin: return .zolkiew
        case .zolkiew: return nil
        }
    }
    
    var coalDecayRate: Double {
        switch self {
        case .prolog, .konin, .zolkiew: return 0.0
        case .krotoszyn: return 1.2
        case .kozmin: return 1.8
        case .jarocin: return 2.5
        case .tunnel: return 1.5
        }
    }
    
    var obstacleSpawnInterval: TimeInterval {
        switch self {
        case .prolog, .krotoszyn, .tunnel, .konin, .zolkiew: return 9999.0
        case .kozmin: return 6.0
        case .jarocin: return 4.0
        }
    }
    
    var airRaidSpawnInterval: TimeInterval {
        switch self {
        case .prolog, .krotoszyn, .kozmin, .tunnel, .konin, .zolkiew: return 9999.0
        case .jarocin: return 4.5
        }
    }
    
    var targetDistance: Double {
        switch self {
        case .prolog: return 0.0
        case .krotoszyn: return 320.0
        case .kozmin: return 480.0
        case .jarocin: return 1280.0
        case .tunnel: return 360.0
        case .konin: return 500.0
        case .zolkiew: return 0.0
        }
    }
}
