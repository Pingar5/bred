package command

import "bred:core"
import "bred:util"

import "core:fmt"
import "core:log"
import "core:slice"
import "core:strings"
import rl "vendor:raylib"

@(private)
CommandPath :: core.CommandPath
@(private)
CommandTreeNode :: core.CommandTreeNode
@(private)
CommandListing :: core.CommandListing
@(private)
CommandSet :: core.CommandSet

GLOBAL_SET :: 0

@(private)
MODIFIER_SET_PRECEDENCE :: [8]core.Modifiers {
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
get_command_set :: proc(
    state: ^core.EditorState,
    set_id: int,
    loc := #caller_location,
) -> ^CommandSet {
    assert(set_id >= 0, "Command set id cannot be negative", loc)
    assert(set_id < len(state.command_sets), "Command set does not exist", loc)
    return &state.command_sets[set_id]
}

@(private)
create_node :: proc() -> (node: ^CommandTreeNode) {
    node = new(CommandTreeNode)

    node.children = make(map[rl.KeyboardKey]^CommandTreeNode)

    return
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
add_node_at :: proc(current: ^CommandTreeNode, path: CommandPath) -> ^CommandTreeNode {
    if len(path) == 0 do return current

    switch step in path[0] {
    case rl.KeyboardKey:
        if step not_in current.children {
            current.children[step] = create_node()
        }

        return add_node_at(current.children[step], path[1:])
    case core.Wildcard:
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

to_string :: proc(
    modifiers: core.Modifiers,
    path: CommandPath,
    allocator := context.temp_allocator,
) -> string {
    builder: strings.Builder
    strings.builder_init(&builder, allocator)

    if .Ctrl in modifiers do strings.write_string(&builder, "C")
    if .Shift in modifiers do strings.write_string(&builder, "S")
    if .Alt in modifiers do strings.write_string(&builder, "A")

    if modifiers != {} do strings.write_string(&builder, "+")

    strings.write_string(&builder, "[")
    first := true
    for step in path {
        if !first do strings.write_string(&builder, ",")
        first = false

        switch key in step {
        case rl.KeyboardKey:
            strings.write_string(&builder, util.key_to_str(key))
        case core.Wildcard:
            switch key {
            case .Num:
                strings.write_string(&builder, "<Num>")
            case .Char:
                strings.write_string(&builder, "<Char>")
            }
        }
    }
    strings.write_string(&builder, "]")

    return strings.to_string(builder)
}

register_command_set :: proc(state: ^core.EditorState) -> int {
    set := CommandSet{}

    for i in 0 ..< len(set.roots) {
        set.roots[i] = create_node()
    }

    append(&state.command_sets, set)
    return len(state.command_sets) - 1
}

register :: proc(
    state: ^core.EditorState,
    set_id: int,
    modifiers: core.Modifiers,
    path: CommandPath,
    command: core.CommandProc,
    allocator := context.allocator,
) {
    set := get_command_set(state, set_id)
    node := add_node_at(set.roots[transmute(u8)(modifiers)], path)

    if node.command.path != nil {
        delete(node.command.path)
        log.errorf(
            "Duplicate command definition in set %v at %s\n",
            set_id,
            to_string(modifiers, path),
        )
    }

    node.command = {command, slice.clone(path, allocator)}
}

is_leaf_or_invalid :: proc(
    state: ^core.EditorState,
    set_id: int,
    motion: core.Motion,
) -> (
    leaf, invalid: bool,
) {
    set := get_command_set(state, set_id)

    root := set.roots[transmute(u8)(motion.modifiers)]

    node, node_found := get_existing_node(root, motion.keys)

    if node_found {
        leaf = len(node.children) == 0 && node.char_wildcard == nil && node.num_wildcard == nil
        return
    }

    return false, true
}

get_commands :: proc(
    state: ^core.EditorState,
    set_id: int,
    motion: core.Motion,
    allocator := context.temp_allocator,
) -> (
    commands: CommandListing,
    found: bool,
) {
    set := get_command_set(state, set_id)

    root := set.roots[transmute(u8)(motion.modifiers)]

    node, node_found := get_existing_node(root, motion.keys)

    if node_found {
        return node.command, true
    }

    return {}, false
}

parse_wildcards :: proc(
    motion: core.Motion,
    path: CommandPath,
    allocator := context.temp_allocator,
) -> []core.WildcardValue {
    values := make([dynamic]core.WildcardValue, allocator)

    if path == nil {
        for char in motion.chars {
            append(&values, byte(char))
        }
    } else {
        motion_key: int
        for path_key, path_index in path {
            wildcard, is_wildcard := path_key.(core.Wildcard)

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
                    if motion_key >= len(motion.keys) do break
                    key = motion.keys[motion_key]
                }
                append(&values, num)
            }
        }
    }

    return values[:]
}
