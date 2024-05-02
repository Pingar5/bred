package status_bar

import "core:strings"
import rl "vendor:raylib"

import "bred:buffer"
import "bred:colors"
import "bred:command"
import "bred:font"
import "bred:math"
import "bred:util"

StatusBar :: struct {
    font:          ^font.Font,
    cb:            ^command.CommandBuffer,
    active_buffer: ^buffer.Buffer,
}

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

render :: proc(sb: ^StatusBar, rect: math.Rect) {
    rl.DrawRectangle(
        i32(rect.left) * sb.font.character_size.x,
        i32(rect.top) * sb.font.character_size.y,
        i32(rect.width) * sb.font.character_size.x,
        i32(rect.height) * sb.font.character_size.y,
        colors.STATUS_BAR_BACKGROUND,
    )

    column: int = 0
    draw_modifier(sb.cb.ctrl, " CTRL ", &column, rect.top, sb.font)
    draw_modifier(sb.cb.shift, " SHIFT ", &column, rect.top, sb.font)
    draw_modifier(sb.cb.alt, " ALT ", &column, rect.top, sb.font)

    column += 1
    if sb.cb.keys_length > 0 {
        for key_idx in 0 ..< sb.cb.keys_length {
            key := sb.cb.keys[key_idx]
            key_str := util.key_to_str(key)
            column = auto_cast font.write(sb.font, {column, rect.top}, key_str, colors.TEXT)
        }
    } else {
        column = auto_cast font.write(sb.font, {column, rect.top}, sb.active_buffer.file_path, rl.GRAY)
    }

}
