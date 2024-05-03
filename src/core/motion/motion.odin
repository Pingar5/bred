package motion

import "core:log"
import "core:slice"
import rl "vendor:raylib"

import "bred:core"
import "bred:core/command"

@(private) CommandBuffer :: core.CommandBuffer
@(private) Motion :: core.Motion
@(private) ModifierState :: core.ModifierState
@(private) Modifiers :: core.Modifiers

MOD_HOLD_MINIMUM :: 0.15
COMMAND_TIMEOUT :: 0.5

SKIP_KEYS :: []rl.KeyboardKey {
    .RIGHT_CONTROL,
    .LEFT_CONTROL,
    .RIGHT_ALT,
    .LEFT_ALT,
    .RIGHT_SHIFT,
    .LEFT_SHIFT,
}

tick :: proc(cb: ^CommandBuffer) -> []Motion {
    update_modifier(&cb.ctrl, .LEFT_CONTROL, .RIGHT_CONTROL)
    update_modifier(&cb.alt, .LEFT_ALT, .RIGHT_ALT)
    update_modifier(&cb.shift, .LEFT_SHIFT, .RIGHT_SHIFT)

    inputs := make([dynamic]Motion, context.temp_allocator)

    cb.timer += rl.GetFrameTime()

    for {
        key := rl.GetKeyPressed()
        if key == .KEY_NULL do break
        if slice.contains(SKIP_KEYS, key) do continue

        r := rl.GetCharPressed()
        if r > rune(255) do log.errorf("Cannot type %v. Bred is ASCII only within buffers", r)
        // BUG: If two buttons are pressed on one frame and the first is not a character key
        //      then this will map incorrectly
        char := byte(r)

        cb.timer = 0
        cb.keys[cb.keys_length] = key
        cb.chars[cb.keys_length] = char
        cb.keys_length += 1
    }

    if cb.keys_length > 0 {
        modifiers: Modifiers
        if cb.ctrl.enabled || cb.ctrl.held do modifiers += {.Ctrl}
        if cb.shift.enabled || cb.shift.held do modifiers += {.Shift}
        if cb.alt.enabled || cb.alt.held do modifiers += {.Alt}

        keys := Motion{modifiers, cb.keys[:cb.keys_length], cb.chars[:cb.keys_length]}

        if (command.is_leaf_or_invalid(keys) ||
               cb.timer > COMMAND_TIMEOUT ||
               cb.keys_length == len(cb.keys)) {
            append(&inputs, keys)
            cb.keys_length = 0

            cb.ctrl.enabled = cb.ctrl.locked
            cb.alt.enabled = cb.alt.locked
            cb.shift.enabled = cb.shift.locked
        }
    }

    return inputs[:]
}

clear_modifiers :: proc(cb: ^CommandBuffer) {
    cb.ctrl.enabled = false
    cb.ctrl.locked = false

    cb.shift.enabled = false
    cb.shift.locked = false

    cb.alt.enabled = false
    cb.alt.locked = false
}

@(private)
update_modifier :: proc(mod: ^ModifierState, left, right: rl.KeyboardKey) {
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
