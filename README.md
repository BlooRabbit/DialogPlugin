# DialogPlugin
Godot plugin for creating dialog jsons

This Godot plugin is designed to create json files containing dialogs, based on a visual nodes system.

The json files are in the format designed by Levrault for his standalone editor, which can be found here, along with a lot of explanations: https://github.com/Levrault/LE-dialogue-editor. Please note that there may be some compatibility issues with his editor, though, as I added some stuff to the json files.

**Use**

The visual node system allows for dialog nodes, conditional nodes, choice nodes and signals nodes.

Start by creating a "new file", which will add a root node. Then plugin whatever other nodes you want. "print" prints out the json to your console.
Don't forget to save your file !

The plugin currently supports two languages, but it is pretty easy to add other languages, once you understand the way it works.

The json files can be read, for example, by the gdscript called "DialogueManager.gd" I am providing in this github folder. This reader is based on simplified choices "OK" and "NO", but you can easily change this.    

**Install**

Just install the plugin in the addon folder and enable it in the Godot editor settings. Use and customize the DialogManager.gd script to read the files, or make your own.

The plugin is work in progress. It is still pretty raw and I will probably add more features in the future.

https://user-images.githubusercontent.com/56018661/127719492-557f85c4-ca9a-445c-8da9-7116be51db3c.mp4



