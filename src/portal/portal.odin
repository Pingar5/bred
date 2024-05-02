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

render :: proc(p: ^Portal) {
    switch contents in p.contents {
    case ^buffer.Buffer:
        buffer.render(contents, p.rect)
    case ^status.StatusBar:
        status.render(contents, p.rect)
    }
}
