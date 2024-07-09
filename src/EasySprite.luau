--!strict

--Version 1.1.1

type CellData = {
	offset: Vector2,
	url: string,
	size: Vector2
}

type SpriteSheet = {
	totalCells: number,
	currentCell: number,
	instance: ImageLabel,
	_frames: {CellData},
	
	display: (cellIndex: number) -> (),
	isFlipped: () -> (),
	flip: () -> (),
	extend: (sheet: SpriteSheet) -> ()
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
		assert(images[cellIndex], `index {cellIndex} out of range in spritesheet`)
		local cell = images[cellIndex]
		if label.Image ~= cell.url then label.Image = cell.url end
		if not sameVectors(label.ImageRectSize, cell.size) then label.ImageRectSize = cell.size end
		
		label.ImageRectOffset = 
			if spritesheet.isFlipped()
			then cell.offset - Vector2.xAxis*label.ImageRectSize.X
			else cell.offset
		
		spritesheet.currentCell = cellIndex
	end
	
	function spritesheet.flip()
		label.ImageRectSize = label.ImageRectSize * Vector2.new(-1, 1)
		spritesheet.display(spritesheet.currentCell)
	end
	
	function spritesheet.isFlipped()
		return label.ImageRectSize.X < 0
	end
	
	function spritesheet.extend(sheet)
		for _, cell in sheet._frames do
			images[#images+1] = cell
		end
		
		spritesheet.totalCells = #images
	end
	
	
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
	
	local images = {} :: {CellData}
	
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
