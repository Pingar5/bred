package status_bar

import rl "vendor:raylib"

import "bred:buffer"
import "bred:colors"
import "bred:command"
import "bred:font"
import "bred:math"
import "bred:util"

StatusBar :: struct {
    cb:            ^command.CommandBuffer,
    active_buffer: ^buffer.Buffer,
}

@(private)
draw_modifier :: proc(
    mod: command.ModifierState,
    mod_str: string,
    column: ^int,
    line: int,
) {
    fg: rl.Color = rl.GRAY
    if mod.enabled || mod.held {
        bg := mod.locked ? colors.MODIFIER_LOCKED : colors.MODIFIER_ACTIVE
        fg = colors.TEXT
        font.draw_bg_rect({components = {column^, line, len(mod_str), 1}}, bg)
    }

    column^ = font.write({column^, line}, mod_str, fg)
}

render :: proc(sb: ^StatusBar, rect: math.Rect) {
    font.draw_bg_rect(rect, colors.STATUS_BAR_BACKGROUND)

    column: int = 0
    draw_modifier(sb.cb.ctrl, " CTRL ", &column, rect.top)
    draw_modifier(sb.cb.shift, " SHIFT ", &column, rect.top)
    draw_modifier(sb.cb.alt, " ALT ", &column, rect.top)

    column += 1
    if sb.cb.keys_length > 0 {
        for key_idx in 0 ..< sb.cb.keys_length {
            key := sb.cb.keys[key_idx]
            key_str := util.key_to_str(key)
            column = auto_cast font.write({column, rect.top}, key_str, colors.TEXT)
        }
    } else {
        column = auto_cast font.write({column, rect.top}, sb.active_buffer.file_path, rl.GRAY)
    }

}
