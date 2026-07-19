--!strict
--!native

--Version 1.5.0

type CellData = {
	offset: Vector2,
	url: string,
	size: Vector2
}

type SpriteSheet = {
	--[[
		@deprecated use self.size() instead
	]]
	totalCells: number,

	currentCell: number,

	instance: ImageLabel,

	_frames: {CellData},
	
	display: (cellIndex: number) -> (),

	--[[
		@deprecated use self.isMirroredX() instead
	]]
	isFlipped: () -> boolean,

	isMirroredX: () -> boolean,

	isMirroredY: () -> boolean,

	--[[
		@deprecated use self.mirrorX() instead
	]]
	flip: () -> (),

	mirrorX: () -> (),

	mirrorY: () -> (),

	extend: (sheet: SpriteSheet) -> (),

	length: () -> number,

	destroy: () -> (),
	Destroy: () -> (),
}

local constructor = {}

local function sameVectors(v1: Vector2, v2: Vector2)
	return v1.X^2 == v2.X^2 and v1.Y^2 == v2.Y^2
end

local function newSpriteSheet(images: {CellData}, label: ImageLabel): SpriteSheet
	local spritesheet = {} :: SpriteSheet
	spritesheet.totalCells = #images
	spritesheet.instance = label
	spritesheet._frames = images
	
	function spritesheet.display(cellIndex)
		if not images[cellIndex] then error(`index {cellIndex} out of range in spritesheet`) end
		local cell = images[cellIndex]
		if label.Image ~= cell.url then label.Image = cell.url end
		if not sameVectors(label.ImageRectSize, cell.size) then label.ImageRectSize = cell.size end
		
		label.ImageRectOffset = 
			Vector2.new(
				if spritesheet.isMirroredX() then cell.offset.X - label.ImageRectSize.X else cell.offset.X,
				if spritesheet.isMirroredY() then cell.offset.Y - label.ImageRectSize.Y else cell.offset.Y
			)

		spritesheet.currentCell = cellIndex
	end
	
	function spritesheet.flip()
		spritesheet.mirrorX()
	end

	function spritesheet.mirrorX()
		label.ImageRectSize = label.ImageRectSize * Vector2.new(-1, 1)
		spritesheet.display(spritesheet.currentCell)
	end
	
	function spritesheet.mirrorY()
		label.ImageRectSize = label.ImageRectSize * Vector2.new(1, -1)
		spritesheet.display(spritesheet.currentCell)
	end

	function spritesheet.isFlipped()
		return spritesheet.isMirroredX()
	end
	
	function spritesheet.isMirroredX()
		return label.ImageRectSize.X < 0
	end

	function spritesheet.isMirroredY()
		return label.ImageRectSize.Y < 0
	end

	function spritesheet.extend(sheet)
		for _, cell in sheet._frames do
			images[#images+1] = cell
		end
		--deprecated functionality
		spritesheet.totalCells = #images
	end
	
	function spritesheet.length()
		return #images
	end

	function spritesheet.destroy()
		spritesheet.instance = nil :: any
		table.clear(images)
		table.clear(spritesheet)

		--poison table for debugging (use after free)
		setmetatable(spritesheet :: any, {
            __index = function(_, key)
                error(`Attempt to access {key} on a destroyed SpriteSheet`, 2)
            end,
            __newindex = function()
                error("Attempt to modify a destroyed SpriteSheet", 2)
            end
        })
	end
	spritesheet.Destroy = spritesheet.destroy
	
	spritesheet.display(1)
	return spritesheet
end

function constructor.new(label: ImageLabel, assetUrl: string, imgSize: Vector2, cellSize: Vector2)
	assert(label:IsA('ImageLabel'), "Instance must be an ImageLabel")
	
	local columns, rows
	do
		local ratio = imgSize/cellSize
		columns, rows = math.floor(ratio.X), math.floor(ratio.Y)
	end
	
	label.Image = assetUrl
	label.ImageRectSize = cellSize
	label.ImageRectOffset = Vector2.zero
	
	local images = table.create(columns*rows) :: {CellData}
	
	do --create image array from grid
		local y = 0
		repeat
			local x = 0
			repeat
				images[y*columns + x+1] = {
					offset = Vector2.new(cellSize.X*x, cellSize.Y*y),
					url = assetUrl,
					size = cellSize
				}
				x += 1
			until x >= columns
			y += 1
		until y >= rows
	end
	
	return newSpriteSheet(images, label)
end

return constructor
