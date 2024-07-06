# Easy Sprite!

Hello! 👋 this is a strictly typed luau library aimed at being the most lightweight solution for 2D spritesheets!

It comes as two modules: EasySprite.luau and SpriteSequencer.luau

The former is the actual SpriteSheet handler, and the latter is a simple wrapper module
which allows you to playback animations at a chosen fps, by tying it to frame cycle events.

This decision was made as to not force users into the frame cycle events, in case they wish to implement their own.

## Usage
Using this library is very straightforward:

```lua
local rs = game:GetService('ReplicatedStorage')
local EasySprite, SpriteSequence = require(pathToEasySprite), require(pathToSpriteSequencer)

local mySpriteSheet = EasySprite.new(
	ImageLabel, --imagelabel instance
	'rbxassetid://00000000000', --assetId of the texture
	Vector2.new(700, 700), --pixel dimensions of the texture (width, height)
	Vector2.new(100, 100) --pixel cell size (width, height)
)

mySpriteSheet.display(1) --displays the first cell (counted from left to right)
mySpriteSheet.flip() --flips the spritesheet horizontally

mySequence = SpriteSequence.fromRange(mySpriteSheet, 1, 10) --create a sequence from cell 1 to 10
mySequence.play(framesPerSecond, isLooping) --play the sequence with chosen playback speed

task.wait(5)
mySequence.stop()
```
Under the hood, all EasySprite does is abstract the math used with ImageRectOffset and ImageRectSize necessary to
create the array of sprites.