package tree_viewer

import "bred:core"
import "bred:core/portal"


move_cursor_up :: proc(state: ^core.EditorState, wildcards: []core.WildcardValue) -> bool {
    self := portal.get_active_portal(state)
    data := transmute(^TreeViewerData)self.config

    data.cursor -= 1
    data.cursor = max(data.cursor, 0)

    return true
}

move_cursor_down :: proc(state: ^core.EditorState, wildcards: []core.WildcardValue) -> bool {
    self := portal.get_active_portal(state)
    data := transmute(^TreeViewerData)self.config

    data.cursor += 1
    data.cursor = min(data.cursor, data.node_count)

    return true
}
