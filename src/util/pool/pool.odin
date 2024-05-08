package pool

import "core:log"
import "core:slice"

ResourceId :: bit_field u16 {
    generation: u8 | 8,
    index:      u8 | 8,
}

@(private)
Slot :: struct($T: typeid) {
    generation: u8,
    value:      T,
}

ResourcePool :: struct($T: typeid) {
    free_indices: [dynamic]u8,
    resources:    [dynamic]Slot(T),
}

init :: proc(pool: ^ResourcePool($T), allocator := context.allocator) {
    pool.free_indices = make([dynamic]u8, allocator)
    pool.resources = make([dynamic]Slot(T), allocator)
    return
}

destroy :: proc(pool: ^ResourcePool($T)) {
    delete(pool.free_indices)
    delete(pool.resources)
}

add :: proc(pool: ^ResourcePool($T), val: T) -> (id: ResourceId) {
    slot: ^Slot(T)
    if len(pool.free_indices) > 0 {
        id.index = pop(&pool.free_indices)
        slot = &pool.resources[id.index]
    } else {
        id.index = auto_cast len(pool.resources)
        resize(&pool.resources, len(pool.resources) + 1)
        slot = &pool.resources[id.index]
        slot.generation += 1
    }

    id.generation = slot.generation
    slot.value = val

    return id
}

get :: proc(pool: ^ResourcePool($T), id: ResourceId) -> (val: ^T, ok: bool) {
    if int(id.index) >= len(pool.resources) do return nil, false
    
    slot := &pool.resources[id.index]

    if slot.generation == id.generation {
        return &slot.value, true
    } else {
        return nil, false
    }
}

remove :: proc(pool: ^ResourcePool($T), id: ResourceId) -> (ok: bool) {
    if int(id.index) >= len(pool.resources) do return false
    
    slot := &pool.resources[id.index]

    if slot.generation > id.generation do return false

    slot.generation += 1
    append(&pool.free_indices, id.index)

    return true
}

iterate :: proc(pool: ^ResourcePool($T), id: ^ResourceId) -> (^T, bool) {
    if id.generation != 0 do id.index += 1

    for slice.contains(pool.free_indices[:], id.index) && int(id.index) < len(pool.resources) {
        id.index += 1
    }

    if int(id.index) >= len(pool.resources) {
        return nil, false
    }

    slot := &pool.resources[id.index]
    id.generation = slot.generation
    return &slot.value, true
}
