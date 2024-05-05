package layout

import "bred:core"
import "bred:core/font"

@(private)
clear_layout :: proc(state: ^core.EditorState) {
    for &portal in state.portals {
        portal = {}
    }
    clear(&state.portals)
}

@(private)
PortalSpec :: struct {
    rect:       core.Rect,
    definition: core.PortalDefinition,
}

@(private)
build_layout :: proc(portals: ^[dynamic]PortalSpec, layout: Layout, rect: core.Rect) {
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

        build_layout(portals, typed_layout.primary_child, primary_rect)
        build_layout(portals, typed_layout.secondary_child, secondary_rect)
    case core.PortalDefinition:
        append(portals, PortalSpec{rect, typed_layout})
    }
}

activate_layout :: proc(state: ^core.EditorState, layout_id: int) {
    clear_layout(state)
    state.current_layout = layout_id

    portal_specs := make([dynamic]PortalSpec, context.temp_allocator)
    build_layout(
        &portal_specs,
        state.layouts[layout_id],
        {vectors = {{0, 0}, font.calculate_window_dims()}},
    )

    for spec in portal_specs {
        append(&state.portals, spec.definition(spec.rect))
    }
}

resize_layout :: proc(state: ^core.EditorState) {
    portal_specs := make([dynamic]PortalSpec, context.temp_allocator)
    build_layout(
        &portal_specs,
        state.layouts[state.current_layout],
        {vectors = {{0, 0}, font.calculate_window_dims()}},
    )

    for spec, index in portal_specs {
        state.portals[index].rect = spec.rect
    }

}