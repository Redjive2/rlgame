package engine

import (
	"reflect"
	"unsafe"

	rl "github.com/gen2brain/raylib-go/raylib"
)

type (
	Entity []Component

	Component interface {
		Init(*Entity)
		Update(*Entity, float64)
		Deinit(*Entity)
	}

	Scene []*Entity
)

func (entity *Entity) Id() uintptr {
	return uintptr(unsafe.Pointer(entity))
}

func (entity *Entity) Query[Q Component]() []Component {
	var (
		query []Component
		queryType = reflect.TypeFor[Q]()
	)
	
	for _, component := range *entity {
		if reflect.TypeOf(component) == queryType {
			query = append(query, component)
		}
	}

	return query
}

func (scene *Scene) Load() {
	rl.ClearBackground(rl.RayWhite)

	for _, entity := range *scene {
		for _, component := range *entity {
			component.Init(entity)
		}
	}
}

func (scene *Scene) Update(frameTime float64) {
	for _, entity := range *scene {
		for _, component := range *entity {
			component.Update(entity, frameTime)
		}
	}

	rl.ClearBackground(rl.RayWhite)
}

func (scene *Scene) Unload() {
	for _, entity := range *scene {
		for _, component := range *entity {
			component.Deinit(entity)
		}
	}

	rl.ClearBackground(rl.RayWhite)
}
