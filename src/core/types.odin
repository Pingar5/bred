package core

import rl "vendor:raylib"

////////////////////
//     EDITOR     //
////////////////////
EditorState :: struct {
    buffers:        [dynamic]Buffer,
    command_buffer: CommandBuffer,
    portals:        [8]Portal,
    active_portal:  int,
}

destroy_editor :: proc(state: ^EditorState) {
    for b in state.buffers {
        destroy(b)
    }

    delete(state.buffers)
    free(state)
}

////////////////////
//     PORTALS    //
////////////////////
Portal :: struct {
    active: bool,
    rect:   Rect,
    render: proc(self: ^Portal, state: ^EditorState),
    buffer: ^Buffer,
    config: rawptr,
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

CommandBuffer :: struct {
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
    destroy_editor,
    destroy_motion,
}
