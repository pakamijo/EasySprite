--!strict
local RunService = game:GetService('RunService')

type SpriteSheet = {
	display: (cell: number) -> (),
	isFlipped: () -> (),
	flip: () -> (),
	totalCells: number,
	currentCell: number,
	instance: ImageLabel
}

type Sequence = {
	looping: boolean,
	cells: {number},
	framerate: number,
	
	play: (fps: number, looping: boolean?) -> (),
	stop: () -> (),
	_nextFrame: (now: number) -> (),
	
}

local MAX_FPS = 60

local activeSequences: {[ImageLabel]: Sequence} = {}

do
	local scheduler = if RunService:IsClient() then 'RenderStepped' else 'Heartbeat'
	
	local t = tick()
	local frames = 0
	RunService[scheduler]:Connect(function()
		--calculate FPS
		frames += 1
		local now = tick()
		local elapsed = now-t
		
		if elapsed >= 1 then
			MAX_FPS = math.floor(frames / elapsed)
			t = now	
			frames = 0
		end
		
		--execute sequences
		for instance, sequence in activeSequences do
			if not instance or not instance.Parent then
				sequence.stop()
				return
			end
			
			sequence._nextFrame(now)
		end
	end)
end


local constructor = {}

function constructor.new(spritesheet: SpriteSheet, cells: {number})
	local sequence = {
		looping = false,
		cells = cells,
		framerate = MAX_FPS,
	} :: Sequence
	
	function sequence.play(fps: number, looping: boolean?)
		looping = looping or false; fps = fps or MAX_FPS
		sequence.looping = looping :: boolean
		sequence.framerate = fps
		
		local hasActiveSequence = activeSequences[spritesheet.instance]
		
		if hasActiveSequence then
			if hasActiveSequence == sequence then return end
			--overwrite the other sequence thats playing
			hasActiveSequence.stop()
		end
		
		activeSequences[spritesheet.instance] = sequence
		
	end
	
	local current_sequence_index = 0
	local last_execution = tick()
	function sequence._nextFrame(now: number)
		if now - last_execution <  1/sequence.framerate then return end
		last_execution = now
		
		current_sequence_index += 1
		spritesheet.display(cells[current_sequence_index])
		
		if current_sequence_index >= #cells then
			if sequence.looping then
				current_sequence_index = 0
			else
				sequence.stop()
			end
		end
	end
	
	function sequence.stop()
		current_sequence_index = 0
		
		local activesequence = activeSequences[spritesheet.instance]
		if not activesequence then return end
		if activesequence ~= sequence then return end
		
		activeSequences[spritesheet.instance] = nil
	end
	
	return sequence
end

function constructor.fromRange(spritesheet: SpriteSheet, from: number, to: number)
	assert(to-from > 0, '.fromRange only accepts positive ranges')
	
	local cells = {}
	for i = from, to do cells[#cells+1] = i end
	
	return constructor.new(spritesheet, cells)
end

return constructor
