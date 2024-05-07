package portal

import "core:fmt"
import "core:log"

import "bred:colors"
import "bred:core"
import "bred:core/buffer"
import "bred:core/font"

import rl "vendor:raylib"

@(private = "file")
Portal :: core.Portal

FilePortalData :: struct {
    scroll:              int,
    look_ahead_distance: int,
}

is_active_portal :: proc(self: ^Portal, state: ^core.EditorState) -> bool {
    active_portal := &state.portals[state.active_portal]
    return self == active_portal
}

create_file_portal :: proc(rect: core.Rect) -> Portal {
    render_file_portal :: proc(self: ^Portal, state: ^core.EditorState) {
        contents := self.buffer
        data := transmute(^FilePortalData)self.config

        font.draw_bg_rect(
            {components = {self.rect.left, self.rect.top, 3, self.rect.height}},
            colors.GUTTER_BACKGROUND,
        )

        if contents == nil do return

        for line_offset in 0 ..< self.rect.height {
            screen_line := self.rect.top + line_offset
            buffer_line := data.scroll + line_offset

            if buffer_line >= len(contents.lines) do break

            line_number_fragment: string
            line_number_color: rl.Color
            if buffer_line == contents.cursor.pos.y {
                line_number_fragment = fmt.tprintf("%- 3d", buffer_line + 1)
                line_number_color = colors.TEXT
            } else {
                line_number_fragment = fmt.tprintf(
                    "% 3d",
                    abs(buffer_line - contents.cursor.pos.y),
                )
                line_number_color = rl.GRAY
            }

            font.render_fragment(
                line_number_fragment,
                {self.rect.left, screen_line},
                3,
                line_number_color,
            )
        }

        buffer_rect := core.Rect {
            components = {
                self.rect.left + 4,
                self.rect.top,
                self.rect.width - 4,
                self.rect.height,
            },
        }

        buffer.render(contents, buffer_rect, data.scroll)
        if is_active_portal(self, state) do buffer.render_cursor(contents, buffer_rect, data.scroll)
    }
    
    config := new(FilePortalData)
    config.look_ahead_distance = rect.height / 3

    return {
        type = "editor",
        rect = rect,
        render = render_file_portal,
        destroy = destroy_file_portal,
        config = config,
    }
}

ensure_cursor_visible :: proc(self: ^Portal, move_direction: int) {
    if self.buffer == nil do return
    data := transmute(^FilePortalData)self.config

    cursor_screen_line := self.buffer.cursor.pos.y - data.scroll

    if move_direction != 0 {
        cursor_screen_line += data.look_ahead_distance * move_direction
    }

    if cursor_screen_line > self.rect.height {
        data.scroll += cursor_screen_line - self.rect.height
    } else if cursor_screen_line < 0 {
        data.scroll += cursor_screen_line
        data.scroll = max(data.scroll, 0)
    }
}

destroy_file_portal :: proc(self: ^Portal) {
    data := transmute(^FilePortalData)self.config
    free(data)
}
