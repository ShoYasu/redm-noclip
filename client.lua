-- === CONFIGURATION ===

-- Configurable controls
local ToggleControl        = 0x35957F6C -- F6
local IncreaseSpeedControl = 0x446258B6 -- Page Up
local DecreaseSpeedControl = 0x3C3DD371 -- Page Down
local UpControl            = 0xD9D0E1C0 -- Spacebar
local DownControl          = 0x8FFC75D6 -- Shift
local ForwardControl       = 0x8FD015D8 -- W
local BackwardControl      = 0xD27782E3 -- S
local LeftControl          = 0x7065027D -- A
local RightControl         = 0xB4E465B4 -- D
local ToggleModeControl    = 0xDE794E3E -- Q

-- Default speed
local Speed = 0.1

-- Max and min speeds
local MaxSpeed = 10.0
local MinSpeed = 0.1

-- Whether to enable relative mode by default.
--
-- false: Movement is based on the cardinal directions.
-- 	W = North
-- 	S = South
-- 	A = East
-- 	D = West
--
-- true: Movement is based on the current heading.
-- 	W = forward
-- 	S = backwards
-- 	A = rotate left
-- 	D = rotate right
--
local RelativeMode = true

-- === END OF CONFIGURATION ===

local Enabled = false

-- Return the player or their vehicle/mount if one exists
function GetNoClipTarget()
	local ped = PlayerPedId()
	local veh = GetVehiclePedIsIn(ped, false)
	local mnt = GetMount(ped)
	return (veh == 0 and (mnt == 0 and ped or mnt) or veh)
end

function ToggleNoClip()
	local entity = GetNoClipTarget()

	if Enabled then
		ClearPedTasksImmediately(entity, false, false)
		FreezeEntityPosition(entity, false)
		Enabled = false
	else
		ClearPedTasksImmediately(entity, false, false)
		FreezeEntityPosition(entity, true)
		Enabled = true
	end
end

RegisterCommand('noclip', ToggleNoClip)

function DrawText(text, x, y, centred)
	SetTextScale(0.35, 0.35)
	SetTextColor(255, 255, 255, 255)
	SetTextCentre(centred)
	SetTextDropshadow(1, 0, 0, 0, 200)
	SetTextFontForCurrentCommand(0)
	DisplayText(CreateVarString(10, "LITERAL_STRING", text), x, y)
end

CreateThread(function()
	TriggerEvent('chat:addSuggestion', '/noclip', 'Toggle noclip mode', {})

	while true do
		Wait(0)

		if IsControlJustPressed(0, ToggleControl) then
			ToggleNoClip()
		end

		if Enabled then
			-- Get the entity we want to control in noclip mode
			local entity = GetNoClipTarget()

			FreezeEntityPosition(entity, true)

			-- FIXME:
			-- Peds face the opposite direction of their heading
			-- when not playing any animation. This can make
			-- orienting yourself in noclip mode confusing.
			--
			-- This function makes the ped face the right way while
			-- not moving in noclip mode, but while moving they
			-- still flip around.
			TaskStandStill(entity, -1)

			-- Get the position and heading of the entity
			local x, y, z = table.unpack(GetEntityCoords(entity))

			-- Cap the speed between MinSpeed and MaxSpeed
			if Speed > MaxSpeed then
				Speed = MaxSpeed
			end
			if Speed < MinSpeed then
				Speed = MinSpeed
			end

			-- Print the current noclip speed on screen
			DrawText(string.format('NoClip Speed: %.1f', Speed), 0.5, 0.90, true)

			-- Change noclip control mode
			if IsControlJustPressed(0, ToggleModeControl) then
				RelativeMode = not RelativeMode
			end

			-- Increase/decrease speed
			if IsControlPressed(0, IncreaseSpeedControl) then
				Speed = Speed + 0.1
			end
			if IsControlPressed(0, DecreaseSpeedControl) then
				Speed = Speed - 0.1
			end

			-- Move up/down
			if IsControlPressed(0, UpControl) then
				SetEntityCoordsNoOffset(entity, x, y, z + Speed)
			end
			if IsControlPressed(0, DownControl) then
				SetEntityCoordsNoOffset(entity, x, y, z - Speed)
			end

			if RelativeMode then
				local h = GetEntityHeading(entity)

				-- Print the coordinates, heading and controls on screen
				DrawText(string.format('Coordinates:\nX: %.2f\nY: %.2f\nZ: %.2f\nHeading: %.0f', x, y, z, h), 0.01, 0.3, false)
				DrawText('W/S - Move, A/D - Rotate, Spacebar/Shift - Up/Down, Page Up/Page Down - Change speed, Q - Absolute mode', 0.5, 0.95, true)

				-- Calculate the change in x and y based on the speed and heading.
				local r = -h * math.pi / 180
				local dx = Speed * math.sin(r)
				local dy = Speed * math.cos(r)

				-- Move forward/backward
				if IsControlPressed(0, ForwardControl) then
					SetEntityCoordsNoOffset(entity, x + dx, y + dy, z)
				end
				if IsControlPressed(0, BackwardControl) then
					SetEntityCoordsNoOffset(entity, x - dx, y - dy, z)
				end

				-- Rotate heading
				if IsControlPressed(0, LeftControl) then
					SetEntityHeading(entity, h + 1)
				end
				if IsControlPressed(0, RightControl) then
					SetEntityHeading(entity, h - 1)
				end
			else
				-- Print the coordinates and controls on screen
				DrawText(string.format('Coordinates:\nX: %.2f\nY: %.2f\nZ: %.2f', x, y, z), 0.01, 0.3, false)
				DrawText('W/A/S/D - Move, Spacebar/Shift - Up/Down, Page Up/Page Down - Change speed, Q - Relative mode', 0.5, 0.95, true)

				SetEntityHeading(entity, 0.0)

				-- Move North
				if IsControlPressed(0, ForwardControl) then
					SetEntityCoordsNoOffset(entity, x, y + Speed, z)
				end

				-- Move South
				if IsControlPressed(0, BackwardControl) then
					SetEntityCoordsNoOffset(entity, x, y - Speed, z)
				end

				-- Move East
				if IsControlPressed(0, LeftControl) then
					SetEntityCoordsNoOffset(entity, x - Speed, y, z)
				end

				-- Move West
				if IsControlPressed(0, RightControl) then
					SetEntityCoordsNoOffset(entity, x + Speed, y, z)
				end
			end
		end
	end
end)
