package example_config

import "core:os"
import "core:strings"

// bred:core has all of the core type definitions for the editor
import "bred:core"
// bred:core's sub-modules are where actual behavior is defined for the core types
import "bred:core/buffer"
import "bred:core/command"
import "bred:core/font"
import "bred:core/layout"
import "bred:core/portal"
// bred:builtin provides a few builtin in tools to help you create your configuration faster
import "bred:builtin/commands"
import "bred:builtin/components/file_editor"
import "bred:builtin/components/status_bar"

// I recommend that you store your layout & command set IDs in global variables
LAYOUT_SINGLE: int
LAYOUT_V_SPLIT: int
CMD_FILE: int

// The init function is called on editor start-up
// This is where you should initialize your layouts, command sets, and keybindings
init :: proc(state: ^core.EditorState) {
    // Currently bred only supports displaying the entire screen with one font at one size
    // This is where we load our font of choice. This path is relative to the executable
    // The size is in pixels
    font.load("CodeNewRomanNerdFontMono-Regular.otf", 36)

    {     // --- LAYOUT CREATION ---
        // The layout type is a discriminated union of core.PortalDefinition & core.Split
        // PortalDefinitions are just functions that take a core.Rect and construct a core.Portal
        // Here we are defining an alias which is properly typed to our file editor portal definition
        STATUS_BAR := core.PortalDefinition(status_bar.create_status_bar)
        FILE := core.PortalDefinition(create_file_portal)

        single_file := layout.create_absolute_split(.Bottom, 1, FILE, STATUS_BAR)
        LAYOUT_SINGLE := layout.register_layout(state, single_file)

        // The layout library contains useful functions for constructing layouts using a nested
        // tree of functions. You can take a look at all of them in src/core/layout/build.odin
        // And if you create a new function that will help build more versatile layouts, please submit a PR
        v_split := layout.create_absolute_split(
            .Bottom,
            1,
            layout.create_percent_split(.Right, 50, FILE, FILE),
            STATUS_BAR,
        )
        LAYOUT_V_SPLIT := layout.register_layout(state, v_split)
    }

    {     // --- COMMAND SET REGISTRATION ---
        // Command sets are used to link a group of commands which can be used in a
        // specific editor context. This configuration has two command sets, the global set
        // which is provided by default and the file editor context we are registering here.
        // This command set is linked to each file portal we create, giving access to any commands
        // in this set when a file portal is our active portal
        CMD_FILE := command.register_command_set(state)
    }

    {     // --- COMMAND REGISTRATION ---

        // Each command registration requires the following:
        //                      command set,       modifiers, motion,  and command procedure
        command.register(state, command.GLOBAL_SET, {.Ctrl}, {.LEFT}, commands.previous_portal)
        command.register(state, command.GLOBAL_SET, {.Ctrl}, {.RIGHT}, commands.next_portal)

        // The available modifiers are Ctrl, Shift, and Alt
        // For a list of available keys to include in your motions
        // take a look at the KeyboardKey enum in vendor:raylib/raylib.odin:555
        // Unlike other modal editors, motions are not case-sensitive. Instead Shift is applied
        // as a modifier to the entire motion.

        // For creating multiple command registrations, the above syntax gets very repetitive
        // So in bred:core/command there is a utility struct called RegistrationFactory which
        // you can use to register multiple similar commands quickly. Here, we create one to
        // register commands in our file editor command set:
        factory := command.factory_create(state, CMD_FILE)

        // By default bred has 0 keybindings. Any action you would like to take will need to
        // be registered manually. Some core commands that you will probably want are provided
        // in bred:builtin/commands
        factory->register({.LEFT}, file_editor.move_cursor_left)
        factory->register({.RIGHT}, file_editor.move_cursor_right)
        factory->register({.UP}, file_editor.move_cursor_up)
        factory->register({.DOWN}, file_editor.move_cursor_down)
        factory->register({.BACKSPACE}, commands.delete_behind)
        factory->register({.DELETE}, commands.delete_ahead)

        // Along with keyboard keys, motions can include wildcards (either .Char or .Num)
        // The char wildcard will match one key which has a single character textual representation
        // (it will not match Enter, Shift, Delete, or other command keys, but will match letters,
        //  numbers and symbols)
        // The num wildcard will match any number of consecutive digit keys to create a single number.
        // If your command takes multiple numbers, those number wildcards need to be separated by another key.
        factory->register({.Char}, commands.insert_character)

        // You can add a modifier to a single command by supplying it at the end of the factory register method
        factory->register({.Char}, commands.insert_character, {.Shift})

        // NOTE: Enter does not count as a Wildcard.Char and needs to be declared separately
        factory->register({.ENTER}, commands.insert_line)

        // For creating multiple keybindings with the same modifier, you can add the modifier
        // to the factory
        factory.modifiers = {.Ctrl}
        factory->register({.H}, file_editor.move_cursor_left)
        factory->register({.L}, file_editor.move_cursor_right)
        factory->register({.K}, file_editor.move_cursor_up)
        factory->register({.J}, file_editor.move_cursor_down)
        factory->register({.Num, .H}, file_editor.move_cursor_left)
        factory->register({.Num, .L}, file_editor.move_cursor_right)
        factory->register({.Num, .K}, file_editor.move_cursor_up)
        factory->register({.Num, .J}, file_editor.move_cursor_down)

        // Bred's buffers have native undo/redo support. However, note that if you create commands that
        // alter the buffer, you have to call buffer.start_history_state before making your edits &
        // buffer.write_to_history after making your edits for those edits to work with the undo/redo system
        factory->register({.Z}, commands.undo)
        factory->register({.Z}, commands.redo, {.Shift})
    }

    {     // --- FILE OPENING ---

        // Here we pull a file path from the application's arguments to open as a buffer
        assert(len(os.args) >= 2, "Must provide file path to open as application argument")
        buffer_id, ref := buffer.create(state)

        // The buffer takes ownership of the file_path upon loading
        load_ok := buffer.load_file(ref, strings.clone(os.args[1]))
        assert(load_ok, "Failed to load test file")

        // Our config must either create a portal manually or activate a layout before the init function returns
        layout.activate_layout(state, LAYOUT_SINGLE)

        // Once we have created a portal & a buffer, we can assign the buffer to the portal to have it display on screen
        state.portals[0].buffer = buffer_id

        // NOTE: Bred does not currently have a built-in component for opening files at runtime. However, I have one in my
        // config which you can take a look at for an example: https://github.com/Pingar5/bred-config/blob/master/components/file_browser
    }
}

// Here we wrap the native file editor portal definiton with our own portal definition to add
// our file editor command set
create_file_portal :: proc(rect: core.Rect) -> (p: core.Portal) {
    p = file_editor.create_file_portal(rect)
    p.command_set_id = CMD_FILE
    return
}
