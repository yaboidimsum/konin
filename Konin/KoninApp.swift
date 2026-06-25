//
//  KoninApp.swift
//  Konin
//
//  Created by Dimas Prihady Setyawan on 23/06/26.
//

import SwiftUI
import CoreText

@main
struct KoninApp: App {
    init() {
        registerCustomFont()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func registerCustomFont() {
        guard let url = Bundle.main.url(forResource: "VCR_OSD_MONO", withExtension: "ttf") else {
            print("[Font] VCR_OSD_MONO.ttf not found in main bundle")
            return
        }
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            print("[Font] Failed to register VCR_OSD_MONO: \(error.debugDescription)")
        } else {
            print("[Font] VCR_OSD_MONO registered successfully")
        }
    }
}
