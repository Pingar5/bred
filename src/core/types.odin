package core

import rl "vendor:raylib"

////////////////////
//     EDITOR     //
////////////////////
EditorState :: struct {
    layouts:        [dynamic]Layout,
    buffers:        [dynamic]Buffer,
    portals:        [dynamic]Portal,
    motion_buffer: MotionBuffer,
    active_portal:  int,
    current_layout: int,
}

destroy_editor :: proc(state: ^EditorState) {
    for b in state.buffers {
        destroy(b)
    }

    for layout in state.layouts {
        destroy(layout)
    }

    delete(state.buffers)
    delete(state.layouts)
    delete(state.portals)
    free(state)
}

////////////////////
//     PORTALS    //
////////////////////
PortalDefinition :: proc(rect: Rect) -> Portal

SplitDirection :: enum {
    Left,
    Right,
    Top,
    Bottom,
}
Split :: struct {
    direction:       SplitDirection,
    absolute_size:   int,
    percent_size:    int,
    primary_child:   Layout,
    secondary_child: Layout,
}

Layout :: union {
    ^Split,
    PortalDefinition,
}

Portal :: struct {
    rect:   Rect,
    render: proc(self: ^Portal, state: ^EditorState),
    buffer: ^Buffer,
    config: rawptr,
}

destroy_layout :: proc(layout: Layout) {
    split, is_split := layout.(^Split)
    if is_split {
        destroy_layout(split.primary_child)
        destroy_layout(split.secondary_child)
        free(split)
    }
}

////////////////////
//     BUFFERS    //
////////////////////
Line :: struct {
    start, end: int,
}

Cursor :: struct {
    index:          int,
    pos:            Position,
    virtual_column: int,
}

Buffer :: struct {
    file_path: string,
    text:      string,
    cursor:    Cursor,
    lines:     [dynamic]Line,
    scroll:    int,
}

destroy_buffer :: proc(b: Buffer) {
    delete(b.text)
    delete(b.lines)
}


////////////////////
//    COMMANDS    //
////////////////////
CommandProc :: proc(editor_state: ^EditorState, wildcards: []WildcardValue)

Wildcard :: enum {
    Num,
    Char,
}

WildcardValue :: union {
    int,
    byte,
}

CommandConstraints :: struct {
    requires_buffer: bool,
}

////////////////////
//     MOTIONS    //
////////////////////
ModifierState :: struct {
    enabled, locked: bool,
    held:            bool,
    held_for:        f32,
}

Modifier :: enum {
    Ctrl,
    Shift,
    Alt,
}
Modifiers :: bit_set[Modifier;u8]

Motion :: struct {
    modifiers: Modifiers,
    keys:      []rl.KeyboardKey,
    chars:     []byte,
}

MotionBuffer :: struct {
    ctrl, shift, alt: ModifierState,
    keys_length:      uint,
    keys:             [8]rl.KeyboardKey,
    chars:            [8]byte,
    timer:            f32,
}

destroy_motion :: proc(motion: Motion) {
    delete(motion.keys)
    delete(motion.chars)
}


////////////////////
//      MATH      //
////////////////////
Position :: distinct [2]int

Rect :: struct #raw_union {
    using vectors:    struct {
        start: Position,
        size:  Position,
    },
    using components: struct {
        left:   int,
        top:    int,
        width:  int,
        height: int,
    },
}

////////////////////
//   PROC GROUPS  //
////////////////////
destroy :: proc {
    destroy_buffer,
    destroy_layout,
    destroy_editor,
    destroy_motion,
}
