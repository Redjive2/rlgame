package game

import (
	"rlgame/engine"

	rl "github.com/gen2brain/raylib-go/raylib"
)

var (
	MenuScene = engine.Scene{
		&engine.Entity{
			&background{
				margins: rl.NewVector2(10, 10),
				rounding: .01,
				segments: 24,
				color: rl.NewColor(128, 92, 92, 255),
			},
		},
	}
)
