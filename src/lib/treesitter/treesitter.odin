package treesitter

import "base:runtime"
import "core:log"

import "bred:colors"

import ts "bindings"
import "highlight"

Tree :: ts.Tree
Node :: ts.Node
Point :: ts.Point

LanguageConfig :: struct {
    parser:      ts.Parser,
    hl_config:   highlight.HighlightConfig,
    highlighter: highlight.Highlighter,
}

logger: runtime.Logger
languages: [dynamic]LanguageConfig
extension_to_language: map[string]int

init :: proc() -> bool {
    logger = context.logger
    ts.set_odin_allocator()

    return true
}

quit :: proc() {
    for lang in languages {
        ts.query_delete(lang.hl_config.query)
        delete(lang.hl_config.non_local_variable_patterns)
        delete(lang.hl_config.highlight_indices)
        delete(lang.hl_config.highlight_names)

        ts.parser_delete(lang.parser)

        ts.parser_delete(lang.highlighter.parser)
        delete(lang.highlighter.cursors)
    }

    delete(languages)
    delete(extension_to_language)
}

add_language :: proc(
    language: ts.Language,
    highlight_query: string,
    locals_query: string,
    injections_query: string,
) -> (
    language_id: int = -1,
    ok: bool = true,
) {
    recognized_names, _ := soa_unzip(colors.THEME[:])

    lang := LanguageConfig {
        parser    = ts.parser_new(),
        hl_config = highlight.create_highlight_config(
            language,
            highlight_query,
            locals_query,
            recognized_names,
            injections_query,
        ) or_return,
    }

    lang.highlighter = {
        parser  = ts.parser_new(),
        cursors = make([dynamic]ts.Query_Cursor),
    }

    lang_version_matches := ts.parser_set_language(lang.parser, language)
    if !lang_version_matches {
        log.error("Language binary is built on a different version of tree-sitter.\n")
        return -1, false
    }

    language_id = len(languages)
    append(&languages, lang)

    return
}

register_extension :: proc(language_id: int, extension: string) {
    assert(language_id != -1, "Cannot register extension on invalid language")
    extension_to_language[extension] = language_id
}

get_language_id :: proc(extension: string) -> int {
    return extension_to_language[extension] if extension in extension_to_language else -1
}

get_tree :: proc(lang: int, data: string) -> Tree {
    if lang == -1 do return nil

    return ts.parser_parse_string(languages[lang].parser, data)
}

update_tree :: proc(
    lang: int,
    tree: Tree,
    start, old_end, new_end: int,
    start_pos, old_end_pos, new_end_pos: Point,
    full_text: string,
) -> Tree {
    edit := ts.Input_Edit {
        u32(start),
        u32(old_end),
        u32(new_end),
        start_pos,
        old_end_pos,
        new_end_pos,
    }
    ts.tree_edit(tree, &edit)

    return ts.parser_parse_string(languages[lang].parser, full_text, tree)
}

delete_tree :: proc(tree: Tree) {
    ts.tree_delete(tree)
}

TreeIterator :: struct {
    is_first:         bool,
    cursor:           ts.Tree_Cursor,
    current_depth:    int,
    visited_children: bool,
}

start_iterate_tree :: proc(tree: Tree) -> TreeIterator {
    root := ts.tree_root_node(tree)

    return {cursor = ts.tree_cursor_new(root), is_first = true}
}

iterate_tree :: proc(iter: ^TreeIterator) -> (node: Node, depth: int, ok: bool) {
    if iter.cursor == {} do return {}, 0, false

    if !iter.is_first {
        cursor_ready := false
        for !cursor_ready {
            if iter.visited_children {
                if ts.tree_cursor_goto_next_sibling(&iter.cursor) {
                    iter.visited_children = false
                    cursor_ready = true
                } else if ts.tree_cursor_goto_parent(&iter.cursor) {
                    iter.visited_children = true
                    iter.current_depth -= 1
                } else {
                    ts.tree_cursor_delete(&iter.cursor)
                    iter.cursor = {}
                    return {}, 0, false
                }
            } else {
                cursor_ready = ts.tree_cursor_goto_first_child(&iter.cursor)

                if cursor_ready do iter.current_depth += 1
                iter.visited_children = !cursor_ready
            }
        }
    } else {
        iter.is_first = false
    }

    return ts.tree_cursor_current_node(&iter.cursor), iter.current_depth, true
}

NodeInfo :: struct {
    missing:            bool,
    start, end:         u32,
    start_pos, end_pos: Point,
    type:               cstring,
}

get_node_info :: proc(node: Node) -> NodeInfo {
    return {
        missing = ts.node_is_missing(node),
        start = ts.node_start_byte(node),
        end = ts.node_end_byte(node),
        start_pos = ts.node_start_point(node),
        end_pos = ts.node_end_point(node),
        type = ts.node_type(node),
    }
}


start_highlight_iter :: proc(
    language_id: int,
    source: string,
    allocator := context.allocator,
) -> (
    iter: highlight.HighlightIter,
    ok: bool,
) {
    lang := &languages[language_id]
    return highlight.start_highlight_iter(&lang.highlighter, &lang.hl_config, source, allocator)
}
