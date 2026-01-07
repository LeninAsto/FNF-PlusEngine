![Logo Off](docs/img/PlusEngineLogo.png)

[![Build](https://github.com/LeninAsto/FNF-PlusEngine/actions/workflows/main.yml/badge.svg)](https://github.com/LeninAsto/FNF-PlusEngine/actions/workflows/main.yml)
[![VirusTotal Scan](https://github.com/LeninAsto/FNF-PlusEngine/actions/workflows/virustotal.yml/badge.svg)](https://github.com/LeninAsto/FNF-PlusEngine/actions/workflows/virustotal.yml)
![Security](https://img.shields.io/badge/security-scanned-brightgreen?logo=virustotal)

[![GitHub stars](https://img.shields.io/github/stars/LeninAsto/FNF-PlusEngine?style=social)](https://github.com/LeninAsto/FNF-PlusEngine/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/LeninAsto/FNF-PlusEngine?style=social)](https://github.com/LeninAsto/FNF-PlusEngine/network/members)
[![GitHub watchers](https://img.shields.io/github/watchers/LeninAsto/FNF-PlusEngine?style=social)](https://github.com/LeninAsto/FNF-PlusEngine/watchers)

[![License](https://img.shields.io/github/license/LeninAsto/FNF-PlusEngine)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/LeninAsto/FNF-PlusEngine)](https://github.com/LeninAsto/FNF-PlusEngine/releases)
[![GitHub issues](https://img.shields.io/github/issues/LeninAsto/FNF-PlusEngine)](https://github.com/LeninAsto/FNF-PlusEngine/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/LeninAsto/FNF-PlusEngine)](https://github.com/LeninAsto/FNF-PlusEngine/pulls)
[![GitHub contributors](https://img.shields.io/github/contributors/LeninAsto/FNF-PlusEngine)](https://github.com/LeninAsto/FNF-PlusEngine/graphs/contributors)

Engine based in Psych 1.0.4 with modcharts like NotITG and compatible with hxcodec videos from Psych mods 0.6.3 and 0.7.3.

## Contributors

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/LeninAsto">
        <img src="https://github.com/LeninAsto.png" width="100px;" alt="LeninAsto"/>
        <br />
        <sub><b>Lenin Asto</b></sub>
      </a>
      <br />
      <sub>Main Developer</sub>
    </td>
    <td align="center">
      <a href="https://github.com/sirthegamercoder">
        <img src="https://github.com/sirthegamercoder.png" width="100px;" alt="Username2"/>
        <br />
        <sub><b>MTGC</b></sub>
      </a>
      <br />
      <sub>Indonesian translation and other PRs</sub>
    </td>
  </tr>
</table>

## Special Thanks

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/Slushi-GitHub">
        <img src="https://github.com/Slushi-Github.png" width="100px;" alt="Slushi-GitHub"/>
        <br />
        <sub><b>Slushi GitHub</b></sub>
      </a>
      <br />
      <sub>Creator of several used Slushi Engine codes</sub>
    </td>
  </tr>
    <td align="center">
      <a href="https://www.facebook.com/hansuke.hotaroshi">
        <img src="https://raw.githubusercontent.com/Psych-Plus-Team/FNF-PlusEngine/d98e506ac8d567d1731e4652bc120887aff4376c/assets/shared/images/credits/hansu.png" width="100px;" alt="Hansu"/>
        <br />
        <sub><b>Hansuke H</b></sub>
      </a>
      <br />
      <sub>Vietnamese translation and alphabet sprite</sub>
    </td>
  </tr>
</table>

Contributions are welcome! If you have ideas, improvements, or fixes, feel free to fork the repo and open a pull request.

> This project is subject to bugs, fixes, improvements and changes.

## Developer Credits:
* Lenin Asto - Main Programmer for Plus Engine

## Original Credits:
* Shadow Mario - Main Programmer and Head of Psych Engine.
* Riveren - Main Artist/Animator of Psych Engine.

## Mobile Credits:
* Homura - Head Porter of Psych Engine Mobile.
* Karim - Second Porter of Psych Engine Mobile.
* Moxie - Helper of Psych Engine Mobile.

## Special Thanks
* bbpanzu - Ex-Team Member (Programmer).
* crowplexus - HScript Iris, Input System v3, and Other PRs.
* Kamizeta - Creator of Pessy, Psych Engine's mascot.
* MaxNeton - Loading Screen Easter Egg Artist/Animator.
* Keoiki - Note Splash Animations and Latin Alphabet.
* SqirraRNG - Crash Handler and Base code for Chart Editor's Waveform.
* EliteMasterEric - Runtime Shaders support and Other PRs.
* MAJigsaw77 - .MP4 Video Loader Library (hxvlc).
* iFlicky - Composer of Psync, Tea Time and some sound effects.
* KadeDev - Fixed some issues on Chart Editor and Other PRs.
* superpowers04 - LUA JIT Fork.
* CheemsAndFriends - Creator of FlxAnimate.
* Ezhalt - Pessy's Easter Egg Jingle.
* MaliciousBunny - Video for the Final Update.

***

# Build Mobile:
You need to have:

- Android Build Tools / Android Command Line Tools
- Android SDK 35
- Android NDK r27d
- Java JDK 17

# Features before 1.0.4

- Variables for window and system management in Lua: Many variables were added, whether to hide the taskbar or window borders, etc.
- Key Viewer
- Modchart settings.
- New Gameplay Changers (Opponent Mode, No Drop Penalty, Perfect Only).
- You can choose your default accuracy system. ITG, Psych, DJMax, Wife3, osu!, Simple
- Added the songs "erect" and "nightmare," BUT without stages and events, only levels
* Support for NotITG levels (without modifiers) and Stepmania, includes UI
![Stepmania](docs/img/Stepmania.png)
- Android support
- Added the "miss" and "combo broken" sprites
- Added the option for "bad" and "shit" to break the combo
- New VideoSprite functionality with optimized hxvlc
- New shader compatibility depending on your graphics card
- Judgement Counter.
- Advanced variables in Lua for the craziest Modcharts.
- New results State and really cool.
- Compatible wth hxcodec videos from Psych mods 0.6.3 and 0.7.3.
- Smooth Health Bar
* +5 Languages availables
![Languages](docs/img/Languages.png)
- New cool transicioning
- If you are in Charting Mode the step, beat, and section will be displayed in gameplay.
- FPS Counter rework
- Trace in Game
- Rework the OutdatedSubstate.hx
* Rework the FreeplayState.hx
![Freeplay](docs/img/Freeplay.png)
![Freeplay Diff](docs/img/FreeplayDiff.png)
- More things will continue to be added in the future...

# Main Features

## Attractive animated dialogue boxes:

![Animated Dialogue Boxes](docs/img/dialogue.gif)

## New Main Menu
* A brand new menu that makes your experience even better!
![Main Menu](docs/img/MainMenu.png)

## Mod Support
* Probably one of the main points of this engine, you can code in .lua files outside of the source code, making your own weeks without even messing with the source!
* Comes with a Mod Organizing/Disabling Menu.
![Mod Support](docs/img/ModsMenu.png)


## Atleast one change to every week:
### Week 1:
  * New Dad Left sing sprite
  * Unused stage lights are now used
  * Dad Battle has a spotlight effect for the breakdown
### Week 2:
  * Both BF and Skid & Pump does "Hey!" animations
  * Thunders does a quick light flash and zooms the camera in slightly
  * Added a quick transition/cutscene to Monster
### Week 3:
  * BF does "Hey!" during Philly Nice
  * Blammed has a cool new colors flash during that sick part of the song
### Week 4:
  * Better hair physics for Mom/Boyfriend (Maybe even slightly better than Week 7's :eyes:)
  * Henchmen die during all songs. Yeah :(
### Week 5:
  * Bottom Boppers and GF does "Hey!" animations during Cocoa and Eggnog
  * On Winter Horrorland, GF bops her head slower in some parts of the song.
### Week 6:
  * On Thorns, the HUD is hidden during the cutscene
  * Also there's the Background girls being spooky during the "Hey!" parts of the Instrumental

## Cool new Chart Editor changes and countless bug fixes
![Chart Editor](docs/img/chart.png)
* You can now chart "Event" notes, which are bookmarks that trigger specific actions that usually were hardcoded on the vanilla version of the game.
* Your song's BPM can now have decimal values
* You can manually adjust a Note's strum time if you're really going for milisecond precision
* You can change a note's type on the Editor, it comes with five example types:
  * Alt Animation: Forces an alt animation to play, useful for songs like Ugh/Stress
  * Hey: Forces a "Hey" animation instead of the base Sing animation, if Boyfriend hits this note, Girlfriend will do a "Hey!" too.
  * Hurt Notes: If Boyfriend hits this note, he plays a miss animation and loses some health.
  * GF Sing: Rather than the character hitting the note and singing, Girlfriend sings instead.
  * No Animation: Character just hits the note, no animation plays.

## Multiple editors to assist you in making your own Mod
![Master Editor Menu](docs/img/editors.png)
* Working both for Source code modding and Downloaded builds!

## Story mode menu rework:
![Story Mode Menu](docs/img/storymode.png)
* Added a different BG to every song (less Tutorial)
* All menu characters are now in individual spritesheets, makes modding it easier.

## Credits menu
![Credits Menu](docs/img/credits.png)
* You can add a head icon, name, description and a Redirect link for when the player presses Enter while the item is currently selected.

## Awards/Achievements
* The engine comes with 16 example achievements that you can mess with and learn how it works (Check Achievements.hx and search for "checkForAchievement" on PlayState.hx)
![Achievements](docs/img/Achievements.png)

## Options menu:
* You can change Note colors, Delay and Combo Offset, Controls and Preferences there.
 * On Preferences you can toggle Downscroll, Middlescroll, Anti-Aliasing, Framerate, Low Quality, Note Splashes, Flashing Lights, etc.
![Options](docs/img/Options.png)

## Other gameplay features:
* When the enemy hits a note, their strum note also glows.
* Lag doesn't impact the camera movement and player icon scaling anymore.
* Some stuff based on Week 7's changes has been put in (Background colors on Freeplay, Note splashes)
* You can reset your Score on Freeplay/Story Mode by pressing Reset button.
* You can listen to a song or adjust Scroll Speed/Damage taken/etc. on Freeplay by pressing Space.
* You can enable "Combo Stacking" in Gameplay Options. This causes the combo sprites to just be one sprite with an animation rather than sprites spawning each note hit.


#### Psych Engine by ShadowMario, Friday Night Funkin' by ninjamuffin99
