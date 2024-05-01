package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"

import "ed:buffer"
import "ed:colors"
import "ed:command"
import "ed:font"
import "ed:logger"
import "ed:status"

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
        monitor_size := [2]i32{rl.GetMonitorWidth(monitor), rl.GetMonitorHeight(monitor)}
        monitor_position := rl.GetMonitorPosition(monitor)
        rl.SetWindowPosition(i32(monitor_position.x), i32(monitor_position.y))
        rl.SetWindowState({.WINDOW_MAXIMIZED, .WINDOW_RESIZABLE})
    }

    font.init()
    defer font.quit()

    f := font.load("CodeNewRomanNerdFontMono-Regular.otf")
    defer font.unload(f)

    b, buffer_ok := buffer.load_file("test.txt", f)
    assert(buffer_ok, "Failed to load test file")
    defer buffer.destroy(b)

    command_buffer := command.CommandBuffer{}

    command.init_command_tree()
    defer command.destroy_command_tree()
    {     // Register commands
        command.register({keys = {.LEFT}}, buffer.move_cursor_left)
        command.register({keys = {.RIGHT}}, buffer.move_cursor_right)
        command.register({keys = {.UP}}, buffer.move_cursor_up)
        command.register({keys = {.DOWN}}, buffer.move_cursor_down)
        command.register({keys = {.BACKSPACE}}, buffer.backspace_rune)
        command.register({keys = {.DELETE}}, buffer.delete_rune)
        command.register({ctrl = true, keys = {.D, .D}}, buffer.delete_line)
    }

    for !(rl.WindowShouldClose()) {
        rl.BeginDrawing()

        rl.ClearBackground(colors.BACKGROUND)

        inputs := command.tick(&command_buffer)

        for input in inputs {
            switch c in input {
            case rune:
                buffer.insert_rune(&b, c)
            case command.KeySequence:
                cmd, command_exists := command.get_command(c)
                if !command_exists do continue

                switch cmd_proc in cmd {
                case command.BufferCommand:
                    cmd_proc(&b)
                }
            }
        }

        if rl.GetMouseWheelMove() != 0 {
            b.scroll += rl.GetMouseWheelMove() > 0 ? -1 : 1
            b.scroll = clamp(b.scroll, 0, len(b.lines) - 1)
        }

        buffer.render(b)
        status.render(f, command_buffer, b)

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
