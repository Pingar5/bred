package portal

import "bred:buffer"
import "bred:math"
import "bred:status"

PortalContents :: union {
    ^buffer.Buffer,
    ^status.StatusBar,
}

Portal :: struct {
    active:   bool,
    rect:     math.Rect,
    contents: PortalContents,
}

render :: proc(p: ^Portal, is_active_portal: bool) {
    switch contents in p.contents {
    case ^buffer.Buffer:
        buffer.render(contents, p.rect, is_active_portal)
    case ^status.StatusBar:
        status.render(contents, p.rect)
    }
}
