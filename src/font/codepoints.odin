package font

import "core:slice"
import "ed:command"
import rl "vendor:raylib"

@(private)
CODEPOINTS: []rune

@(private)
generate_codepoint_list :: proc() {
    codepoints := make([dynamic]rune, 0, 300)

    // ALL ASCII
    for r in rune(0) ..< rune(255) {
        append(&codepoints, r)
    }

    CODEPOINTS = codepoints[:]
}
