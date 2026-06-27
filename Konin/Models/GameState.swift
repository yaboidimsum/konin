//
//  GameState.swift
//  Konin
//

import Foundation

enum GameState: Equatable {
    case menu
    case loading
    case cutscene(Chapter)   // NEW — cinematic scene before a chapter's story screen
    case story(Chapter)
    case playing(Chapter)
    case failed(Chapter)
    case ending
    case credits
}
