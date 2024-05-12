package tree_viewer

import "core:fmt"

import "bred:builtin/components/file_editor"
import "bred:colors"
import "bred:core"
import "bred:core/buffer"
import "bred:core/font"
import ts "bred:lib/treesitter"

TreeViewerData :: struct {
    portal_to_follow: int,
    cursor:           int,
    node_count:       int,
}

create_tree_viewer :: proc(rect: core.Rect, portal_to_follow: int) -> core.Portal {
    render_tree_viewer :: proc(self: ^core.Portal, state: ^core.EditorState) {
        data := transmute(^TreeViewerData)self.config
        other_portal := state.portals[data.portal_to_follow]

        target_buffer, ok := buffer.get_buffer(state, other_portal.buffer)

        if !ok do return
        if target_buffer.language_id == -1 do return

        data.node_count = 0

        font.draw_bg_rect(
            {components = {self.rect.left, self.rect.height / 2, self.rect.width, 1}},
            colors.GUTTER_BACKGROUND,
        )

        iter := ts.start_iterate_tree(target_buffer.syntax_tree)
        line := 0
        for node, depth in ts.iterate_tree(&iter) {
            screen_line := (line - data.cursor) + self.rect.height / 2

            indent := depth * 2

            info := ts.get_node_info(node)

            font.render_fragment(
                fmt.tprintf(
                    "%s%s [%d, %d] - [%d, %d]",
                    "MISSING " if info.missing else "",
                    info.type,
                    info.start_pos.col,
                    info.start_pos.row,
                    info.end_pos.col,
                    info.end_pos.row,
                ),
                {self.rect.left + indent, self.rect.top + screen_line},
                self.rect.width - indent,
                colors.TEXT,
            )


            if line == data.cursor {
                other_data := transmute(^file_editor.FilePortalData)other_portal.config

                if info.start_pos.row == info.end_pos.row {
                    font.draw_outline_rect(
                        {
                            components = {
                                other_portal.rect.left + int(info.start_pos.col) + 4,
                                other_portal.rect.top +
                                int(info.start_pos.row) -
                                other_data.scroll,
                                int(info.end_pos.col - info.start_pos.col),
                                1,
                            },
                        },
                        colors.MODIFIER_ACTIVE,
                    )
                } else {
                    min_row := int(min(info.start_pos.row, info.end_pos.row))
                    max_row := int(max(info.start_pos.row, info.end_pos.row))

                    font.draw_outline_rect(
                        {
                            components = {
                                other_portal.rect.left + 4,
                                other_portal.rect.top + min_row - other_data.scroll,
                                other_portal.rect.width - 4,
                                max_row - min_row,
                            },
                        },
                        colors.MODIFIER_ACTIVE,
                    )
                }
            }

            line += 1
            data.node_count += 1
        }
    }

    config := new(TreeViewerData)
    config.portal_to_follow = portal_to_follow

    return {
        type = "tree_sitter_viewer",
        rect = rect,
        render = render_tree_viewer,
        destroy = destroy_tree_viewer,
        config = config,
    }
}


destroy_tree_viewer :: proc(self: ^core.Portal) {
    data := transmute(^TreeViewerData)self.config
    free(data)
}
