package command

import "ed:buffer"

import "core:log"
import "core:strings"
import rl "vendor:raylib"

BufferCommand :: proc(buffer: ^buffer.Buffer)

Command :: union {
    BufferCommand,
}

CommandTreeNode :: struct {
    key:      rl.KeyboardKey,
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
create_node :: proc(key: rl.KeyboardKey) -> (node: ^CommandTreeNode) {
    node = new(CommandTreeNode)

    node.key = key
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
        current.children[keys[0]] = create_node(keys[0])

        return get_sub_node(current.children[keys[0]], keys[1:], allow_create)
    } else {
        return {}, false
    }
}

@(private)
get_node :: proc(keys: KeySequence, allow_create := false) -> (^CommandTreeNode, bool) {
    root: ^CommandTreeNode
    if keys.ctrl {
        if keys.shift {
            if keys.alt {
                root = tree.ctrl_shift_alt
            } else {
                root = tree.ctrl_shift
            }
        } else if keys.alt {
            root = tree.ctrl_alt
        } else {
            root = tree.ctrl
        }
    } else {
        root = tree.normal
    }

    return get_sub_node(root, keys.keys, allow_create)
}

init_command_tree :: proc() {
    tree.normal = create_node(.KEY_NULL)
    tree.ctrl = create_node(.KEY_NULL)
    tree.ctrl_shift = create_node(.KEY_NULL)
    tree.ctrl_alt = create_node(.KEY_NULL)
    tree.ctrl_shift_alt = create_node(.KEY_NULL)
}

destroy_command_tree :: proc() {
    delete_node(tree.normal)
    delete_node(tree.ctrl)
    delete_node(tree.ctrl_shift)
    delete_node(tree.ctrl_alt)
    delete_node(tree.ctrl_shift_alt)
}

register :: proc(keys: KeySequence, command: Command) {
    node, ok := get_node(keys, true)

    assert(ok, "Failed to create command tree node")
    assert(node.command == nil, "Command already exists with that key sequence")

    node.command = command
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
