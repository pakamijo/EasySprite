--!strict
type SpriteImage = {
	url: string,
	width: number,
	height: number
}

type SpriteSheet = {
	display: (cell: number) -> (),
	isFlipped: () -> (),
	flip: () -> (),
	totalCells: number,
	currentCell: number,
	instance: ImageLabel
}

local constructor = {}

local function newSpriteSheet(images: {Vector2}, label: ImageLabel): SpriteSheet
	local spritesheet = {} :: SpriteSheet
	spritesheet.totalCells = #images
	spritesheet.instance = label
	
	function spritesheet.display(cell)
		assert(images[cell], `index {cell} out of range in spritesheet`)
		
		label.ImageRectOffset = 
			if spritesheet.isFlipped()
			then images[cell] - Vector2.xAxis*label.ImageRectSize.X
			else images[cell]
		
		spritesheet.currentCell = cell
	end
	
	function spritesheet.flip()
		label.ImageRectSize = label.ImageRectSize * Vector2.new(-1, 1)
		spritesheet.display(spritesheet.currentCell)
	end
	
	function spritesheet.isFlipped()
		return label.ImageRectSize.X < 0
	end
	
	spritesheet.display(1)
	
	return spritesheet
end

function constructor.new(label: ImageLabel, assetUrl: string, imgSize: Vector2, cellSize: Vector2)
	assert(label:IsA('ImageLabel'), "Instance must be an ImageLabel")
	
	local columns, rows
	do
		local ratio = imgSize/cellSize
		columns, rows = ratio.X, ratio.Y
	end
	
	label.Image = assetUrl
	label.ImageRectSize = cellSize
	label.ImageRectOffset = Vector2.zero
	
	local images: {Vector2} = {}
	
	do --create image array from grid
		local y = 0
		repeat
			local x = 0
			repeat
				images[y*rows + x+1] = Vector2.new(cellSize.X*x, cellSize.Y*y)
				x += 1
			until x >= columns
			y += 1
		until y >= rows
	end
	
	return newSpriteSheet(images, label)
end

return constructor
