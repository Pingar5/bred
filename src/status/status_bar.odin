package status_bar

import "core:strings"
import "ed:buffer"
import "ed:colors"
import "ed:command"
import "ed:util"
import "ed:font"
import rl "vendor:raylib"

@(private)
draw_modifier :: proc(
    mod: command.Modifier,
    mod_str: string,
    column: ^i32,
    line: i32,
    f: ^font.Font,
) {
    fg: rl.Color = rl.GRAY
    if mod.enabled || mod.held {
        bg := mod.locked ? colors.MODIFIER_LOCKED : colors.MODIFIER_ACTIVE
        fg = colors.TEXT
        rl.DrawRectangle(
            column^ * f.character_size.x,
            line * f.character_size.y,
            f.character_size.x * i32(len(mod_str)),
            f.character_size.y,
            bg,
        )
    }

    column^ = auto_cast font.write(f, line, column^, mod_str, fg)
}

render :: proc(f: ^font.Font, cb: command.CommandBuffer, active_buffer: buffer.Buffer) {
    top := (rl.GetScreenHeight() / f.character_size.y) - 1

    rl.DrawRectangle(
        0,
        top * f.character_size.y,
        rl.GetScreenWidth(),
        f.character_size.y,
        colors.STATUS_BAR_BACKGROUND,
    )

    column: i32 = 0
    draw_modifier(cb.ctrl, " CTRL ", &column, top, f)
    draw_modifier(cb.shift, " SHIFT ", &column, top, f)
    draw_modifier(cb.alt, " ALT ", &column, top, f)

    column += 1
    if cb.keys_length > 0 {
        for key_idx in 0 ..< cb.keys_length {
            key := cb.keys[key_idx]
            key_str := util.key_to_str(key)
            column = auto_cast font.write(f, top, column, key_str, colors.TEXT)
        }
    } else {
        column = auto_cast font.write(f, top, column, active_buffer.file_path, rl.GRAY)
    }

}
