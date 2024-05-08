package command

import "base:runtime"

import "bred:core"

@(private = "file")
RegistrationFactoryMethods :: struct {
    register: proc(
        factory: RegistrationFactory,
        path: CommandPath,
        command: core.CommandProc,
        additional_modifiers: core.Modifiers = {},
    ),
}

@(private = "file")
METHODS :: RegistrationFactoryMethods{factory_register}

RegistrationFactory :: struct {
    using methods: RegistrationFactoryMethods,
    state:         ^core.EditorState,
    set_id:        int,
    modifiers:     core.Modifiers,
    allocator:     runtime.Allocator,
}

factory_create :: proc(
    state: ^core.EditorState,
    set_id: int,
    allocator := context.allocator,
) -> RegistrationFactory {
    return {state = state, set_id = set_id, methods = METHODS, allocator = allocator}
}

factory_register :: proc(
    factory: RegistrationFactory,
    path: CommandPath,
    command: core.CommandProc,
    additional_modifiers: core.Modifiers = {},
) {
    register(
        factory.state,
        factory.set_id,
        factory.modifiers + additional_modifiers,
        path,
        command,
        factory.allocator,
    )
}
