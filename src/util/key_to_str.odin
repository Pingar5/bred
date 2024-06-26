package util

import rl "vendor:raylib"

@(private)
CHAR_MAP := map[rl.KeyboardKey]string {
    .APOSTROPHE    = "\"",
    .COMMA         = ",",
    .MINUS         = "-",
    .PERIOD        = ".",
    .SLASH         = "/",
    .ZERO          = "0",
    .ONE           = "1",
    .TWO           = "2",
    .THREE         = "3",
    .FOUR          = "4",
    .FIVE          = "5",
    .SIX           = "6",
    .SEVEN         = "7",
    .EIGHT         = "8",
    .NINE          = "9",
    .SEMICOLON     = ";",
    .EQUAL         = "=",
    .A             = "a",
    .B             = "b",
    .C             = "c",
    .D             = "d",
    .E             = "e",
    .F             = "f",
    .G             = "g",
    .H             = "h",
    .I             = "i",
    .J             = "j",
    .K             = "k",
    .L             = "l",
    .M             = "m",
    .N             = "n",
    .O             = "o",
    .P             = "p",
    .Q             = "q",
    .R             = "r",
    .S             = "s",
    .T             = "t",
    .U             = "u",
    .V             = "v",
    .W             = "w",
    .X             = "x",
    .Y             = "y",
    .Z             = "z",
    .LEFT_BRACKET  = "[",
    .BACKSLASH     = "\\",
    .RIGHT_BRACKET = "]",
    .GRAVE         = "`",
    .SPACE         = "•",
    .ESCAPE        = "<ESC>",
    .ENTER         = "⏎",
    .TAB           = "⭾",
    .BACKSPACE     = "↤",
    .DELETE        = "↦",
    .RIGHT         = "→",
    .LEFT          = "←",
    .DOWN          = "↓",
    .UP            = "↑",
    .PAGE_UP       = "⇑",
    .PAGE_DOWN     = "⇓",
    .HOME          = "⇐",
    .END           = "⇒",
    .F1            = "<F1>",
    .F2            = "<F2>",
    .F3            = "<F3>",
    .F4            = "<F4>",
    .F5            = "<F5>",
    .F6            = "<F6>",
    .F7            = "<F7>",
    .F8            = "<F8>",
    .F9            = "<F9>",
    .F10           = "<F10>",
    .F11           = "<F11>",
    .F12           = "<F12>",
    .KP_0          = "0",
    .KP_1          = "1",
    .KP_2          = "2",
    .KP_3          = "3",
    .KP_4          = "4",
    .KP_5          = "5",
    .KP_6          = "6",
    .KP_7          = "7",
    .KP_8          = "8",
    .KP_9          = "9",
    .KP_DECIMAL    = ".",
    .KP_DIVIDE     = "/",
    .KP_MULTIPLY   = "*",
    .KP_SUBTRACT   = "-",
    .KP_ADD        = "+",
    .KP_ENTER      = "⏎",
    .KP_EQUAL      = "=",
}

key_to_str :: proc(key: rl.KeyboardKey) -> string {
    if key in CHAR_MAP {
        return CHAR_MAP[key]
    } else {
        return ""
    }
}

// I have no fucking idea who put this here, but when I deleted it the editor wouldn’t start.
// Words cannot describe my fucking confusion.
//▕╮╭┻┻╮╭┻┻╮╭▕╮╲
//▕╯┃╭╮┃┃╭╮┃╰▕╯╭▏
//▕╭┻┻┻┛┗┻┻┛ ╰▏
//▕╰━━━┓┈┈┈╭╮▕╭╮▏
//▕╭╮╰┳┳┳┳╯╰╯▕╰╯▏
//▕╰╯┈┗┛┗┛┈╭╮▕╮┈▏