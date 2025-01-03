# Save Made Easy - A simple, diverse Save/Load plugin for Godot 4
An easy to use, versatile Save/Load System inspired by the simplicity of Unity's PlayerPrefs. Supports nested variables, Resources and encryption.

I've browsed multiple forum sites and checked the Asset Library, only to find out there are no plugins made to simplify saving data really, while this is default built-in functionality in Unity.

New programmers (and people who don't want to spend too much time coding) shouldn't have to struggle with save systems, as they are quite finicky to debug if something is not set up right in the core code. Thus, here we go.

This compact plugin stores all the data in an encrypted save file (encoded with the player's unique OS ID - meaning, players cannot exchange save files), which is automatically loaded at start-up.  


# Instructions
1. **Download the plugin**: from the <ins>Godot Asset Library</ins> **or** the zip file of this repo by clicking on "Code", and the "Local" tab. You should see a "Download ZIP" option.
2. **If you downloaded manually**, place the addons/save_system file into your project directory, ideally into a folder called "addons".
3. **Enable the plugin**: Go to Godot's Plugins tab (Project -> Project Settings -> Plugins) and tick "Enable" by the plugin. (If the plugin doesn't show up, you may need to restart the editor.)
4. **Set the SaveSystem AutoLoad as the first one in the boot order** by going to Project -> Project Settings -> AutoLoad. This ensures other AutoLoads relying on it will already have the Save System loaded by the time they are initialized.
5. You're good to go! **Don't forget to read the documentation.** You can modify the save file name (`const file_name`) at the top of the **SaveSystem.gd** script.

*Note: You may want to visit Project -> Project Settings -> AutoLoads and make the SaveSystem AutoLoad be the very first one that boots, to allow other AutoLoads to work with the plugin at start-up. You can do this by dragging it to the top of the AutoLoad list.*

# Limitations
- You generally shouldn't use **numerals** as whole Dictionary keys (123), or at the beginning (12mykey), unless you have the perform_typecast_on_dictionary_keys constant boolean set to false. (At the top of the script.) This is because if it's true, the plugin saves the Dictionary key as a numeral, but you can only access keys via Strings, considering the key path nesting. (In this case, when accessing keys, you also have to stringify your input key. -- TODO: Automatically handle this conversion, maybe log it.)

# Contact
If you have any questions/concerns or just wanna say hi, you can message me on [Twitter](https://twitter.com/olcgreen) or add me on Discord. My handle is olcgreen on both.


# Documentation
While you can find complete documentation in the plugin code, let me highlight the most important functions:
- `set_var(key_path, value)`: **Use this for storing a variable.**
- `get_var(key_path, default)`: **Use this for retrieving a variable.** If the variable at `key_path` doesn't exist, `default` is returned.
- `delete(key_path)`: **Deletes variable at `key_path`.**
- `delete_all`: **Deletes all data.** (Still need to call `save()` for the file to be overwritten.)
- `has(key_path)`: **Checks if a variable exists at `key_path`.**
- `save`: **Use this to save data and write the file.**

You can also notice functions intended for internal use begin their names with an underscore in the code.

> [!NOTE]
> Your save file will go into what Godot refers to as the `user://` directory.  
> On Windows, this is `C:\Users\UserName\AppData\Roaming\Godot\app_userdata`.  
> More at [Godot's official docs](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html).


# Demonstration
_Here's a class of our Resource created for testing this system:_

```GDScript
class_name TestResource extends Resource

var a
var b
var c
var d = {"z": 54}
```

_You may use the `set_var` and `get_var` variables of the **SaveSystem Singleton** for the core functionality: (This code sample can be found in **SaveSystem.gd**)_

```GDScript
set_var("Bob", TestResource.new())
set_var("Bob:a", TestResource.new())
set_var("Bob:a:b", 3)

print(get_var("Bob:a:d))
print(has("Bob"))
```
Prints:
```
{ "z": 54 }
true
```

**Nesting is expressed by the colon symbol (`:`). You may also access dictionary values with this notation.**


# Support
If you like my work and wanna support me, please consider checking out my [YouTube](https://www.youtube.com/@AdamsGodotTutorials) channel, which has a handful of tutorials - with more to come as time goes on!

I also have a [Discord](https://discord.gg/vhpYfYZSWh) server for my community, you're welcome to hop in. :)

Aaand last but not least, I'm working on games too. Wishlists are appreciated! [Pik The Archon](https://store.steampowered.com/app/3373330/Pik_the_Archon/) is my 3D beat 'em up-platformer hybrid with mount-and-combat (I also have a [Discord community](https://discord.gg/taTX4bAe5n) for it), [Odyssey of Dremid'ir](https://store.steampowered.com/app/2134530/Odyssey_of_Dremidir/) is a hand-drawn RPG, and [Frieseria](https://store.steampowered.com/app/2591170/Frieseria_The_Grand_Reopening/) is a restaurant management game.
