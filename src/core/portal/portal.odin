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

is_active_portal :: proc(self: ^Portal, state: ^core.EditorState) -> bool {
    active_portal := &state.portals[state.active_portal]
    return self == active_portal
}