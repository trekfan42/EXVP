# EXVP
 External Video Player app for Windows


This is a simple Video Player designed for windows to be used in Live Production. 

It features a simple easy to use interface for playing out Videos, Still images, Audio files and Slideshows (folders filled with pictures) onto a connected fullscreen Extended Monitor.

It currently supports Fullscreen extended monitor playback as well as NDI output.
If I can build a plguin for Godot I will also attempt Decklink output.

The App supports saving and loading playlists.

Currently FFMPEG is used to decode videos, CPU decode only. A VLC plugin is in testing as well as several other playback engines.

This codebase is exteremely messy, I was learning Godot at the same time I built this, caution ye who fork...


## Requirements:

You will need the following addons to open the project:

- https://github.com/Tattomoosa/Spinner/
- https://github.com/KoBeWi/Godot-Slider-Label
- https://github.com/FoolLin/ReorderableContainer
- https://github.com/98teg/NativeDialogs
- https://github.com/unvermuthet/godot-ndi
- https://github.com/EIRTeam/EIRTeam.FFmpeg
- https://github.com/trekfan42/BoxHandle

## Exporting:

Due to current Video decoding plugin limitations, only Windows is supported for now.
