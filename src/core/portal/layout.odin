package portal

import "bred:core"
import "bred:core/font"

@(private = "file")
Split :: core.Split
@(private = "file")
SplitDirection :: core.SplitDirection
@(private = "file")
Layout :: core.Layout
@(private = "file")
Portal :: core.Portal

register_layout :: proc(state: ^core.EditorState, layout: Layout) -> int {
    append(&state.layouts, layout)
    return len(state.layouts) - 1
}

@(private)
clear_layout :: proc(state: ^core.EditorState) {
    for &portal in state.portals {
        portal = {}
    }
    clear(&state.portals)
}

build_layout :: proc(state: ^core.EditorState, layout: Layout, rect: core.Rect) {
    switch typed_layout in layout {
    case ^core.Split:
        primary_rect := rect
        secondary_rect := rect
        split_size: int

        if typed_layout.absolute_size != 0 {
            split_size = typed_layout.absolute_size
        } else {
            axis_size :=
                typed_layout.direction == .Top || typed_layout.direction == .Bottom \
                ? rect.height \
                : rect.width
            split_size = (axis_size * typed_layout.percent_size) / 100
        }

        switch typed_layout.direction {
        case .Top:
            primary_rect.top += split_size
            primary_rect.height -= split_size

            secondary_rect.height = split_size
        case .Bottom:
            primary_rect.height -= split_size

            secondary_rect.top += primary_rect.height
            secondary_rect.height = split_size
        case .Left:
            primary_rect.left += split_size
            primary_rect.width -= split_size

            secondary_rect.width = split_size
        case .Right:
            primary_rect.width -= split_size

            secondary_rect.left += primary_rect.width
            secondary_rect.width = split_size
        }

        build_layout(state, typed_layout.primary_child, primary_rect)
        build_layout(state, typed_layout.secondary_child, secondary_rect)
    case core.PortalDefinition:
        append(&state.portals, typed_layout(rect))
    }
}

activate_layout :: proc(state: ^core.EditorState, layout_id: int) {
    clear_layout(state)

    portal_index: int
    full_window_rect := core.Rect {
        vectors = {{0, 0}, font.calculate_window_dims()},
    }
    build_layout(state, state.layouts[layout_id], full_window_rect)
}

create_absolute_split :: proc(
    direction: SplitDirection,
    size: int,
    primary_child, secondary_child: Layout,
) -> Layout {
    split := new(Split)

    split^ = {
        direction       = direction,
        absolute_size   = size,
        primary_child   = primary_child,
        secondary_child = secondary_child,
    }

    return split
}

create_percent_split :: proc(
    direction: SplitDirection,
    size: int,
    primary_child, secondary_child: Layout,
) -> Layout {
    split := new(Split)

    split^ = {
        direction       = direction,
        percent_size    = size,
        primary_child   = primary_child,
        secondary_child = secondary_child,
    }

    return split
}
