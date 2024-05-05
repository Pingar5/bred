package layout

import "bred:core"

@(private)
Split :: core.Split
@(private)
SplitDirection :: core.SplitDirection
@(private)
Layout :: core.Layout
@(private)
Portal :: core.Portal

register_layout :: proc(state: ^core.EditorState, layout: Layout) -> int {
    append(&state.layouts, layout)
    return len(state.layouts) - 1
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
