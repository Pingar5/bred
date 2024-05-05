package motion

import "core:log"
import "core:slice"
import rl "vendor:raylib"

import "bred:core"
import "bred:core/command"

@(private) MotionBuffer :: core.MotionBuffer
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

tick :: proc(mb: ^MotionBuffer) -> []Motion {
    update_modifier(&mb.ctrl, .LEFT_CONTROL, .RIGHT_CONTROL)
    update_modifier(&mb.alt, .LEFT_ALT, .RIGHT_ALT)
    update_modifier(&mb.shift, .LEFT_SHIFT, .RIGHT_SHIFT)

    inputs := make([dynamic]Motion, context.temp_allocator)

    mb.timer += rl.GetFrameTime()

    for {
        key := rl.GetKeyPressed()
        if key == .KEY_NULL do break
        if slice.contains(SKIP_KEYS, key) do continue

        r := rl.GetCharPressed()
        if r > rune(255) do log.errorf("Cannot type %v. Bred is ASCII only within buffers", r)
        // BUG: If two buttons are pressed on one frame and the first is not a character key
        //      then this will map incorrectly
        char := byte(r)

        mb.timer = 0
        mb.keys[mb.keys_length] = key
        mb.chars[mb.keys_length] = char
        mb.keys_length += 1
    }

    if mb.keys_length > 0 {
        modifiers: Modifiers
        if mb.ctrl.enabled || mb.ctrl.held do modifiers += {.Ctrl}
        if mb.shift.enabled || mb.shift.held do modifiers += {.Shift}
        if mb.alt.enabled || mb.alt.held do modifiers += {.Alt}

        keys := Motion{modifiers, mb.keys[:mb.keys_length], mb.chars[:mb.keys_length]}

        if (command.is_leaf_or_invalid(keys) ||
               mb.timer > COMMAND_TIMEOUT ||
               mb.keys_length == len(mb.keys)) {
            append(&inputs, keys)
            mb.keys_length = 0

            mb.ctrl.enabled = mb.ctrl.locked
            mb.alt.enabled = mb.alt.locked
            mb.shift.enabled = mb.shift.locked
        }
    }

    return inputs[:]
}

clear_modifiers :: proc(mb: ^MotionBuffer) {
    mb.ctrl.enabled = false
    mb.ctrl.locked = false

    mb.shift.enabled = false
    mb.shift.locked = false

    mb.alt.enabled = false
    mb.alt.locked = false
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
