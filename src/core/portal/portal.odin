package portal

import "bred:core"
import "bred:core/buffer"

@(private) Portal :: core.Portal

render :: proc(p: ^Portal, is_active_portal: bool) {
    buffer.render(p.contents, p.rect, is_active_portal)
}
