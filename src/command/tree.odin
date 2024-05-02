package command

import "bred:buffer"

import "core:fmt"
import "core:log"
import rl "vendor:raylib"

BufferCommand :: proc(buffer: ^buffer.Buffer)
CommandBufferCommand :: proc(command_buffer: ^CommandBuffer)
EditorCommand :: proc(editor_state: rawptr)

Command :: union {
    BufferCommand,
    CommandBufferCommand,
    EditorCommand,
}

CommandTreeNode :: struct {
    children: map[rl.KeyboardKey]^CommandTreeNode,
    command:  Command,
}

MODIFIER_SET_PRECEDENCE :: [8]Modifiers {
    {.Ctrl, .Shift, .Alt},
    {.Ctrl, .Shift},
    {.Ctrl, .Alt},
    {.Shift, .Alt},
    {.Ctrl},
    {.Shift},
    {.Alt},
    {},
}
CommandTree :: struct {
    roots: [8]^CommandTreeNode,
}

@(private)
tree: CommandTree

@(private)
create_node :: proc() -> (node: ^CommandTreeNode) {
    node = new(CommandTreeNode)

    node.children = make(map[rl.KeyboardKey]^CommandTreeNode)

    return
}

@(private)
delete_node :: proc(node: ^CommandTreeNode) {
    for _, child in node.children {
        delete_node(child)
    }
    delete(node.children)
    free(node)
}

@(private)
get_child :: proc(node: ^CommandTreeNode, key: rl.KeyboardKey) -> ^CommandTreeNode {
    if key in node.children {
        return node.children[key]
    } else {
        return nil
    }
}

@(private)
get_sub_node :: proc(
    current: ^CommandTreeNode,
    keys: []rl.KeyboardKey,
    allow_create: bool,
) -> (
    ^CommandTreeNode,
    bool,
) {
    if len(keys) == 0 do return current, true

    if keys[0] in current.children {
        return get_sub_node(current.children[keys[0]], keys[1:], allow_create)
    } else if allow_create {
        current.children[keys[0]] = create_node()

        return get_sub_node(current.children[keys[0]], keys[1:], allow_create)
    } else {
        return {}, false
    }
}

@(private)
get_node :: proc(keys: KeySequence, allow_create := false) -> (cmd: ^CommandTreeNode, ok: bool) {
    for modifiers in MODIFIER_SET_PRECEDENCE {
        if modifiers <= keys.modifiers {
            root := tree.roots[transmute(u8)(modifiers)]

            cmd, ok = get_sub_node(root, keys.keys, allow_create)
            if ok do return
        }
    }

    return
}

init_command_tree :: proc() {
    for i in 0 ..< len(tree.roots) {
        tree.roots[i] = create_node()
    }
}

destroy_command_tree :: proc() {
    for i in 0 ..< len(tree.roots) {
        delete_node(tree.roots[i])
    }
}

register_command :: proc(keys: KeySequence, command: Command) {
    node, ok := get_node(keys, true)

    assert(ok, "Failed to create command tree node")
    assert(node.command == nil, fmt.tprintf("Command already exists with key sequence: %#v", keys))

    node.command = command
}

register_buffer_command :: proc(keys: KeySequence, command: BufferCommand) {
    register_command(keys, command)
}

register_command_buffer_command :: proc(keys: KeySequence, command: CommandBufferCommand) {
    register_command(keys, command)
}

register_editor_command :: proc(keys: KeySequence, command: EditorCommand) {
    register_command(keys, command)
}

register :: proc {
    register_buffer_command,
    register_command_buffer_command,
    register_editor_command,
}

is_leaf_or_invalid :: proc(keys: KeySequence) -> bool {
    node, ok := get_node(keys)

    if !ok do return true

    return len(node.children) == 0
}

get_command :: proc(keys: KeySequence) -> (command: Command, ok: bool) {
    node := get_node(keys) or_return

    if node.command == nil do return nil, false

    return node.command, true
}
