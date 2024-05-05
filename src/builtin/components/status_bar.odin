package components

import "core:strings"
import rl "vendor:raylib"

import "bred:colors"
import "bred:core"
import "bred:core/buffer"
import "bred:core/font"
import "bred:util"

@(private)
draw_modifier :: proc(
    mod: core.ModifierState,
    mod_str: string,
    pos: core.Position,
    max_length: int,
) -> int {
    length := min(max_length, len(mod_str))

    fg: rl.Color = rl.GRAY
    if mod.enabled || mod.held {
        bg := mod.locked ? colors.MODIFIER_LOCKED : colors.MODIFIER_ACTIVE
        fg = colors.TEXT
        font.draw_bg_rect({components = {pos.x, pos.y, length, 1}}, bg)
    }

    return font.render_fragment(mod_str, pos, max_length, fg)
}

create_status_bar :: proc(rect: core.Rect) -> core.Portal {
    render_status_bar :: proc(self: ^core.Portal, state: ^core.EditorState) {
        font.draw_bg_rect(self.rect, colors.STATUS_BAR_BACKGROUND)

        column := 0
        column += draw_modifier(
            state.motion_buffer.ctrl,
            " CTRL ",
            self.rect.start,
            self.rect.width,
        )
        column += draw_modifier(
            state.motion_buffer.shift,
            " SHIFT ",
            self.rect.start + {column, 0},
            self.rect.width - column,
        )
        column += draw_modifier(
            state.motion_buffer.alt,
            " ALT ",
            self.rect.start + {column, 0},
            self.rect.width - column,
        )

        column += 1

        motion_buffer := &state.motion_buffer
        if motion_buffer.keys_length > 0 {
            column := 18
            for key_idx in 0 ..< motion_buffer.keys_length {
                key := motion_buffer.keys[key_idx]
                key_str := util.key_to_str(key)

                column += font.render_fragment(
                    key_str,
                    self.rect.start + {column, 0},
                    self.rect.width - column,
                    rl.WHITE,
                )
            }
        } else {
            active_portal := state.portals[state.active_portal]

            if active_portal.buffer != nil {
                font.render_fragment(
                    active_portal.buffer.file_path,
                    self.rect.start + {18, 0},
                    self.rect.width - 18,
                    rl.GRAY,
                )
            }

        }
    }

    return {active = true, rect = rect, render = render_status_bar}
}
