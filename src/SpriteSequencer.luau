--!strict
--!native

local RunService = game:GetService('RunService')

-- Signal types
type Connection = {
	Disconnect: () -> ()
}

type Signal = {
	Connect: (self: Signal, callback: () -> ()) -> Connection,
	Fire: (self: Signal) -> (),
	Destroy: (self: Signal) -> (),
}

--replace with custom signal library if desired
local createSignal: () -> Signal

type SpriteSheet = {
	display: (cell: number) -> (),
	--...
	instance: ImageLabel
}

type Sequence = {
	looping: boolean,
	reverses: boolean,
	cells: {number},
	framerate: number,
	
	play: (fps: number, looping: boolean?, reverses: boolean?) -> (),
	stop: () -> (),
	isPlaying: () -> boolean,
	destroy: () -> (),
	Destroy: () -> (),

	_nextFrame: (now: number) -> (),
	_previousFrame: (now: number) -> (),
	_playingInReverse: boolean,
	
	-- replace the bindable with our custom Signal
	didLoop: Signal, 
}

local MAX_FPS = 60

local activeSequences: {[ImageLabel]: Sequence} = {}

do
	local scheduler = (if RunService:IsClient() then RunService.RenderStepped else RunService.Heartbeat) :: RBXScriptSignal<number>
	local t = tick()
	local frames = 0
	scheduler:Connect(function()
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
				continue
			end
			
			if sequence._playingInReverse then
				sequence._previousFrame(now)
			else
				sequence._nextFrame(now)
			end
		end
	end)
end


local constructor = {}

function constructor.new(spritesheet: SpriteSheet, cells: {number})
	local sequence = {
		looping = false,
		reverses = false,
		cells = cells,
		framerate = MAX_FPS,
		_playingInReverse = false,
		didLoop = createSignal() 
	} :: Sequence

	function sequence.play(fps: number, looping: boolean?, reverses: boolean?)
		reverses = reverses or false
		looping = looping or false
		fps = fps or MAX_FPS
		sequence.reverses = reverses :: boolean
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
	
	function sequence.isPlaying()
		return activeSequences[spritesheet.instance] == sequence
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
				if sequence.reverses then
					sequence._playingInReverse = true
				else
					current_sequence_index = 0
					sequence.didLoop:Fire() 
				end
			else
				if sequence.reverses then
					sequence._playingInReverse = true
				else
					sequence.stop()
				end
			end
		end
	end
	
	function sequence._previousFrame(now: number)
		if now - last_execution <  1/sequence.framerate then return end
		last_execution = now
		
		current_sequence_index -= 1
		spritesheet.display(cells[current_sequence_index])
		
		if current_sequence_index <= 1 then
			if sequence.looping then
				sequence._playingInReverse = false
				sequence.didLoop:Fire() 
			else
				sequence._playingInReverse = false
				sequence.stop()
			end
		end
	end
	
	function sequence.stop()
		current_sequence_index = 0
		sequence._playingInReverse = false
		
		local activesequence = activeSequences[spritesheet.instance]
		if not activesequence then return end
		if activesequence ~= sequence then return end
		
		activeSequences[spritesheet.instance] = nil
	end
	
	function sequence.destroy()
		sequence.stop()

		sequence.didLoop:Destroy()

		table.clear(sequence.cells)
		table.clear(sequence)

		--poison table for debugging (use after free)
		setmetatable(sequence :: any, {
            __index = function(_, key)
                error(`Attempt to access {key} on a destroyed Sequence`, 2)
            end,
            __newindex = function()
                error("Attempt to modify a destroyed Sequence", 2)
            end
        })
	end
	sequence.Destroy = sequence.destroy

	return sequence
end

function constructor.fromRange(spritesheet: SpriteSheet, from: number, to: number)
	assert(to-from > 0, '.fromRange only accepts positive ranges')
	
	local cells = {}
	for i = from, to do cells[#cells+1] = i end
	
	return constructor.new(spritesheet, cells)
end

-- lightweight signal implementation
createSignal = function(): Signal
	local listeners = {}
	local signal = {}
	
	function signal:Connect(callback)
		local node = { callback = callback }
		listeners[node] = true
		
		return {
			Disconnect = function()
				listeners[node] = nil
			end
		}
	end
	
	function signal:Fire()
		for node in listeners do
			task.spawn(node.callback) 
		end
	end
	
	function signal:Destroy()
		table.clear(listeners)
		table.clear(signal)
	end

	return signal :: Signal
end

return constructor
