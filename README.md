# Vimp

Vimp implements a screen-reader inside World of Warcraft.  It does so by leveraging the recently introduced text-to-speech API to the add-on sandbox which in turn relies on the host's operating system's speech capabilities.  At the moment it has generic code to read pretty much every pane in the game, even if not very efficiently for the user.  In the future I plan on adding pane-specific modules to optimize the experience as well as add tools to aid in actual gameplay, within the bounds allowed by Blizzard's add-on sandbox.

## Motivation

I stopped playing World of Warcraft in 2010, shortly before Cataclysm came out and for reasons unrelated to my sight.  In 2014 I went totally blind and became extremely bored.  I really wanted to return to the game but couldn't find a way to do it with enough autonomy because although it is possible to follow other players around thereby using them as guides, it was nearly impossible to interact with the game's user interface locally without sighted assistance.  Recently Blizzard added a text-to-speech API to the add-on sandbox, so once I learned about that I decided to investigate the possibility and feasibility of building a screen-reader inside the game, which to my surprise was very much possible and not very hard.

I don't know if I will end up playing the game myself, but I've heard of other blind players who have been doing it for quite some time, so even if I don't end up benefiting from this, the mere thought that I can contribute to someone else's happiness, as well as having a project to work on, are enough reasons for me to feel happy and motivated.

## Installation

I do not recommend installing this add-on just yet, and therefore I haven't published any release versions.  However if you do really want to try this out you can clone this repository into the `_retail_/Interface/AddOns` folder that can be found inside the folder where World of Warcraft is installed.  After that just launch the game and the add-on should be automatically activated.

## Setup

This add-on uses the same settings that are used to configure Blizzard's text-to-speech for chat, which at least in my installation of MacOS do not have sane defaults.  Blizzard's text-to-speech chat uses two configurable voices: one main and one alternative.  To configure the main voice, which is the one Vimp uses, just type `/tts voice id`, where id is a number representing the identification of the desired voice.  To configure the alternative voice, type the same command but with `altvoice` instead of `voice`.  The speech rate can be configured by typing `/tts speed value`, where a value of 0 means the default rate, lower values reduce the rate, and higher values increas it.

The default key bindings for this add-on are the left and right brackets for moving to the previous and next elements respectively, the apostrophe to read the currently selected element, shift plus the left and right brackets to decrement and increment values, and shift plus apostrophe to activate an element.  These key bindings work well on an American keyboard but might not work on other layouts, and they are only set if there's nothing else bound to the same keys, so you might need to change them using the in-game user interface or writing them directly to your account's `bindings-cache.wtf` file, using the actions defined in the `Bindings.xml` file in the add-on's root folder.

## Caveats

Since the add-on sandbox does not allow third-party add-ons to perform certain tasks, and since I haven't figured out a generic way to programmatically check which tasks cannot be performed, you are highly likely to run into warning dialogs stating that Vimp attempted to perform a protected action.  Attempting to exit the game using this add-on to click on the Exit Game button is known to cause this issue, however you can always exit by typing `/quit` in the chat text box, or `/camp` to log out.
