package font

import "core:slice"
import "bred:util"
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

    for key in rl.KeyboardKey {
        key_str := util.key_to_str(key)
        for r in string(key_str) {
            if !slice.contains(codepoints[:], r) {
                append(&codepoints, r)
            }
        }
    }

    CODEPOINTS = codepoints[:]
}
