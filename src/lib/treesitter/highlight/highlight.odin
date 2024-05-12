package ts_highlight

import "base:runtime"
import "core:log"
import "core:slice"
import "core:strings"

// import "bred:colors"
import ts "bred:lib/treesitter/bindings"

INT_MAX: int : 9_223_372_036_854_775_807

Highlight :: struct {
    theme_index: u32,
    name:        string,
}
Range :: struct {
    start, end: int,
}

HighlightConfig :: struct {
    language:                      ts.Language,
    query:                         ts.Query,
    highlight_pattern_index:       u16,
    locals_pattern_index:          u16,
    local_scope_capture_index:     u32,
    local_def_capture_index:       u32,
    local_def_value_capture_index: u32,
    local_ref_capture_index:       u32,
    non_local_variable_patterns:   []u16,
    highlight_indices:             []Highlight,
    highlight_names:               []string,
}

Highlighter :: struct {
    parser:  ts.Parser,
    cursors: [dynamic]ts.Query_Cursor,
}

LocalDef :: struct {
    name:        string,
    value_range: Range,
    highlight:   Maybe(Highlight),
}

LocalScope :: struct {
    inherits:   bool,
    range:      Range,
    local_defs: [dynamic]LocalDef,
}

StartEvent :: struct {
    highlight: Highlight,
}
SourceEvent :: distinct Range
EndEvent :: struct {}

HighlightEvent :: union {
    StartEvent,
    SourceEvent,
    EndEvent,
}

QueryCapture :: struct {
    pattern_index:  u16,
    capture_index:  u32,
    node:           ts.Node,
    other_captures: []ts.Query_Capture,
}

HighlightIter :: struct {
    source:               string,
    byte_offset:          int,
    highlighter:          ^Highlighter,
    layers:               [dynamic]HighlightIterLayer,
    iter_count:           int,
    next_event:           HighlightEvent,
    last_highlight_range: Maybe([3]int),
    allocator:            runtime.Allocator,
}

HighlightIterLayer :: struct {
    tree:          ts.Tree,
    cursor:        ts.Query_Cursor,
    capture_index: int,
    captures:      []QueryCapture,
    config:        ^HighlightConfig,
    end_stack:     [dynamic]int,
    scope_stack:   [dynamic]LocalScope,
    ranges:        []ts.Range,
    depth:         int,
}

HighlightIterLayerSortKey :: struct {
    next_event_offset: int,
    next_is_start:     bool,
    depth:             int,
}

create_highlight_config :: proc(
    language: ts.Language,
    highlights_query: string,
    locals_query: string,
    recognized_names: []string,
    injections_query: string = "",
    allocator := context.allocator,
) -> (
    config: HighlightConfig,
    ok: bool = true,
) {
    full_query := strings.concatenate(
        { /*injections_query,*/locals_query, highlights_query},
        context.temp_allocator,
    )
    locals_query_offset: u32 = 0 //u32(len(injections_query))
    highlights_query_offset := u32(len(locals_query))

    query, err_offset, err := ts.query_new(language, full_query)
    if err != .None {
        log.errorf("Failed to compile Tree-Sitter query. %v at byte %d\n", err, err_offset)
        return {}, false
    }

    non_local_variable_patterns := make([dynamic]u16, allocator)
    for i in 0 ..< ts.query_pattern_count(query) {
        pattern_offset := ts.query_start_byte_for_pattern(query, i)

        if pattern_offset < highlights_query_offset {
            config.highlight_pattern_index += 1
            if pattern_offset < locals_query_offset {
                config.locals_pattern_index += 1
            }
        }

        // predicates := ts.query_predicates_for_pattern(query, i)
        // for _ in predicates {
        //     // TODO: determine if pattern is non-local
        //     if false {
        //         append(&non_local_variable_patterns, u16(i))
        //     }
        // }
    }
    config.non_local_variable_patterns = non_local_variable_patterns[:]

    // TODO: Combined injections query

    highlight_indices := make([dynamic]Highlight, allocator)
    highlight_names := make([dynamic]string, allocator)
    for capture_index in 0 ..< ts.query_capture_count(query) {
        name := ts.query_capture_name_for_id(query, capture_index)

        switch name {
        // case "injection.content":
        //     config.injection_content_capture_index = capture_index
        // case "injection.language":
        //     config.injection_language_capture_index = capture_index
        case "local.definition":
            config.local_def_capture_index = capture_index
        case "local.definition-value":
            config.local_def_value_capture_index = capture_index
        case "local.reference":
            config.local_ref_capture_index = capture_index
        case "local.scope":
            config.local_scope_capture_index = capture_index
        }

        best_index, best_match_len: int = 0, 0
        for recognized_name, i in recognized_names {
            if !strings.has_prefix(name, recognized_name) do continue

            if len(recognized_name) > best_match_len {
                best_index = i
                best_match_len = len(recognized_name)
            }
        }

        append(&highlight_indices, Highlight{u32(best_index), name})
    }

    config.language = language
    config.query = query
    config.highlight_indices = highlight_indices[:]
    config.highlight_names = highlight_names[:]

    return
}

start_highlight_iter :: proc(
    self: ^Highlighter,
    config: ^HighlightConfig,
    source: string,
    allocator := context.allocator,
) -> (
    iter: HighlightIter,
    ok: bool,
) {
    layers := create_highlight_layers(source, self, config, nil, allocator = allocator) or_return

    iter = HighlightIter {
        source      = source,
        highlighter = self,
        layers      = layers,
        allocator   = allocator,
    }

    assert(len(layers) == 1, "HighlightIter doesn't support multiple layers yet")
    sort_layers(&iter)

    return
}

destroy_highlight_iter_layer :: proc(layer: ^HighlightIterLayer) {
    for scope in layer.scope_stack {
        delete(scope.local_defs)
    }
    delete(layer.scope_stack)

    delete(layer.end_stack)

    ts.tree_delete(layer.tree)
    ts.query_cursor_delete(layer.cursor)
}

destroy_highlight_iter :: proc(iter: ^HighlightIter) {
    for &layer in iter.layers {
        destroy_highlight_iter_layer(&layer)
    }

    delete(iter.layers)
}

iterate_highlight_iter :: proc(iter: ^HighlightIter) -> (event: HighlightEvent, ok: bool) {
    main: for {
        // If we queued a next event last iteration, return that
        if iter.next_event != nil {
            event = iter.next_event
            iter.next_event = nil

            return event, true
        }

        // If there are no layers left, return the rest of the source code
        if len(iter.layers) == 0 {
            if iter.byte_offset < len(iter.source) {
                event = SourceEvent{iter.byte_offset, len(iter.source)}
                iter.byte_offset = len(iter.source)
                return event, true
            } else {
                return nil, false
            }
        }

        range: Range
        layer := &iter.layers[0]
        if layer.capture_index < len(layer.captures) {
            // If our current layer has a capture, then check if we need to end a highlight before that capture
            capture := layer.captures[layer.capture_index]

            range = node_range(capture.node)
            if len(layer.end_stack) > 0 {
                end_byte := layer.end_stack[len(layer.end_stack) - 1]
                if end_byte < range.start {
                    pop(&layer.end_stack)
                    return emit_event(iter, end_byte, EndEvent{}), true
                }
            }
        } else {
            if len(layer.end_stack) > 0 {
                end_byte := pop(&layer.end_stack)
                return emit_event(iter, end_byte, EndEvent{}), true
            } else {
                return emit_event(iter, len(iter.source), nil), true
            }
        }

        capture := layer.captures[layer.capture_index]
        layer.capture_index += 1

        // TODO: Handle injections

        for last_scope := layer.scope_stack[len(layer.scope_stack) - 1];
            range.start > last_scope.range.end;
            last_scope = layer.scope_stack[len(layer.scope_stack) - 1] {
            scope := pop(&layer.scope_stack)
            delete(scope.local_defs)
        }

        reference_highlight, definition_highlight: ^Highlight = nil, nil
        for capture.pattern_index < layer.config.highlight_pattern_index {
            if capture.capture_index == layer.config.local_scope_capture_index {
                scope := LocalScope {
                    inherits   = true,
                    range      = range,
                    local_defs = make([dynamic]LocalDef, iter.allocator),
                }

                // TODO: Read property settings to determine if scope inherits

                append(&layer.scope_stack, scope)
            } else if capture.capture_index == layer.config.local_def_capture_index {
                scope := layer.scope_stack[len(layer.scope_stack) - 1]

                value_range: Range
                for value_capture in capture.other_captures {
                    if value_capture.index == layer.config.local_def_value_capture_index {
                        value_range = node_range(value_capture.node)
                    }
                }

                name := iter.source[range.start:range.end]
                append(
                    &scope.local_defs,
                    LocalDef{name = name, value_range = value_range, highlight = nil},
                )

                definition_highlight =
                &scope.local_defs[len(scope.local_defs) - 1].highlight.(Highlight)
            } else if capture.capture_index == layer.config.local_ref_capture_index {
                name := iter.source[range.start:range.end]

                def_found := false
                for &scope in layer.scope_stack {
                    for &def in scope.local_defs {
                        if def.name == name && range.start >= def.value_range.end {
                            def_highlight, def_highlight_ok := &def.highlight.(Highlight)
                            reference_highlight = def_highlight if def_highlight_ok else nil
                            def_found = true
                            break
                        }
                    }

                    if !scope.inherits do break
                    if def_found do break
                }
            }

            if layer.capture_index < len(layer.captures) {
                capture = layer.captures[layer.capture_index]
                layer.capture_index += 1

                continue
            }

            sort_layers(iter)
            continue main
        }

        if last_highlight_range, cast_ok := iter.last_highlight_range.([3]int); cast_ok {
            if range.start == last_highlight_range[0] &&
               range.end == last_highlight_range[1] &&
               layer.depth == last_highlight_range[2] {
                sort_layers(iter)
                continue main
            }
        }

        for layer.capture_index < len(layer.captures) {
            next_capture := layer.captures[layer.capture_index]

            if next_capture.node == capture.node {
                layer.capture_index += 1

                if (definition_highlight != nil || reference_highlight != nil) &&
                   slice.contains(
                       layer.config.non_local_variable_patterns,
                       next_capture.pattern_index,
                   ) {
                    continue
                }

                capture = next_capture
            } else {
                break
            }
        }

        current_highlight := layer.config.highlight_indices[capture.capture_index]
        if definition_highlight != nil {
            definition_highlight^ = current_highlight
        }

        highlight := reference_highlight^ if reference_highlight != nil else current_highlight
        iter.last_highlight_range = [3]int{range.start, range.end, layer.depth}
        append(&layer.end_stack, range.end)

        sort_layers(iter)
        return emit_event(iter, range.start, StartEvent{highlight}), true
    }
}

@(private)
node_range :: proc(node: ts.Node) -> Range {
    return {int(ts.node_start_byte(node)), int(ts.node_end_byte(node))}
}

get_sort_key :: proc(layer: HighlightIterLayer) -> (key: HighlightIterLayerSortKey, ok: bool) {
    key.depth = layer.depth

    next_start: int = -1
    if layer.capture_index < len(layer.captures) {
        next_capture := layer.captures[layer.capture_index]
        next_start = int(ts.node_start_byte(next_capture.node))
    }


    next_end := layer.end_stack[len(layer.end_stack) - 1] if len(layer.end_stack) > 0 else -1

    if next_start < 0 && next_end < 0 {
        return {}, false
    } else if next_end < 0 {
        key.next_event_offset = next_start
        key.next_is_start = true
    } else if next_start < 0 {
        key.next_event_offset = next_end
        key.next_is_start = false
    } else {
        key.next_event_offset = min(next_start, next_end)
        key.next_is_start = next_start < next_end
    }

    return key, true
}

compare_sort_keys :: proc(a, b: HighlightIterLayerSortKey) -> (a_is_better: bool) {
    a_type_ordinal, b_type_ordinal := int(a.next_is_start), int(b.next_is_start)

    return(
        a.next_event_offset < b.next_event_offset ||
        (a.next_event_offset == b.next_event_offset &&
                (a_type_ordinal < b_type_ordinal ||
                        (a_type_ordinal == b_type_ordinal && (a.depth > b.depth)))) \
    )
}

@(private)
sort_layers :: proc(iter: ^HighlightIter) {
    best_key: HighlightIterLayerSortKey
    best_index: int
    for i := 0; i < len(iter.layers); i += 1 {
        key, has_next := get_sort_key(iter.layers[i])

        if !has_next {
            destroy_highlight_iter_layer(&iter.layers[i])
            unordered_remove(&iter.layers, i)
            i -= 1
            continue
        }

        if compare_sort_keys(key, best_key) {
            best_key = key
            best_index = i
        }
    }

    if best_index != 0 {
        iter.layers[0], iter.layers[best_index] = iter.layers[best_index], iter.layers[0]
    }
}

@(private)
emit_event :: proc(
    iter: ^HighlightIter,
    offset: int,
    event: HighlightEvent,
) -> (
    result: HighlightEvent,
) {
    result = event

    if iter.byte_offset < offset {
        result = SourceEvent{iter.byte_offset, offset}
        iter.byte_offset = offset
        iter.next_event = event
    }

    sort_layers(iter)

    return
}

@(private)
create_highlight_layers :: proc(
    source: string,
    highlighter: ^Highlighter,
    config: ^HighlightConfig,
    ranges: []ts.Range,
    parent_name: string = "",
    depth: int = 0,
    allocator := context.allocator,
) -> (
    [dynamic]HighlightIterLayer,
    bool,
) {
    result := make([dynamic]HighlightIterLayer, 0, 1, allocator)
    queue: [dynamic]u32 = {}
    
    for {
        // TODO: Need to reset ranges on second iteration?
        if ranges != nil && !ts.parser_set_included_ranges(highlighter.parser, ranges) do continue
        
        if !ts.parser_set_language(highlighter.parser, config.language) {
            return nil, false
        }
        
        tree := ts.parser_parse_string(highlighter.parser, source)
        
        // TODO: Process combined injections
        
        cursor := ts.query_cursor_new()
        captures := make([dynamic]QueryCapture, allocator)
        ts.query_cursor_exec(cursor, config.query, ts.tree_root_node(tree))
        for match, capture_index in ts.query_cursor_next_capture(cursor) {
            capture := match.captures[capture_index]
            append(
                &captures,
                QueryCapture {
                    match.pattern_index,
                    capture.index,
                    capture.node,
                    slice.clone(match.captures[:match.capture_count], allocator),
                },
            )
        }

        layer := HighlightIterLayer {
            end_stack   = make([dynamic]int, allocator),
            scope_stack = make([dynamic]LocalScope, allocator),
            cursor      = cursor,
            captures    = captures[:],
            depth       = depth,
            tree        = tree,
            config      = config,
            ranges      = ranges,
        }

        append(
            &layer.scope_stack,
            LocalScope {
                inherits = false,
                range = {0, INT_MAX},
                local_defs = make([dynamic]LocalDef, allocator),
            },
        )
        append(&result, layer)


        if len(queue) == 0 do break

        // TODO: Pop injection from queue
    }
    
    return result, true
}
