package portal

import "bred:buffer"
import "bred:math"
import "bred:status"

Portal :: struct {
    active:   bool,
    rect:     math.Rect,
    contents: ^buffer.Buffer,
}

render :: proc(p: ^Portal, is_active_portal: bool) {
    buffer.render(p.contents, p.rect, is_active_portal)
}
