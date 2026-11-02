package game

import (
	"image/color"
	"rlgame/engine"

	rl "github.com/gen2brain/raylib-go/raylib"
)

type background struct {
	margins    rl.Vector2
	rounding   float32
	segments   int32
	color      color.RGBA
}

func (bg *background) Init(host *engine.Entity) {
}

func (bg *background) Update(host *engine.Entity, frameTime float64) {
	rec := rl.NewRectangle(
		bg.margins.X,
		bg.margins.Y,
		float32(rl.GetScreenWidth())-bg.margins.X*2,
		float32(rl.GetScreenHeight())-bg.margins.Y*2,
	)
	
	rl.DrawRectangleRounded(rec, bg.rounding, bg.segments, bg.color)
}

func (bg *background) Deinit(host *engine.Entity) {
}
