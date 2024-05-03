package command

import "bred:core"

import "core:fmt"
import "core:log"
import "core:slice"
import rl "vendor:raylib"

@(private)
CommandProc :: core.CommandProc
@(private)
Modifiers :: core.Modifiers
@(private)
Wildcard :: core.Wildcard
@(private)
WildcardValue :: core.WildcardValue
@(private)
Motion :: core.Motion
@(private)
CommandConstraints :: core.CommandConstraints

DEFAULT_COMMAND_CONSTRAINTS :: CommandConstraints {
    requires_buffer = true,
}

@(private)
PathStep :: union {
    core.Wildcard,
    rl.KeyboardKey,
}

@(private)
CommandTreeNode :: struct {
    children:      map[rl.KeyboardKey]^CommandTreeNode,
    num_wildcard:  ^CommandTreeNode,
    char_wildcard: ^CommandTreeNode,
    commands:      [dynamic]CommandListing,
}

@(private)
CommandListing :: struct {
    procedure:   CommandProc,
    constraints: CommandConstraints,
    path:        []PathStep,
}

@(private)
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

@(private)
CommandTree :: struct {
    roots:            [8]^CommandTreeNode,
    default_commands: [dynamic]CommandListing,
}

@(private)
tree: CommandTree

@(private)
create_node :: proc() -> (node: ^CommandTreeNode) {
    node = new(CommandTreeNode)

    node.children = make(map[rl.KeyboardKey]^CommandTreeNode)
    node.commands = make([dynamic]CommandListing)

    return
}

@(private)
delete_node :: proc(node: ^CommandTreeNode) {
    for _, child in node.children {
        delete_node(child)
    }

    if node.char_wildcard != nil do delete_node(node.char_wildcard)
    if node.num_wildcard != nil do delete_node(node.num_wildcard)
    
    for listing in node.commands {
        delete(listing.path)
    }

    delete(node.commands)
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
key_is_number :: proc(key: rl.KeyboardKey) -> bool {
    return (key >= .ZERO && key <= .NINE) || (key >= .KP_0 && key <= .KP_9)
}

@(private)
key_is_char :: proc(key: rl.KeyboardKey) -> bool {
    return (key >= .SPACE && key <= .GRAVE) || (key >= .KP_0 && key <= .KP_ADD) || key == .KP_EQUAL
}

@(private)
get_existing_node :: proc(
    current: ^CommandTreeNode,
    keys: []rl.KeyboardKey,
) -> (
    ^CommandTreeNode,
    bool,
) {
    if len(keys) == 0 do return current, true

    if keys[0] in current.children {
        return get_existing_node(current.children[keys[0]], keys[1:])
    } else if key_is_number(keys[0]) && current.num_wildcard != nil {
        first_non_number := 1
        for first_non_number < len(keys) && key_is_number(keys[first_non_number]) do first_non_number += 1

        return get_existing_node(current.num_wildcard, keys[first_non_number:])
    } else if key_is_char(keys[0]) && current.char_wildcard != nil {
        return get_existing_node(current.char_wildcard, keys[1:])
    } else {
        return {}, false
    }
}

@(private)
add_node_at :: proc(current: ^CommandTreeNode, path: []PathStep) -> ^CommandTreeNode {
    if len(path) == 0 do return current

    switch step in path[0] {
    case rl.KeyboardKey:
        if step not_in current.children {
            current.children[step] = create_node()
        }

        return add_node_at(current.children[step], path[1:])
    case Wildcard:
        switch step {
        case .Char:
            if current.char_wildcard == nil do current.char_wildcard = create_node()

            return add_node_at(current.char_wildcard, path[1:])
        case .Num:
            if current.num_wildcard == nil do current.num_wildcard = create_node()

            return add_node_at(current.num_wildcard, path[1:])
        }
    }

    panic("Unreachable")
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

register :: proc(
    modifiers: Modifiers,
    path: []PathStep,
    command: CommandProc,
    constraints := DEFAULT_COMMAND_CONSTRAINTS,
    allocator := context.allocator,
) {
    node := add_node_at(tree.roots[transmute(u8)(modifiers)], path)

    append(&node.commands, CommandListing{command, constraints, slice.clone(path, allocator)})
}

register_default_command :: proc(
    command: CommandProc,
    constraints := DEFAULT_COMMAND_CONSTRAINTS,
) {
    append(&tree.default_commands, CommandListing{command, constraints, nil})
}

is_leaf_or_invalid :: proc(keys: Motion) -> bool {
    for modifiers in MODIFIER_SET_PRECEDENCE {
        if modifiers <= keys.modifiers {
            root := tree.roots[transmute(u8)(modifiers)]

            node, node_found := get_existing_node(root, keys.keys)

            if node_found {
                return(
                    len(node.children) == 0 &&
                    node.char_wildcard == nil &&
                    node.num_wildcard == nil \
                )
            }
        }
    }

    return true
}

get_commands :: proc(
    motion: Motion,
    allocator := context.temp_allocator,
) -> (
    commands: []CommandListing,
) {
    for modifiers in MODIFIER_SET_PRECEDENCE {
        if modifiers <= motion.modifiers {
            root := tree.roots[transmute(u8)(modifiers)]

            node, node_found := get_existing_node(root, motion.keys)

            if node_found {
                return node.commands[:]
            }
        }
    }

    return tree.default_commands[:]
}

parse_wildcards :: proc(
    motion: Motion,
    path: []PathStep,
    allocator := context.temp_allocator,
) -> []WildcardValue {
    values := make([dynamic]WildcardValue, allocator)

    if path == nil {
        for char in motion.chars {
            append(&values, byte(char))
        }
    } else {
        motion_key: int
        for path_key, path_index in path {
            wildcard, is_wildcard := path_key.(Wildcard)

            if !is_wildcard {
                motion_key += 1
                continue
            }

            switch wildcard {
            case .Char:
                append(&values, motion.chars[motion_key])
            case .Num:
                num: int = 0

                key := motion.keys[motion_key]
                for key_is_number(key) {
                    num *= 10

                    if key >= .KP_0 {
                        num += int(key) - int(rl.KeyboardKey.KP_0)
                    } else {
                        num += int(key) - int(rl.KeyboardKey.ZERO)
                    }

                    motion_key += 1
                    key = motion.keys[motion_key]
                }
                append(&values, num)
            }
        }
    }

    return values[:]
}
