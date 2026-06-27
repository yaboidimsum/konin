//
//  Projects.md
//  Konin
//
//  Created by Dimas Prihady Setyawan on 23/06/26.
//


# PROJECTS.md

# Last Train East

## Project Overview

Last Train East is a narrative arcade game set during the German invasion of Poland in 1939.

Players take the role of John, a railway operator responsible for escorting evacuation trains carrying civilian families away from the advancing western frontline.

The journey begins in Krotoszyn and proceeds eastward through Koźmin, Jarocin, and Konin before reaching Żółkiew.

The game combines resource management, obstacle avoidance, and narrative storytelling through a minimalist first-person train simulation.

---

# Vision

Create a short but memorable historical experience that can be completed in approximately 10–15 minutes.

The gameplay should remain simple while gradually building tension before delivering a narrative twist during the Konin chapter.

Players should feel responsible for keeping the evacuation train moving while remaining unaware of the story's final revelation until the ending.

---

# Platform

## Primary Target

macOS

## Technology Stack

* Swift
* SwiftUI
* SpriteKit

## Input Methods

| Action           | Input           |
| ---------------- | --------------- |
| Move Left Track  | A / Left Arrow  |
| Move Right Track | D / Right Arrow |
| Add Coal         | Space           |
| Duck             | S / Down Arrow  |

---

# Core Gameplay Loop

1. Maintain coal reserves.
2. Avoid damaged railways.
3. Survive Luftwaffe attacks.
4. Reach the next station.
5. Progress toward Żółkiew.

---

# Core Systems

## Coal System

### Purpose

Acts as the primary resource.

### Behavior

* Coal decreases over time.
* Players replenish coal using the furnace.
* Running out of coal results in failure.

### Player Interaction

Space Key

---

## Track Switching

### Purpose

Avoid German land mines.

### Behavior

* German land mines appear on either lane.
* Player must switch tracks before impact.

### Failure Result

* Significant coal loss.
* Screen shake.
* Audio feedback.

---

## Air Raid System

### Purpose

Introduce reaction-based gameplay.

### Behavior

* Air raid warning appears.
* Player must duck before the attack.

### Success

* No penalty.

### Failure

* Coal loss.
* Visual explosion effects.
* Strong screen shake.

---

# Narrative Structure

## Chapter 1 — Krotoszyn

### Gameplay

Tutorial

### Introduces

* Train movement
* Coal system

### Tone

Hopeful

---

## Chapter 2 — Koźmin

### Gameplay

German land mine hazards introduced.

### Tone

Growing tension

---

## Chapter 3 — Jarocin

### Gameplay

* German land mines
* Luftwaffe attacks

### Tone

Dangerous
Chaotic
Uncertain

---

## Tunnel Sequence

### Purpose

Narrative transition

### Events

* Train enters tunnel.
* Visibility reduced.
* Audio becomes muffled.

At the tunnel exit:

* Air raid siren activates.
* Explosion occurs.
* Screen flashes white.

The game immediately continues.

No explanation is provided.

---

## Chapter 4 — Konin

### Narrative Purpose

The player has already died.

This information is hidden.

### Gameplay

No hazards.

No air raids.

No land mines.

No coal pressure.

### Atmosphere

* Bright skies
* Soft lighting
* Peaceful music
* Calm environment

Players should feel that they have finally escaped the danger.

---

## Final Destination — Żółkiew

The train reaches its destination peacefully.

Passengers depart.

The world remains silent.

---

## Ending Reveal

Display the following text:

"The train never reached Konin."

"Destroyed during an air raid in September 1939."

"The families, crew, and passengers never arrived at their destination."

"Yet some journeys continue beyond the rails."

Fade to white.

Credits.

---

# Visual Direction

## Gameplay

Pseudo-3D first-person railway perspective.

### Techniques

* Converging rails
* Scaling sprites
* Perspective illusion
* Moving horizon

### References

* Mode 7 racing games
* Endless runners
* Early train simulators

---

## Konin

### Visual Changes

* Increased brightness
* Reduced contrast
* Warm colors
* Floating particles
* Soft fog

### Purpose

Create a dreamlike atmosphere without explicitly revealing the twist.

---

# Audio Direction

## Krotoszyn

* Calm train ambience
* Hopeful music

## Koźmin

* Mechanical tension
* Distant war sounds

## Jarocin

* Sirens
* Aircraft engines
* Explosions

## Tunnel

* Muffled sounds
* Echo effects

## Konin

* Gentle ambience
* Minimal instrumentation
* Peaceful atmosphere

---

# Architecture

## SwiftUI Responsibilities

* Main Menu
* Story Screens
* Credits
* Ending Sequence
* Game State Navigation

## SpriteKit Responsibilities

* Gameplay
* Train Systems
* Hazards
* Visual Effects
* Camera Effects

---

# Project Structure

```text
LastTrainEast/

├── App/
│   └── LastTrainEastApp.swift
│
├── Views/
│   ├── MainMenuView.swift
│   ├── GameView.swift
│   ├── StoryView.swift
│   └── EndingView.swift
│
├── SpriteKit/
│   ├── GameScene.swift
│   ├── TrainController.swift
│   ├── CoalSystem.swift
│   ├── HazardManager.swift
│   ├── AirRaidController.swift
│   ├── StageManager.swift
│   └── CameraController.swift
│
├── Models/
│   ├── Chapter.swift
│   └── GameState.swift
│
├── Assets/
│
└── Audio/
```

---

# MVP Scope

## Must Have

* First-person railway view
* Coal system
* German land mines
* Air raid mechanic
* Station progression
* Tunnel sequence
* Konin chapter
* Ending reveal

## Nice To Have

* Voice-over narration
* Historical photographs
* Particle enhancements
* Additional sound effects

---

# One Week Development Plan

## Day 1

* Project setup
* First-person railway prototype
* Basic movement

## Day 2

* Coal system
* Furnace interaction

## Day 3

* German land mine hazards
* Lane switching

## Day 4

* Air raid system
* Duck mechanic

## Day 5

* Station progression
* Tunnel sequence

## Day 6

* Konin implementation
* Ending reveal

## Day 7

* Polish
* Audio
* Bug fixes
* Submission build

```
```
