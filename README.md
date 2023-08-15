# Save Made Easy - A simple, diverse Save/Load plugin for Godot 4
An easy to use, versatile Save/Load System inspired by the simplicity of Unity's PlayerPrefs. Supports nested variables, Resources and encryption.
I've browsed multiple forum sites and checked the Asset Library, only to find out there are no plugins made to simplify saving data really, while this is default built-in functionality in Unity.
New programmers (and people who don't want to spend too much time coding) shouldn't have to struggle with save systems, as they are quite finicky to debug if something is not set up right in the core code. Thus, here we go.
This compact plugin stores all the data in an encrypted save file (encoded with the player's unique OS ID - meaning, players cannot exchange save files), which is automatically loaded at start-up.

# Instructions
1. Download the plugin from the Godot Asset Library or the zip file of this repo by clicking on "Code", and the "Local" menu. You should see a "Download ZIP" option.
2. If you downloaded manually, place the addons/save_system file into your project directory, ideally into a folder called "addons".
3. Go to Godot's Plugins tab (Project -> Project Settings -> Plugins) and tick "Enable" by the plugin. (If the plugin doesn't show up, you may need to restart the editor.)
4. You're good to go! Don't forget to read the documentation. You can modify the save file name ("const file_name") at the top of the SaveSystem.gd script.

# Contact
If you have any questions/concerns or just wanna say hi, you can message me on Twitter or add me on Discord. My handle is olcgreen on both.

# Documentation
While you can find complete documentation in the plugin code, let me highlight the most important functions:
- set_var(key_path, value): **Use this for storing a variable.**
- get_var(key_path, default): **Use this for retrieving a variable.** If the variable at "key_path" doesn't exist, "default" is returned.
- delete(key_path): **Deletes variable at "key_path".**
- delete_all: **Deletes all data.** (Still need to call save() for the file to be overwritten.)
- has(key_path): **Checks if a variable exists at "key_path".**
- save: **Use this to save data and write the file.**
You can also notice functions intended for internal use begin their names with an underscore in the code.

# Demonstration
_Here's a class of our Resource created for testing this system:_


![Screenshot_43](https://github.com/AdamKormos/SaveMadeEasy/assets/49873113/d9547f06-9253-4005-9e3b-989ca69e92f3)

_You may use the set_var and get_var variables of the SaveSystem Singleton for the core functionality: (This code sample can be found in SaveSystem.gd)_

![Screenshot_41](https://github.com/AdamKormos/SaveMadeEasy/assets/49873113/f860e709-c108-4ebc-a0f8-c18e3e7925af)

**Nesting is expressed by the colon symbol (:). You may also access dictionary values with this notation.**
