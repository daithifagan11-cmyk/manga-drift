# Project: MangaDrift (Godot 4.x Forward+)

## Core Game Design
- **Genre:** 3D Arcade Touge Drift Score-Attack Game.
- **Visual Style:** Japanese Manga / Initial D aesthetic. High-contrast black-and-white/screentone cel-shading with thick inverted-hull black ink outlines, 2D fullscreen manga speed lines during high-speed drifts, and floating Katakana/Romaji onomatopoeia popups ("ゴゴゴ / GOGOGO", "ギャアア / SCREECH!") spawned in 3D space near the rear tires.
- **Camera:** 3D Chase Camera (`SpringArm3D` + `Camera3D`) behind the car. Dynamic FOV kick based on speed, subtle camera roll/tilt into corners, and smooth horizontal lag so the player sees the side profile of the car when drifting at wide angles.
- **Gameplay Mode:** Score-Based Drift Attack.
  - Score increases while drifting based on: `Drift Angle (degrees) * Car Speed * Combo Multiplier`.
  - Chaining left-to-right transition drifts within 2.5 seconds increments the Combo Multiplier (`1x` up to `10x`).
  - Hitting walls resets the current unbanked drift combo to zero.
  - Includes a 120-second stage timer and a Manga-styled HUD displaying live Drift Points, Multiplier, Angle bar, and Total Banked Score.

## Technical Rules for MCP Agent
1. Always use Godot MCP tools to inspect the scene tree before modifying nodes.
2. Build the car using `VehicleBody3D` and four `VehicleWheel3D` nodes. Implement arcade drift physics in `res://scripts/drift_car.gd` by dynamically lowering rear `wheel_friction_slip` when handbraking (`ui_select`) or counter-steering at speed, while applying an angular torque assist to hold slides smoothly.
3. Keep shaders in `res://shaders/` (`manga_ink.gdshader` for 3D cel-shading + halftone screentones, and `speed_lines.gdshader` for the `CanvasLayer` UI overlay).
4. After creating or modifying any scene or script, run the project via MCP, inspect debug logs for errors, and fix any issues automatically.