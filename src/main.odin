package main

import "bred:buffer"
import "bred:colors"
import "bred:command"
import "bred:font"
import "bred:logger"
import "bred:editor"
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
    defer editor.destroy(state)

    for file_path in ([]string{"test.txt", "test2.txt"}) {
        b, buffer_ok := buffer.load_file(file_path)
        assert(buffer_ok, "Failed to load test file")
        append(&state.buffers, b)
    }

    window_dims := font.calculate_window_dims()

    state.portals[0] = {
        active = true,
        contents = &state.buffers[0],
        rect = {components = {0, 0, window_dims.x / 2, window_dims.y - 1}},
    }

    state.portals[1] = {
        active = true,
        contents = &state.buffers[1],
        rect = {components = {window_dims.x / 2, 0, window_dims.x / 2, window_dims.y - 1}},
    }

    state.portals[2] = {
        active = true,
        contents = &state.status_bar,
        rect = {components = {0, window_dims.y - 1, window_dims.x, 1}},
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
