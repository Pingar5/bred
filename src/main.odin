package main

import "bred:colors"
import "bred:core"
import "bred:core/buffer"
import "bred:core/command"
import "bred:core/editor"
import "bred:core/font"
import "bred:core/layout"
import "bred:util/logger"
import "bred:util/pool"
import "user:config"

import "core:log"
import "core:mem"
import rl "vendor:raylib"

tracking_allocator: mem.Tracking_Allocator

main :: proc() {
    context.logger = logger.create_logger()

    allocator := context.allocator
    mem.tracking_allocator_init(&tracking_allocator, allocator)
    allocator = mem.tracking_allocator(&tracking_allocator)
    context.allocator = allocator
    defer {
        check_tracking_allocator()
        mem.tracking_allocator_destroy(&tracking_allocator)
    }

    rl.SetTraceLogLevel(.NONE)
    rl.InitWindow(400, 400, "Editor")
    defer rl.CloseWindow()

    rl.SetExitKey(.KEY_NULL)
    rl.SetTargetFPS(144)

    {     // Maximize the Window
        monitor := rl.GetCurrentMonitor()
        monitor_position := rl.GetMonitorPosition(monitor)
        rl.SetWindowPosition(i32(monitor_position.x), i32(monitor_position.y))
        rl.SetWindowState({.WINDOW_MAXIMIZED, .WINDOW_RESIZABLE})
    }

    font.init()
    defer font.quit()

    state := editor.create()
    defer core.destroy(state)

    command.register_command_set(state)

    config.init(state)

    assert(font.ACTIVE_FONT != {}, "User configuration must load a font")
    assert(len(state.portals) > 0, "User configuration must create at least one portal")

    state.portals[0].buffer = auto_cast pool.ResourceId{generation = 1, index = 0}

    for !(rl.WindowShouldClose()) {
        if rl.IsWindowResized() {
            layout.resize_layout(state)
        }

        editor.update(state)

        rl.BeginDrawing()
        rl.ClearBackground(colors.BACKGROUND)

        editor.render(state)

        rl.EndDrawing()

        free_all(context.temp_allocator)
    }

    buffer_id: core.BufferId
    for b in pool.iterate(&state.buffers, auto_cast &buffer_id) {
        buffer.save(b)
    }
}

check_tracking_allocator :: proc() {
    if len(tracking_allocator.allocation_map) > 0 {
        log.errorf("=== %v allocations not freed: ===\n", len(tracking_allocator.allocation_map))
        for _, entry in tracking_allocator.allocation_map {
            log.errorf("- %v bytes @ %v\n", entry.size, entry.location)
        }
    }

    if len(tracking_allocator.bad_free_array) > 0 {
        log.errorf("=== %v incorrect frees: ===\n", len(tracking_allocator.bad_free_array))
        for entry in tracking_allocator.bad_free_array {
            log.errorf("- %p @ %v\n", entry.memory, entry.location)
        }
    }
}
