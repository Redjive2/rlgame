package main

import (
	"rlgame/game"
	"time"

	rl "github.com/gen2brain/raylib-go/raylib"
)

func main() {
	var (
		frameTime  = .0
		frameStart time.Time
	)

	rl.InitWindow(1280, 720, "rlgame")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)
	rl.SetWindowState(rl.FlagWindowResizable)

	game.MenuScene.Load()
	defer game.MenuScene.Unload()

	for !rl.WindowShouldClose() {
		frameStart = time.Now()

		rl.BeginDrawing()

		game.MenuScene.Update(frameTime)

		rl.EndDrawing()

		frameTime = float64(time.Since(frameStart))
	}
}
