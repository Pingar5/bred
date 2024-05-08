# Bred
Bred is a text editor engine (think game engine, but for text editors). Use it to create your own custom text editor that meets your needs and your needs only.

## Building & Installation
There are no pre-built versions of Bred because it comes with 0 keybindings out of the box. Without the user configuration (which is compiled into the executable) it will simply crash as soon as open the program.

To get started, I recommend you read through the example config in /example/config/config.odin. It will walk you through the basics of creating a config file. You can then copy that file into a folder called /user/config or create your own file from scratch in that directory!

Once you have created a configuration file that loads a font, creates a portal, and registers some keybindings. You can run the following command to build your new editor! (If you prefer it, you can run the build with -vet and -strict-style, the engine itself is built with those two turned on, so you will not run into any issues turning them on)

```odin
odin build src -out:.build/editor.exe -collection:bred=src -collection:user=user
```