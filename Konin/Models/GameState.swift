//
//  GameState.swift
//  Konin
//

import Foundation

enum GameState: Equatable {
    case menu
    case story(Chapter)
    case playing(Chapter)
    case failed(Chapter) // Added for when coal runs out
    case ending
    case credits
}
