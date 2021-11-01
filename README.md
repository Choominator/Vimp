# Vimp

Vimp implements a modular screen-reader inside World of Warcraft.  It does so by leveraging the recently introduced text-to-speech API for add-ons which in turn relies on the host's operating system's speech capabilities.  At the moment it has generic code to read a lot of the game's user interface, even if not very efficiently for the user.  In the future I plan on adding specific modules to optimize the experience as well as add tools to aid in actual gameplay, within the bounds allowed by Blizzard's add-on sandbox.

To demonstrate the add-on in action, I've made a [video](https://youtu.be/DUgVrluiWd4), however it no longer reflects the current state of the add-on since the code has since been refactored and improved.

## Motivation

At one point in my life, playing World of Warcraft was one of my main hobbies. I ended up quitting the game in 2010, when the third expansion came out, because I was fed up with the community over the fact that pretty much everyone who played the game was learning strategies from outside sources instead of figuring things out by themselves, a problem which was causing me trouble finding raiding guilds even though I was generally considered a decent tank.

After going blind in 2014, and finding myself with more time in my hands than I could handle, I started craving this game again. I desperately wanted to play it but never actually tried because I couldn't figure out a way to have an acceptable degree of independence particularly with its user interface. Over the years I kept reading about people like [this guy](https://www.reddit.com/r/wow/comments/9w7mr1/guide_on_how_to_play_world_of_warcraft_blind/) who wound up even [beating people in arenas](https://dotesports.com/streaming/news/blind-wow-streamer-plays-pvp-with-no-monitor) without any sight, but there was one thing missing in my life that those blind players have: real life friends or relatives willing to assist them with everything that's not accessible in this game. My niece plays it sometimes but has an extremely busy life and doesn't commit enough so I cannot count on her most of the time.

Fast forward to the summer of 2021 and my niece said she wanted to return to the game during her holidays, which was when I learned that coincidentally Blizzard had just implemented a text-to-speech API in the add-on sandbox, so I went out on a quest to find out whether it was both possible and feasible to implement a screen-reading add-on, as the text-to-speech API is only being used by Blizzard to read chat at the moment.  To my surprise it ended up being very much possible, even if challenging sometimes, because the game was never intended to be played this way.

It is my hope that one day Blizzard themselves implement something like this in the default user interface thereby rendering this add-on obsolete, because unfortunately there's a lot that third-party add-ons cannot do.

## Installation

The easiest way to download this add-on is by visiting the [Releases](https://github.com/Choominator/Vimp/releases) page, where GitHub conveniently compresses tagged versions for easy distribution.  To install just decompress the downloaded file or clone this git repository in the `_retail_/Interface/AddOns` folder inside the folder where World of Warcraft is installed, which by default is `/Applications/World of Warcraft/_retail_/Interface/AddOns/` on MacOS or `C:\Program Files\World of Warcraft\_retail_\Interface\AddOns\` on Windows, and make sure that the add-on's folder is named exactly `Vimp` without the trailing version tag.  After that just launch the game and the add-on should be automatically activated.

## Setup

This add-on uses the same settings that are used to configure Blizzard's text-to-speech for chat, which at least in my installation of MacOS do not have sane defaults.  Blizzard's text-to-speech chat uses two configurable voices: one main and one alternative.  To configure the main voice, which is the one Vimp uses, just type `/tts voice id`, where id is a number representing the identification of the desired voice.  To configure the alternative voice, type the same command but with `altvoice` instead of `voice`.  The speech rate can be configured by typing `/tts speed value`, where a value of 0 means the default rate, lower values reduce the rate, and higher values increas it.  On my system, and as can be heard in the video linked above, I use the Samantha voice which has ID 11, and speed 3, however I'm not sure whether the IDs are the same for everyone.

## Key Bindings

This add-on overrides your key bindings by making its visual indicator the topmost frame on the screen and selectively consuming the keys that it uses for navigation.  I did it this way because that was the only way I could find to override key bindings in combat as well as because certain panes also consume keyboard input so I had to find a way to consume it first.

The keys that are used for navigation are as follows:

* `TAB` - Moves the cursor to the next element;
* `SHIFT-TAB` - Moves the cursor to the previous element;
* `CTRL-TAB` - Cycles through active interface windows;
* `SPACE` - Describes the element highlighted by the cursor;
* `ENTER` - Interacts with or activates the element highlighted by the cursor;
* `ESCAPE` - Moves the cursor to the container of the element highlighted by the cursor, or stops interacting with the element highlighted by the cursor;
* `LEFT`, `RIGHT`, `DOWN`, `UP` - Performs context-specific directional interactions with the element highlighted by the cursor;
* `CTRL` - Dequeues any text in the speech synthesizer's queues and stops speaking.

## Commands

Vimp creates the `/vimp` and `/vi` commands that can be used in macros with the following subcommands:

* `error` - Reads any script errors outloud for debugging purposes.  This command also focuses the error frame and highlights the error message so that pressing Command+C on MacOS or Control+C on Windows copies it to the clipboard.
* `mouse` - Toggles the reporting of any tooltips generated by hovering with the mouse over user interface or world objects.  This is useful to click on certain things that are not keyboard-targetable such as portals, chests, doors, pets, and the heads up display.
* `nav` - Reports a lot of information regarding your character's current status, location, and orientation.  This is probably worth adding to a macro for easy activation.
* `mark mnemonic` - Marks a location in the the current map for a later recall.  Marks are zone-specific, so just marking a bank in Stormwind as `bank` won't conflict with banks in other cities with the same mnemonic.
* `unmark mnemonic` - Unmarks a previously marked location in the current map.  This command only exists to prevent accidental replacement of a previously marked location.
* `recall mnemonic` - Recalls the closest marked location with the specified mnemonic or lists all the locations in case none are in the current continent.  This command also sets the current target location as if the `goto` command below was issued on it.
* `goto x y zone` - Tracks a location in the current or specified zone.  The zone argument is optional, and is tolerant to abbreviations and misspells.
* `dest` - Reports information about the distance and direction of the currently tracked location.  This might also be worth adding to a macro.  Originally I intended to issue these reports automatically every once in a while when the player is not in combat, but then figured that it might be annoying.

In addition, Blizzard makes available the `/tts stop` command which tells the text-to-speech synthesizer to stop speaking, clearing all the queued speech in the process, however due to a bug in Blizzard's own code, this works much better for Vimp's messages than for Blizzard's.

## Caveats

Since the add-on sandbox does not allow third-party add-ons to perform certain tasks, and since I haven't figured out a generic way to programmatically check which tasks cannot be performed, you are highly likely to run into warning dialogs stating that Vimp attempted to perform a protected action.  Attempting to exit the game using this add-on to click on the Exit Game button is an example of an action that causes this issue, however you can always exit by typing `/quit` in the chat text box, or `/camp` to log out.
