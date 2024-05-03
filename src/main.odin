package main

import "bred:builtin/components"
import "bred:colors"
import "bred:core"
import "bred:core/buffer"
import "bred:core/command"
import "bred:core/editor"
import "bred:core/font"
import "bred:core/portal"
import "bred:util/logger"
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

    font.load("CodeNewRomanNerdFontMono-Regular.otf")

    state := editor.create()
    defer core.destroy(state)

    window_dims := font.calculate_window_dims()

    state.portals[0] = portal.create_file_portal(
        {components = {0, 0, window_dims.x / 2, window_dims.y - 1}},
    )
    state.portals[1] = portal.create_file_portal(
        {components = {window_dims.x / 2, 0, window_dims.x / 2, window_dims.y - 1}},
    )
    state.portals[2] = components.create_status_bar(
        {components = {0, window_dims.y - 1, window_dims.x, 1}},
    )

    for file_path, index in ([]string{"test.txt", "test2.txt"}) {
        b, buffer_ok := buffer.load_file(file_path)
        assert(buffer_ok, "Failed to load test file")
        append(&state.buffers, b)
        state.portals[index].buffer = &state.buffers[len(state.buffers) - 1]
    }

    command.init_command_tree()
    defer command.destroy_command_tree()

    config.init()

    for !(rl.WindowShouldClose()) {
        editor.update(state)

        rl.BeginDrawing()
        rl.ClearBackground(colors.BACKGROUND)

        editor.render(state)

        rl.EndDrawing()

        free_all(context.temp_allocator)
    }

    for b in state.buffers {
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
