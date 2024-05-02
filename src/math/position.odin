package bred_math

Position :: distinct [2]int

Rect :: struct #raw_union {
    using vectors: struct {
        start: Position,
        size:  Position,
    },
    using components:  struct {
        left:   int,
        top:    int,
        width:  int,
        height: int,
    },
}
