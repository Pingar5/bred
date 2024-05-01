package command

import "core:log"
import "core:slice"
import rl "vendor:raylib"

MOD_HOLD_MINIMUM :: 0.15
COMMAND_TIMEOUT :: 0.2

Modifier :: struct {
    enabled, locked: bool,
    held:            bool,
    held_for:        f32,
}

KeySequence :: struct {
    ctrl, shift, alt: bool,
    keys:             []rl.KeyboardKey,
}

CommandBuffer :: struct {
    ctrl, shift, alt: Modifier,
    keys_length:      uint,
    keys:             [8]rl.KeyboardKey,
    timer:            f32,
}

Input :: union {
    byte,
    KeySequence,
}

tick :: proc(cb: ^CommandBuffer) -> []Input {
    update_modifier(&cb.ctrl, .LEFT_CONTROL, .RIGHT_CONTROL)
    update_modifier(&cb.alt, .LEFT_ALT, .RIGHT_ALT)
    update_modifier(&cb.shift, .LEFT_SHIFT, .RIGHT_SHIFT)

    inputs := make([dynamic]Input, context.temp_allocator)

    if cb.ctrl.enabled || cb.ctrl.held {
        poll_control_mode(cb, &inputs)
    } else {
        poll_normal_mode(cb, &inputs)
    }

    return inputs[:]
}

@(private)
poll_normal_mode :: proc(cb: ^CommandBuffer, inputs: ^[dynamic]Input) {
    for {
        key := rl.GetKeyPressed()
        if key == .KEY_NULL do break

        char := rl.GetCharPressed()

        if char != rune(0) {
            append(inputs, byte(char))
        } else {
            key_list := make([]rl.KeyboardKey, 1, context.temp_allocator)
            key_list[0] = key

            append(
                inputs,
                KeySequence {
                    ctrl = false,
                    shift = cb.shift.enabled || cb.shift.held,
                    alt = cb.alt.enabled || cb.alt.held,
                    keys = key_list,
                },
            )
        }
    }
}

SKIP_KEYS :: []rl.KeyboardKey {
    .RIGHT_CONTROL,
    .LEFT_CONTROL,
    .RIGHT_ALT,
    .LEFT_ALT,
    .RIGHT_SHIFT,
    .LEFT_SHIFT,
}
@(private)
poll_control_mode :: proc(cb: ^CommandBuffer, inputs: ^[dynamic]Input) {
    cb.timer += rl.GetFrameTime()

    for {
        key := rl.GetKeyPressed()
        if key == .KEY_NULL do break
        if slice.contains(SKIP_KEYS, key) do continue

        cb.timer = 0
        cb.keys[cb.keys_length] = key
        cb.keys_length += 1
    }

    if cb.keys_length > 0 {
        keys := KeySequence {
            ctrl  = cb.ctrl.enabled || cb.ctrl.held,
            shift = cb.shift.enabled || cb.shift.held,
            alt   = cb.alt.enabled || cb.alt.held,
            keys  = cb.keys[:cb.keys_length],
        }

        if (is_leaf_or_invalid(keys) ||
               cb.timer > COMMAND_TIMEOUT ||
               cb.keys_length == len(cb.keys)) {
            append(inputs, keys)
            cb.keys_length = 0

            cb.ctrl.enabled = cb.ctrl.locked
            cb.alt.enabled = cb.alt.locked
            cb.shift.enabled = cb.shift.locked
        }
    }
}

@(private)
update_modifier :: proc(mod: ^Modifier, left, right: rl.KeyboardKey) {
    if rl.IsKeyPressed(left) || rl.IsKeyPressed(right) do mod.held_for = 0

    mod.held = rl.IsKeyDown(left) || rl.IsKeyDown(right)
    if mod.held do mod.held_for += rl.GetFrameTime()

    if rl.IsKeyReleased(left) || rl.IsKeyReleased(right) {
        if mod.held_for < MOD_HOLD_MINIMUM {
            if !mod.enabled do mod.enabled = true
            else {
                if !mod.locked do mod.locked = true
                else {
                    mod.enabled = false
                    mod.locked = false
                }
            }
        } else {
            mod.enabled = false
            mod.locked = false
        }
    }
}
