package core

import rl "vendor:raylib"

import "bred:util/history"
import "bred:util/pool"

////////////////////
//     EDITOR     //
////////////////////
BufferId :: distinct u16

EditorState :: struct {
    layouts:        [dynamic]Layout,
    buffers:        pool.ResourcePool(Buffer),
    portals:        [dynamic]Portal,
    command_sets:   [dynamic]CommandSet,
    motion_buffer:  MotionBuffer,
    active_portal:  int,
    current_layout: int,
}

destroy_editor :: proc(state: ^EditorState) {
    buffer_id: BufferId
    for b in pool.iterate(&state.buffers, auto_cast &buffer_id) {
        destroy(b^)
    }

    for layout in state.layouts {
        destroy(layout)
    }

    for &portal in state.portals {
        if portal.destroy != nil do portal->destroy()
    }

    for command_set in state.command_sets {
        destroy(command_set)
    }

    pool.destroy(&state.buffers)
    delete(state.layouts)
    delete(state.portals)
    delete(state.command_sets)
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
    type:           string,
    rect:           Rect,
    render:         proc(self: ^Portal, state: ^EditorState),
    destroy:        proc(self: ^Portal),
    command_set_id: int,
    buffer:         BufferId,
    config:         rawptr,
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

BufferState :: struct {
    text:         string,
    cursor_index: int,
}

Buffer :: struct {
    file_path: string,
    is_dirty:  bool,
    text:      string,
    cursor:    Cursor,
    lines:     [dynamic]Line,
    history:   history.History(BufferState),
}

destroy_buffer :: proc(b: Buffer) {
    // b.text is destroyed by history
    history.destroy_history(b.history)

    delete(b.lines)
    delete(b.file_path)
}


////////////////////
//    COMMANDS    //
////////////////////
CommandProc :: proc(editor_state: ^EditorState, wildcards: []WildcardValue) -> bool

Wildcard :: enum {
    Num,
    Char,
}

WildcardValue :: union {
    int,
    byte,
}

CommandPath :: []union {
    Wildcard,
    rl.KeyboardKey,
}

CommandTreeNode :: struct {
    children:      map[rl.KeyboardKey]^CommandTreeNode,
    num_wildcard:  ^CommandTreeNode,
    char_wildcard: ^CommandTreeNode,
    command:       CommandListing,
}

CommandListing :: struct {
    procedure: CommandProc,
    path:      CommandPath,
}

CommandSet :: struct {
    roots:            [8]^CommandTreeNode,
    default_commands: [dynamic]CommandListing,
}

destroy_command_set :: proc(command_set: CommandSet) {
    destroy_node :: proc(node: ^CommandTreeNode) {
        for _, child in node.children {
            destroy_node(child)
        }

        if node.char_wildcard != nil do destroy_node(node.char_wildcard)
        if node.num_wildcard != nil do destroy_node(node.num_wildcard)

        delete(node.command.path)
        delete(node.children)
        free(node)
    }

    for i in 0 ..< len(command_set.roots) {
        destroy_node(command_set.roots[i])
    }
    delete(command_set.default_commands)
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
    destroy_command_set,
    destroy_layout,
    destroy_editor,
    destroy_motion,
}
