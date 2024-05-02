package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"

import "bred:buffer"
import "bred:colors"
import "bred:command"
import "bred:font"
import "bred:logger"
import "bred:portal"
import "bred:status"

import rl "vendor:raylib"

tracking_allocator: mem.Tracking_Allocator

portals: [8]portal.Portal

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
        monitor_size := [2]i32{rl.GetMonitorWidth(monitor), rl.GetMonitorHeight(monitor)}
        monitor_position := rl.GetMonitorPosition(monitor)
        rl.SetWindowPosition(i32(monitor_position.x), i32(monitor_position.y))
        rl.SetWindowState({.WINDOW_MAXIMIZED, .WINDOW_RESIZABLE})
    }

    font.init()
    defer font.quit()

    font.load("CodeNewRomanNerdFontMono-Regular.otf")

    b, buffer_ok := buffer.load_file("test.txt")
    assert(buffer_ok, "Failed to load test file")
    defer buffer.destroy(b)

    b2, buffer2_ok := buffer.load_file("test2.txt")
    assert(buffer2_ok, "Failed to load test file")
    defer buffer.destroy(b2)

    command_buffer := command.CommandBuffer{}

    status_bar := status.StatusBar {
        cb            = &command_buffer,
        active_buffer = &b,
    }

    window_dims := font.calculate_window_dims()

    portals[0] = {
        active = true,
        contents = &b,
        rect = {components = {0, 0, window_dims.x / 2, window_dims.y - 1}},
    }

    portals[1] = {
        active = true,
        contents = &b2,
        rect = {components = {window_dims.x / 2, 0, window_dims.x / 2, window_dims.y - 1}},
    }

    portals[2] = {
        active = true,
        contents = &status_bar,
        rect = {components = {0, window_dims.y - 1, window_dims.x, 1}},
    }

    command.init_command_tree()
    defer command.destroy_command_tree()
    register_keybinds()

    for !(rl.WindowShouldClose()) {
        rl.BeginDrawing()

        rl.ClearBackground(colors.BACKGROUND)

        inputs := command.tick(&command_buffer)

        for input in inputs {
            switch c in input {
            case byte:
                buffer.insert_character(&b, c)
            case command.KeySequence:
                cmd, command_exists := command.get_command(c)
                if !command_exists do continue

                switch cmd_proc in cmd {
                case command.BufferCommand:
                    cmd_proc(&b)
                case command.CommandBufferCommand:
                    cmd_proc(&command_buffer)
                }
            }
        }

        if rl.GetMouseWheelMove() != 0 {
            b.scroll += rl.GetMouseWheelMove() > 0 ? -1 : 1
            b.scroll = clamp(b.scroll, 0, len(b.lines) - 1)
        }

        for &p in portals {
            if p.active {
                portal.render(&p)
            }
        }

        rl.EndDrawing()

        free_all(context.temp_allocator)
    }

    buffer.save(b)
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
