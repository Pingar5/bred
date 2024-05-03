package logger

import "core:fmt"
import "core:runtime"

LoggerData :: struct {}

create_logger :: proc(allocator := context.allocator) -> runtime.Logger {
    data := new(LoggerData)

    return {procedure = log, data = rawptr(data), lowest_level = .Debug, options = {}}
}

log :: proc(
    data_ptr: rawptr,
    level: runtime.Logger_Level,
    text: string,
    options: runtime.Logger_Options,
    location := #caller_location,
) {
    fmt.print(text)
}
