package command

import "ed:buffer"

import "core:log"
import "core:strings"
import rl "vendor:raylib"

BufferCommand :: proc(buffer: ^buffer.Buffer)
CommandBufferCommand :: proc(command_buffer: ^CommandBuffer)

Command :: union {
    BufferCommand,
    CommandBufferCommand,
}

CommandTreeNode :: struct {
    children: map[rl.KeyboardKey]^CommandTreeNode,
    command:  Command,
}

CommandTree :: struct {
    normal:         ^CommandTreeNode,
    ctrl:           ^CommandTreeNode,
    ctrl_shift:     ^CommandTreeNode,
    ctrl_shift_alt: ^CommandTreeNode,
    ctrl_alt:       ^CommandTreeNode,
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
    root: ^CommandTreeNode

    if keys.alt && keys.shift && keys.ctrl {
        cmd, ok = get_sub_node(tree.ctrl_shift_alt, keys.keys, allow_create)
        if ok do return
    }

    if keys.shift && keys.ctrl {
        cmd, ok = get_sub_node(tree.ctrl_shift, keys.keys, allow_create)
        if ok do return
    }

    if keys.alt && keys.ctrl {
        cmd, ok = get_sub_node(tree.ctrl_alt, keys.keys, allow_create)
        if ok do return
    }

    if keys.ctrl {
        cmd, ok = get_sub_node(tree.ctrl, keys.keys, allow_create)
        if ok do return
    }

    cmd, ok = get_sub_node(tree.normal, keys.keys, allow_create)

    return
}

init_command_tree :: proc() {
    tree.normal = create_node()
    tree.ctrl = create_node()
    tree.ctrl_shift = create_node()
    tree.ctrl_alt = create_node()
    tree.ctrl_shift_alt = create_node()
}

destroy_command_tree :: proc() {
    delete_node(tree.normal)
    delete_node(tree.ctrl)
    delete_node(tree.ctrl_shift)
    delete_node(tree.ctrl_alt)
    delete_node(tree.ctrl_shift_alt)
}

register_command :: proc(keys: KeySequence, command: Command) {
    node, ok := get_node(keys, true)

    assert(ok, "Failed to create command tree node")
    assert(node.command == nil, "Command already exists with that key sequence")

    node.command = command
}

register_buffer_command :: proc(keys: KeySequence, command: BufferCommand) {
    register_command(keys, command)
}

register_command_buffer_command :: proc(keys: KeySequence, command: CommandBufferCommand) {
    register_command(keys, command)
}

register :: proc {
    register_buffer_command,
    register_command_buffer_command,
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
