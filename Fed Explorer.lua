--[[
    Fed Explorer
    Developed by 7n8z

    Fed is the most lightweight client-side Roblox explorer built for total inspection flexibility and minimal performance impact.

    This is still unfinished, feel free to join my Discord server https://discord.gg/4KYxV25nqu
    Report every bugs you found could help me improve this project so much!
    Thanks
]]
local ts = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local players = game:GetService("Players")
local rs = game:GetService("RunService")
local me = players.LocalPlayer
local pg = me:WaitForChild("PlayerGui")

pcall(function()
	if not isfolder("Fed") then makefolder("Fed") end
	if not isfolder("Fed/Icons") then makefolder("Fed/Icons") end
	if not isfolder("Fed/Icons/Class") then makefolder("Fed/Icons/Class") end
	if not isfolder("Fed/Exports") then makefolder("Fed/Exports") end
end)

local function applyClassIcon(imageLabel, className)
	local path = "Fed/Icons/Class/" .. className .. ".png"
	local worked = false
	pcall(function()
		if isfile(path) and getcustomasset then
			imageLabel.Image = getcustomasset(path)
			worked = true
		end
	end)
	if not worked then
		imageLabel.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	end
end

local function makeDraggable(handle, window)
	local dragging = false
	local dragStart = nil
	local windowStart = nil
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			windowStart = window.Position
		end
	end)
	uis.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			window.Position = UDim2.new(
				windowStart.X.Scale,
				windowStart.X.Offset + delta.X,
				windowStart.Y.Scale,
				windowStart.Y.Offset + delta.Y
			)
		end
	end)
	uis.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end

local luaKeywords = {
	["and"]=true,["break"]=true,["do"]=true,["else"]=true,["elseif"]=true,["end"]=true,
	["false"]=true,["for"]=true,["function"]=true,["if"]=true,["in"]=true,["local"]=true,
	["nil"]=true,["not"]=true,["or"]=true,["repeat"]=true,["return"]=true,["then"]=true,
	["true"]=true,["until"]=true,["while"]=true,["continue"]=true,
}

local globalFunctions = {
	["print"]=true,["warn"]=true,["error"]=true,["assert"]=true,["pcall"]=true,["xpcall"]=true,
	["ipairs"]=true,["pairs"]=true,["next"]=true,["select"]=true,["tonumber"]=true,["tostring"]=true,
	["type"]=true,["typeof"]=true,["rawget"]=true,["rawset"]=true,["rawequal"]=true,["rawlen"]=true,
	["setmetatable"]=true,["getmetatable"]=true,["unpack"]=true,["require"]=true,["loadstring"]=true,
	["spawn"]=true,["delay"]=true,["wait"]=true,["tick"]=true,["time"]=true,
	["table"]=true,["string"]=true,["math"]=true,["os"]=true,["io"]=true,["coroutine"]=true,
	["task"]=true,
}

local robloxTypes = {
	["game"]=true,["workspace"]=true,["script"]=true,["_G"]=true,["shared"]=true,
	["Instance"]=true,["Enum"]=true,["Vector3"]=true,["Vector2"]=true,["CFrame"]=true,
	["Color3"]=true,["UDim2"]=true,["UDim"]=true,["Ray"]=true,["Region3"]=true,
	["TweenInfo"]=true,["BrickColor"]=true,["NumberSequence"]=true,["ColorSequence"]=true,
	["NumberRange"]=true,["Rect"]=true,["PhysicalProperties"]=true,["Random"]=true,
	["RaycastParams"]=true,["OverlapParams"]=true,["PathfindingResult"]=true,
}

local function htmlEscape(str)
	return (str:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;"):gsub('"',"&quot;"))
end

local function colorizeSource(source)
	local parts = {}
	local pos = 1
	local len = #source
	while pos <= len do
		local ch = source:sub(pos, pos)

		if ch == "\n" then
			parts[#parts+1] = "\n"
			pos = pos + 1

		elseif ch == " " or ch == "\t" or ch == "\r" then
			local j = pos
			while j <= len and (source:sub(j,j) == " " or source:sub(j,j) == "\t" or source:sub(j,j) == "\r") do
				j = j + 1
			end
			parts[#parts+1] = htmlEscape(source:sub(pos, j-1))
			pos = j

		elseif ch == "-" and source:sub(pos, pos+1) == "--" then
			if source:sub(pos, pos+3) == "--[[" then
				local level = 0
				local j = pos + 2
				while source:sub(j,j) == "=" do level = level + 1; j = j + 1 end
				local closeStr = "]" .. string.rep("=", level) .. "]"
				local found = source:find(closeStr, j+1, true)
				local block = found and source:sub(pos, found + #closeStr - 1) or source:sub(pos)
				parts[#parts+1] = '<font color="#57A64A">' .. htmlEscape(block) .. '</font>'
				pos = found and found + #closeStr or len + 1
			else
				local found = source:find("\n", pos)
				local line = found and source:sub(pos, found-1) or source:sub(pos)
				parts[#parts+1] = '<font color="#57A64A">' .. htmlEscape(line) .. '</font>'
				pos = found or len + 1
			end

		elseif ch == "[" and (source:sub(pos, pos+1) == "[[" or (source:sub(pos+1,pos+1) == "=" and source:find("^%[=*%[", pos))) then
			local level = 0
			local j = pos + 1
			while source:sub(j,j) == "=" do level = level + 1; j = j + 1 end
			if source:sub(j,j) == "[" then
				local closeStr = "]" .. string.rep("=", level) .. "]"
				local found = source:find(closeStr, j+1, true)
				local block = found and source:sub(pos, found + #closeStr - 1) or source:sub(pos)
				parts[#parts+1] = '<font color="#D69D85">' .. htmlEscape(block) .. '</font>'
				pos = found and found + #closeStr or len + 1
			else
				parts[#parts+1] = htmlEscape(ch); pos = pos + 1
			end

		elseif ch == '"' or ch == "'" then
			local quote = ch
			local j = pos + 1
			while j <= len do
				local c = source:sub(j,j)
				if c == "\\" then j = j + 2
				elseif c == quote then j = j + 1; break
				elseif c == "\n" then break
				else j = j + 1 end
			end
			parts[#parts+1] = '<font color="#D69D85">' .. htmlEscape(source:sub(pos, j-1)) .. '</font>'
			pos = j

		elseif ch:match("%d") or (ch == "." and source:sub(pos+1, pos+1):match("%d")) then
			local j = pos
			if source:sub(j, j+1) == "0x" or source:sub(j, j+1) == "0X" then
				j = j + 2
				while j <= len and source:sub(j,j):match("[%da-fA-F_]") do j = j + 1 end
			else
				while j <= len and source:sub(j,j):match("[%d_]") do j = j + 1 end
				if j <= len and source:sub(j,j) == "." then
					j = j + 1
					while j <= len and source:sub(j,j):match("[%d_]") do j = j + 1 end
				end
				if j <= len and source:sub(j,j):match("[eE]") then
					j = j + 1
					if j <= len and source:sub(j,j):match("[%+%-]") then j = j + 1 end
					while j <= len and source:sub(j,j):match("%d") do j = j + 1 end
				end
			end
			parts[#parts+1] = '<font color="#B5CEA8">' .. htmlEscape(source:sub(pos, j-1)) .. '</font>'
			pos = j

		elseif ch:match("[%a_]") then
			local j = pos
			while j <= len and source:sub(j,j):match("[%w_]") do j = j + 1 end
			local word = source:sub(pos, j-1)
			if luaKeywords[word] then
				parts[#parts+1] = '<font color="#569CD6">' .. htmlEscape(word) .. '</font>'
			elseif word == "self" or word == "_ENV" then
				parts[#parts+1] = '<font color="#9CDCFE">' .. htmlEscape(word) .. '</font>'
			elseif robloxTypes[word] then
				parts[#parts+1] = '<font color="#4EC9B0">' .. htmlEscape(word) .. '</font>'
			elseif globalFunctions[word] then
				parts[#parts+1] = '<font color="#DCDCAA">' .. htmlEscape(word) .. '</font>'
			elseif source:sub(j,j) == "(" then
				parts[#parts+1] = '<font color="#DCDCAA">' .. htmlEscape(word) .. '</font>'
			elseif word:sub(1,1):match("%u") then
				parts[#parts+1] = '<font color="#4EC9B0">' .. htmlEscape(word) .. '</font>'
			else
				parts[#parts+1] = '<font color="#9CDCFE">' .. htmlEscape(word) .. '</font>'
			end
			pos = j

		elseif ch == "." and source:sub(pos, pos+2) == "..." then
			parts[#parts+1] = '<font color="#569CD6">...</font>'; pos = pos + 3
		elseif ch == "~" and source:sub(pos, pos+1) == "~=" then
			parts[#parts+1] = htmlEscape("~="); pos = pos + 2
		elseif ch == "=" and source:sub(pos, pos+1) == "==" then
			parts[#parts+1] = htmlEscape("=="); pos = pos + 2
		elseif ch == "<" and source:sub(pos, pos+1) == "<=" then
			parts[#parts+1] = htmlEscape("<="); pos = pos + 2
		elseif ch == ">" and source:sub(pos, pos+1) == ">=" then
			parts[#parts+1] = htmlEscape(">="); pos = pos + 2
		elseif ch == "." and source:sub(pos, pos+1) == ".." then
			parts[#parts+1] = htmlEscape(".."); pos = pos + 2
		else
			parts[#parts+1] = htmlEscape(ch); pos = pos + 1
		end
	end
	return table.concat(parts)
end

local function isUnderServerService(inst)
	local current = inst
	while current do
		local ok, parent = pcall(function() return current.Parent end)
		if not ok or parent == nil then break end
		local name = ""
		pcall(function() name = parent.Name end)
		if name == "ServerScriptService" or name == "ServerStorage" then
			return true
		end
		current = parent
	end
	return false
end

local function getInstanceSource(inst)
	local src = ""
	pcall(function() src = inst.Source or "" end)
	if src == "" and not isUnderServerService(inst) then
		pcall(function()
			if decompile then src = decompile(inst) or "" end
		end)
	end
	return src ~= "" and src or "-- source unavailable"
end

local function readProperty(inst, propName)
	local ok, value = pcall(function() return inst[propName] end)
	return ok and value or nil, ok and typeof(value) or "error"
end

local function serializeInstance(inst, depth)
	depth = depth or 0
	local indent = string.rep("\t", depth)
	local lines = {}
	lines[#lines+1] = indent .. "Instance: " .. inst.ClassName .. " [" .. inst.Name .. "]"
	local importantProps = {"Position","Size","Color","BrickColor","Transparency","Anchored","CanCollide","Value","Text","Visible","Enabled"}
	for _, propName in ipairs(importantProps) do
		local value, vtype = readProperty(inst, propName)
		if vtype ~= "error" and value ~= nil then
			lines[#lines+1] = indent .. "\t" .. propName .. " = " .. tostring(value)
		end
	end
	for _, child in ipairs(inst:GetChildren()) do
		if depth < 3 then
			lines[#lines+1] = serializeInstance(child, depth + 1)
		end
	end
	return table.concat(lines, "\n")
end

local function exportInstance(inst)
	local ok, err = pcall(function()
		if not isfolder("Fed") then makefolder("Fed") end
		if not isfolder("Fed/Exports") then makefolder("Fed/Exports") end
		local safeName = inst.Name:gsub("[^%w_%-]", "_")
		local fileName = "Fed/Exports/" .. safeName .. "_" .. inst.ClassName .. ".txt"
		local content = "Fed Export\nName: " .. inst.Name .. "\nClass: " .. inst.ClassName .. "\nPath: " .. inst:GetFullName() .. "\n\n" .. serializeInstance(inst)
		if writefile then
			writefile(fileName, content)
		end
	end)
	if not ok then
		warn("Fed: export failed - " .. tostring(err))
	end
end

local function applyPropertyChange(inst, propName, currentValue, vtype, newText)
	local worked = false
	if vtype == "boolean" then
		local newBool = (newText == "true" or newText == "1" or newText == "True")
		pcall(function() inst[propName] = newBool; worked = true end)
	elseif vtype == "number" then
		local num = tonumber(newText)
		if num then pcall(function() inst[propName] = num; worked = true end) end
	elseif vtype == "string" then
		pcall(function() inst[propName] = newText; worked = true end)
	elseif vtype == "Vector3" then
		local x, y, z = newText:match("([%-%.%d]+),%s*([%-%.%d]+),%s*([%-%.%d]+)")
		if x and y and z then
			pcall(function() inst[propName] = Vector3.new(tonumber(x), tonumber(y), tonumber(z)); worked = true end)
		end
	elseif vtype == "Vector2" then
		local x, y = newText:match("([%-%.%d]+),%s*([%-%.%d]+)")
		if x and y then
			pcall(function() inst[propName] = Vector2.new(tonumber(x), tonumber(y)); worked = true end)
		end
	elseif vtype == "Color3" then
		local r, g, b = newText:match("([%d]+),%s*([%d]+),%s*([%d]+)")
		if r and g and b then
			pcall(function() inst[propName] = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)); worked = true end)
		end
	elseif vtype == "UDim2" then
		local xs, xo, ys, yo = newText:match("([%-%.%d]+),%s*([%-%.%d]+),%s*([%-%.%d]+),%s*([%-%.%d]+)")
		if xs and xo and ys and yo then
			pcall(function() inst[propName] = UDim2.new(tonumber(xs), tonumber(xo), tonumber(ys), tonumber(yo)); worked = true end)
		end
	elseif vtype == "CFrame" then
		local x, y, z = newText:match("([%-%.%d]+),%s*([%-%.%d]+),%s*([%-%.%d]+)")
		if x and y and z then
			pcall(function()
				local cf = inst[propName]
				inst[propName] = CFrame.new(tonumber(x), tonumber(y), tonumber(z)) * (cf - cf.Position)
				worked = true
			end)
		end
	end
	return worked
end

local gui = Instance.new("ScreenGui")
gui.Name = "Fed"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.IgnoreGuiInset = true
gui.Parent = pg

local loadDone = false

local loadWin = Instance.new("Frame")
loadWin.Name = "LoadingScreen"
loadWin.BorderSizePixel = 0
loadWin.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
loadWin.Size = UDim2.new(0, 400, 0, 250)
loadWin.Position = UDim2.new(0.5, -200, 0.5, -125)
loadWin.ZIndex = 1000
loadWin.Parent = gui
Instance.new("UICorner", loadWin).CornerRadius = UDim.new(0, 5)

local function makeLoadLabel(text, size, posY, xPos, xOff)
	local lbl = Instance.new("TextLabel")
	lbl.BorderSizePixel = 0
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.Font = Enum.Font.SourceSans
	lbl.TextSize = size
	lbl.Text = text
	lbl.Size = UDim2.new(0, xOff or 400, 0, 50)
	lbl.Position = UDim2.new(xPos or 0, 0, posY, 0)
	lbl.ZIndex = 1001
	lbl.Parent = loadWin
	return lbl
end

local loadTitle  = makeLoadLabel("Fed", 62, 0.052, 0, 144)
local loadSub    = makeLoadLabel("Explorer 2.0", 16, 0.096, 0.2675, 75)
local loadDesc   = makeLoadLabel("The most lightweight client-side Roblox explorer built for total inspection flexibility and minimal performance impact.", 16, 0.252, 0.025, 380)
local loadCredit = makeLoadLabel("Developed by 7n8z", 16, 0.096, 0.69, 124)
local loadVer    = makeLoadLabel("Public Edition", 16, 0, 0.69, 124)

loadDesc.TextWrapped = true
loadDesc.TextScaled = true

local loadBarBg = Instance.new("Frame")
loadBarBg.BorderSizePixel = 0
loadBarBg.BackgroundColor3 = Color3.fromRGB(37, 37, 38)
loadBarBg.Size = UDim2.new(0, 400, 0, 20)
loadBarBg.Position = UDim2.new(0, 0, 0.46, 0)
loadBarBg.ZIndex = 1001
loadBarBg.Parent = loadWin

local loadBar = Instance.new("Frame")
loadBar.BorderSizePixel = 0
loadBar.BackgroundColor3 = Color3.fromRGB(0, 131, 221)
loadBar.Size = UDim2.new(0, 0, 1, 0)
loadBar.ZIndex = 1002
loadBar.Parent = loadBarBg

local loadPercent      = makeLoadLabel("0%",                     16, 0.54, 0, 400)
local loadFolderStatus = makeLoadLabel("Fed folder: Checking...", 16, 0.64, 0, 400)
local loadLogoStatus   = makeLoadLabel("Logo: Checking...",       16, 0.74, 0, 400)
local loadIconStatus   = makeLoadLabel("Icons: Checking...",      16, 0.84, 0, 400)

local colorGreen = Color3.fromRGB(80, 220, 100)
local colorRed   = Color3.fromRGB(255, 90, 90)

local function setLoadProgress(pct)
	ts:Create(loadBar, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
		Size = UDim2.new(pct, 0, 1, 0)
	}):Play()
	loadPercent.Text = math.floor(pct * 100) .. "%"
end

task.spawn(function()
	task.wait(0.3)

	local hasFedFolder = false
	pcall(function() hasFedFolder = isfolder("Fed") end)
	if hasFedFolder then
		loadFolderStatus.Text = "Fed folder: Found"
		loadFolderStatus.TextColor3 = colorGreen
	else
		loadFolderStatus.Text = "Fed folder: Not Found"
		loadFolderStatus.TextColor3 = colorRed
	end
	setLoadProgress(0.33)
	task.wait(0.35)

	local hasLogo = false
	pcall(function() hasLogo = isfile("Fed/Icons/fedlogo.png") end)
	if hasLogo then
		loadLogoStatus.Text = "Logo: Found"
		loadLogoStatus.TextColor3 = colorGreen
	else
		loadLogoStatus.Text = "Logo: Not Found"
		loadLogoStatus.TextColor3 = colorRed
	end
	setLoadProgress(0.66)
	task.wait(0.35)

	local hasIcons = false
	pcall(function()
		hasIcons = isfolder("Fed/Icons/Class")
	end)
	if hasIcons then
		loadIconStatus.Text = "Icons: Found"
		loadIconStatus.TextColor3 = colorGreen
	else
		loadIconStatus.Text = "Icons: Not Found"
		loadIconStatus.TextColor3 = colorRed
	end
	setLoadProgress(1)
	task.wait(0.5)

	ts:Create(loadWin, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
		BackgroundTransparency = 1
	}):Play()
	for _, child in ipairs(loadWin:GetDescendants()) do
		if child:IsA("TextLabel") or child:IsA("Frame") then
			pcall(function()
				ts:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
					BackgroundTransparency = 1,
					TextTransparency = 1
				}):Play()
			end)
		end
	end
	task.wait(0.35)
	loadWin:Destroy()
	loadDone = true
end)

local contextMenu = Instance.new("Frame")
contextMenu.Name = "ContextMenu"
contextMenu.BorderSizePixel = 0
contextMenu.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
contextMenu.Size = UDim2.new(0, 148, 0, 0)
contextMenu.ZIndex = 200
contextMenu.ClipsDescendants = true
contextMenu.Visible = false
contextMenu.Parent = gui
Instance.new("UICorner", contextMenu).CornerRadius = UDim.new(0, 5)

local ctxStroke = Instance.new("UIStroke")
ctxStroke.Color = Color3.fromRGB(70, 70, 70)
ctxStroke.Thickness = 1
ctxStroke.Parent = contextMenu

local ctxLayout = Instance.new("UIListLayout")
ctxLayout.SortOrder = Enum.SortOrder.LayoutOrder
ctxLayout.Padding = UDim.new(0, 0)
ctxLayout.Parent = contextMenu

local ctxPad = Instance.new("UIPadding")
ctxPad.PaddingTop = UDim.new(0, 3)
ctxPad.PaddingBottom = UDim.new(0, 3)
ctxPad.Parent = contextMenu

local activeContextInst = nil
local copiedInst = nil

local function hideContextMenu()
	contextMenu.Visible = false
	activeContextInst = nil
end

local function makeContextItem(label, order, textColor)
	local btn = Instance.new("TextButton")
	btn.BorderSizePixel = 0
	btn.BackgroundTransparency = 1
	btn.TextColor3 = textColor or Color3.fromRGB(215, 215, 215)
	btn.Font = Enum.Font.SourceSans
	btn.TextSize = 13
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Size = UDim2.new(1, 0, 0, 24)
	btn.LayoutOrder = order
	btn.AutoButtonColor = false
	btn.ZIndex = 201
	btn.Parent = contextMenu

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.Parent = btn

	local hoverFrame = Instance.new("Frame")
	hoverFrame.BorderSizePixel = 0
	hoverFrame.BackgroundColor3 = Color3.fromRGB(0, 110, 210)
	hoverFrame.BackgroundTransparency = 1
	hoverFrame.Size = UDim2.new(1, 0, 1, 0)
	hoverFrame.ZIndex = btn.ZIndex - 1
	hoverFrame.Parent = btn

	btn.MouseEnter:Connect(function() hoverFrame.BackgroundTransparency = 0.6 end)
	btn.MouseLeave:Connect(function() hoverFrame.BackgroundTransparency = 1 end)
	btn.Text = label
	return btn
end

local ctxViewScript   = makeContextItem("View Script",    1)
local ctxCopy         = makeContextItem("Copy",           2)
local ctxCopyPath     = makeContextItem("Copy Path",      3)
local ctxCopyClass    = makeContextItem("Copy ClassName", 4)
local ctxDupe         = makeContextItem("Duplicate",      5)
local ctxRename       = makeContextItem("Rename",         6)
local ctxPaste        = makeContextItem("Paste Into",     7)
local ctxSelectParent = makeContextItem("Select Parent",  8)
local ctxExport       = makeContextItem("Export",         9)
local ctxExportScript = makeContextItem("Export Script",  10)
local ctxDelete       = makeContextItem("Delete",         11, Color3.fromRGB(255, 100, 100))

local CTX_ITEM_HEIGHT = 24
local CTX_PADDING     = 6
local allCtxItems = {ctxViewScript,ctxCopy,ctxCopyPath,ctxCopyClass,ctxDupe,ctxRename,ctxPaste,ctxSelectParent,ctxExport,ctxExportScript,ctxDelete}

local function countVisibleItems(items)
	local count = 0
	for _, item in ipairs(items) do
		if item.Visible then count = count + 1 end
	end
	return count
end

local function showContextMenu(inst, x, y)
	activeContextInst = inst
	local isScript = inst:IsA("BaseScript") or inst:IsA("ModuleScript")
	ctxViewScript.Visible   = isScript
	ctxExportScript.Visible = isScript
	local visCount = countVisibleItems(allCtxItems)
	contextMenu.Size = UDim2.new(0, 148, 0, visCount * CTX_ITEM_HEIGHT + CTX_PADDING)
	contextMenu.Position = UDim2.new(0, x, 0, y)
	contextMenu.Visible = true
end

uis.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if contextMenu.Visible then
			task.defer(hideContextMenu)
		end
	end
end)

local function makeTopButton()
	local top = Instance.new("Frame")
	top.Name = "TOP"
	top.BorderSizePixel = 0
	top.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
	top.BackgroundTransparency = 0.25
	top.Size = UDim2.new(0, 44, 0, 44)
	top.Position = UDim2.new(0.5, -22, 0, 2)
	top.Active = true
	top.Parent = gui
	Instance.new("UICorner", top).CornerRadius = UDim.new(0, 6)

	local logoImg = Instance.new("ImageLabel")
	logoImg.BackgroundTransparency = 1
	logoImg.Size = UDim2.new(1, -6, 1, -6)
	logoImg.Position = UDim2.new(0, 3, 0, 3)
	logoImg.ZIndex = 1
	logoImg.Parent = top

	local hasLogo = false
	pcall(function()
		if isfile("Fed/Icons/fedlogo.png") and getcustomasset then
			logoImg.Image = getcustomasset("Fed/Icons/fedlogo.png")
			hasLogo = true
		end
	end)

	local topLabel = Instance.new("TextLabel")
	topLabel.BackgroundTransparency = 1
	topLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	topLabel.Font = Enum.Font.SourceSansBold
	topLabel.TextSize = 15
	topLabel.Text = "Fed"
	topLabel.Size = UDim2.new(1, 0, 1, 0)
	topLabel.ZIndex = 1
	topLabel.Visible = not hasLogo
	topLabel.Parent = top

	local topBtn = Instance.new("TextButton")
	topBtn.Size = UDim2.new(1, 0, 1, 0)
	topBtn.BackgroundTransparency = 1
	topBtn.Text = ""
	topBtn.ZIndex = 2
	topBtn.Parent = top

	makeDraggable(top, top)
	return top, topBtn
end

local mainTop, topBtn = makeTopButton()

local dropMenu = Instance.new("Frame")
dropMenu.Name = "DropMenu"
dropMenu.BorderSizePixel = 0
dropMenu.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
dropMenu.Size = UDim2.new(0, 460, 0, 0)
dropMenu.Position = UDim2.new(0, -208, 1, 6)
dropMenu.ClipsDescendants = true
dropMenu.ZIndex = 60
dropMenu.Parent = mainTop
Instance.new("UICorner", dropMenu).CornerRadius = UDim.new(0, 6)

local menuOpen = false
local menuTween

local function closeMenu()
	if menuTween then menuTween:Cancel() end
	menuOpen = false
	ts:Create(dropMenu, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {Size=UDim2.new(0,460,0,0)}):Play()
end

local function openMenu()
	if menuTween then menuTween:Cancel() end
	menuOpen = true
	ts:Create(dropMenu, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {Size=UDim2.new(0,460,0,46)}):Play()
end

topBtn.MouseButton1Click:Connect(function()
	if menuOpen then closeMenu() else openMenu() end
end)

local function makeMenuTabButton(text, xPos, width)
	local btn = Instance.new("TextButton")
	btn.BorderSizePixel = 0
	btn.BackgroundTransparency = 1
	btn.TextColor3 = Color3.fromRGB(200, 200, 200)
	btn.Font = Enum.Font.SourceSans
	btn.TextSize = 13
	btn.Text = text
	btn.Size = UDim2.new(0, width, 0, 36)
	btn.Position = UDim2.new(0, xPos, 0, 5)
	btn.ZIndex = 61
	btn.AutoButtonColor = false
	btn.Parent = dropMenu

	local underline = Instance.new("Frame")
	underline.BorderSizePixel = 0
	underline.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	underline.Size = UDim2.new(1, -6, 0, 2)
	underline.Position = UDim2.new(0, 3, 1, -2)
	underline.Visible = false
	underline.ZIndex = 62
	underline.Parent = btn
	return btn, underline
end

local bw = 72
local svBtn,   svLine   = makeMenuTabButton("Script viewer", 3,          bw)
local expBtn,  expLine  = makeMenuTabButton("Explorer",       3+bw+2,    bw)
local propBtn, propLine = makeMenuTabButton("Properties",     3+bw*2+4,  bw)
local saveBtn, saveLine = makeMenuTabButton("Save game",      3+bw*3+6,  bw)
local scanBtn, scanLine = makeMenuTabButton("Server scan",    3+bw*4+8,  bw)
local exitBtn, exitLine = makeMenuTabButton("Exit",           3+bw*5+10, bw-10)

local sideTab = Instance.new("Frame")
sideTab.BorderSizePixel = 0
sideTab.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
sideTab.Size = UDim2.new(0, 14, 0, 40)
sideTab.Position = UDim2.new(1, -14, 0, 0)
sideTab.Parent = gui

local sideBtn = Instance.new("TextButton")
sideBtn.BackgroundTransparency = 1
sideBtn.BorderSizePixel = 0
sideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sideBtn.Font = Enum.Font.SourceSans
sideBtn.TextSize = 14
sideBtn.Text = "<"
sideBtn.Size = UDim2.new(1, 0, 1, 0)
sideBtn.Parent = sideTab

local panelWidth = 270

local expPanel = Instance.new("Frame")
expPanel.Name = "Explorer"
expPanel.BorderSizePixel = 0
expPanel.BackgroundColor3 = Color3.fromRGB(44, 44, 44)
expPanel.Size = UDim2.new(0, panelWidth, 1, 0)
expPanel.Position = UDim2.new(1, 0, 0, 0)
expPanel.ClipsDescendants = true
expPanel.Parent = gui

local expHeader = Instance.new("Frame")
expHeader.BorderSizePixel = 0
expHeader.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
expHeader.Size = UDim2.new(1, 0, 0, 34)
expHeader.ZIndex = 2
expHeader.Parent = expPanel

local expHeaderLabel = Instance.new("TextLabel")
expHeaderLabel.BorderSizePixel = 0
expHeaderLabel.BackgroundTransparency = 1
expHeaderLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
expHeaderLabel.Font = Enum.Font.SourceSansBold
expHeaderLabel.TextSize = 16
expHeaderLabel.Text = "Fed Explorer V2"
expHeaderLabel.Size = UDim2.new(1, -60, 1, 0)
expHeaderLabel.Position = UDim2.new(0, 8, 0, 0)
expHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
expHeaderLabel.ZIndex = 2
expHeaderLabel.Parent = expHeader

local refreshBtn = Instance.new("TextButton")
refreshBtn.BorderSizePixel = 0
refreshBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
refreshBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
refreshBtn.Font = Enum.Font.SourceSansBold
refreshBtn.TextSize = 14
refreshBtn.Text = "R"
refreshBtn.Size = UDim2.new(0, 24, 0, 20)
refreshBtn.Position = UDim2.new(1, -52, 0.5, -10)
refreshBtn.ZIndex = 3
refreshBtn.AutoButtonColor = false
refreshBtn.Parent = expHeader
Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 4)

refreshBtn.MouseEnter:Connect(function()
	refreshBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
end)
refreshBtn.MouseLeave:Connect(function()
	refreshBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
end)

local function makeCloseButton(parent, zIndex, yOffset)
	local btn = Instance.new("TextButton")
	btn.BorderSizePixel = 0
	btn.BackgroundTransparency = 1
	btn.AutoButtonColor = false
	btn.Size = UDim2.new(0, 16, 0, 16)
	btn.Position = UDim2.new(1, -18, 0, yOffset)
	btn.Text = ""
	btn.ZIndex = zIndex
	btn.Parent = parent
	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://5054663650"
	icon.Size = UDim2.new(0, 10, 0, 10)
	icon.Position = UDim2.new(0, 3, 0, 3)
	icon.ZIndex = zIndex
	icon.Parent = btn
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)
	return btn
end

local expClose = makeCloseButton(expHeader, 4, 9)

local searchBar = Instance.new("Frame")
searchBar.BorderSizePixel = 0
searchBar.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
searchBar.Size = UDim2.new(1, 0, 0, 28)
searchBar.Position = UDim2.new(0, 0, 0, 34)
searchBar.ZIndex = 2
searchBar.Parent = expPanel

local searchBox = Instance.new("TextBox")
searchBox.BorderSizePixel = 0
searchBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
searchBox.TextColor3 = Color3.fromRGB(220, 220, 220)
searchBox.PlaceholderText = "Search instances..."
searchBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 110)
searchBox.Font = Enum.Font.SourceSans
searchBox.TextSize = 13
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Text = ""
searchBox.ClearTextOnFocus = false
searchBox.Size = UDim2.new(1, -10, 0, 20)
searchBox.Position = UDim2.new(0, 5, 0, 4)
searchBox.ZIndex = 3
searchBox.Parent = searchBar
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 4)

local searchBoxPad = Instance.new("UIPadding")
searchBoxPad.PaddingLeft = UDim.new(0, 6)
searchBoxPad.Parent = searchBox

local expScroll = Instance.new("ScrollingFrame")
expScroll.BorderSizePixel = 0
expScroll.BackgroundTransparency = 1
expScroll.Size = UDim2.new(1, 0, 1, -62)
expScroll.Position = UDim2.new(0, 0, 0, 62)
expScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
expScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
expScroll.ScrollBarThickness = 5
expScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
expScroll.Parent = expPanel

local expLayout = Instance.new("UIListLayout")
expLayout.SortOrder = Enum.SortOrder.LayoutOrder
expLayout.Parent = expScroll

local splitDivider = Instance.new("Frame")
splitDivider.BorderSizePixel = 0
splitDivider.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
splitDivider.Size = UDim2.new(1, 0, 0, 5)
splitDivider.Position = UDim2.new(0, 0, 1, 0)
splitDivider.ZIndex = 5
splitDivider.Visible = false
splitDivider.Parent = expPanel

local splitGrip = Instance.new("TextButton")
splitGrip.BackgroundTransparency = 1
splitGrip.BorderSizePixel = 0
splitGrip.Size = UDim2.new(1, 0, 1, 0)
splitGrip.Text = ""
splitGrip.ZIndex = 6
splitGrip.Parent = splitDivider

local propPanel = Instance.new("Frame")
propPanel.Name = "Properties"
propPanel.BorderSizePixel = 0
propPanel.BackgroundColor3 = Color3.fromRGB(44, 44, 44)
propPanel.Size = UDim2.new(1, 0, 0, 0)
propPanel.Position = UDim2.new(0, 0, 1, 0)
propPanel.ClipsDescendants = true
propPanel.Visible = false
propPanel.Parent = expPanel

local propHeader = Instance.new("TextLabel")
propHeader.BorderSizePixel = 0
propHeader.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
propHeader.TextColor3 = Color3.fromRGB(240, 240, 240)
propHeader.Font = Enum.Font.SourceSansBold
propHeader.TextSize = 14
propHeader.Text = "Properties"
propHeader.Size = UDim2.new(1, 0, 0, 28)
propHeader.ZIndex = 2
propHeader.Parent = propPanel

local propClose = makeCloseButton(propPanel, 4, 6)

local propScroll = Instance.new("ScrollingFrame")
propScroll.BorderSizePixel = 0
propScroll.BackgroundTransparency = 1
propScroll.Size = UDim2.new(1, 0, 1, -28)
propScroll.Position = UDim2.new(0, 0, 0, 28)
propScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
propScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
propScroll.ScrollBarThickness = 5
propScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
propScroll.Parent = propPanel

local propListLayout = Instance.new("UIListLayout")
propListLayout.SortOrder = Enum.SortOrder.LayoutOrder
propListLayout.Parent = propScroll

local highlightBox = Instance.new("SelectionBox")
highlightBox.Color3 = Color3.fromRGB(0, 170, 255)
highlightBox.LineThickness = 0.06
highlightBox.SurfaceTransparency = 0.8
highlightBox.SurfaceColor3 = Color3.fromRGB(0, 100, 200)
highlightBox.Adornee = nil
highlightBox.Parent = workspace

local expVisible   = false
local expTween     = nil
local expBuilt     = false
local propVisible  = false
local selectedInst = nil
local propHeight   = 0
local toggleExplorer

local function applySplitLayout()
	if propHeight == 0 then propHeight = math.floor(expPanel.AbsoluteSize.Y * 0.42) end
	local totalH = expPanel.AbsoluteSize.Y
	local expH   = math.max(60, totalH - propHeight - 5)
	propHeight = math.max(60, totalH - expH - 5)
	expScroll.Size        = UDim2.new(1, 0, 0, expH - 62)
	splitDivider.Position = UDim2.new(0, 0, 0, 62 + expH - 62)
	propPanel.Position    = UDim2.new(0, 0, 0, 62 + expH - 62 + 5)
	propPanel.Size        = UDim2.new(1, 0, 0, propHeight)
end

local splitDragging   = false
local splitDragOriginY = nil
local splitStartExpH  = nil

splitGrip.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		splitDragging    = true
		splitDragOriginY = input.Position.Y
		splitStartExpH   = expScroll.Size.Y.Offset + 62
	end
end)
uis.InputChanged:Connect(function(input)
	if splitDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta   = input.Position.Y - splitDragOriginY
		local totalH  = expPanel.AbsoluteSize.Y
		local newExpH = math.max(60, math.min(totalH - 60 - 5, splitStartExpH + delta))
		propHeight = math.max(60, totalH - newExpH - 5)
		expScroll.Size        = UDim2.new(1, 0, 0, newExpH - 62)
		splitDivider.Position = UDim2.new(0, 0, 0, newExpH)
		propPanel.Position    = UDim2.new(0, 0, 0, newExpH + 5)
		propPanel.Size        = UDim2.new(1, 0, 0, propHeight)
	end
end)
uis.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then splitDragging = false end
end)

local allProps = {
	"Name","ClassName","Parent","Archivable",
	"Position","Size","CFrame","Rotation","Orientation",
	"Color","BrickColor","Material","Transparency","Reflectance","CastShadow",
	"Anchored","CanCollide","CanTouch","CanQuery","Locked","Massless",
	"Velocity","AssemblyLinearVelocity","AssemblyAngularVelocity","AssemblyMass",
	"Visible","BackgroundColor3","BackgroundTransparency","BorderColor3","BorderSizePixel","ZIndex",
	"AnchorPoint","ClipsDescendants","Active","Selectable","LayoutOrder",
	"TextColor3","Text","TextSize","Font","TextTransparency","TextScaled","TextWrapped",
	"TextXAlignment","TextYAlignment","RichText","PlaceholderText","MultiLine","ClearTextOnFocus",
	"AbsoluteSize","AbsolutePosition",
	"Image","ImageColor3","ImageTransparency","ScaleType",
	"Value",
	"Disabled","Source",
	"Health","MaxHealth","WalkSpeed","JumpPower","AutoRotate",
	"SoundId","Volume","PlaybackSpeed","Looped","Playing","TimePosition",
	"Brightness","Range","Shadows","Face","Enabled","Angle",
	"FieldOfView","CameraType",
	"MeshId","TextureId","Scale","MeshType",
	"ScrollBarThickness","CanvasSize","AutomaticCanvasSize",
	"CornerRadius","Thickness",
}

local readOnlyProps = {
	ClassName=true,
	AbsoluteSize=true, AbsolutePosition=true,
	AssemblyMass=true,
}

local function buildPropertyRow(inst, propName, vtype, rawValue)
	local row = Instance.new("Frame")
	row.BorderSizePixel = 0
	row.BackgroundColor3 = Color3.fromRGB(48, 48, 48)
	row.Size = UDim2.new(1, 0, 0, 22)
	row.Parent = propScroll

	local separator = Instance.new("Frame")
	separator.BorderSizePixel = 0
	separator.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
	separator.Size = UDim2.new(1, 0, 0, 1)
	separator.Position = UDim2.new(0, 0, 1, -1)
	separator.ZIndex = 2
	separator.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BorderSizePixel = 0
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(165, 165, 165)
	nameLabel.Font = Enum.Font.SourceSans
	nameLabel.TextSize = 12
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Text = propName
	nameLabel.Size = UDim2.new(0.46, 0, 1, 0)
	nameLabel.Position = UDim2.new(0, 5, 0, 0)
	nameLabel.Parent = row

	local valStr = tostring(rawValue)
	if #valStr > 55 then valStr = valStr:sub(1, 52) .. "..." end

	local isEditable = not readOnlyProps[propName] and (
		vtype == "boolean" or vtype == "number" or vtype == "string"
		or vtype == "Vector3" or vtype == "Vector2" or vtype == "Color3"
		or vtype == "UDim2" or vtype == "CFrame"
	)

	if vtype == "boolean" then
		local checkbox = Instance.new("TextButton")
		checkbox.BorderSizePixel = 1
		checkbox.BorderColor3 = Color3.fromRGB(110, 110, 110)
		checkbox.BackgroundColor3 = rawValue and Color3.fromRGB(0, 130, 255) or Color3.fromRGB(55, 55, 55)
		checkbox.Size = UDim2.new(0, 13, 0, 13)
		checkbox.Position = UDim2.new(0.47, 2, 0.5, -6)
		checkbox.Text = rawValue and "✓" or ""
		checkbox.TextColor3 = Color3.fromRGB(255, 255, 255)
		checkbox.Font = Enum.Font.SourceSansBold
		checkbox.TextSize = 11
		checkbox.AutoButtonColor = false
		checkbox.ZIndex = 3
		checkbox.Parent = row
		if isEditable then
			checkbox.MouseButton1Click:Connect(function()
				local newVal = not rawValue
				local worked = applyPropertyChange(inst, propName, rawValue, vtype, tostring(newVal))
				if worked then
					rawValue = newVal
					checkbox.BackgroundColor3 = newVal and Color3.fromRGB(0, 130, 255) or Color3.fromRGB(55, 55, 55)
					checkbox.Text = newVal and "✓" or ""
				end
			end)
		end

	elseif vtype == "Color3" then
		local swatch = Instance.new("Frame")
		swatch.BorderSizePixel = 1
		swatch.BorderColor3 = Color3.fromRGB(70, 70, 70)
		swatch.BackgroundColor3 = rawValue
		swatch.Size = UDim2.new(0, 32, 0, 12)
		swatch.Position = UDim2.new(0.47, 2, 0.5, -6)
		swatch.Parent = row
		local rgbLabel = Instance.new("TextLabel")
		rgbLabel.BackgroundTransparency = 1
		rgbLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
		rgbLabel.Font = Enum.Font.Code
		rgbLabel.TextSize = 11
		rgbLabel.TextXAlignment = Enum.TextXAlignment.Left
		rgbLabel.Text = string.format("[%d,%d,%d]", math.round(rawValue.R*255), math.round(rawValue.G*255), math.round(rawValue.B*255))
		rgbLabel.Size = UDim2.new(0.5, -4, 1, 0)
		rgbLabel.Position = UDim2.new(0.47, 38, 0, 0)
		rgbLabel.Parent = row

	elseif vtype == "BrickColor" then
		local swatch = Instance.new("Frame")
		swatch.BorderSizePixel = 1
		swatch.BorderColor3 = Color3.fromRGB(70, 70, 70)
		swatch.BackgroundColor3 = rawValue.Color
		swatch.Size = UDim2.new(0, 32, 0, 12)
		swatch.Position = UDim2.new(0.47, 2, 0.5, -6)
		swatch.Parent = row
		local bcLabel = Instance.new("TextLabel")
		bcLabel.BackgroundTransparency = 1
		bcLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
		bcLabel.Font = Enum.Font.SourceSans
		bcLabel.TextSize = 11
		bcLabel.TextXAlignment = Enum.TextXAlignment.Left
		bcLabel.Text = tostring(rawValue)
		bcLabel.Size = UDim2.new(0.5, -4, 1, 0)
		bcLabel.Position = UDim2.new(0.47, 38, 0, 0)
		bcLabel.Parent = row

	elseif vtype == "EnumItem" then
		local valLabel = Instance.new("TextLabel")
		valLabel.BackgroundTransparency = 1
		valLabel.TextColor3 = Color3.fromRGB(196, 220, 156)
		valLabel.Font = Enum.Font.SourceSans
		valLabel.TextSize = 12
		valLabel.TextXAlignment = Enum.TextXAlignment.Left
		valLabel.TextTruncate = Enum.TextTruncate.AtEnd
		valLabel.Text = tostring(rawValue)
		valLabel.Size = UDim2.new(0.52, -5, 1, 0)
		valLabel.Position = UDim2.new(0.47, 3, 0, 0)
		valLabel.Parent = row

	elseif isEditable then
		local displayText = valStr
		if vtype == "Vector3" then
			local ok, fmt = pcall(function() return string.format("%.3f, %.3f, %.3f", rawValue.X, rawValue.Y, rawValue.Z) end)
			displayText = ok and fmt or valStr
		elseif vtype == "Vector2" then
			local ok, fmt = pcall(function() return string.format("%.3f, %.3f", rawValue.X, rawValue.Y) end)
			displayText = ok and fmt or valStr
		elseif vtype == "CFrame" then
			local ok, fmt = pcall(function() return string.format("%.2f, %.2f, %.2f", rawValue.X, rawValue.Y, rawValue.Z) end)
			displayText = ok and fmt or valStr
		elseif vtype == "Color3" then
			displayText = string.format("%d, %d, %d", math.round(rawValue.R*255), math.round(rawValue.G*255), math.round(rawValue.B*255))
		end

		local textColor = Color3.fromRGB(215, 215, 215)
		if vtype == "number" then textColor = Color3.fromRGB(181, 206, 168)
		elseif vtype == "Vector3" or vtype == "Vector2" then textColor = Color3.fromRGB(156, 220, 254)
		elseif vtype == "CFrame" then textColor = Color3.fromRGB(200, 170, 255)
		elseif vtype == "UDim2" or vtype == "UDim" then textColor = Color3.fromRGB(220, 200, 140)
		end

		local inputBox = Instance.new("TextBox")
		inputBox.BorderSizePixel = 0
		inputBox.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
		inputBox.BackgroundTransparency = 1
		inputBox.TextColor3 = textColor
		inputBox.Font = Enum.Font.SourceSans
		inputBox.TextSize = 13
		inputBox.TextXAlignment = Enum.TextXAlignment.Left
		inputBox.TextTruncate = Enum.TextTruncate.AtEnd
		inputBox.Text = displayText
		inputBox.Size = UDim2.new(0.52, -5, 1, 0)
		inputBox.Position = UDim2.new(0.47, 3, 0, 0)
		inputBox.ClearTextOnFocus = false
		inputBox.ZIndex = 3
		inputBox.Parent = row

		inputBox.Focused:Connect(function()
			inputBox.BackgroundTransparency = 0
			inputBox.BackgroundColor3 = Color3.fromRGB(30, 45, 65)
		end)
		inputBox.FocusLost:Connect(function(submitted)
			inputBox.BackgroundTransparency = 1
			if submitted then
				local worked = applyPropertyChange(inst, propName, rawValue, vtype, inputBox.Text)
				if not worked then
					inputBox.Text = displayText
				else
					displayText = inputBox.Text
				end
			else
				inputBox.Text = displayText
			end
		end)

	else
		local textColor = Color3.fromRGB(215, 215, 215)
		local displayText = valStr
		if vtype == "number" then
			textColor = Color3.fromRGB(181, 206, 168)
			local num = tonumber(valStr)
			displayText = num and (math.floor(num) == num and tostring(math.floor(num)) or string.format("%.4g", num)) or valStr
		elseif vtype == "Instance" then
			textColor = Color3.fromRGB(255, 200, 100)
		elseif vtype == "Vector3" then
			textColor = Color3.fromRGB(156, 220, 254)
			local ok, fmt = pcall(function() return string.format("%.3f, %.3f, %.3f", rawValue.X, rawValue.Y, rawValue.Z) end)
			displayText = ok and fmt or valStr
		elseif vtype == "Vector2" then
			textColor = Color3.fromRGB(156, 220, 254)
			local ok, fmt = pcall(function() return string.format("%.3f, %.3f", rawValue.X, rawValue.Y) end)
			displayText = ok and fmt or valStr
		elseif vtype == "CFrame" then
			textColor = Color3.fromRGB(200, 170, 255)
			local ok, fmt = pcall(function() return string.format("%.2f, %.2f, %.2f", rawValue.X, rawValue.Y, rawValue.Z) end)
			displayText = ok and fmt or valStr
		elseif vtype == "UDim2" or vtype == "UDim" then
			textColor = Color3.fromRGB(220, 200, 140)
		end

		local valLabel = Instance.new("TextLabel")
		valLabel.BackgroundTransparency = 1
		valLabel.TextColor3 = textColor
		valLabel.Font = Enum.Font.SourceSans
		valLabel.TextSize = 13
		valLabel.TextXAlignment = Enum.TextXAlignment.Left
		valLabel.TextTruncate = Enum.TextTruncate.AtEnd
		valLabel.Text = displayText
		valLabel.Size = UDim2.new(0.52, -5, 1, 0)
		valLabel.Position = UDim2.new(0.47, 3, 0, 0)
		valLabel.Parent = row
	end
end

local function showProperties(inst)
	for _, child in ipairs(propScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	propHeader.Text = inst.Name .. " [" .. inst.ClassName .. "]"
	for _, propName in ipairs(allProps) do
		local raw, vtype = readProperty(inst, propName)
		if vtype ~= "error" and raw ~= nil then
			buildPropertyRow(inst, propName, vtype, raw)
		end
	end
end

local propAutoRefreshConn

local function openProperties(inst)
	selectedInst = inst
	showProperties(inst)

	if propAutoRefreshConn then
		propAutoRefreshConn:Disconnect()
		propAutoRefreshConn = nil
	end

	propAutoRefreshConn = rs.Heartbeat:Connect(function()
		if not (selectedInst and propVisible and propPanel.Visible) then return end
		local ok = pcall(function() return selectedInst.Parent end)
		if not ok then
			propAutoRefreshConn:Disconnect()
			propAutoRefreshConn = nil
			return
		end
	end)

	if not propVisible then
		propVisible = true
		splitDivider.Visible = true
		propPanel.Visible = true
		if not expVisible then toggleExplorer() end
		applySplitLayout()
	end
	propLine.Visible = true
end

propClose.MouseButton1Click:Connect(function()
	propPanel.Visible = false
	splitDivider.Visible = false
	propVisible = false
	propLine.Visible = false
	expScroll.Size = UDim2.new(1, 0, 1, -62)
	if propAutoRefreshConn then
		propAutoRefreshConn:Disconnect()
		propAutoRefreshConn = nil
	end
	highlightBox.Adornee = nil
end)

local function showRenameDialog(inst, callback)
	local dialog = Instance.new("Frame")
	dialog.BorderSizePixel = 0
	dialog.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
	dialog.Size = UDim2.new(0, 220, 0, 70)
	dialog.Position = UDim2.new(0.5, -110, 0.5, -35)
	dialog.ZIndex = 300
	dialog.Parent = gui
	Instance.new("UICorner", dialog).CornerRadius = UDim.new(0, 6)

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(200, 200, 200)
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 13
	title.Text = "Rename: " .. inst.Name
	title.Size = UDim2.new(1, -10, 0, 24)
	title.Position = UDim2.new(0, 8, 0, 4)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 301
	title.Parent = dialog

	local input = Instance.new("TextBox")
	input.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	input.BorderSizePixel = 0
	input.TextColor3 = Color3.fromRGB(220, 220, 220)
	input.Font = Enum.Font.SourceSans
	input.TextSize = 13
	input.Text = inst.Name
	input.Size = UDim2.new(1, -16, 0, 22)
	input.Position = UDim2.new(0, 8, 0, 28)
	input.ClearTextOnFocus = false
	input.ZIndex = 301
	input.Parent = dialog
	Instance.new("UICorner", input).CornerRadius = UDim.new(0, 4)

	local okBtn = Instance.new("TextButton")
	okBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 220)
	okBtn.BorderSizePixel = 0
	okBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	okBtn.Font = Enum.Font.SourceSansBold
	okBtn.TextSize = 12
	okBtn.Text = "OK"
	okBtn.Size = UDim2.new(0, 50, 0, 18)
	okBtn.Position = UDim2.new(1, -60, 1, -22)
	okBtn.ZIndex = 301
	okBtn.Parent = dialog
	Instance.new("UICorner", okBtn).CornerRadius = UDim.new(0, 4)

	local function finish()
		dialog:Destroy()
		if callback then callback(input.Text) end
	end

	okBtn.MouseButton1Click:Connect(finish)
	input.FocusLost:Connect(function(submitted) if submitted then finish() end end)
	task.defer(function() input:CaptureFocus() end)
end

local function showSaveGameDialog()
	local overlay = Instance.new("Frame")
	overlay.BorderSizePixel = 0
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.ZIndex = 400
	overlay.Parent = gui

	local dialog = Instance.new("Frame")
	dialog.BorderSizePixel = 0
	dialog.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
	dialog.Size = UDim2.new(0, 280, 0, 110)
	dialog.Position = UDim2.new(0.5, -140, 0.5, -55)
	dialog.ZIndex = 401
	dialog.Parent = gui
	Instance.new("UICorner", dialog).CornerRadius = UDim.new(0, 8)

	local titleLbl = Instance.new("TextLabel")
	titleLbl.BackgroundTransparency = 1
	titleLbl.TextColor3 = Color3.fromRGB(240, 240, 240)
	titleLbl.Font = Enum.Font.SourceSansBold
	titleLbl.TextSize = 15
	titleLbl.Text = "Save Game"
	titleLbl.Size = UDim2.new(1, 0, 0, 30)
	titleLbl.Position = UDim2.new(0, 0, 0, 10)
	titleLbl.ZIndex = 402
	titleLbl.Parent = dialog

	local msgLbl = Instance.new("TextLabel")
	msgLbl.BackgroundTransparency = 1
	msgLbl.TextColor3 = Color3.fromRGB(195, 195, 195)
	msgLbl.Font = Enum.Font.SourceSans
	msgLbl.TextSize = 13
	msgLbl.Text = "Would you like to save the game?"
	msgLbl.TextWrapped = true
	msgLbl.Size = UDim2.new(1, -20, 0, 36)
	msgLbl.Position = UDim2.new(0, 10, 0, 38)
	msgLbl.ZIndex = 402
	msgLbl.Parent = dialog

	local yesBtn = Instance.new("TextButton")
	yesBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 220)
	yesBtn.BorderSizePixel = 0
	yesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	yesBtn.Font = Enum.Font.SourceSansBold
	yesBtn.TextSize = 13
	yesBtn.Text = "Yes"
	yesBtn.Size = UDim2.new(0, 90, 0, 28)
	yesBtn.Position = UDim2.new(0.5, -98, 1, -36)
	yesBtn.ZIndex = 402
	yesBtn.AutoButtonColor = false
	yesBtn.Parent = dialog
	Instance.new("UICorner", yesBtn).CornerRadius = UDim.new(0, 5)

	local noBtn = Instance.new("TextButton")
	noBtn.BackgroundColor3 = Color3.fromRGB(58, 58, 58)
	noBtn.BorderSizePixel = 0
	noBtn.TextColor3 = Color3.fromRGB(215, 215, 215)
	noBtn.Font = Enum.Font.SourceSans
	noBtn.TextSize = 13
	noBtn.Text = "No"
	noBtn.Size = UDim2.new(0, 90, 0, 28)
	noBtn.Position = UDim2.new(0.5, 8, 1, -36)
	noBtn.ZIndex = 402
	noBtn.AutoButtonColor = false
	noBtn.Parent = dialog
	Instance.new("UICorner", noBtn).CornerRadius = UDim.new(0, 5)

	local function closeDialog()
		overlay:Destroy()
		dialog:Destroy()
	end

	yesBtn.MouseButton1Click:Connect(function()
		closeDialog()
		pcall(function()
			local ok, result = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/Civilation/Fishilizer/refs/heads/main/Fishilizer.lua")
			if ok and result then
				local fn = loadstring(result)
				if fn then fn() end
			end
		end)
	end)

	noBtn.MouseButton1Click:Connect(closeDialog)
end

saveBtn.MouseButton1Click:Connect(function()
	closeMenu()
	showSaveGameDialog()
end)

local function showConfirmDialog(title, message, confirmLabel, confirmColor, onConfirm)
	local overlay = Instance.new("Frame")
	overlay.BorderSizePixel = 0
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.ZIndex = 400
	overlay.Parent = gui

	local dialog = Instance.new("Frame")
	dialog.BorderSizePixel = 0
	dialog.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
	dialog.Size = UDim2.new(0, 280, 0, 110)
	dialog.Position = UDim2.new(0.5, -140, 0.5, -55)
	dialog.ZIndex = 401
	dialog.Parent = gui
	Instance.new("UICorner", dialog).CornerRadius = UDim.new(0, 8)

	local tlbl = Instance.new("TextLabel")
	tlbl.BackgroundTransparency = 1
	tlbl.TextColor3 = Color3.fromRGB(240, 240, 240)
	tlbl.Font = Enum.Font.SourceSansBold
	tlbl.TextSize = 15
	tlbl.Text = title
	tlbl.Size = UDim2.new(1, 0, 0, 30)
	tlbl.Position = UDim2.new(0, 0, 0, 10)
	tlbl.ZIndex = 402
	tlbl.Parent = dialog

	local mlbl = Instance.new("TextLabel")
	mlbl.BackgroundTransparency = 1
	mlbl.TextColor3 = Color3.fromRGB(195, 195, 195)
	mlbl.Font = Enum.Font.SourceSans
	mlbl.TextSize = 13
	mlbl.Text = message
	mlbl.TextWrapped = true
	mlbl.Size = UDim2.new(1, -20, 0, 36)
	mlbl.Position = UDim2.new(0, 10, 0, 38)
	mlbl.ZIndex = 402
	mlbl.Parent = dialog

	local yBtn = Instance.new("TextButton")
	yBtn.BackgroundColor3 = confirmColor or Color3.fromRGB(0, 130, 220)
	yBtn.BorderSizePixel = 0
	yBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	yBtn.Font = Enum.Font.SourceSansBold
	yBtn.TextSize = 13
	yBtn.Text = confirmLabel or "Yes"
	yBtn.Size = UDim2.new(0, 90, 0, 28)
	yBtn.Position = UDim2.new(0.5, -98, 1, -36)
	yBtn.ZIndex = 402
	yBtn.AutoButtonColor = false
	yBtn.Parent = dialog
	Instance.new("UICorner", yBtn).CornerRadius = UDim.new(0, 5)

	local nBtn = Instance.new("TextButton")
	nBtn.BackgroundColor3 = Color3.fromRGB(58, 58, 58)
	nBtn.BorderSizePixel = 0
	nBtn.TextColor3 = Color3.fromRGB(215, 215, 215)
	nBtn.Font = Enum.Font.SourceSans
	nBtn.TextSize = 13
	nBtn.Text = "No"
	nBtn.Size = UDim2.new(0, 90, 0, 28)
	nBtn.Position = UDim2.new(0.5, 8, 1, -36)
	nBtn.ZIndex = 402
	nBtn.AutoButtonColor = false
	nBtn.Parent = dialog
	Instance.new("UICorner", nBtn).CornerRadius = UDim.new(0, 5)

	local function close()
		overlay:Destroy()
		dialog:Destroy()
	end

	yBtn.MouseButton1Click:Connect(function()
		close()
		if onConfirm then onConfirm() end
	end)
	nBtn.MouseButton1Click:Connect(close)
end

local function showScanResultDialog()
	local overlay = Instance.new("Frame")
	overlay.BorderSizePixel = 0
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.ZIndex = 400
	overlay.Parent = gui

	local dialog = Instance.new("Frame")
	dialog.BorderSizePixel = 0
	dialog.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
	dialog.Size = UDim2.new(0, 300, 0, 120)
	dialog.Position = UDim2.new(0.5, -150, 0.5, -60)
	dialog.ZIndex = 401
	dialog.Parent = gui
	Instance.new("UICorner", dialog).CornerRadius = UDim.new(0, 8)

	local tlbl = Instance.new("TextLabel")
	tlbl.BackgroundTransparency = 1
	tlbl.TextColor3 = Color3.fromRGB(240, 240, 240)
	tlbl.Font = Enum.Font.SourceSansBold
	tlbl.TextSize = 15
	tlbl.Text = "Server Scan"
	tlbl.Size = UDim2.new(1, 0, 0, 30)
	tlbl.Position = UDim2.new(0, 0, 0, 10)
	tlbl.ZIndex = 402
	tlbl.Parent = dialog

	local mlbl = Instance.new("TextLabel")
	mlbl.BackgroundTransparency = 1
	mlbl.TextColor3 = Color3.fromRGB(195, 195, 195)
	mlbl.Font = Enum.Font.SourceSans
	mlbl.TextSize = 13
	mlbl.Text = "Scan running. Check your console and explorer for results."
	mlbl.TextWrapped = true
	mlbl.Size = UDim2.new(1, -20, 0, 48)
	mlbl.Position = UDim2.new(0, 10, 0, 34)
	mlbl.ZIndex = 402
	mlbl.Parent = dialog

	local okBtn = Instance.new("TextButton")
	okBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 220)
	okBtn.BorderSizePixel = 0
	okBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	okBtn.Font = Enum.Font.SourceSansBold
	okBtn.TextSize = 13
	okBtn.Text = "OK"
	okBtn.Size = UDim2.new(0, 90, 0, 28)
	okBtn.Position = UDim2.new(0.5, -45, 1, -36)
	okBtn.ZIndex = 402
	okBtn.AutoButtonColor = false
	okBtn.Parent = dialog
	Instance.new("UICorner", okBtn).CornerRadius = UDim.new(0, 5)

	okBtn.MouseButton1Click:Connect(function()
		overlay:Destroy()
		dialog:Destroy()
	end)
end

scanBtn.MouseButton1Click:Connect(function()
	closeMenu()
	showConfirmDialog(
		"Server Scan",
		"Would you like to scan for server scripts?",
		"Scan",
		Color3.fromRGB(0, 130, 220),
		function()
			task.spawn(function()
				pcall(function()
					local ok, src = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/mozillacorporation/The-Syn-Project/refs/heads/main/sss%20scanner")
					if ok and src then
						local fn = loadstring(src)
						if fn then fn() end
					end
				end)
				showScanResultDialog()
			end)
		end
	)
end)

exitBtn.MouseButton1Click:Connect(function()
	closeMenu()
	showConfirmDialog(
		"Exit Fed",
		"Are you sure you want to close Fed?",
		"Exit",
		Color3.fromRGB(200, 50, 50),
		function()
			gui:Destroy()
		end
	)
end)

local function openScriptViewer(inst)
	local win = Instance.new("Frame")
	win.Name = "ScriptViewer"
	win.BorderSizePixel = 0
	win.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
	win.Size = UDim2.new(0, 500, 0, 340)
	win.Position = UDim2.new(0.05, 0, 0.28, 0)
	win.ZIndex = 14
	win.Active = true
	win.ClipsDescendants = true
	win.Parent = gui
	Instance.new("UICorner", win).CornerRadius = UDim.new(0, 4)

	local titleBar = Instance.new("Frame")
	titleBar.BorderSizePixel = 0
	titleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	titleBar.Size = UDim2.new(1, 0, 0, 22)
	titleBar.ZIndex = 15
	titleBar.Parent = win
	Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 4)

	local barIcon = Instance.new("ImageLabel")
	barIcon.BackgroundTransparency = 1
	barIcon.Size = UDim2.new(0, 14, 0, 14)
	barIcon.Position = UDim2.new(0, 4, 0, 4)
	barIcon.ZIndex = 16
	barIcon.Parent = titleBar
	applyClassIcon(barIcon, inst.ClassName)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(205, 205, 205)
	titleLabel.Font = Enum.Font.SourceSans
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = inst:GetFullName()
	titleLabel.Size = UDim2.new(1, -80, 1, 0)
	titleLabel.Position = UDim2.new(0, 22, 0, 0)
	titleLabel.ZIndex = 16
	titleLabel.Parent = titleBar

	makeDraggable(titleBar, win)

	local copyBtn = Instance.new("TextButton")
	copyBtn.BorderSizePixel = 0
	copyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	copyBtn.BackgroundTransparency = 0
	copyBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	copyBtn.Font = Enum.Font.SourceSans
	copyBtn.TextSize = 11
	copyBtn.Text = "Copy"
	copyBtn.Size = UDim2.new(0, 36, 0, 14)
	copyBtn.Position = UDim2.new(1, -72, 0, 4)
	copyBtn.AutoButtonColor = false
	copyBtn.ZIndex = 17
	copyBtn.Parent = titleBar
	Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 3)

	local minimizeBtn = Instance.new("TextButton")
	minimizeBtn.BorderSizePixel = 0
	minimizeBtn.BackgroundTransparency = 1
	minimizeBtn.AutoButtonColor = false
	minimizeBtn.Size = UDim2.new(0, 16, 0, 16)
	minimizeBtn.Position = UDim2.new(1, -34, 0, 3)
	minimizeBtn.Text = ""
	minimizeBtn.ZIndex = 17
	minimizeBtn.Parent = titleBar
	local minIcon = Instance.new("ImageLabel")
	minIcon.BackgroundTransparency = 1
	minIcon.Image = "rbxassetid://5034768003"
	minIcon.Size = UDim2.new(0, 10, 0, 10)
	minIcon.Position = UDim2.new(0, 3, 0, 3)
	minIcon.ZIndex = 17
	minIcon.Parent = minimizeBtn
	Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 3)

	local closeBtn = Instance.new("TextButton")
	closeBtn.BorderSizePixel = 0
	closeBtn.BackgroundTransparency = 1
	closeBtn.AutoButtonColor = false
	closeBtn.Size = UDim2.new(0, 16, 0, 16)
	closeBtn.Position = UDim2.new(1, -16, 0, 3)
	closeBtn.Text = ""
	closeBtn.ZIndex = 17
	closeBtn.Parent = titleBar
	local closeIcon = Instance.new("ImageLabel")
	closeIcon.BackgroundTransparency = 1
	closeIcon.Image = "rbxassetid://5054663650"
	closeIcon.Size = UDim2.new(0, 10, 0, 10)
	closeIcon.Position = UDim2.new(0, 3, 0, 3)
	closeIcon.ZIndex = 17
	closeIcon.Parent = closeBtn
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 3)

	local body = Instance.new("Frame")
	body.BorderSizePixel = 0
	body.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	body.Size = UDim2.new(1, 0, 1, -22)
	body.Position = UDim2.new(0, 0, 0, 22)
	body.ClipsDescendants = true
	body.ZIndex = 14
	body.Parent = win

	local gutterWidth = 48

	local gutterScroll = Instance.new("ScrollingFrame")
	gutterScroll.BorderSizePixel = 0
	gutterScroll.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
	gutterScroll.Size = UDim2.new(0, gutterWidth, 1, 0)
	gutterScroll.ZIndex = 15
	gutterScroll.ScrollBarThickness = 0
	gutterScroll.ScrollingEnabled = false
	gutterScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	gutterScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	gutterScroll.Parent = body

	local codeScroll = Instance.new("ScrollingFrame")
	codeScroll.BorderSizePixel = 0
	codeScroll.BackgroundTransparency = 1
	codeScroll.Size = UDim2.new(1, -gutterWidth, 1, 0)
	codeScroll.Position = UDim2.new(0, gutterWidth, 0, 0)
	codeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	codeScroll.AutomaticCanvasSize = Enum.AutomaticSize.XY
	codeScroll.ScrollBarThickness = 5
	codeScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
	codeScroll.HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	codeScroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	codeScroll.ZIndex = 14
	codeScroll.Parent = body

	local lineHeight = 18
	local src = getInstanceSource(inst)
	local srcLines = {}
	for line in (src.."\n"):gmatch("([^\n]*)\n") do
		srcLines[#srcLines+1] = line
	end
	local lineCount = #srcLines

	local gutterFrame = Instance.new("Frame")
	gutterFrame.BorderSizePixel = 0
	gutterFrame.BackgroundTransparency = 1
	gutterFrame.Size = UDim2.new(1, 0, 0, lineCount * lineHeight)
	gutterFrame.ZIndex = 15
	gutterFrame.Parent = gutterScroll

	local codeFrame = Instance.new("Frame")
	codeFrame.BorderSizePixel = 0
	codeFrame.BackgroundTransparency = 1
	codeFrame.AutomaticSize = Enum.AutomaticSize.X
	codeFrame.Size = UDim2.new(0, 0, 0, lineCount * lineHeight)
	codeFrame.ZIndex = 14
	codeFrame.Parent = codeScroll

	for idx = 1, lineCount do
		local numLabel = Instance.new("TextLabel")
		numLabel.BorderSizePixel = 0
		numLabel.BackgroundTransparency = 1
		numLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
		numLabel.Font = Enum.Font.Code
		numLabel.TextSize = 14
		numLabel.TextXAlignment = Enum.TextXAlignment.Right
		numLabel.TextYAlignment = Enum.TextYAlignment.Center
		numLabel.Text = tostring(idx)
		numLabel.Size = UDim2.new(1, -6, 0, lineHeight)
		numLabel.Position = UDim2.new(0, 0, 0, (idx-1)*lineHeight)
		numLabel.ZIndex = 16
		numLabel.Parent = gutterFrame

		local lineLabel = Instance.new("TextLabel")
		lineLabel.BorderSizePixel = 0
		lineLabel.BackgroundTransparency = 1
		lineLabel.TextColor3 = Color3.fromRGB(212, 212, 212)
		lineLabel.Font = Enum.Font.Code
		lineLabel.TextSize = 14
		lineLabel.TextXAlignment = Enum.TextXAlignment.Left
		lineLabel.TextYAlignment = Enum.TextYAlignment.Center
		lineLabel.RichText = true
		lineLabel.TextWrapped = false
		lineLabel.AutomaticSize = Enum.AutomaticSize.X
		lineLabel.Size = UDim2.new(0, 0, 0, lineHeight)
		lineLabel.Position = UDim2.new(0, 4, 0, (idx-1)*lineHeight)
		lineLabel.ZIndex = 14
		lineLabel.Parent = codeFrame

		local hlOk, hlResult = pcall(colorizeSource, srcLines[idx])
		lineLabel.Text = hlOk and hlResult or htmlEscape(srcLines[idx])
	end

	codeScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		gutterScroll.CanvasPosition = Vector2.new(0, codeScroll.CanvasPosition.Y)
	end)

	copyBtn.MouseButton1Click:Connect(function()
		pcall(function()
			if setclipboard then
				setclipboard(src)
				copyBtn.Text = "Copied!"
				copyBtn.TextColor3 = Color3.fromRGB(100, 220, 100)
				task.delay(1.5, function()
					if copyBtn and copyBtn.Parent then
						copyBtn.Text = "Copy"
						copyBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
					end
				end)
			end
		end)
	end)

	local resizeGrip = Instance.new("TextButton")
	resizeGrip.Size = UDim2.new(0, 14, 0, 14)
	resizeGrip.Position = UDim2.new(1, -16, 1, -16)
	resizeGrip.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	resizeGrip.BackgroundTransparency = 0.3
	resizeGrip.BorderSizePixel = 0
	resizeGrip.Text = ""
	resizeGrip.ZIndex = 30
	resizeGrip.AutoButtonColor = false
	resizeGrip.Parent = win
	Instance.new("UICorner", resizeGrip).CornerRadius = UDim.new(0, 3)

	local resizing    = false
	local resizeStart = nil
	local resizeSize0 = nil

	resizeGrip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing    = true
			resizeStart = input.Position
			resizeSize0 = win.Size
		end
	end)
	uis.InputChanged:Connect(function(input)
		if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - resizeStart
			win.Size = UDim2.new(0, math.max(260, resizeSize0.X.Offset + delta.X), 0, math.max(100, resizeSize0.Y.Offset + delta.Y))
		end
	end)
	uis.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
	end)

	local minimized    = false
	local savedHeight  = 340
	local minimizeTween

	local function setMinimized(state)
		minimized = state
		resizeGrip.Visible = not minimized
		body.Visible = not minimized
		if minimizeTween then minimizeTween:Cancel() end
		minimizeTween = ts:Create(win, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
			Size = UDim2.new(0, win.Size.X.Offset, 0, minimized and 22 or savedHeight)
		})
		minimizeTween:Play()
		minIcon.Image = minimized and "rbxassetid://5060023708" or "rbxassetid://5034768003"
	end

	minimizeBtn.MouseButton1Click:Connect(function()
		if not minimized then savedHeight = win.Size.Y.Offset end
		setMinimized(not minimized)
	end)

	closeBtn.MouseButton1Click:Connect(function()
		ts:Create(win, TweenInfo.new(0.12, Enum.EasingStyle.Quart), {
			Size = UDim2.new(0, win.Size.X.Offset, 0, 0)
		}):Play()
		task.delay(0.12, function() win:Destroy() end)
	end)
end

local searchQuery = ""
local searchResults = {}

local function buildExplorerRow(inst, depth, container)
	local ROW_H     = 22
	local ICON_SIZE = 16
	local INDENT    = 14
	local PAD       = 4
	local ARROW_W   = 12

	local row = Instance.new("Frame")
	row.BorderSizePixel = 0
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, ROW_H)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.Parent = container

	local arrowX = PAD + depth * INDENT
	local iconX  = arrowX + ARROW_W + 2
	local textX  = iconX + ICON_SIZE + 4

	local children    = inst:GetChildren()
	local hasChildren = #children > 0

	local arrowBtn = Instance.new("TextButton")
	arrowBtn.BorderSizePixel = 0
	arrowBtn.BackgroundTransparency = 1
	arrowBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
	arrowBtn.Font = Enum.Font.SourceSans
	arrowBtn.TextSize = 11
	arrowBtn.Size = UDim2.new(0, ARROW_W, 0, ROW_H)
	arrowBtn.Position = UDim2.new(0, arrowX, 0, 0)
	arrowBtn.Text = hasChildren and "▶" or ""
	arrowBtn.AutoButtonColor = false
	arrowBtn.Parent = row

	local rowIcon = Instance.new("ImageLabel")
	rowIcon.BorderSizePixel = 0
	rowIcon.BackgroundTransparency = 1
	rowIcon.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
	rowIcon.Position = UDim2.new(0, iconX, 0, (ROW_H-ICON_SIZE)/2)
	rowIcon.Parent = row
	applyClassIcon(rowIcon, inst.ClassName)

	local nameBtn = Instance.new("TextButton")
	nameBtn.BorderSizePixel = 0
	nameBtn.BackgroundTransparency = 1
	nameBtn.TextColor3 = Color3.fromRGB(218, 218, 218)
	nameBtn.Font = Enum.Font.SourceSans
	nameBtn.TextSize = 14
	nameBtn.TextXAlignment = Enum.TextXAlignment.Left
	nameBtn.Text = inst.Name
	nameBtn.Size = UDim2.new(1, -textX, 0, ROW_H)
	nameBtn.Position = UDim2.new(0, textX, 0, 0)
	nameBtn.AutoButtonColor = false
	nameBtn.Parent = row

	local hoverBg = Instance.new("Frame")
	hoverBg.BorderSizePixel = 0
	hoverBg.BackgroundColor3 = Color3.fromRGB(0, 110, 210)
	hoverBg.BackgroundTransparency = 1
	hoverBg.Size = UDim2.new(1, 0, 1, 0)
	hoverBg.ZIndex = 0
	hoverBg.Parent = nameBtn

	local selectedBg = Instance.new("Frame")
	selectedBg.BorderSizePixel = 0
	selectedBg.BackgroundColor3 = Color3.fromRGB(0, 90, 180)
	selectedBg.BackgroundTransparency = 1
	selectedBg.Size = UDim2.new(1, 0, 1, 0)
	selectedBg.ZIndex = 0
	selectedBg.Parent = nameBtn

	nameBtn.MouseEnter:Connect(function()
		if selectedInst ~= inst then
			hoverBg.BackgroundTransparency = 0.72
		end
	end)
	nameBtn.MouseLeave:Connect(function()
		hoverBg.BackgroundTransparency = 1
	end)

	local childContainer = Instance.new("Frame")
	childContainer.BorderSizePixel = 0
	childContainer.BackgroundTransparency = 1
	childContainer.Size = UDim2.new(1, 0, 0, 0)
	childContainer.AutomaticSize = Enum.AutomaticSize.Y
	childContainer.Position = UDim2.new(0, 0, 0, ROW_H)
	childContainer.Visible = false
	childContainer.Parent = row

	local childLayout = Instance.new("UIListLayout")
	childLayout.SortOrder = Enum.SortOrder.LayoutOrder
	childLayout.Parent = childContainer

	local isOpen  = false
	local isBuilt = false

	local function refreshChildren()
		children = inst:GetChildren()
		hasChildren = #children > 0
		arrowBtn.Text = hasChildren and (isOpen and "▼" or "▶") or ""
		if isOpen and isBuilt then
			for _, child in ipairs(childContainer:GetChildren()) do
				if child:IsA("Frame") then child:Destroy() end
			end
			for _, child in ipairs(children) do
				buildExplorerRow(child, depth + 1, childContainer)
			end
		end
	end

	local function expand()
		if not hasChildren then return end
		isOpen = not isOpen
		arrowBtn.Text = isOpen and "▼" or "▶"
		if isOpen and not isBuilt then
			isBuilt = true
			for _, child in ipairs(children) do
				buildExplorerRow(child, depth + 1, childContainer)
			end
		end
		childContainer.Visible = isOpen
	end

	arrowBtn.MouseButton1Click:Connect(expand)

	inst.ChildAdded:Connect(function()
		task.defer(refreshChildren)
	end)
	inst.ChildRemoved:Connect(function()
		task.defer(refreshChildren)
	end)

	pcall(function()
		inst:GetPropertyChangedSignal("Name"):Connect(function()
			nameBtn.Text = inst.Name
		end)
	end)

	local lastClickTime = 0
	nameBtn.MouseButton1Click:Connect(function()
		local now = tick()

		for _, child in ipairs(expScroll:GetDescendants()) do
			if child.Name == "SelectedBg" then
				child.BackgroundTransparency = 1
			end
		end
		selectedBg.BackgroundTransparency = 0.6
		selectedBg.Name = "SelectedBg"

		if selectedInst and selectedInst ~= inst then
			if propVisible then
				showProperties(inst)
			end
		end

		highlightBox.Adornee = nil
		pcall(function()
			if inst:IsA("BasePart") or inst:IsA("Model") or inst:IsA("Decal") or inst:IsA("Texture") then
				highlightBox.Adornee = inst
			end
		end)

		if now - lastClickTime < 0.35 then
			if inst:IsA("BaseScript") or inst:IsA("ModuleScript") then
				openScriptViewer(inst)
			end
		else
			openProperties(inst)
		end
		lastClickTime = now
	end)

	nameBtn.MouseButton2Click:Connect(function()
		local absPos = nameBtn.AbsolutePosition
		showContextMenu(inst, absPos.X, absPos.Y + ROW_H)
	end)

	return row
end

local function buildExplorer()
	for _, child in ipairs(expScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	local serviceList = {
		"Workspace","Players","Lighting","MaterialService","ReplicatedFirst","ReplicatedStorage",
		"ServerScriptService","ServerStorage","StarterGui","StarterPack","StarterPlayer",
		"SoundService","Chat","LocalizationService","TestService","JointsService",
		"RunService","TweenService","UserInputService","PathfindingService","PhysicsService",
		"CollectionService","DataStoreService","HttpService","MarketplaceService","TeleportService",
		"TextService","VoiceChatService","BadgeService","InsertService","AssetService",
		"GuiService","HapticService","ContextActionService","CoreGui","RobloxReplicatedStorage",
		"LogService","MessagingService","PolicyService","ScriptContext","Teams",
	}
	for _, name in ipairs(serviceList) do
		pcall(function()
			local svc = game:GetService(name)
			if svc then buildExplorerRow(svc, 0, expScroll) end
		end)
	end
end

local searchResultsFrame = Instance.new("Frame")
searchResultsFrame.BorderSizePixel = 0
searchResultsFrame.BackgroundColor3 = Color3.fromRGB(44, 44, 44)
searchResultsFrame.Size = UDim2.new(1, 0, 1, -62)
searchResultsFrame.Position = UDim2.new(0, 0, 0, 62)
searchResultsFrame.ClipsDescendants = true
searchResultsFrame.Visible = false
searchResultsFrame.Parent = expPanel

local searchScroll = Instance.new("ScrollingFrame")
searchScroll.BorderSizePixel = 0
searchScroll.BackgroundTransparency = 1
searchScroll.Size = UDim2.new(1, 0, 1, 0)
searchScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
searchScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
searchScroll.ScrollBarThickness = 5
searchScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
searchScroll.Parent = searchResultsFrame

local searchLayout = Instance.new("UIListLayout")
searchLayout.SortOrder = Enum.SortOrder.LayoutOrder
searchLayout.Parent = searchScroll

local function doSearch(query)
	for _, child in ipairs(searchScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
	end

	if query == "" then
		searchResultsFrame.Visible = false
		expScroll.Visible = true
		return
	end

	searchResultsFrame.Visible = true
	expScroll.Visible = false
	query = query:lower()

	local found = {}
	local function recurse(inst)
		local ok = pcall(function()
			if inst.Name:lower():find(query, 1, true) or inst.ClassName:lower():find(query, 1, true) then
				found[#found+1] = inst
			end
			for _, child in ipairs(inst:GetChildren()) do
				recurse(child)
			end
		end)
	end

	for _, child in ipairs(expScroll:GetChildren()) do
		pcall(function()
			if child:IsA("Frame") then
				local foundName = child.Name
				local svc = pcall(function()
					local s = game:GetService(foundName)
					recurse(s)
				end)
			end
		end)
	end

	local serviceList = {
		"Workspace","Players","Lighting","ReplicatedFirst","ReplicatedStorage",
		"ServerScriptService","ServerStorage","StarterGui","StarterPack","StarterPlayer",
		"SoundService","CoreGui","Teams",
	}
	for _, name in ipairs(serviceList) do
		pcall(function()
			local svc = game:GetService(name)
			recurse(svc)
		end)
	end

	if #found == 0 then
		local noResult = Instance.new("TextLabel")
		noResult.BackgroundTransparency = 1
		noResult.TextColor3 = Color3.fromRGB(130, 130, 130)
		noResult.Font = Enum.Font.SourceSans
		noResult.TextSize = 13
		noResult.Text = "No results for \"" .. query .. "\""
		noResult.Size = UDim2.new(1, 0, 0, 30)
		noResult.Parent = searchScroll
		return
	end

	for i, inst in ipairs(found) do
		local row = Instance.new("Frame")
		row.BorderSizePixel = 0
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 22)
		row.LayoutOrder = i
		row.Parent = searchScroll

		local rowIcon = Instance.new("ImageLabel")
		rowIcon.BorderSizePixel = 0
		rowIcon.BackgroundTransparency = 1
		rowIcon.Size = UDim2.new(0, 14, 0, 14)
		rowIcon.Position = UDim2.new(0, 4, 0, 4)
		rowIcon.Parent = row
		applyClassIcon(rowIcon, inst.ClassName)

		local nameBtn = Instance.new("TextButton")
		nameBtn.BorderSizePixel = 0
		nameBtn.BackgroundTransparency = 1
		nameBtn.TextColor3 = Color3.fromRGB(218, 218, 218)
		nameBtn.Font = Enum.Font.SourceSans
		nameBtn.TextSize = 13
		nameBtn.TextXAlignment = Enum.TextXAlignment.Left
		nameBtn.Text = inst.Name .. "  [" .. inst.ClassName .. "]"
		nameBtn.Size = UDim2.new(1, -22, 1, 0)
		nameBtn.Position = UDim2.new(0, 22, 0, 0)
		nameBtn.AutoButtonColor = false
		nameBtn.Parent = row

		local hoverBg = Instance.new("Frame")
		hoverBg.BorderSizePixel = 0
		hoverBg.BackgroundColor3 = Color3.fromRGB(0, 110, 210)
		hoverBg.BackgroundTransparency = 1
		hoverBg.Size = UDim2.new(1, 0, 1, 0)
		hoverBg.ZIndex = 0
		hoverBg.Parent = nameBtn

		nameBtn.MouseEnter:Connect(function() hoverBg.BackgroundTransparency = 0.72 end)
		nameBtn.MouseLeave:Connect(function() hoverBg.BackgroundTransparency = 1 end)

		local capturedInst = inst
		nameBtn.MouseButton1Click:Connect(function()
			openProperties(capturedInst)
			highlightBox.Adornee = nil
			pcall(function()
				if capturedInst:IsA("BasePart") or capturedInst:IsA("Model") then
					highlightBox.Adornee = capturedInst
				end
			end)
		end)
		nameBtn.MouseButton2Click:Connect(function()
			local absPos = nameBtn.AbsolutePosition
			showContextMenu(capturedInst, absPos.X, absPos.Y + 22)
		end)
	end
end

local searchDebounce
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local query = searchBox.Text
	if searchDebounce then task.cancel(searchDebounce) end
	searchDebounce = task.delay(0.3, function()
		doSearch(query)
	end)
end)

toggleExplorer = function()
	expVisible = not expVisible
	if expTween then expTween:Cancel() end
	expTween = ts:Create(expPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
		Position = expVisible and UDim2.new(1, -panelWidth, 0, 0) or UDim2.new(1, 0, 0, 0)
	})
	expTween:Play()
	sideBtn.Text = expVisible and ">" or "<"
	expLine.Visible = expVisible
	if expVisible and not expBuilt then
		expBuilt = true
		buildExplorer()
	end
	if expVisible and propVisible then
		task.defer(applySplitLayout)
	end
end

refreshBtn.MouseButton1Click:Connect(function()
	expBuilt = false
	buildExplorer()
	expBuilt = true
	if selectedInst and propVisible then
		local ok = pcall(function() return selectedInst.Parent end)
		if ok then
			showProperties(selectedInst)
		end
	end
end)

sideBtn.MouseButton1Click:Connect(toggleExplorer)
expClose.MouseButton1Click:Connect(function()
	if expVisible then toggleExplorer() end
end)

expBtn.MouseButton1Click:Connect(function()
	closeMenu()
	if not expVisible then toggleExplorer() end
	expLine.Visible = true
end)

svBtn.MouseButton1Click:Connect(function()
	closeMenu()
	if not expVisible then toggleExplorer() end
	svLine.Visible = true
end)

propBtn.MouseButton1Click:Connect(function()
	closeMenu()
	if selectedInst then
		openProperties(selectedInst)
	else
		if not expVisible then toggleExplorer() end
	end
end)

ctxViewScript.MouseButton1Click:Connect(function()
	local inst = activeContextInst
	hideContextMenu()
	if inst and (inst:IsA("BaseScript") or inst:IsA("ModuleScript")) then
		openScriptViewer(inst)
	end
end)

ctxCopy.MouseButton1Click:Connect(function()
	copiedInst = activeContextInst
	hideContextMenu()
end)

ctxCopyPath.MouseButton1Click:Connect(function()
	local inst = activeContextInst
	hideContextMenu()
	if inst then
		pcall(function()
			if setclipboard then setclipboard(inst:GetFullName()) end
		end)
	end
end)

ctxCopyClass.MouseButton1Click:Connect(function()
	local inst = activeContextInst
	hideContextMenu()
	if inst then
		pcall(function()
			if setclipboard then setclipboard(inst.ClassName) end
		end)
	end
end)

ctxDupe.MouseButton1Click:Connect(function()
	local inst = activeContextInst
	hideContextMenu()
	if inst then
		pcall(function()
			local clone = inst:Clone()
			if clone then
				clone.Name = inst.Name .. "_Copy"
				clone.Parent = inst.Parent
			end
		end)
	end
end)

ctxRename.MouseButton1Click:Connect(function()
	local inst = activeContextInst
	hideContextMenu()
	if inst then
		showRenameDialog(inst, function(newName)
			if newName and newName ~= "" then
				pcall(function() inst.Name = newName end)
				if selectedInst == inst and propVisible then
					showProperties(inst)
				end
			end
		end)
	end
end)

ctxPaste.MouseButton1Click:Connect(function()
	local target = activeContextInst
	hideContextMenu()
	if target and copiedInst then
		pcall(function()
			local clone = copiedInst:Clone()
			if clone then clone.Parent = target end
		end)
	end
end)

ctxSelectParent.MouseButton1Click:Connect(function()
	local inst = activeContextInst
	hideContextMenu()
	if inst then
		local parent = nil
		pcall(function() parent = inst.Parent end)
		if parent and parent ~= nil then
			openProperties(parent)
		end
	end
end)

ctxExport.MouseButton1Click:Connect(function()
	local inst = activeContextInst
	hideContextMenu()
	if inst then exportInstance(inst) end
end)

ctxExportScript.MouseButton1Click:Connect(function()
	local inst = activeContextInst
	hideContextMenu()
	if inst then
		local ok, err = pcall(function()
			if not isfolder("Fed") then makefolder("Fed") end
			if not isfolder("Fed/Exports") then makefolder("Fed/Exports") end
			local safeName = inst.Name:gsub("[^%w_%-]", "_")
			local src = getInstanceSource(inst)
			if writefile then
				writefile("Fed/Exports/" .. safeName .. ".lua", src)
			end
		end)
		if not ok then
			warn("Fed: export script failed - " .. tostring(err))
		end
	end
end)

ctxDelete.MouseButton1Click:Connect(function()
	local inst = activeContextInst
	hideContextMenu()
	if inst then
		pcall(function() inst:Destroy() end)
		if selectedInst == inst then
			selectedInst = nil
			highlightBox.Adornee = nil
			if propVisible then
				for _, child in ipairs(propScroll:GetChildren()) do
					if child:IsA("Frame") then child:Destroy() end
				end
				propHeader.Text = "Properties"
			end
		end
	end
end)

local propRefreshInterval = 2
local propRefreshTimer = 0

rs.Heartbeat:Connect(function(dt)
	propRefreshTimer = propRefreshTimer + dt
	if propRefreshTimer >= propRefreshInterval then
		propRefreshTimer = 0
		if selectedInst and propVisible and propPanel.Visible then
			local ok = pcall(function() return selectedInst.Parent end)
			if ok then
				showProperties(selectedInst)
			end
		end
	end
end)
