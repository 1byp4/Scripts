_G.settings = {
	-- keybinds
	ballHBEKeybind = "Z", -- increases ur ball pickup range a bit
	fullPowerKeybind = "X", -- shoots the ball at full power
	stealBallKeybind = "C", -- steals the ball (either from a player or just wherever it is on the field)
	autoGoalKeybind = "V", -- self explanatory, must have the ball
	autoJoinTeamBind = "P", -- press while in the lobby, auto joins team at CF
	autoDribbleKeybind = "Y", -- self explanatory
	onBallWalkSpeedBind = "U", -- walkspeed, but only whilst you have the ball

	-- configuration
	autoJoinTeam = "A", -- put "A" or "B"
	autoDribbleMaxDistance = 15, -- recommended 15-25
	onBallWalkSpeed = 100
}

local plrs = game:GetService("Players")
local runservice = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local lplr = plrs.LocalPlayer
local lchr = lplr.Character
local cam = workspace.CurrentCamera

local ballhbe = false
local jointeam = false
local autodribble = false
local speed = false

local storedspeed

local function getroot(char: Model?): BasePart?
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

local function getnearby(): {Player}
	local nearby: {Player} = {}
	if not lchr then return nearby end

	local lplrRoot = getroot(lchr)
	if not lplrRoot then return nearby end

	for _, plr in ipairs(plrs:GetPlayers()) do
		if plr == lplr then continue end

		local oChar = plr.Character
		local oRoot = getroot(oChar)

		if oRoot then
			local dist = (lplrRoot.Position - oRoot.Position).Magnitude
			if dist <= _G.settings.autoDribbleMaxDistance then
				table.insert(nearby, plr)
			end
		end
	end
	return nearby
end

local function updateLplrChar()
	lchr = lplr.Character or lplr.CharacterAdded:Wait()
end

uis.InputBegan:Connect(function(key, istyping)
	if istyping then return end

	if key.KeyCode == Enum.KeyCode[string.upper(_G.settings.ballHBEKeybind)] then

		ballhbe = not ballhbe

	elseif key.KeyCode == Enum.KeyCode[string.upper(_G.settings.fullPowerKeybind)] then

		local args = {
			buffer.fromstring("\024\001"),
			{
				{
					"kick",
					100,
					false,
					vector.create(cam.CFrame.LookVector.X,cam.CFrame.LookVector.Y,cam.CFrame.LookVector.Z)
				}
			}
		}
		game:GetService("ReplicatedStorage"):WaitForChild("ByteNetReliable"):FireServer(unpack(args))

	elseif key.KeyCode == Enum.KeyCode[string.upper(_G.settings.stealBallKeybind)] then

		if workspace.Terrain:FindFirstChild("Ball") then
			local storedcf = lchr:FindFirstChild("HumanoidRootPart").CFrame
			local targetcf
			if workspace.Terrain:FindFirstChild("Ball").CFrame.Position.Y <= storedcf.Position.Y then
				targetcf = CFrame.new(workspace.Terrain:FindFirstChild("Ball").CFrame.Position.X,storedcf.Position.Y,workspace.Terrain:FindFirstChild("Ball").CFrame.Position.Z)
			else
				targetcf = workspace.Terrain:FindFirstChild("Ball").CFrame
			end

			lchr:FindFirstChild("HumanoidRootPart").CFrame = targetcf
			lchr:FindFirstChild("state"):FindFirstChild("hrpCF").Value = targetcf
			task.wait(0.05)
			local args = {
				buffer.fromstring("\014")
			}
			game:GetService("ReplicatedStorage"):WaitForChild("ByteNetReliable"):FireServer(unpack(args))
			task.wait(0.1)
			lchr:FindFirstChild("HumanoidRootPart").CFrame = storedcf
			lchr:FindFirstChild("state"):FindFirstChild("hrpCF").Value = storedcf
		else
			for i,chr in pairs(workspace.characters:GetChildren()) do
				if chr:IsA("Model") and chr:FindFirstChild("Ball") then
					local storedcf = lchr:FindFirstChild("HumanoidRootPart").CFrame
					local targetcf = chr:FindFirstChild("HumanoidRootPart").CFrame * CFrame.new(0,0,5)
					local args = {
						buffer.fromstring("\024\001"),
						{
							{
								"slice"
							}
						}
					}
					lchr:FindFirstChild("HumanoidRootPart").CFrame = targetcf
					lchr:FindFirstChild("state"):FindFirstChild("hrpCF").Value = targetcf
					task.wait(0.05)
					game:GetService("ReplicatedStorage"):WaitForChild("ByteNetReliable"):FireServer(unpack(args))
					task.wait(0.1)
					lchr:FindFirstChild("HumanoidRootPart").CFrame = storedcf
					lchr:FindFirstChild("state"):FindFirstChild("hrpCF").Value = storedcf
				end
			end
		end

	elseif key.KeyCode == Enum.KeyCode[string.upper(_G.settings.autoGoalKeybind)] then

		local lteam = tostring(game.Players.LocalPlayer.Team)
		local targetteam
		local hrp = lchr:FindFirstChild("HumanoidRootPart")

		if lteam == "A" then
			targetteam = "B"
		else
			targetteam = "A"
		end

		local targetcf = workspace.map:FindFirstChild(targetteam.."goal").CFrame

		lchr:FindFirstChild("HumanoidRootPart").CFrame = targetcf
		lchr:FindFirstChild("state"):FindFirstChild("hrpCF").Value = targetcf
		task.wait(0.25)
		local args = {
			buffer.fromstring("\024\001"),
			{
				{
					"kick",
					10,
					false,
					vector.create(hrp.CFrame.LookVector.X,hrp.CFrame.LookVector.Y,hrp.CFrame.LookVector.Z)
				}
			}
		}
		game:GetService("ReplicatedStorage"):WaitForChild("ByteNetReliable"):FireServer(unpack(args))

	elseif key.KeyCode == Enum.KeyCode[string.upper(_G.settings.autoJoinTeamBind)] then
		jointeam = not jointeam
	elseif key.KeyCode == Enum.KeyCode[string.upper(_G.settings.autoDribbleKeybind)] then
		autodribble = not autodribble
	elseif key.KeyCode == Enum.KeyCode[string.upper(_G.settings.onBallWalkSpeedBind)] then
		if speed == false then
			repeat task.wait() until lchr.movements:FindFirstChild("Configuration")
			storedspeed = lchr.movements:FindFirstChild("Configuration"):GetAttribute("speed")
		else
			repeat task.wait() until lchr.movements:FindFirstChild("Configuration")
			lchr.movements:FindFirstChild("Configuration"):SetAttribute("speed", storedspeed)
		end
		speed = not speed
	end
end)

-- auto dribble stuff

lplr.CharacterAdded:Connect(function(char: Model)
	lchr = char
end)

lplr.CharacterRemoving:Connect(function(char: Model)
	if lchr == char then
		lchr = nil
	end
end)

runservice.Heartbeat:Connect(function()
	if not lchr then
		if lplr.Character then lchr = lplr.Character end
		if not lchr then return end
	end

	if autodribble then
		local nearbyPlayers = getnearby()

		if #nearbyPlayers > 0 then
			local names = {}
			for _, p in ipairs(nearbyPlayers) do
				table.insert(names, p.Name)
				local otherhum = p.Character:FindFirstChild("Humanoid")
				for i,v in pairs(otherhum:GetPlayingAnimationTracks()) do
					if v.Animation.AnimationId == "rbxassetid://109744655458082" then
						local args = {
							buffer.fromstring("\024\001"),
							{
								{
									"dribble",
									false
								}
							}
						}
						game:GetService("ReplicatedStorage"):WaitForChild("ByteNetReliable"):FireServer(unpack(args))

					end
				end
			end
		end
	elseif ballhbe then
		local args = {
			buffer.fromstring("\014")
		}
		game:GetService("ReplicatedStorage"):WaitForChild("ByteNetReliable"):FireServer(unpack(args))
	elseif jointeam then
		local lteam = tostring(game.Players.LocalPlayer.Team)
		if lteam == "lobby" then
			local args = {
				buffer.fromstring("\013\001\001\000"..string.upper(_G.settings.autoJoinTeam))
			}
			game:GetService("ReplicatedStorage"):WaitForChild("ByteNetReliable"):FireServer(unpack(args))
		else
			jointeam = false
		end
	elseif speed then
		local cfg = lchr.movements:FindFirstChild("Configuration")
		cfg:SetAttribute("speed", _G.settings.onBallWalkSpeed)
	end
end)