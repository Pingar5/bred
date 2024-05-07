package history

import "core:log"

import "base:runtime"

@(private)
HistoryNode :: struct($State: typeid) {
    state: State,
    next:  ^HistoryNode(State),
    prev:  ^HistoryNode(State),
}

History :: struct($State: typeid) {
    head, tail:    ^HistoryNode(State),
    allocator:     runtime.Allocator,
    destroy_state: proc(state: State),
}

@(private)
create_node :: proc(state: $State, allocator := context.allocator) -> ^HistoryNode(State) {
    node := new(HistoryNode(State), allocator)
    node.state = state
    return node
}

@(private)
destroy_node :: proc(node: ^$N/HistoryNode($State), destroy_state: proc(state: State)) {
    if node.next != nil do destroy_node(node.next, destroy_state)
    destroy_state(node.state)
    free(node)
}

create_history :: proc(
    current_state: $State,
    destroy_state: proc(state: State),
    allocator := context.allocator,
) -> History(State) {
    node := create_node(current_state, allocator)

    return {head = node, tail = node, allocator = allocator, destroy_state = destroy_state}
}

destroy_history :: proc(h: $H/History) {
    destroy_node(h.head, h.destroy_state)
}

write :: proc(h: ^$H/History($State), state: State) {
    if h.tail.next == nil {
        h.tail.next = create_node(state, h.allocator)
        h.tail.next.prev = h.tail
    } else {
        h.destroy_state(h.tail.next.state)
        h.tail.next.state = state

        if h.tail.next.next != nil {
            destroy_node(h.tail.next.next, h.destroy_state)
            h.tail.next.next = nil
        }
    }
    h.tail = h.tail.next
}

undo :: proc(h: ^$H/History($State)) -> (State, bool) {
    if h.tail == h.head do return {}, false

    h.tail = h.tail.prev
    return h.tail.state, true
}

redo :: proc(h: ^$H/History($State)) -> (State, bool) {
    if h.tail.next == nil do return {}, false

    h.tail = h.tail.next
    return h.tail.state, true
}

get_ref :: proc(h: ^$H/History($State)) -> ^State {
    return &h.tail.state
}

count :: proc(h: ^$H/History($State)) -> (undos, redos: int) {
    for node := h.head; node != h.tail; node = node.next {
        undos += 1
    }

    for node := h.tail; node.next != nil; node = node.next {
        redos += 1
    }

    return
}
