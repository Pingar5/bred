package status_bar

import "core:strings"
import rl "vendor:raylib"

import "bred:buffer"
import "bred:colors"
import "bred:command"
import "bred:font"
import "bred:math"
import "bred:util"

@(private)
draw_modifier :: proc(
    mod: command.Modifier,
    mod_str: string,
    column: ^int,
    line: int,
    f: ^font.Font,
) {
    fg: rl.Color = rl.GRAY
    if mod.enabled || mod.held {
        bg := mod.locked ? colors.MODIFIER_LOCKED : colors.MODIFIER_ACTIVE
        fg = colors.TEXT
        rl.DrawRectangle(
            i32(column^) * f.character_size.x,
            i32(line) * f.character_size.y,
            f.character_size.x * i32(len(mod_str)),
            f.character_size.y,
            bg,
        )
    }

    column^ = font.write(f, {column^, line}, mod_str, fg)
}

render :: proc(
    f: ^font.Font,
    cb: command.CommandBuffer,
    active_buffer: buffer.Buffer,
    rect: math.Rect,
) {
    rl.DrawRectangle(
        i32(rect.left) * f.character_size.x,
        i32(rect.top) * f.character_size.y,
        i32(rect.width) * f.character_size.x,
        i32(rect.height) * f.character_size.y,
        colors.STATUS_BAR_BACKGROUND,
    )

    column: int = 0
    draw_modifier(cb.ctrl, " CTRL ", &column, rect.top, f)
    draw_modifier(cb.shift, " SHIFT ", &column, rect.top, f)
    draw_modifier(cb.alt, " ALT ", &column, rect.top, f)

    column += 1
    if cb.keys_length > 0 {
        for key_idx in 0 ..< cb.keys_length {
            key := cb.keys[key_idx]
            key_str := util.key_to_str(key)
            column = auto_cast font.write(f, {column, rect.top}, key_str, colors.TEXT)
        }
    } else {
        column = auto_cast font.write(f, {column, rect.top}, active_buffer.file_path, rl.GRAY)
    }

}
