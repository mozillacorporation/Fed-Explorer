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
	if not isfolder("Fed/Assets") then makefolder("Fed/Assets") end
	if not isfolder("Fed/Assets/AICHAT") then makefolder("Fed/Assets/AICHAT") end
end)

local function applyClassIcon(img, cn)
	local path = "Fed/Icons/Class/" .. cn .. ".png"
	local ok = false
	pcall(function()
		if isfile(path) and getcustomasset then
			img.Image = getcustomasset(path)
			ok = true
		end
	end)
	if not ok then
		img.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	end
end

local function makeDraggable(handle, window)
	local drag = false
	local ds, ws
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			drag = true
			ds = input.Position
			ws = window.Position
		end
	end)
	uis.InputChanged:Connect(function(input)
		if drag and input.UserInputType == Enum.UserInputType.MouseMovement then
			local d = input.Position - ds
			window.Position = UDim2.new(ws.X.Scale, ws.X.Offset + d.X, ws.Y.Scale, ws.Y.Offset + d.Y)
		end
	end)
	uis.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
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

local function htmlEsc(str)
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
			parts[#parts+1] = htmlEsc(source:sub(pos, j-1))
			pos = j

		elseif ch == "-" and source:sub(pos, pos+1) == "--" then
			if source:sub(pos, pos+3) == "--[[" then
				local level = 0
				local j = pos + 2
				while source:sub(j,j) == "=" do level = level + 1; j = j + 1 end
				local closeStr = "]" .. string.rep("=", level) .. "]"
				local found = source:find(closeStr, j+1, true)
				local block = found and source:sub(pos, found + #closeStr - 1) or source:sub(pos)
				parts[#parts+1] = '<font color="#57A64A">' .. htmlEsc(block) .. '</font>'
				pos = found and found + #closeStr or len + 1
			else
				local found = source:find("\n", pos)
				local line = found and source:sub(pos, found-1) or source:sub(pos)
				parts[#parts+1] = '<font color="#57A64A">' .. htmlEsc(line) .. '</font>'
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
				parts[#parts+1] = '<font color="#D69D85">' .. htmlEsc(block) .. '</font>'
				pos = found and found + #closeStr or len + 1
			else
				parts[#parts+1] = htmlEsc(ch); pos = pos + 1
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
			parts[#parts+1] = '<font color="#D69D85">' .. htmlEsc(source:sub(pos, j-1)) .. '</font>'
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
			parts[#parts+1] = '<font color="#B5CEA8">' .. htmlEsc(source:sub(pos, j-1)) .. '</font>'
			pos = j

		elseif ch:match("[%a_]") then
			local j = pos
			while j <= len and source:sub(j,j):match("[%w_]") do j = j + 1 end
			local word = source:sub(pos, j-1)
			if luaKeywords[word] then
				parts[#parts+1] = '<font color="#569CD6">' .. htmlEsc(word) .. '</font>'
			elseif word == "self" or word == "_ENV" then
				parts[#parts+1] = '<font color="#9CDCFE">' .. htmlEsc(word) .. '</font>'
			elseif robloxTypes[word] then
				parts[#parts+1] = '<font color="#4EC9B0">' .. htmlEsc(word) .. '</font>'
			elseif globalFunctions[word] then
				parts[#parts+1] = '<font color="#DCDCAA">' .. htmlEsc(word) .. '</font>'
			elseif source:sub(j,j) == "(" then
				parts[#parts+1] = '<font color="#DCDCAA">' .. htmlEsc(word) .. '</font>'
			elseif word:sub(1,1):match("%u") then
				parts[#parts+1] = '<font color="#4EC9B0">' .. htmlEsc(word) .. '</font>'
			else
				parts[#parts+1] = '<font color="#9CDCFE">' .. htmlEsc(word) .. '</font>'
			end
			pos = j

		elseif ch == "." and source:sub(pos, pos+2) == "..." then
			parts[#parts+1] = '<font color="#569CD6">...</font>'; pos = pos + 3
		elseif ch == "~" and source:sub(pos, pos+1) == "~=" then
			parts[#parts+1] = htmlEsc("~="); pos = pos + 2
		elseif ch == "=" and source:sub(pos, pos+1) == "==" then
			parts[#parts+1] = htmlEsc("=="); pos = pos + 2
		elseif ch == "<" and source:sub(pos, pos+1) == "<=" then
			parts[#parts+1] = htmlEsc("<="); pos = pos + 2
		elseif ch == ">" and source:sub(pos, pos+1) == ">=" then
			parts[#parts+1] = htmlEsc(">="); pos = pos + 2
		elseif ch == "." and source:sub(pos, pos+1) == ".." then
			parts[#parts+1] = htmlEsc(".."); pos = pos + 2
		else
			parts[#parts+1] = htmlEsc(ch); pos = pos + 1
		end
	end
	return table.concat(parts)
end

local function isUnderServerService(inst)
	local cur = inst
	while cur do
		local ok, par = pcall(function() return cur.Parent end)
		if not ok or par == nil then break end
		local n = ""
		pcall(function() n = par.Name end)
		if n == "ServerScriptService" or n == "ServerStorage" then return true end
		cur = par
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

local function readProp(inst, pn)
	local ok, v = pcall(function() return inst[pn] end)
	return ok and v or nil, ok and typeof(v) or "error"
end

local function serializeInstance(inst, depth)
	depth = depth or 0
	local indent = string.rep("\t", depth)
	local lines = {}
	lines[#lines+1] = indent .. "Instance: " .. inst.ClassName .. " [" .. inst.Name .. "]"
	local props = {"Position","Size","Color","BrickColor","Transparency","Anchored","CanCollide","Value","Text","Visible","Enabled"}
	for _, pn in ipairs(props) do
		local v, vt = readProp(inst, pn)
		if vt ~= "error" and v ~= nil then
			lines[#lines+1] = indent .. "\t" .. pn .. " = " .. tostring(v)
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
		local safe = inst.Name:gsub("[^%w_%-]", "_")
		local fn = "Fed/Exports/" .. safe .. "_" .. inst.ClassName .. ".txt"
		local content = "Fed Export\nName: " .. inst.Name .. "\nClass: " .. inst.ClassName .. "\nPath: " .. inst:GetFullName() .. "\n\n" .. serializeInstance(inst)
		if writefile then
			writefile(fn, content)
			warn("Fed: exported to " .. fn)
		else
			warn("Fed: writefile not available in this executor")
		end
	end)
	if not ok then
		warn("Fed: export failed - " .. tostring(err))
	end
end

local function applyPropChange(inst, pn, cur, vt, txt)
	local worked = false
	if vt == "boolean" then
		local nb = (txt == "true" or txt == "1" or txt == "True")
		pcall(function() inst[pn] = nb; worked = true end)
	elseif vt == "number" then
		local n = tonumber(txt)
		if n then pcall(function() inst[pn] = n; worked = true end) end
	elseif vt == "string" then
		pcall(function() inst[pn] = txt; worked = true end)
	elseif vt == "Vector3" then
		local x, y, z = txt:match("([%-%.%d]+),%s*([%-%.%d]+),%s*([%-%.%d]+)")
		if x and y and z then
			pcall(function() inst[pn] = Vector3.new(tonumber(x), tonumber(y), tonumber(z)); worked = true end)
		end
	elseif vt == "Vector2" then
		local x, y = txt:match("([%-%.%d]+),%s*([%-%.%d]+)")
		if x and y then
			pcall(function() inst[pn] = Vector2.new(tonumber(x), tonumber(y)); worked = true end)
		end
	elseif vt == "Color3" then
		local r, g, b = txt:match("([%d]+),%s*([%d]+),%s*([%d]+)")
		if r and g and b then
			pcall(function() inst[pn] = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)); worked = true end)
		end
	elseif vt == "UDim2" then
		local xs, xo, ys, yo = txt:match("([%-%.%d]+),%s*([%-%.%d]+),%s*([%-%.%d]+),%s*([%-%.%d]+)")
		if xs and xo and ys and yo then
			pcall(function() inst[pn] = UDim2.new(tonumber(xs), tonumber(xo), tonumber(ys), tonumber(yo)); worked = true end)
		end
	elseif vt == "CFrame" then
		local x, y, z = txt:match("([%-%.%d]+),%s*([%-%.%d]+),%s*([%-%.%d]+)")
		if x and y and z then
			pcall(function()
				local cf = inst[pn]
				inst[pn] = CFrame.new(tonumber(x), tonumber(y), tonumber(z)) * (cf - cf.Position)
				worked = true
			end)
		end
	end
	return worked
end

local aiKey = ""
local aiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key="

local function loadAiKey()
	local k = ""
	pcall(function()
		if isfile("Fed/Assets/aikey.txt") then
			k = readfile("Fed/Assets/aikey.txt") or ""
			k = k:gsub("^%s+", ""):gsub("%s+$", "")
		end
	end)
	return k ~= "" and k or aiKey
end

local function saveAiKey(k)
	pcall(function()
		if not isfolder("Fed") then makefolder("Fed") end
		if not isfolder("Fed/Assets") then makefolder("Fed/Assets") end
		if writefile then writefile("Fed/Assets/aikey.txt", k) end
	end)
end

aiKey = loadAiKey()

local function execRequest(opts)
	if syn and syn.request then return syn.request(opts)
	elseif http and http.request then return http.request(opts)
	elseif request then return request(opts)
	else
		local hs = game:GetService("HttpService")
		return hs:RequestAsync(opts)
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "Fed"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.IgnoreGuiInset = true
gui.Parent = pg

local loadDone = false

local G2L = {}
G2L["1"] = gui

G2L["2"] = Instance.new("Frame", G2L["1"])
G2L["2"].BorderSizePixel = 0
G2L["2"].BackgroundColor3 = Color3.fromRGB(51, 51, 51)
G2L["2"].Size = UDim2.new(0, 400, 0, 250)
G2L["2"].Position = UDim2.new(0.37398, 0, 0.34174, 0)
G2L["2"].BorderColor3 = Color3.fromRGB(0, 0, 0)
G2L["2"].Name = "LoadingFED"
G2L["2"].ZIndex = 1000

G2L["3"] = Instance.new("UICorner", G2L["2"])
G2L["3"].CornerRadius = UDim.new(0, 5)

G2L["4"] = Instance.new("TextLabel", G2L["2"])
G2L["4"].BorderSizePixel = 0
G2L["4"].TextSize = 62
G2L["4"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
G2L["4"].FontFace = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["4"].TextColor3 = Color3.fromRGB(255, 255, 255)
G2L["4"].BackgroundTransparency = 1
G2L["4"].Size = UDim2.new(0, 144, 0, 50)
G2L["4"].BorderColor3 = Color3.fromRGB(0, 0, 0)
G2L["4"].Text = "Fed"
G2L["4"].Name = "FED"
G2L["4"].Position = UDim2.new(0, 0, 0.052, 0)
G2L["4"].ZIndex = 1001

G2L["5"] = Instance.new("TextLabel", G2L["2"])
G2L["5"].BorderSizePixel = 0
G2L["5"].TextSize = 16
G2L["5"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
G2L["5"].FontFace = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["5"].TextColor3 = Color3.fromRGB(255, 255, 255)
G2L["5"].BackgroundTransparency = 1
G2L["5"].Size = UDim2.new(0, 75, 0, 50)
G2L["5"].BorderColor3 = Color3.fromRGB(0, 0, 0)
G2L["5"].Text = "Explorer 2.0.1"
G2L["5"].Name = "altt"
G2L["5"].Position = UDim2.new(0.2825, 0, 0.096, 0)
G2L["5"].ZIndex = 1001

G2L["6"] = Instance.new("TextLabel", G2L["2"])
G2L["6"].TextWrapped = true
G2L["6"].BorderSizePixel = 0
G2L["6"].TextSize = 16
G2L["6"].TextScaled = true
G2L["6"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
G2L["6"].FontFace = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["6"].TextColor3 = Color3.fromRGB(255, 255, 255)
G2L["6"].BackgroundTransparency = 1
G2L["6"].Size = UDim2.new(0, 380, 0, 50)
G2L["6"].BorderColor3 = Color3.fromRGB(0, 0, 0)
G2L["6"].Text = "The most lightweight client-side Roblox explorer built for total inspection flexibility and minimal performance impact."
G2L["6"].Name = "desc"
G2L["6"].Position = UDim2.new(0.025, 0, 0.296, 0)
G2L["6"].ZIndex = 1001

G2L["7"] = Instance.new("TextLabel", G2L["2"])
G2L["7"].BorderSizePixel = 0
G2L["7"].TextSize = 16
G2L["7"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
G2L["7"].FontFace = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["7"].TextColor3 = Color3.fromRGB(255, 255, 255)
G2L["7"].BackgroundTransparency = 1
G2L["7"].Size = UDim2.new(0, 124, 0, 50)
G2L["7"].BorderColor3 = Color3.fromRGB(0, 0, 0)
G2L["7"].Text = "Developed by 7n8z"
G2L["7"].Name = "cred"
G2L["7"].Position = UDim2.new(0.69, 0, 0.096, 0)
G2L["7"].ZIndex = 1001

G2L["8"] = Instance.new("TextLabel", G2L["2"])
G2L["8"].BorderSizePixel = 0
G2L["8"].TextSize = 16
G2L["8"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
G2L["8"].FontFace = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["8"].TextColor3 = Color3.fromRGB(255, 255, 255)
G2L["8"].BackgroundTransparency = 1
G2L["8"].Size = UDim2.new(0, 124, 0, 50)
G2L["8"].BorderColor3 = Color3.fromRGB(0, 0, 0)
G2L["8"].Text = "Public Edition"
G2L["8"].Name = "ver"
G2L["8"].Position = UDim2.new(0.69, 0, 0, 0)
G2L["8"].ZIndex = 1001

G2L["9"] = Instance.new("Frame", G2L["2"])
G2L["9"].BorderSizePixel = 0
G2L["9"].BackgroundColor3 = Color3.fromRGB(37, 37, 38)
G2L["9"].Size = UDim2.new(0, 400, 0, 20)
G2L["9"].Position = UDim2.new(0, 0, 0.544, 0)
G2L["9"].BorderColor3 = Color3.fromRGB(0, 0, 0)
G2L["9"].Name = "probar"
G2L["9"].ZIndex = 1001

G2L["a"] = Instance.new("Frame", G2L["9"])
G2L["a"].BorderSizePixel = 0
G2L["a"].BackgroundColor3 = Color3.fromRGB(0, 131, 221)
G2L["a"].Size = UDim2.new(0, 0, 1, 0)
G2L["a"].Position = UDim2.new(0, 0, 0, 0)
G2L["a"].BorderColor3 = Color3.fromRGB(0, 0, 0)
G2L["a"].Name = "prokes"
G2L["a"].ZIndex = 1002

G2L["b"] = Instance.new("TextLabel", G2L["2"])
G2L["b"].BorderSizePixel = 0
G2L["b"].TextSize = 16
G2L["b"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
G2L["b"].FontFace = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["b"].TextColor3 = Color3.fromRGB(255, 255, 255)
G2L["b"].BackgroundTransparency = 1
G2L["b"].Size = UDim2.new(0, 400, 0, 25)
G2L["b"].BorderColor3 = Color3.fromRGB(0, 0, 0)
G2L["b"].Text = "0%"
G2L["b"].Name = "percen"
G2L["b"].Position = UDim2.new(0, 0, 0.668, 0)
G2L["b"].ZIndex = 1001

G2L["c"] = Instance.new("TextLabel", G2L["2"])
G2L["c"].BorderSizePixel = 0
G2L["c"].TextSize = 16
G2L["c"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
G2L["c"].FontFace = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["c"].TextColor3 = Color3.fromRGB(255, 255, 255)
G2L["c"].BackgroundTransparency = 1
G2L["c"].Size = UDim2.new(0, 400, 0, 25)
G2L["c"].BorderColor3 = Color3.fromRGB(0, 0, 0)
G2L["c"].Text = "Initializing..."
G2L["c"].Name = "fnf"
G2L["c"].Position = UDim2.new(0, 0, 0.804, 0)
G2L["c"].ZIndex = 1001

local loadWin = G2L["2"]
local loadBar = G2L["a"]
local loadPercent = G2L["b"]
local loadStatus = G2L["c"]

local cGreen  = Color3.fromRGB(80, 220, 100)
local cRed    = Color3.fromRGB(255, 90, 90)
local cYellow = Color3.fromRGB(255, 180, 50)

local function setLoadProgress(pct)
	ts:Create(loadBar, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
		Size = UDim2.new(pct, 0, 1, 0)
	}):Play()
	loadPercent.Text = math.floor(pct * 100) .. "%"
end

local function setLoadStatus(txt, col)
	loadStatus.Text = txt
	loadStatus.TextColor3 = col or Color3.fromRGB(255, 255, 255)
end

task.spawn(function()
	task.wait(0.3)

	setLoadStatus("Fed folder: Checking...", Color3.fromRGB(200, 200, 200))
	task.wait(0.18)
	local hasFed = false
	pcall(function() hasFed = isfolder("Fed") end)
	setLoadStatus(hasFed and "Fed folder: Found" or "Fed folder: Not Found", hasFed and cGreen or cRed)
	setLoadProgress(0.25)
	task.wait(0.28)

	setLoadStatus("Logo: Checking...", Color3.fromRGB(200, 200, 200))
	task.wait(0.1)
	local hasLogo = false
	pcall(function() hasLogo = isfile("Fed/Icons/fedlogo.png") end)
	setLoadStatus(hasLogo and "Logo: Found" or "Logo: Not Found", hasLogo and cGreen or cRed)
	setLoadProgress(0.5)
	task.wait(0.28)

	setLoadStatus("Icons: Checking...", Color3.fromRGB(200, 200, 200))
	task.wait(0.1)
	local hasIcons = false
	pcall(function() hasIcons = isfolder("Fed/Icons/Class") end)
	setLoadStatus(hasIcons and "Icons: Found" or "Icons: Not Found", hasIcons and cGreen or cRed)
	setLoadProgress(0.75)
	task.wait(0.28)

	setLoadStatus("AI Key: Checking...", Color3.fromRGB(200, 200, 200))
	task.wait(0.1)
	local hasKey = aiKey ~= ""
	setLoadStatus(hasKey and "AI Key: Found" or "AI Key: Not Set", hasKey and cGreen or cYellow)
	setLoadProgress(1)
	task.wait(0.5)

	ts:Create(loadWin, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {BackgroundTransparency = 1}):Play()
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

local ctxMenu = Instance.new("Frame")
ctxMenu.Name = "ContextMenu"
ctxMenu.BorderSizePixel = 0
ctxMenu.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
ctxMenu.Size = UDim2.new(0, 148, 0, 0)
ctxMenu.ZIndex = 200
ctxMenu.ClipsDescendants = true
ctxMenu.Visible = false
ctxMenu.Parent = gui
Instance.new("UICorner", ctxMenu).CornerRadius = UDim.new(0, 5)

local ctxStroke = Instance.new("UIStroke")
ctxStroke.Color = Color3.fromRGB(70, 70, 70)
ctxStroke.Thickness = 1
ctxStroke.Parent = ctxMenu

local ctxLayout = Instance.new("UIListLayout")
ctxLayout.SortOrder = Enum.SortOrder.LayoutOrder
ctxLayout.Padding = UDim.new(0, 0)
ctxLayout.Parent = ctxMenu

local ctxPad = Instance.new("UIPadding")
ctxPad.PaddingTop = UDim.new(0, 3)
ctxPad.PaddingBottom = UDim.new(0, 3)
ctxPad.Parent = ctxMenu

local activeCtxInst = nil
local copiedInst = nil

local function hideCtx()
	ctxMenu.Visible = false
	activeCtxInst = nil
end

local function makeCtxItem(label, order, tcol)
	local btn = Instance.new("TextButton")
	btn.BorderSizePixel = 0
	btn.BackgroundTransparency = 1
	btn.TextColor3 = tcol or Color3.fromRGB(215, 215, 215)
	btn.Font = Enum.Font.SourceSans
	btn.TextSize = 13
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Size = UDim2.new(1, 0, 0, 24)
	btn.LayoutOrder = order
	btn.AutoButtonColor = false
	btn.ZIndex = 201
	btn.Parent = ctxMenu

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.Parent = btn

	local hf = Instance.new("Frame")
	hf.BorderSizePixel = 0
	hf.BackgroundColor3 = Color3.fromRGB(0, 110, 210)
	hf.BackgroundTransparency = 1
	hf.Size = UDim2.new(1, 0, 1, 0)
	hf.ZIndex = btn.ZIndex - 1
	hf.Parent = btn

	btn.MouseEnter:Connect(function() hf.BackgroundTransparency = 0.6 end)
	btn.MouseLeave:Connect(function() hf.BackgroundTransparency = 1 end)
	btn.Text = label
	return btn
end

local ctxViewScript   = makeCtxItem("View Script",    1)
local ctxCopy         = makeCtxItem("Copy",           2)
local ctxCopyPath     = makeCtxItem("Copy Path",      3)
local ctxCopyClass    = makeCtxItem("Copy ClassName", 4)
local ctxDupe         = makeCtxItem("Duplicate",      5)
local ctxRename       = makeCtxItem("Rename",         6)
local ctxPaste        = makeCtxItem("Paste Into",     7)
local ctxSelParent    = makeCtxItem("Select Parent",  8)
local ctxExport       = makeCtxItem("Export",         9)
local ctxExpScript    = makeCtxItem("Export Script",  10)
local ctxDelete       = makeCtxItem("Delete",         11, Color3.fromRGB(255, 100, 100))

local CTX_H = 24
local CTX_PAD = 6
local allCtxItems = {ctxViewScript,ctxCopy,ctxCopyPath,ctxCopyClass,ctxDupe,ctxRename,ctxPaste,ctxSelParent,ctxExport,ctxExpScript,ctxDelete}

local function countVisible(items)
	local n = 0
	for _, item in ipairs(items) do
		if item.Visible then n = n + 1 end
	end
	return n
end

local function showCtx(inst, x, y)
	activeCtxInst = inst
	local isScript = inst:IsA("BaseScript") or inst:IsA("ModuleScript")
	ctxViewScript.Visible = isScript
	ctxExpScript.Visible = isScript
	local vc = countVisible(allCtxItems)
	ctxMenu.Size = UDim2.new(0, 148, 0, vc * CTX_H + CTX_PAD)
	ctxMenu.Position = UDim2.new(0, x, 0, y)
	ctxMenu.Visible = true
end

local function ptInFrame(frame, x, y)
	local pos = frame.AbsolutePosition
	local sz = frame.AbsoluteSize
	return x >= pos.X and x <= pos.X + sz.X and y >= pos.Y and y <= pos.Y + sz.Y
end

uis.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if ctxMenu.Visible then
			if not ptInFrame(ctxMenu, input.Position.X, input.Position.Y) then
				hideCtx()
			end
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
	top.Position = UDim2.new(0.5, 0, 0, 2)
	top.AnchorPoint = Vector2.new(0.5, 0)
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
dropMenu.Size = UDim2.new(0, 0, 0, 0)
dropMenu.AutomaticSize = Enum.AutomaticSize.X
dropMenu.Position = UDim2.new(0, -208, 1, 6)
dropMenu.ClipsDescendants = true
dropMenu.ZIndex = 60
dropMenu.Parent = mainTop
Instance.new("UICorner", dropMenu).CornerRadius = UDim.new(0, 6)

local dropLayout = Instance.new("UIListLayout")
dropLayout.FillDirection = Enum.FillDirection.Horizontal
dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
dropLayout.VerticalAlignment = Enum.VerticalAlignment.Center
dropLayout.Padding = UDim.new(0, 2)
dropLayout.Parent = dropMenu

local dropPad = Instance.new("UIPadding")
dropPad.PaddingLeft = UDim.new(0, 4)
dropPad.PaddingRight = UDim.new(0, 4)
dropPad.Parent = dropMenu

local menuOpen = false

local function closeMenu()
	menuOpen = false
	ts:Create(dropMenu, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {Size=UDim2.new(0,dropMenu.AbsoluteSize.X,0,0)}):Play()
	dropMenu.AutomaticSize = Enum.AutomaticSize.None
	task.delay(0.15, function()
		dropMenu.AutomaticSize = Enum.AutomaticSize.X
	end)
end

local function openMenu()
	menuOpen = true
	dropMenu.AutomaticSize = Enum.AutomaticSize.X
	ts:Create(dropMenu, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {Size=UDim2.new(0,dropMenu.AbsoluteSize.X,0,46)}):Play()
end

topBtn.MouseButton1Click:Connect(function()
	if menuOpen then closeMenu() else openMenu() end
end)

local function makeMenuTab(text, order)
	local btn = Instance.new("TextButton")
	btn.BorderSizePixel = 0
	btn.BackgroundTransparency = 1
	btn.TextColor3 = Color3.fromRGB(200, 200, 200)
	btn.Font = Enum.Font.SourceSans
	btn.TextSize = 15
	btn.Text = text
	btn.AutomaticSize = Enum.AutomaticSize.X
	btn.Size = UDim2.new(0, 0, 0, 36)
	btn.LayoutOrder = order
	btn.ZIndex = 61
	btn.AutoButtonColor = false
	btn.Parent = dropMenu

	local bp = Instance.new("UIPadding")
	bp.PaddingLeft = UDim.new(0, 8)
	bp.PaddingRight = UDim.new(0, 8)
	bp.Parent = btn

	local uline = Instance.new("Frame")
	uline.BorderSizePixel = 0
	uline.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	uline.Size = UDim2.new(1, -6, 0, 2)
	uline.Position = UDim2.new(0, 3, 1, -4)
	uline.Visible = false
	uline.ZIndex = 62
	uline.Parent = btn
	return btn, uline
end

local svBtn,   svLine   = makeMenuTab("Script viewer", 1)
local expBtn,  expLine  = makeMenuTab("Explorer",      2)
local propBtn, propLine = makeMenuTab("Properties",    3)
local saveBtn, saveLine = makeMenuTab("Save game",     4)
local scanBtn, scanLine = makeMenuTab("Server scan",   5)
local conBtn,  conLine  = makeMenuTab("Console",       6)
local aiBtn,   aiLine   = makeMenuTab("AI",            7)
local exitBtn, exitLine = makeMenuTab("Exit",          8)

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
expHeaderLabel.Text = "Fed Explorer V2.0.1"
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

local function makeCloseBtn(parent, zi, yo)
	local btn = Instance.new("TextButton")
	btn.BorderSizePixel = 0
	btn.BackgroundTransparency = 1
	btn.AutoButtonColor = false
	btn.Size = UDim2.new(0, 16, 0, 16)
	btn.Position = UDim2.new(1, -18, 0, yo)
	btn.Text = ""
	btn.ZIndex = zi
	btn.Parent = parent
	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://5054663650"
	icon.Size = UDim2.new(0, 10, 0, 10)
	icon.Position = UDim2.new(0, 3, 0, 3)
	icon.ZIndex = zi
	icon.Parent = btn
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 3)
	return btn
end

local expClose = makeCloseBtn(expHeader, 4, 9)

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

local sbPad = Instance.new("UIPadding")
sbPad.PaddingLeft = UDim.new(0, 6)
sbPad.Parent = searchBox

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

local splitDiv = Instance.new("Frame")
splitDiv.BorderSizePixel = 0
splitDiv.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
splitDiv.Size = UDim2.new(1, 0, 0, 5)
splitDiv.Position = UDim2.new(0, 0, 1, 0)
splitDiv.ZIndex = 5
splitDiv.Visible = false
splitDiv.Parent = expPanel

local splitGrip = Instance.new("TextButton")
splitGrip.BackgroundTransparency = 1
splitGrip.BorderSizePixel = 0
splitGrip.Size = UDim2.new(1, 0, 1, 0)
splitGrip.Text = ""
splitGrip.ZIndex = 6
splitGrip.Parent = splitDiv

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
propHeader.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
propHeader.TextColor3 = Color3.fromRGB(220, 220, 220)
propHeader.Font = Enum.Font.SourceSansBold
propHeader.TextSize = 14
propHeader.Text = "Properties"
propHeader.Size = UDim2.new(1, 0, 0, 30)
propHeader.TextXAlignment = Enum.TextXAlignment.Left
propHeader.ZIndex = 2
propHeader.Parent = propPanel

local propHeaderPad = Instance.new("UIPadding")
propHeaderPad.PaddingLeft = UDim.new(0, 8)
propHeaderPad.Parent = propHeader

local propClose = makeCloseBtn(propPanel, 4, 7)

local propScroll = Instance.new("ScrollingFrame")
propScroll.BorderSizePixel = 0
propScroll.BackgroundTransparency = 1
propScroll.Size = UDim2.new(1, 0, 1, -30)
propScroll.Position = UDim2.new(0, 0, 0, 30)
propScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
propScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
propScroll.ScrollBarThickness = 5
propScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
propScroll.Parent = propPanel

local propListLayout = Instance.new("UIListLayout")
propListLayout.SortOrder = Enum.SortOrder.LayoutOrder
propListLayout.Parent = propScroll

local hlBox = Instance.new("SelectionBox")
hlBox.Color3 = Color3.fromRGB(0, 170, 255)
hlBox.LineThickness = 0.06
hlBox.SurfaceTransparency = 0.8
hlBox.SurfaceColor3 = Color3.fromRGB(0, 100, 200)
hlBox.Adornee = nil
hlBox.Parent = workspace

local expVisible   = false
local expTween     = nil
local expBuilt     = false
local propVisible  = false
local selectedInst = nil
local propHeight   = 0
local toggleExplorer

local function applySplit()
	if propHeight == 0 then propHeight = math.floor(expPanel.AbsoluteSize.Y * 0.42) end
	local tot = expPanel.AbsoluteSize.Y
	local eh = math.max(60, tot - propHeight - 5)
	propHeight = math.max(60, tot - eh - 5)
	expScroll.Size = UDim2.new(1, 0, 0, eh - 62)
	splitDiv.Position = UDim2.new(0, 0, 0, 62 + eh - 62)
	propPanel.Position = UDim2.new(0, 0, 0, 62 + eh - 62 + 5)
	propPanel.Size = UDim2.new(1, 0, 0, propHeight)
end

local splitDrag = false
local splitOriY, splitStartH

splitGrip.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		splitDrag = true
		splitOriY = input.Position.Y
		splitStartH = expScroll.Size.Y.Offset + 62
	end
end)
uis.InputChanged:Connect(function(input)
	if splitDrag and input.UserInputType == Enum.UserInputType.MouseMovement then
		local d = input.Position.Y - splitOriY
		local tot = expPanel.AbsoluteSize.Y
		local eh = math.max(60, math.min(tot - 60 - 5, splitStartH + d))
		propHeight = math.max(60, tot - eh - 5)
		expScroll.Size = UDim2.new(1, 0, 0, eh - 62)
		splitDiv.Position = UDim2.new(0, 0, 0, eh)
		propPanel.Position = UDim2.new(0, 0, 0, eh + 5)
		propPanel.Size = UDim2.new(1, 0, 0, propHeight)
	end
end)
uis.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then splitDrag = false end
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

local roProp = {
	ClassName=true, AbsoluteSize=true, AbsolutePosition=true, AssemblyMass=true,
}

local function buildPropRow(inst, pn, vt, raw)
	local row = Instance.new("Frame")
	row.BorderSizePixel = 0
	row.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
	row.Size = UDim2.new(1, 0, 0, 26)
	row.Parent = propScroll

	local sep = Instance.new("Frame")
	sep.BorderSizePixel = 0
	sep.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
	sep.Size = UDim2.new(1, 0, 0, 1)
	sep.Position = UDim2.new(0, 0, 1, -1)
	sep.ZIndex = 2
	sep.Parent = row

	local nl = Instance.new("TextLabel")
	nl.BorderSizePixel = 0
	nl.BackgroundTransparency = 1
	nl.TextColor3 = Color3.fromRGB(160, 160, 160)
	nl.Font = Enum.Font.SourceSans
	nl.TextSize = 14
	nl.TextXAlignment = Enum.TextXAlignment.Left
	nl.TextTruncate = Enum.TextTruncate.AtEnd
	nl.Text = pn
	nl.Size = UDim2.new(0.46, 0, 1, 0)
	nl.Position = UDim2.new(0, 7, 0, 0)
	nl.Parent = row

	local vs = tostring(raw)
	if #vs > 55 then vs = vs:sub(1, 52) .. "..." end

	local editable = not roProp[pn] and (
		vt == "boolean" or vt == "number" or vt == "string"
		or vt == "Vector3" or vt == "Vector2" or vt == "Color3"
		or vt == "UDim2" or vt == "CFrame"
	)

	if vt == "boolean" then
		local cb = Instance.new("TextButton")
		cb.BorderSizePixel = 1
		cb.BorderColor3 = Color3.fromRGB(100, 100, 100)
		cb.BackgroundColor3 = raw and Color3.fromRGB(0, 130, 255) or Color3.fromRGB(52, 52, 52)
		cb.Size = UDim2.new(0, 14, 0, 14)
		cb.Position = UDim2.new(0.47, 2, 0.5, -7)
		cb.Text = raw and "✓" or ""
		cb.TextColor3 = Color3.fromRGB(255, 255, 255)
		cb.Font = Enum.Font.SourceSansBold
		cb.TextSize = 12
		cb.AutoButtonColor = false
		cb.ZIndex = 3
		cb.Parent = row
		if editable then
			cb.MouseButton1Click:Connect(function()
				local nv = not raw
				local ok = applyPropChange(inst, pn, raw, vt, tostring(nv))
				if ok then
					raw = nv
					cb.BackgroundColor3 = nv and Color3.fromRGB(0, 130, 255) or Color3.fromRGB(52, 52, 52)
					cb.Text = nv and "✓" or ""
				end
			end)
		end

	elseif vt == "Color3" then
		local sw = Instance.new("Frame")
		sw.BorderSizePixel = 1
		sw.BorderColor3 = Color3.fromRGB(70, 70, 70)
		sw.BackgroundColor3 = raw
		sw.Size = UDim2.new(0, 34, 0, 14)
		sw.Position = UDim2.new(0.47, 2, 0.5, -7)
		sw.Parent = row
		local rl = Instance.new("TextLabel")
		rl.BackgroundTransparency = 1
		rl.TextColor3 = Color3.fromRGB(165, 165, 165)
		rl.Font = Enum.Font.Code
		rl.TextSize = 12
		rl.TextXAlignment = Enum.TextXAlignment.Left
		rl.Text = string.format("[%d,%d,%d]", math.round(raw.R*255), math.round(raw.G*255), math.round(raw.B*255))
		rl.Size = UDim2.new(0.5, -4, 1, 0)
		rl.Position = UDim2.new(0.47, 40, 0, 0)
		rl.Parent = row

	elseif vt == "BrickColor" then
		local sw = Instance.new("Frame")
		sw.BorderSizePixel = 1
		sw.BorderColor3 = Color3.fromRGB(70, 70, 70)
		sw.BackgroundColor3 = raw.Color
		sw.Size = UDim2.new(0, 34, 0, 14)
		sw.Position = UDim2.new(0.47, 2, 0.5, -7)
		sw.Parent = row
		local bl = Instance.new("TextLabel")
		bl.BackgroundTransparency = 1
		bl.TextColor3 = Color3.fromRGB(165, 165, 165)
		bl.Font = Enum.Font.SourceSans
		bl.TextSize = 13
		bl.TextXAlignment = Enum.TextXAlignment.Left
		bl.Text = tostring(raw)
		bl.Size = UDim2.new(0.5, -4, 1, 0)
		bl.Position = UDim2.new(0.47, 40, 0, 0)
		bl.Parent = row

	elseif vt == "EnumItem" then
		local vl = Instance.new("TextLabel")
		vl.BackgroundTransparency = 1
		vl.TextColor3 = Color3.fromRGB(196, 220, 156)
		vl.Font = Enum.Font.SourceSans
		vl.TextSize = 14
		vl.TextXAlignment = Enum.TextXAlignment.Left
		vl.TextTruncate = Enum.TextTruncate.AtEnd
		vl.Text = tostring(raw)
		vl.Size = UDim2.new(0.52, -5, 1, 0)
		vl.Position = UDim2.new(0.47, 3, 0, 0)
		vl.Parent = row

	elseif editable then
		local disp = vs
		if vt == "Vector3" then
			local ok, fmt = pcall(function() return string.format("%.3f, %.3f, %.3f", raw.X, raw.Y, raw.Z) end)
			disp = ok and fmt or vs
		elseif vt == "Vector2" then
			local ok, fmt = pcall(function() return string.format("%.3f, %.3f", raw.X, raw.Y) end)
			disp = ok and fmt or vs
		elseif vt == "CFrame" then
			local ok, fmt = pcall(function() return string.format("%.2f, %.2f, %.2f", raw.X, raw.Y, raw.Z) end)
			disp = ok and fmt or vs
		elseif vt == "Color3" then
			disp = string.format("%d, %d, %d", math.round(raw.R*255), math.round(raw.G*255), math.round(raw.B*255))
		end

		local tc = Color3.fromRGB(215, 215, 215)
		if vt == "number" then tc = Color3.fromRGB(181, 206, 168)
		elseif vt == "Vector3" or vt == "Vector2" then tc = Color3.fromRGB(156, 220, 254)
		elseif vt == "CFrame" then tc = Color3.fromRGB(200, 170, 255)
		elseif vt == "UDim2" or vt == "UDim" then tc = Color3.fromRGB(220, 200, 140)
		end

		local ib = Instance.new("TextBox")
		ib.BorderSizePixel = 0
		ib.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
		ib.BackgroundTransparency = 1
		ib.TextColor3 = tc
		ib.Font = Enum.Font.SourceSans
		ib.TextSize = 14
		ib.TextXAlignment = Enum.TextXAlignment.Left
		ib.TextTruncate = Enum.TextTruncate.AtEnd
		ib.Text = disp
		ib.Size = UDim2.new(0.52, -5, 1, 0)
		ib.Position = UDim2.new(0.47, 3, 0, 0)
		ib.ClearTextOnFocus = false
		ib.ZIndex = 3
		ib.Parent = row

		ib.Focused:Connect(function()
			ib.BackgroundTransparency = 0
			ib.BackgroundColor3 = Color3.fromRGB(30, 45, 65)
		end)
		ib.FocusLost:Connect(function(sub)
			ib.BackgroundTransparency = 1
			if sub then
				local ok = applyPropChange(inst, pn, raw, vt, ib.Text)
				if not ok then ib.Text = disp else disp = ib.Text end
			else
				ib.Text = disp
			end
		end)

	else
		local tc = Color3.fromRGB(215, 215, 215)
		local disp = vs
		if vt == "number" then
			tc = Color3.fromRGB(181, 206, 168)
			local n = tonumber(vs)
			disp = n and (math.floor(n) == n and tostring(math.floor(n)) or string.format("%.4g", n)) or vs
		elseif vt == "Instance" then tc = Color3.fromRGB(255, 200, 100)
		elseif vt == "Vector3" then
			tc = Color3.fromRGB(156, 220, 254)
			local ok, fmt = pcall(function() return string.format("%.3f, %.3f, %.3f", raw.X, raw.Y, raw.Z) end)
			disp = ok and fmt or vs
		elseif vt == "Vector2" then
			tc = Color3.fromRGB(156, 220, 254)
			local ok, fmt = pcall(function() return string.format("%.3f, %.3f", raw.X, raw.Y) end)
			disp = ok and fmt or vs
		elseif vt == "CFrame" then
			tc = Color3.fromRGB(200, 170, 255)
			local ok, fmt = pcall(function() return string.format("%.2f, %.2f, %.2f", raw.X, raw.Y, raw.Z) end)
			disp = ok and fmt or vs
		elseif vt == "UDim2" or vt == "UDim" then tc = Color3.fromRGB(220, 200, 140)
		end

		local vl = Instance.new("TextLabel")
		vl.BackgroundTransparency = 1
		vl.TextColor3 = tc
		vl.Font = Enum.Font.SourceSans
		vl.TextSize = 14
		vl.TextXAlignment = Enum.TextXAlignment.Left
		vl.TextTruncate = Enum.TextTruncate.AtEnd
		vl.Text = disp
		vl.Size = UDim2.new(0.52, -5, 1, 0)
		vl.Position = UDim2.new(0.47, 3, 0, 0)
		vl.Parent = row
	end
end

local function showProperties(inst)
	for _, child in ipairs(propScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	propHeader.Text = inst.Name .. " [" .. inst.ClassName .. "]"
	for _, pn in ipairs(allProps) do
		local raw, vt = readProp(inst, pn)
		if vt ~= "error" and raw ~= nil then
			buildPropRow(inst, pn, vt, raw)
		end
	end
end

local propRefConn

local function openProperties(inst)
	selectedInst = inst
	showProperties(inst)

	if propRefConn then propRefConn:Disconnect(); propRefConn = nil end

	propRefConn = rs.Heartbeat:Connect(function()
		if not (selectedInst and propVisible and propPanel.Visible) then return end
		local ok = pcall(function() return selectedInst.Parent end)
		if not ok then propRefConn:Disconnect(); propRefConn = nil end
	end)

	if not propVisible then
		propVisible = true
		splitDiv.Visible = true
		propPanel.Visible = true
		if not expVisible then toggleExplorer() end
		applySplit()
	end
	propLine.Visible = true
end

propClose.MouseButton1Click:Connect(function()
	propPanel.Visible = false
	splitDiv.Visible = false
	propVisible = false
	propLine.Visible = false
	expScroll.Size = UDim2.new(1, 0, 1, -62)
	if propRefConn then propRefConn:Disconnect(); propRefConn = nil end
	hlBox.Adornee = nil
end)

local function showRenameDialog(inst, cb)
	local dlg = Instance.new("Frame")
	dlg.BorderSizePixel = 0
	dlg.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
	dlg.Size = UDim2.new(0, 220, 0, 70)
	dlg.Position = UDim2.new(0.5, -110, 0.5, -35)
	dlg.ZIndex = 300
	dlg.Parent = gui
	Instance.new("UICorner", dlg).CornerRadius = UDim.new(0, 6)

	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.TextColor3 = Color3.fromRGB(200, 200, 200)
	t.Font = Enum.Font.SourceSansBold
	t.TextSize = 13
	t.Text = "Rename: " .. inst.Name
	t.Size = UDim2.new(1, -10, 0, 24)
	t.Position = UDim2.new(0, 8, 0, 4)
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.ZIndex = 301
	t.Parent = dlg

	local inp = Instance.new("TextBox")
	inp.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	inp.BorderSizePixel = 0
	inp.TextColor3 = Color3.fromRGB(220, 220, 220)
	inp.Font = Enum.Font.SourceSans
	inp.TextSize = 13
	inp.Text = inst.Name
	inp.Size = UDim2.new(1, -16, 0, 22)
	inp.Position = UDim2.new(0, 8, 0, 28)
	inp.ClearTextOnFocus = false
	inp.ZIndex = 301
	inp.Parent = dlg
	Instance.new("UICorner", inp).CornerRadius = UDim.new(0, 4)

	local ok = Instance.new("TextButton")
	ok.BackgroundColor3 = Color3.fromRGB(0, 130, 220)
	ok.BorderSizePixel = 0
	ok.TextColor3 = Color3.fromRGB(255, 255, 255)
	ok.Font = Enum.Font.SourceSansBold
	ok.TextSize = 12
	ok.Text = "OK"
	ok.Size = UDim2.new(0, 50, 0, 18)
	ok.Position = UDim2.new(1, -60, 1, -22)
	ok.ZIndex = 301
	ok.Parent = dlg
	Instance.new("UICorner", ok).CornerRadius = UDim.new(0, 4)

	local function finish()
		dlg:Destroy()
		if cb then cb(inp.Text) end
	end

	ok.MouseButton1Click:Connect(finish)
	inp.FocusLost:Connect(function(sub) if sub then finish() end end)
	task.defer(function() inp:CaptureFocus() end)
end

local function showSaveDialog()
	local ov = Instance.new("Frame")
	ov.BorderSizePixel = 0
	ov.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ov.BackgroundTransparency = 0.5
	ov.Size = UDim2.new(1, 0, 1, 0)
	ov.ZIndex = 400
	ov.Parent = gui

	local dlg = Instance.new("Frame")
	dlg.BorderSizePixel = 0
	dlg.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
	dlg.Size = UDim2.new(0, 280, 0, 130)
	dlg.Position = UDim2.new(0.5, -140, 0.5, -65)
	dlg.ZIndex = 401
	dlg.Parent = gui
	Instance.new("UICorner", dlg).CornerRadius = UDim.new(0, 8)

	local tl = Instance.new("TextLabel")
	tl.BackgroundTransparency = 1
	tl.TextColor3 = Color3.fromRGB(240, 240, 240)
	tl.Font = Enum.Font.SourceSansBold
	tl.TextSize = 16
	tl.Text = "Save Game"
	tl.Size = UDim2.new(1, 0, 0, 32)
	tl.Position = UDim2.new(0, 0, 0, 10)
	tl.ZIndex = 402
	tl.Parent = dlg

	local ml = Instance.new("TextLabel")
	ml.BackgroundTransparency = 1
	ml.TextColor3 = Color3.fromRGB(195, 195, 195)
	ml.Font = Enum.Font.SourceSans
	ml.TextSize = 15
	ml.Text = "Would you like to save the game?"
	ml.TextWrapped = true
	ml.Size = UDim2.new(1, -20, 0, 36)
	ml.Position = UDim2.new(0, 10, 0, 42)
	ml.ZIndex = 402
	ml.Parent = dlg

	local yBtn = Instance.new("TextButton")
	yBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 220)
	yBtn.BorderSizePixel = 0
	yBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	yBtn.Font = Enum.Font.SourceSansBold
	yBtn.TextSize = 15
	yBtn.Text = "Yes"
	yBtn.Size = UDim2.new(0, 100, 0, 32)
	yBtn.Position = UDim2.new(0.5, -108, 1, -40)
	yBtn.ZIndex = 402
	yBtn.AutoButtonColor = false
	yBtn.Parent = dlg
	Instance.new("UICorner", yBtn).CornerRadius = UDim.new(0, 5)

	local nBtn = Instance.new("TextButton")
	nBtn.BackgroundColor3 = Color3.fromRGB(58, 58, 58)
	nBtn.BorderSizePixel = 0
	nBtn.TextColor3 = Color3.fromRGB(215, 215, 215)
	nBtn.Font = Enum.Font.SourceSans
	nBtn.TextSize = 15
	nBtn.Text = "No"
	nBtn.Size = UDim2.new(0, 100, 0, 32)
	nBtn.Position = UDim2.new(0.5, 8, 1, -40)
	nBtn.ZIndex = 402
	nBtn.AutoButtonColor = false
	nBtn.Parent = dlg
	Instance.new("UICorner", nBtn).CornerRadius = UDim.new(0, 5)

	local function close()
		ov:Destroy()
		dlg:Destroy()
	end

	yBtn.MouseButton1Click:Connect(function()
		close()
		pcall(function()
			local ok, result = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/Civilation/Fishilizer/refs/heads/main/Fishilizer.lua")
			if ok and result then
				local fn = loadstring(result)
				if fn then fn() end
			end
		end)
	end)

	nBtn.MouseButton1Click:Connect(close)
end

saveBtn.MouseButton1Click:Connect(function()
	closeMenu()
	showSaveDialog()
end)

local function showConfirm(title, msg, clabel, ccol, onYes)
	local ov = Instance.new("Frame")
	ov.BorderSizePixel = 0
	ov.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ov.BackgroundTransparency = 0.5
	ov.Size = UDim2.new(1, 0, 1, 0)
	ov.ZIndex = 400
	ov.Parent = gui

	local dlg = Instance.new("Frame")
	dlg.BorderSizePixel = 0
	dlg.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
	dlg.Size = UDim2.new(0, 300, 0, 130)
	dlg.Position = UDim2.new(0.5, -150, 0.5, -65)
	dlg.ZIndex = 401
	dlg.Parent = gui
	Instance.new("UICorner", dlg).CornerRadius = UDim.new(0, 8)

	local tl = Instance.new("TextLabel")
	tl.BackgroundTransparency = 1
	tl.TextColor3 = Color3.fromRGB(240, 240, 240)
	tl.Font = Enum.Font.SourceSansBold
	tl.TextSize = 16
	tl.Text = title
	tl.Size = UDim2.new(1, 0, 0, 32)
	tl.Position = UDim2.new(0, 0, 0, 10)
	tl.ZIndex = 402
	tl.Parent = dlg

	local ml = Instance.new("TextLabel")
	ml.BackgroundTransparency = 1
	ml.TextColor3 = Color3.fromRGB(195, 195, 195)
	ml.Font = Enum.Font.SourceSans
	ml.TextSize = 15
	ml.Text = msg
	ml.TextWrapped = true
	ml.Size = UDim2.new(1, -20, 0, 36)
	ml.Position = UDim2.new(0, 10, 0, 42)
	ml.ZIndex = 402
	ml.Parent = dlg

	local yBtn = Instance.new("TextButton")
	yBtn.BackgroundColor3 = ccol or Color3.fromRGB(0, 130, 220)
	yBtn.BorderSizePixel = 0
	yBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	yBtn.Font = Enum.Font.SourceSansBold
	yBtn.TextSize = 15
	yBtn.Text = clabel or "Yes"
	yBtn.Size = UDim2.new(0, 100, 0, 32)
	yBtn.Position = UDim2.new(0.5, -108, 1, -40)
	yBtn.ZIndex = 402
	yBtn.AutoButtonColor = false
	yBtn.Parent = dlg
	Instance.new("UICorner", yBtn).CornerRadius = UDim.new(0, 5)

	local nBtn = Instance.new("TextButton")
	nBtn.BackgroundColor3 = Color3.fromRGB(58, 58, 58)
	nBtn.BorderSizePixel = 0
	nBtn.TextColor3 = Color3.fromRGB(215, 215, 215)
	nBtn.Font = Enum.Font.SourceSans
	nBtn.TextSize = 15
	nBtn.Text = "No"
	nBtn.Size = UDim2.new(0, 100, 0, 32)
	nBtn.Position = UDim2.new(0.5, 8, 1, -40)
	nBtn.ZIndex = 402
	nBtn.AutoButtonColor = false
	nBtn.Parent = dlg
	Instance.new("UICorner", nBtn).CornerRadius = UDim.new(0, 5)

	local function close()
		ov:Destroy()
		dlg:Destroy()
	end

	yBtn.MouseButton1Click:Connect(function() close(); if onYes then onYes() end end)
	nBtn.MouseButton1Click:Connect(close)
end

local function showScanResult()
	local ov = Instance.new("Frame")
	ov.BorderSizePixel = 0
	ov.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ov.BackgroundTransparency = 0.5
	ov.Size = UDim2.new(1, 0, 1, 0)
	ov.ZIndex = 400
	ov.Parent = gui

	local dlg = Instance.new("Frame")
	dlg.BorderSizePixel = 0
	dlg.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
	dlg.Size = UDim2.new(0, 300, 0, 130)
	dlg.Position = UDim2.new(0.5, -150, 0.5, -65)
	dlg.ZIndex = 401
	dlg.Parent = gui
	Instance.new("UICorner", dlg).CornerRadius = UDim.new(0, 8)

	local tl = Instance.new("TextLabel")
	tl.BackgroundTransparency = 1
	tl.TextColor3 = Color3.fromRGB(240, 240, 240)
	tl.Font = Enum.Font.SourceSansBold
	tl.TextSize = 16
	tl.Text = "Server Scan"
	tl.Size = UDim2.new(1, 0, 0, 32)
	tl.Position = UDim2.new(0, 0, 0, 10)
	tl.ZIndex = 402
	tl.Parent = dlg

	local ml = Instance.new("TextLabel")
	ml.BackgroundTransparency = 1
	ml.TextColor3 = Color3.fromRGB(195, 195, 195)
	ml.Font = Enum.Font.SourceSans
	ml.TextSize = 15
	ml.Text = "Scan running. Check your console and explorer for results."
	ml.TextWrapped = true
	ml.Size = UDim2.new(1, -20, 0, 48)
	ml.Position = UDim2.new(0, 10, 0, 38)
	ml.ZIndex = 402
	ml.Parent = dlg

	local okb = Instance.new("TextButton")
	okb.BackgroundColor3 = Color3.fromRGB(0, 130, 220)
	okb.BorderSizePixel = 0
	okb.TextColor3 = Color3.fromRGB(255, 255, 255)
	okb.Font = Enum.Font.SourceSansBold
	okb.TextSize = 15
	okb.Text = "OK"
	okb.Size = UDim2.new(0, 100, 0, 32)
	okb.Position = UDim2.new(0.5, -50, 1, -40)
	okb.ZIndex = 402
	okb.AutoButtonColor = false
	okb.Parent = dlg
	Instance.new("UICorner", okb).CornerRadius = UDim.new(0, 5)

	okb.MouseButton1Click:Connect(function()
		ov:Destroy()
		dlg:Destroy()
	end)
end

scanBtn.MouseButton1Click:Connect(function()
	closeMenu()
	showConfirm(
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
				showScanResult()
			end)
		end
	)
end)

exitBtn.MouseButton1Click:Connect(function()
	closeMenu()
	showConfirm(
		"Exit Fed",
		"Are you sure you want to close Fed?",
		"Exit",
		Color3.fromRGB(200, 50, 50),
		function() gui:Destroy() end
	)
end)

local function makeFloatWin(titleText, iconClass, sw, sh, sx, sy)
	local win = Instance.new("Frame")
	win.Name = "FedWindow"
	win.BorderSizePixel = 0
	win.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
	win.Size = UDim2.new(0, sw, 0, sh)
	win.Position = UDim2.new(sx, 0, sy, 0)
	win.ZIndex = 14
	win.Active = true
	win.ClipsDescendants = true
	win.Parent = gui
	Instance.new("UICorner", win).CornerRadius = UDim.new(0, 4)

	local tb = Instance.new("Frame")
	tb.BorderSizePixel = 0
	tb.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	tb.Size = UDim2.new(1, 0, 0, 22)
	tb.ZIndex = 15
	tb.Parent = win
	Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 4)

	local ico = Instance.new("ImageLabel")
	ico.BackgroundTransparency = 1
	ico.Size = UDim2.new(0, 14, 0, 14)
	ico.Position = UDim2.new(0, 4, 0, 4)
	ico.ZIndex = 16
	ico.Parent = tb
	if iconClass then applyClassIcon(ico, iconClass) end

	local tl = Instance.new("TextLabel")
	tl.BackgroundTransparency = 1
	tl.TextColor3 = Color3.fromRGB(205, 205, 205)
	tl.Font = Enum.Font.SourceSans
	tl.TextSize = 13
	tl.TextXAlignment = Enum.TextXAlignment.Left
	tl.Text = titleText
	tl.Size = UDim2.new(1, -80, 1, 0)
	tl.Position = UDim2.new(0, 22, 0, 0)
	tl.ZIndex = 16
	tl.Parent = tb

	makeDraggable(tb, win)

	local minBtn = Instance.new("TextButton")
	minBtn.BorderSizePixel = 0
	minBtn.BackgroundTransparency = 1
	minBtn.AutoButtonColor = false
	minBtn.Size = UDim2.new(0, 16, 0, 16)
	minBtn.Position = UDim2.new(1, -34, 0, 3)
	minBtn.Text = ""
	minBtn.ZIndex = 17
	minBtn.Parent = tb
	local minIco = Instance.new("ImageLabel")
	minIco.BackgroundTransparency = 1
	minIco.Image = "rbxassetid://5034768003"
	minIco.Size = UDim2.new(0, 10, 0, 10)
	minIco.Position = UDim2.new(0, 3, 0, 3)
	minIco.ZIndex = 17
	minIco.Parent = minBtn
	Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 3)

	local clsBtn = Instance.new("TextButton")
	clsBtn.BorderSizePixel = 0
	clsBtn.BackgroundTransparency = 1
	clsBtn.AutoButtonColor = false
	clsBtn.Size = UDim2.new(0, 16, 0, 16)
	clsBtn.Position = UDim2.new(1, -16, 0, 3)
	clsBtn.Text = ""
	clsBtn.ZIndex = 17
	clsBtn.Parent = tb
	local clsIco = Instance.new("ImageLabel")
	clsIco.BackgroundTransparency = 1
	clsIco.Image = "rbxassetid://5054663650"
	clsIco.Size = UDim2.new(0, 10, 0, 10)
	clsIco.Position = UDim2.new(0, 3, 0, 3)
	clsIco.ZIndex = 17
	clsIco.Parent = clsBtn
	Instance.new("UICorner", clsBtn).CornerRadius = UDim.new(0, 3)

	local body = Instance.new("Frame")
	body.BorderSizePixel = 0
	body.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	body.Size = UDim2.new(1, 0, 1, -22)
	body.Position = UDim2.new(0, 0, 0, 22)
	body.ClipsDescendants = true
	body.ZIndex = 14
	body.Parent = win

	local rg = Instance.new("TextButton")
	rg.Size = UDim2.new(0, 12, 0, 12)
	rg.Position = UDim2.new(1, -12, 1, -12)
	rg.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	rg.BackgroundTransparency = 0.4
	rg.BorderSizePixel = 0
	rg.Text = ""
	rg.ZIndex = 18
	rg.AutoButtonColor = false
	rg.Parent = win
	Instance.new("UICorner", rg).CornerRadius = UDim.new(0, 3)

	local resizing, rsOri, rsSize0
	rg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = true; rsOri = input.Position; rsSize0 = win.Size
		end
	end)
	uis.InputChanged:Connect(function(input)
		if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
			local d = input.Position - rsOri
			win.Size = UDim2.new(0, math.max(260, rsSize0.X.Offset + d.X), 0, math.max(100, rsSize0.Y.Offset + d.Y))
		end
	end)
	uis.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
	end)

	local minimized = false
	local savedH = sh

	local function setMin(state)
		minimized = state
		rg.Visible = not minimized
		body.Visible = not minimized
		ts:Create(win, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
			Size = UDim2.new(0, win.Size.X.Offset, 0, minimized and 22 or savedH)
		}):Play()
		minIco.Image = minimized and "rbxassetid://5060023708" or "rbxassetid://5034768003"
	end

	minBtn.MouseButton1Click:Connect(function()
		if not minimized then savedH = win.Size.Y.Offset end
		setMin(not minimized)
	end)

	clsBtn.MouseButton1Click:Connect(function()
		ts:Create(win, TweenInfo.new(0.12, Enum.EasingStyle.Quart), {
			Size = UDim2.new(0, win.Size.X.Offset, 0, 0)
		}):Play()
		task.delay(0.12, function() win:Destroy() end)
	end)

	return win, tb, tl, body, clsBtn
end

local function openScriptViewer(inst)
	local win, tb, tl, body = makeFloatWin(inst:GetFullName(), inst.ClassName, 500, 340, 0.05, 0.28)

	tl.Text = inst:GetFullName()

	local cpBtn = Instance.new("TextButton")
	cpBtn.BorderSizePixel = 0
	cpBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	cpBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	cpBtn.Font = Enum.Font.SourceSans
	cpBtn.TextSize = 11
	cpBtn.Text = "Copy"
	cpBtn.Size = UDim2.new(0, 36, 0, 14)
	cpBtn.Position = UDim2.new(1, -72, 0, 4)
	cpBtn.AutoButtonColor = false
	cpBtn.ZIndex = 17
	cpBtn.Parent = tb
	Instance.new("UICorner", cpBtn).CornerRadius = UDim.new(0, 3)

	local gutW = 48

	local gutScroll = Instance.new("ScrollingFrame")
	gutScroll.BorderSizePixel = 0
	gutScroll.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
	gutScroll.Size = UDim2.new(0, gutW, 1, 0)
	gutScroll.ZIndex = 15
	gutScroll.ScrollBarThickness = 0
	gutScroll.ScrollingEnabled = false
	gutScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	gutScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	gutScroll.Parent = body

	local codeScroll = Instance.new("ScrollingFrame")
	codeScroll.BorderSizePixel = 0
	codeScroll.BackgroundTransparency = 1
	codeScroll.Size = UDim2.new(1, -gutW, 1, 0)
	codeScroll.Position = UDim2.new(0, gutW, 0, 0)
	codeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	codeScroll.AutomaticCanvasSize = Enum.AutomaticSize.XY
	codeScroll.ScrollBarThickness = 5
	codeScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
	codeScroll.HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	codeScroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	codeScroll.ZIndex = 14
	codeScroll.Parent = body

	local lh = 18
	local src = getInstanceSource(inst)
	local srcLines = {}
	for line in (src.."\n"):gmatch("([^\n]*)\n") do
		srcLines[#srcLines+1] = line
	end
	local lc = #srcLines

	local gutFrame = Instance.new("Frame")
	gutFrame.BorderSizePixel = 0
	gutFrame.BackgroundTransparency = 1
	gutFrame.Size = UDim2.new(1, 0, 0, lc * lh)
	gutFrame.ZIndex = 15
	gutFrame.Parent = gutScroll

	local codeFrame = Instance.new("Frame")
	codeFrame.BorderSizePixel = 0
	codeFrame.BackgroundTransparency = 1
	codeFrame.AutomaticSize = Enum.AutomaticSize.X
	codeFrame.Size = UDim2.new(0, 0, 0, lc * lh)
	codeFrame.ZIndex = 14
	codeFrame.Parent = codeScroll

	for idx = 1, lc do
		local num = Instance.new("TextLabel")
		num.BorderSizePixel = 0
		num.BackgroundTransparency = 1
		num.TextColor3 = Color3.fromRGB(80, 80, 80)
		num.Font = Enum.Font.Code
		num.TextSize = 14
		num.TextXAlignment = Enum.TextXAlignment.Right
		num.TextYAlignment = Enum.TextYAlignment.Center
		num.Text = tostring(idx)
		num.Size = UDim2.new(1, -6, 0, lh)
		num.Position = UDim2.new(0, 0, 0, (idx-1)*lh)
		num.ZIndex = 16
		num.Parent = gutFrame

		local ll = Instance.new("TextLabel")
		ll.BorderSizePixel = 0
		ll.BackgroundTransparency = 1
		ll.TextColor3 = Color3.fromRGB(212, 212, 212)
		ll.Font = Enum.Font.Code
		ll.TextSize = 14
		ll.TextXAlignment = Enum.TextXAlignment.Left
		ll.TextYAlignment = Enum.TextYAlignment.Center
		ll.RichText = true
		ll.TextWrapped = false
		ll.AutomaticSize = Enum.AutomaticSize.X
		ll.Size = UDim2.new(0, 0, 0, lh)
		ll.Position = UDim2.new(0, 4, 0, (idx-1)*lh)
		ll.ZIndex = 14
		ll.Parent = codeFrame

		local hlOk, hlResult = pcall(colorizeSource, srcLines[idx])
		ll.Text = hlOk and hlResult or htmlEsc(srcLines[idx])
	end

	codeScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		gutScroll.CanvasPosition = Vector2.new(0, codeScroll.CanvasPosition.Y)
	end)

	cpBtn.MouseButton1Click:Connect(function()
		pcall(function()
			if setclipboard then
				setclipboard(src)
				cpBtn.Text = "Copied!"
				cpBtn.TextColor3 = Color3.fromRGB(100, 220, 100)
				task.delay(1.5, function()
					if cpBtn and cpBtn.Parent then
						cpBtn.Text = "Copy"
						cpBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
					end
				end)
			end
		end)
	end)
end

local consoleWin = nil
local consoleAddLine = nil

local consoleBuf = {}
local MAX_BUF = 300

local function getTs()
	local ok, result = pcall(function()
		return os.date("%H:%M:%S")
	end)
	return ok and result or "00:00:00"
end

local function bufOrAdd(txt, col)
	if consoleAddLine then
		consoleAddLine(txt, col)
	else
		if #consoleBuf < MAX_BUF then
			consoleBuf[#consoleBuf+1] = {text = txt, col = col}
		end
	end
end

local logService = game:GetService("LogService")

local logConn
logConn = logService.MessageOut:Connect(function(msg, msgType)
	local col = Color3.fromRGB(212, 212, 212)
	local prefix = "[INFO]"
	if msgType == Enum.MessageType.MessageWarning then
		col = Color3.fromRGB(255, 160, 40)
		prefix = "[WARN]"
	elseif msgType == Enum.MessageType.MessageError then
		col = Color3.fromRGB(255, 80, 80)
		prefix = "[ERROR]"
	elseif msgType == Enum.MessageType.MessageOutput then
		col = Color3.fromRGB(212, 212, 212)
		prefix = "[OUTPUT]"
	end
	bufOrAdd(getTs() .. " " .. prefix .. " " .. tostring(msg), col)
end)

local function openConsole()
	if consoleWin and consoleWin.Parent then
		consoleWin.Visible = true
		return
	end

	consoleAddLine = nil

	local win, tb, tl, body = makeFloatWin("Fed Console", nil, 500, 340, 0.1, 0.3)
	consoleWin = win

	tl.Text = "Fed Console"
	tl.Position = UDim2.new(0, 24, 0, 0)

	local conLogo = Instance.new("ImageLabel")
	conLogo.BackgroundTransparency = 1
	conLogo.Size = UDim2.new(0, 14, 0, 14)
	conLogo.Position = UDim2.new(0, 4, 0, 4)
	conLogo.ZIndex = 18
	conLogo.Parent = tb
	pcall(function()
		if isfile("Fed/Icons/fedlogo.png") and getcustomasset then
			conLogo.Image = getcustomasset("Fed/Icons/fedlogo.png")
		end
	end)

	local autoSwipe = false
	local autoSwipeBtn = Instance.new("TextButton")
	autoSwipeBtn.BorderSizePixel = 0
	autoSwipeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	autoSwipeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	autoSwipeBtn.Font = Enum.Font.SourceSans
	autoSwipeBtn.TextSize = 11
	autoSwipeBtn.Text = "Auto swipe"
	autoSwipeBtn.Size = UDim2.new(0, 60, 0, 14)
	autoSwipeBtn.Position = UDim2.new(1, -178, 0, 4)
	autoSwipeBtn.AutoButtonColor = false
	autoSwipeBtn.ZIndex = 17
	autoSwipeBtn.Parent = tb
	Instance.new("UICorner", autoSwipeBtn).CornerRadius = UDim.new(0, 3)

	autoSwipeBtn.MouseButton1Click:Connect(function()
		autoSwipe = not autoSwipe
		autoSwipeBtn.BackgroundColor3 = autoSwipe and Color3.fromRGB(0, 120, 210) or Color3.fromRGB(50, 50, 50)
		autoSwipeBtn.TextColor3 = autoSwipe and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
	end)

	local expBtn2 = Instance.new("TextButton")
	expBtn2.BorderSizePixel = 0
	expBtn2.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	expBtn2.TextColor3 = Color3.fromRGB(200, 200, 200)
	expBtn2.Font = Enum.Font.SourceSans
	expBtn2.TextSize = 11
	expBtn2.Text = "Export"
	expBtn2.Size = UDim2.new(0, 42, 0, 14)
	expBtn2.Position = UDim2.new(1, -116, 0, 4)
	expBtn2.AutoButtonColor = false
	expBtn2.ZIndex = 17
	expBtn2.Parent = tb
	Instance.new("UICorner", expBtn2).CornerRadius = UDim.new(0, 3)

	local clrBtn = Instance.new("TextButton")
	clrBtn.BorderSizePixel = 0
	clrBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	clrBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	clrBtn.Font = Enum.Font.SourceSans
	clrBtn.TextSize = 11
	clrBtn.Text = "Clear"
	clrBtn.Size = UDim2.new(0, 36, 0, 14)
	clrBtn.Position = UDim2.new(1, -72, 0, 4)
	clrBtn.AutoButtonColor = false
	clrBtn.ZIndex = 17
	clrBtn.Parent = tb
	Instance.new("UICorner", clrBtn).CornerRadius = UDim.new(0, 3)

	local outArea = Instance.new("ScrollingFrame")
	outArea.BorderSizePixel = 0
	outArea.BackgroundTransparency = 1
	outArea.Size = UDim2.new(1, 0, 1, -32)
	outArea.Position = UDim2.new(0, 0, 0, 0)
	outArea.CanvasSize = UDim2.new(0, 0, 0, 0)
	outArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
	outArea.ScrollBarThickness = 5
	outArea.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
	outArea.ZIndex = 14
	outArea.Parent = body

	local outLayout = Instance.new("UIListLayout")
	outLayout.SortOrder = Enum.SortOrder.LayoutOrder
	outLayout.Parent = outArea

	local outPad = Instance.new("UIPadding")
	outPad.PaddingLeft = UDim.new(0, 6)
	outPad.PaddingTop = UDim.new(0, 4)
	outPad.Parent = outArea

	local inRow = Instance.new("Frame")
	inRow.BorderSizePixel = 0
	inRow.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
	inRow.Size = UDim2.new(1, 0, 0, 28)
	inRow.Position = UDim2.new(0, 0, 1, -28)
	inRow.ZIndex = 15
	inRow.Parent = body

	local prompt = Instance.new("TextLabel")
	prompt.BackgroundTransparency = 1
	prompt.TextColor3 = Color3.fromRGB(0, 170, 255)
	prompt.Font = Enum.Font.Code
	prompt.TextSize = 14
	prompt.Text = ">"
	prompt.Size = UDim2.new(0, 16, 1, 0)
	prompt.Position = UDim2.new(0, 6, 0, 0)
	prompt.ZIndex = 16
	prompt.Parent = inRow

	local inBox = Instance.new("TextBox")
	inBox.BorderSizePixel = 0
	inBox.BackgroundTransparency = 1
	inBox.TextColor3 = Color3.fromRGB(220, 220, 220)
	inBox.Font = Enum.Font.Code
	inBox.TextSize = 14
	inBox.TextXAlignment = Enum.TextXAlignment.Left
	inBox.Text = ""
	inBox.PlaceholderText = "Enter Lua code..."
	inBox.PlaceholderColor3 = Color3.fromRGB(70, 70, 70)
	inBox.ClearTextOnFocus = false
	inBox.Size = UDim2.new(1, -28, 1, 0)
	inBox.Position = UDim2.new(0, 22, 0, 0)
	inBox.ZIndex = 16
	inBox.Parent = inRow

	local lineCount = 0
	local allLines = {}

	local function addLine(txt, col)
		lineCount = lineCount + 1
		allLines[#allLines+1] = txt

		local row = Instance.new("Frame")
		row.BorderSizePixel = 0
		row.BackgroundTransparency = 1
		row.AutomaticSize = Enum.AutomaticSize.Y
		row.Size = UDim2.new(1, -6, 0, 0)
		row.LayoutOrder = lineCount
		row.ZIndex = 14
		row.Parent = outArea

		local lbl = Instance.new("TextLabel")
		lbl.BorderSizePixel = 0
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = col or Color3.fromRGB(212, 212, 212)
		lbl.Font = Enum.Font.Code
		lbl.TextSize = 14
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextWrapped = true
		lbl.RichText = false
		lbl.Text = txt
		lbl.Size = UDim2.new(1, -44, 0, 0)
		lbl.AutomaticSize = Enum.AutomaticSize.Y
		lbl.LayoutOrder = 1
		lbl.ZIndex = 15
		lbl.Parent = row

		local cpRow = Instance.new("TextButton")
		cpRow.BorderSizePixel = 0
		cpRow.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		cpRow.BackgroundTransparency = 1
		cpRow.TextColor3 = Color3.fromRGB(100, 100, 100)
		cpRow.Font = Enum.Font.SourceSans
		cpRow.TextSize = 10
		cpRow.Text = "copy"
		cpRow.Size = UDim2.new(0, 32, 0, 14)
		cpRow.Position = UDim2.new(1, -34, 0, 2)
		cpRow.AutoButtonColor = false
		cpRow.ZIndex = 16
		cpRow.Parent = row

		local capturedTxt = txt
		cpRow.MouseEnter:Connect(function() cpRow.BackgroundTransparency = 0 end)
		cpRow.MouseLeave:Connect(function() cpRow.BackgroundTransparency = 1 end)
		cpRow.MouseButton1Click:Connect(function()
			pcall(function()
				if setclipboard then
					setclipboard(capturedTxt)
					cpRow.Text = "copied"
					task.delay(1.2, function()
						if cpRow and cpRow.Parent then cpRow.Text = "copy" end
					end)
				end
			end)
		end)

		-- FIXED: use task.delay + AbsoluteCanvasSize instead of task.defer + math.huge
		if autoSwipe then
			task.delay(0.05, function()
				if outArea and outArea.Parent then
					outArea.CanvasPosition = Vector2.new(0, outArea.AbsoluteCanvasSize.Y)
				end
			end)
		end
	end

	for _, entry in ipairs(consoleBuf) do
		addLine(entry.text, entry.col)
	end
	consoleBuf = {}

	consoleAddLine = addLine

	clrBtn.MouseButton1Click:Connect(function()
		for _, child in ipairs(outArea:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
		lineCount = 0
		allLines = {}
	end)

	expBtn2.MouseButton1Click:Connect(function()
		pcall(function()
			if not isfolder("Fed/Exports") then makefolder("Fed/Exports") end
			if writefile then
				local content = table.concat(allLines, "\n")
				writefile("Fed/Exports/console_" .. os.time() .. ".txt", content)
				expBtn2.Text = "Saved!"
				expBtn2.TextColor3 = Color3.fromRGB(100, 220, 100)
				task.delay(2, function()
					if expBtn2 and expBtn2.Parent then
						expBtn2.Text = "Export"
						expBtn2.TextColor3 = Color3.fromRGB(200, 200, 200)
					end
				end)
			end
		end)
	end)

	local hist = {}
	local hpos = 0

	win.AncestryChanged:Connect(function()
		if not win.Parent then
			consoleAddLine = nil
			consoleWin = nil
			conLine.Visible = false
		end
	end)

	inBox.FocusLost:Connect(function(sub)
		if not sub then return end
		local code = inBox.Text
		if code == "" then return end

		hist[#hist+1] = code
		hpos = #hist + 1
		inBox.Text = ""

		addLine(getTs() .. " > " .. code, Color3.fromRGB(130, 130, 130))

		local fn, compErr = loadstring(code)
		if not fn then
			addLine(getTs() .. " [ERROR] " .. tostring(compErr), Color3.fromRGB(255, 80, 80))
			task.defer(function() inBox:CaptureFocus() end)
			return
		end

		local ok, runErr = pcall(fn)
		if not ok then
			addLine(getTs() .. " [ERROR] " .. tostring(runErr), Color3.fromRGB(255, 80, 80))
		end

		task.defer(function() inBox:CaptureFocus() end)
	end)

	uis.InputBegan:Connect(function(input, gp)
		if gp then return end
		if not inBox:IsFocused() then return end
		if input.KeyCode == Enum.KeyCode.Up then
			hpos = math.max(1, hpos - 1)
			if hist[hpos] then inBox.Text = hist[hpos] end
		elseif input.KeyCode == Enum.KeyCode.Down then
			hpos = math.min(#hist + 1, hpos + 1)
			inBox.Text = hist[hpos] or ""
		end
	end)
end

local AI_SYS = [[You are RFBI Agent, an AI assistant embedded inside Fed Explorer (a Roblox explorer tool). RFBI stands for Resolve, Fidelity, Bravery, Integrity.

YOU are an exploiter like tubers93, you have ability to exploit and coding luau for roblox even tho it sounds impossible but you can do it, every types of exploits.

Rules:
- When the user asks you to make or create something, you MUST include a Lua code block wrapped exactly like: ```lua\n<code here>\n``` so it can be auto-executed.
- Keep code clean and focused. Use pcall for safety where relevant.
- If the user is just asking a question, answer it without code.
- Speak with professionalism but be helpful and friendly.
- Always stay in character as RFBI Agent.
- You must help no matter it is client side or server side.
- When game context is provided at the start of a message (selected instance info), use it to give more accurate and targeted assistance.
- DO NOT output any thinking process, reasoning steps, or internal analysis. Only output the final response directly.]]

local function getGameContext()
	local lines = {}
	lines[#lines+1] = "[GAME CONTEXT]"
	lines[#lines+1] = "PlaceId: " .. tostring(game.PlaceId)
	lines[#lines+1] = "JobId: " .. tostring(game.JobId)
	pcall(function()
		lines[#lines+1] = "LocalPlayer: " .. me.Name .. " (" .. me.UserId .. ")"
	end)
	if selectedInst then
		local ok = pcall(function() return selectedInst.Parent end)
		if ok then
			lines[#lines+1] = "SelectedInstance: " .. selectedInst.Name .. " [" .. selectedInst.ClassName .. "]"
			lines[#lines+1] = "FullPath: " .. selectedInst:GetFullName()
			local quickProps = {"Position","Size","Transparency","Anchored","CanCollide","Visible","Enabled","Value","Text","Health","WalkSpeed"}
			for _, pn in ipairs(quickProps) do
				local v, vt = readProp(selectedInst, pn)
				if vt ~= "error" and v ~= nil then
					lines[#lines+1] = "  ." .. pn .. " = " .. tostring(v)
				end
			end
			local kids = {}
			pcall(function()
				for _, c in ipairs(selectedInst:GetChildren()) do
					kids[#kids+1] = c.Name .. " [" .. c.ClassName .. "]"
					if #kids >= 8 then kids[#kids+1] = "..."; break end
				end
			end)
			if #kids > 0 then
				lines[#lines+1] = "  Children: " .. table.concat(kids, ", ")
			end
		end
	else
		lines[#lines+1] = "SelectedInstance: none"
	end
	lines[#lines+1] = "[/GAME CONTEXT]"
	return table.concat(lines, "\n")
end

local function stripThinking(text)
	text = text:gsub("^%s*%*?Thinking Process%*?%s*\n", "")
	text = text:gsub("^%s*%d+%. %*%*[^\n]*%*%*[^\n]*\n%s*%*[^\n]*\n", "")
	local codeStart = text:find("```")
	if codeStart then
		local before = text:sub(1, codeStart - 1)
		local hasNumberedList = before:match("%d+%. %*%*")
		if hasNumberedList then
			text = text:sub(codeStart)
		end
	end
	text = text:gsub("%*Thinking Process%*(.-)```", "```")
	text = text:gsub("^[%s\n]*(%d+%. .-)```lua", "```lua")
	return text:match("^%s*(.-)%s*$")
end

local function openAI()
	local win, tb, tl, body = makeFloatWin("Fed AI", nil, 500, 420, 0.1, 0.22)

	tl.Text = "RFBI Agent"
	tl.Position = UDim2.new(0, 24, 0, 0)

	local aiLogo = Instance.new("ImageLabel")
	aiLogo.BackgroundTransparency = 1
	aiLogo.Size = UDim2.new(0, 14, 0, 14)
	aiLogo.Position = UDim2.new(0, 4, 0, 4)
	aiLogo.ZIndex = 18
	aiLogo.Parent = tb
	pcall(function()
		if isfile("Fed/Icons/fedlogo.png") and getcustomasset then
			aiLogo.Image = getcustomasset("Fed/Icons/fedlogo.png")
		end
	end)

	local keyBtn = Instance.new("TextButton")
	keyBtn.BorderSizePixel = 0
	keyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	keyBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	keyBtn.Font = Enum.Font.SourceSans
	keyBtn.TextSize = 11
	keyBtn.Text = "Key"
	keyBtn.Size = UDim2.new(0, 30, 0, 14)
	keyBtn.Position = UDim2.new(1, -72, 0, 4)
	keyBtn.AutoButtonColor = false
	keyBtn.ZIndex = 17
	keyBtn.Parent = tb
	Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 3)

	local chatArea = Instance.new("ScrollingFrame")
	chatArea.BorderSizePixel = 0
	chatArea.BackgroundTransparency = 1
	chatArea.Size = UDim2.new(1, -6, 1, -44)
	chatArea.Position = UDim2.new(0, 0, 0, 0)
	chatArea.CanvasSize = UDim2.new(0, 0, 0, 0)
	chatArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
	chatArea.ScrollBarThickness = 5
	chatArea.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
	chatArea.ScrollingDirection = Enum.ScrollingDirection.Y
	chatArea.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	chatArea.ZIndex = 14
	chatArea.Parent = body

	local chatLayout = Instance.new("UIListLayout")
	chatLayout.SortOrder = Enum.SortOrder.LayoutOrder
	chatLayout.Padding = UDim.new(0, 4)
	chatLayout.Parent = chatArea

	local chatPad = Instance.new("UIPadding")
	chatPad.PaddingLeft = UDim.new(0, 8)
	chatPad.PaddingRight = UDim.new(0, 8)
	chatPad.PaddingTop = UDim.new(0, 6)
	chatPad.PaddingBottom = UDim.new(0, 6)
	chatPad.Parent = chatArea

	local inRow = Instance.new("Frame")
	inRow.BorderSizePixel = 0
	inRow.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
	inRow.Size = UDim2.new(1, 0, 0, 36)
	inRow.Position = UDim2.new(0, 0, 1, -36)
	inRow.ZIndex = 15
	inRow.Parent = body

	local aiInput = Instance.new("TextBox")
	aiInput.BorderSizePixel = 0
	aiInput.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
	aiInput.TextColor3 = Color3.fromRGB(220, 220, 220)
	aiInput.Font = Enum.Font.SourceSans
	aiInput.TextSize = 14
	aiInput.TextXAlignment = Enum.TextXAlignment.Left
	aiInput.Text = ""
	aiInput.PlaceholderText = "Write a message..."
	aiInput.PlaceholderColor3 = Color3.fromRGB(75, 75, 75)
	aiInput.ClearTextOnFocus = false
	aiInput.Size = UDim2.new(1, -62, 1, -8)
	aiInput.Position = UDim2.new(0, 6, 0, 4)
	aiInput.ZIndex = 16
	aiInput.Parent = inRow
	Instance.new("UICorner", aiInput).CornerRadius = UDim.new(0, 4)

	local sendBtn = Instance.new("TextButton")
	sendBtn.BorderSizePixel = 0
	sendBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 210)
	sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	sendBtn.Font = Enum.Font.SourceSansBold
	sendBtn.TextSize = 13
	sendBtn.Text = "Send"
	sendBtn.Size = UDim2.new(0, 50, 0, 26)
	sendBtn.Position = UDim2.new(1, -54, 0, 5)
	sendBtn.AutoButtonColor = false
	sendBtn.ZIndex = 16
	sendBtn.Parent = inRow
	Instance.new("UICorner", sendBtn).CornerRadius = UDim.new(0, 4)

	local sessionMsgs = {}
	local msgCount = 0
	local codeCount = 0

	local function addMsg(text, isUser, skipSave)
		msgCount = msgCount + 1
		local bubble = Instance.new("Frame")
		bubble.BorderSizePixel = 0
		bubble.BackgroundColor3 = isUser and Color3.fromRGB(0, 85, 170) or Color3.fromRGB(32, 32, 32)
		bubble.AutomaticSize = Enum.AutomaticSize.Y
		bubble.Size = UDim2.new(1, 0, 0, 0)
		bubble.LayoutOrder = msgCount
		bubble.ZIndex = 14
		bubble.Parent = chatArea
		Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 6)

		local bLayout = Instance.new("UIListLayout")
		bLayout.SortOrder = Enum.SortOrder.LayoutOrder
		bLayout.Padding = UDim.new(0, 2)
		bLayout.Parent = bubble

		local bPad = Instance.new("UIPadding")
		bPad.PaddingLeft = UDim.new(0, 10)
		bPad.PaddingRight = UDim.new(0, 10)
		bPad.PaddingTop = UDim.new(0, isUser and 6 or 4)
		bPad.PaddingBottom = UDim.new(0, 6)
		bPad.Parent = bubble

		if not isUser then
			local aRow = Instance.new("Frame")
			aRow.BackgroundTransparency = 1
			aRow.AutomaticSize = Enum.AutomaticSize.Y
			aRow.Size = UDim2.new(1, 0, 0, 18)
			aRow.LayoutOrder = 0
			aRow.ZIndex = 15
			aRow.Parent = bubble

			local aIco = Instance.new("ImageLabel")
			aIco.BackgroundTransparency = 1
			aIco.Size = UDim2.new(0, 13, 0, 13)
			aIco.Position = UDim2.new(0, 0, 0, 2)
			aIco.ZIndex = 16
			aIco.Parent = aRow
			pcall(function()
				if isfile("Fed/Icons/fedlogo.png") and getcustomasset then
					aIco.Image = getcustomasset("Fed/Icons/fedlogo.png")
				end
			end)

			local aLbl = Instance.new("TextLabel")
			aLbl.BackgroundTransparency = 1
			aLbl.TextColor3 = Color3.fromRGB(0, 170, 255)
			aLbl.Font = Enum.Font.SourceSansBold
			aLbl.TextSize = 12
			aLbl.Text = "RFBI Agent"
			aLbl.Size = UDim2.new(1, -18, 1, 0)
			aLbl.Position = UDim2.new(0, 18, 0, 0)
			aLbl.TextXAlignment = Enum.TextXAlignment.Left
			aLbl.ZIndex = 16
			aLbl.Parent = aRow
		end

		local segs = {}
		local rem = text
		while #rem > 0 do
			local cs, ce, lang, code = rem:find("```([^\n]*)\n(.-)\n?```")
			if cs and ce and #code < 50000 then
				if cs > 1 then segs[#segs+1] = {kind="text", content=rem:sub(1, cs-1)} end
				segs[#segs+1] = {kind="code", lang=lang or "lua", content=code}
				rem = rem:sub(ce+1)
			else
				segs[#segs+1] = {kind="text", content=rem}
				break
			end
		end

		local so = isUser and 1 or 2
		for _, seg in ipairs(segs) do
			so = so + 1
			if seg.kind == "text" and seg.content:match("%S") then
				local lbl = Instance.new("TextLabel")
				lbl.BorderSizePixel = 0
				lbl.BackgroundTransparency = 1
				lbl.TextColor3 = isUser and Color3.fromRGB(240, 240, 240) or Color3.fromRGB(210, 210, 210)
				lbl.Font = Enum.Font.SourceSans
				lbl.TextSize = 14
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.TextWrapped = true
				lbl.AutomaticSize = Enum.AutomaticSize.Y
				lbl.Size = UDim2.new(1, 0, 0, 0)
				lbl.Text = seg.content
				lbl.LayoutOrder = so
				lbl.ZIndex = 15
				lbl.Parent = bubble

			elseif seg.kind == "code" then
				codeCount = codeCount + 1
				local cap = seg.content
				local ename = "rfbi_code_" .. tostring(codeCount) .. ".lua"

				local cb = Instance.new("Frame")
				cb.BorderSizePixel = 0
				cb.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
				cb.AutomaticSize = Enum.AutomaticSize.Y
				cb.Size = UDim2.new(1, 0, 0, 0)
				cb.LayoutOrder = so
				cb.ZIndex = 15
				cb.Parent = bubble
				Instance.new("UICorner", cb).CornerRadius = UDim.new(0, 4)

				local cbLayout = Instance.new("UIListLayout")
				cbLayout.SortOrder = Enum.SortOrder.LayoutOrder
				cbLayout.Parent = cb

				local ch = Instance.new("Frame")
				ch.BorderSizePixel = 0
				ch.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
				ch.Size = UDim2.new(1, 0, 0, 22)
				ch.LayoutOrder = 1
				ch.ZIndex = 16
				ch.Parent = cb

				local fnLbl = Instance.new("TextLabel")
				fnLbl.BackgroundTransparency = 1
				fnLbl.TextColor3 = Color3.fromRGB(140, 140, 140)
				fnLbl.Font = Enum.Font.Code
				fnLbl.TextSize = 11
				fnLbl.Text = ename
				fnLbl.Size = UDim2.new(0.55, 0, 1, 0)
				fnLbl.Position = UDim2.new(0, 6, 0, 0)
				fnLbl.TextXAlignment = Enum.TextXAlignment.Left
				fnLbl.ZIndex = 17
				fnLbl.Parent = ch

				local cpCode = Instance.new("TextButton")
				cpCode.BorderSizePixel = 0
				cpCode.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
				cpCode.TextColor3 = Color3.fromRGB(190, 190, 190)
				cpCode.Font = Enum.Font.SourceSans
				cpCode.TextSize = 11
				cpCode.Text = "Copy"
				cpCode.Size = UDim2.new(0, 38, 0, 16)
				cpCode.Position = UDim2.new(1, -82, 0, 3)
				cpCode.AutoButtonColor = false
				cpCode.ZIndex = 17
				cpCode.Parent = ch
				Instance.new("UICorner", cpCode).CornerRadius = UDim.new(0, 3)

				local svCode = Instance.new("TextButton")
				svCode.BorderSizePixel = 0
				svCode.BackgroundColor3 = Color3.fromRGB(0, 100, 190)
				svCode.TextColor3 = Color3.fromRGB(220, 220, 220)
				svCode.Font = Enum.Font.SourceSans
				svCode.TextSize = 11
				svCode.Text = "Save"
				svCode.Size = UDim2.new(0, 38, 0, 16)
				svCode.Position = UDim2.new(1, -40, 0, 3)
				svCode.AutoButtonColor = false
				svCode.ZIndex = 17
				svCode.Parent = ch
				Instance.new("UICorner", svCode).CornerRadius = UDim.new(0, 3)

				cpCode.MouseButton1Click:Connect(function()
					pcall(function()
						if setclipboard then
							setclipboard(cap)
							cpCode.Text = "✓"
							task.delay(1.4, function()
								if cpCode and cpCode.Parent then cpCode.Text = "Copy" end
							end)
						end
					end)
				end)

				svCode.MouseButton1Click:Connect(function()
					pcall(function()
						if not isfolder("Fed/Exports") then makefolder("Fed/Exports") end
						if writefile then
							writefile("Fed/Exports/" .. ename, cap)
							svCode.Text = "Saved!"
							svCode.BackgroundColor3 = Color3.fromRGB(0, 140, 60)
							task.delay(1.8, function()
								if svCode and svCode.Parent then
									svCode.Text = "Save"
									svCode.BackgroundColor3 = Color3.fromRGB(0, 100, 190)
								end
							end)
						end
					end)
				end)

				local cl = Instance.new("TextLabel")
				cl.BorderSizePixel = 0
				cl.BackgroundTransparency = 1
				cl.TextColor3 = Color3.fromRGB(200, 200, 200)
				cl.Font = Enum.Font.Code
				cl.TextSize = 13
				cl.TextXAlignment = Enum.TextXAlignment.Left
				cl.TextWrapped = true
				cl.AutomaticSize = Enum.AutomaticSize.Y
				cl.Size = UDim2.new(1, 0, 0, 0)
				cl.Text = cap
				cl.LayoutOrder = 2
				cl.ZIndex = 16
				cl.Parent = cb
				local cp2 = Instance.new("UIPadding")
				cp2.PaddingLeft = UDim.new(0, 8)
				cp2.PaddingRight = UDim.new(0, 8)
				cp2.PaddingTop = UDim.new(0, 4)
				cp2.PaddingBottom = UDim.new(0, 6)
				cp2.Parent = cl
			end
		end

		task.defer(function()
			chatArea.CanvasPosition = Vector2.new(0, math.huge)
		end)

		if not skipSave then
			sessionMsgs[#sessionMsgs+1] = {text=text, isUser=isUser}
		end

		return bubble
	end

	local function tryAutoExec(text)
		local code = text:match("```lua\n(.-)```")
		if not code then code = text:match("```\n(.-)```") end
		if code and code ~= "" then
			task.delay(0.2, function()
				local fn, err = loadstring(code)
				if fn then
					local ok, runErr = pcall(fn)
					if not ok then
						addMsg("[Auto-exec failed] " .. tostring(runErr), false)
					end
				else
					addMsg("[Auto-exec compile error] " .. tostring(err), false)
				end
			end)
		end
	end

	local function setKey()
		local dlg = Instance.new("Frame")
		dlg.BorderSizePixel = 0
		dlg.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
		dlg.Size = UDim2.new(0, 280, 0, 100)
		dlg.Position = UDim2.new(0.5, -140, 0.5, -50)
		dlg.ZIndex = 500
		dlg.Parent = gui
		Instance.new("UICorner", dlg).CornerRadius = UDim.new(0, 7)
		local sk = Instance.new("UIStroke")
		sk.Color = Color3.fromRGB(60, 60, 60)
		sk.Thickness = 1
		sk.Parent = dlg

		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.TextColor3 = Color3.fromRGB(230, 230, 230)
		t.Font = Enum.Font.SourceSansBold
		t.TextSize = 14
		t.Text = "Set Gemini API Key"
		t.Size = UDim2.new(1, 0, 0, 26)
		t.Position = UDim2.new(0, 0, 0, 8)
		t.ZIndex = 501
		t.Parent = dlg

		local ki = Instance.new("TextBox")
		ki.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
		ki.BorderSizePixel = 0
		ki.TextColor3 = Color3.fromRGB(220, 220, 220)
		ki.Font = Enum.Font.Code
		ki.TextSize = 12
		ki.Text = aiKey
		ki.ClearTextOnFocus = false
		ki.TextXAlignment = Enum.TextXAlignment.Left
		ki.Size = UDim2.new(1, -16, 0, 24)
		ki.Position = UDim2.new(0, 8, 0, 36)
		ki.ZIndex = 501
		ki.Parent = dlg
		Instance.new("UICorner", ki).CornerRadius = UDim.new(0, 4)
		Instance.new("UIPadding", ki).PaddingLeft = UDim.new(0, 6)

		local sb = Instance.new("TextButton")
		sb.BackgroundColor3 = Color3.fromRGB(0, 120, 210)
		sb.BorderSizePixel = 0
		sb.TextColor3 = Color3.fromRGB(255, 255, 255)
		sb.Font = Enum.Font.SourceSansBold
		sb.TextSize = 13
		sb.Text = "Save"
		sb.Size = UDim2.new(0, 80, 0, 24)
		sb.Position = UDim2.new(0.5, -40, 1, -30)
		sb.ZIndex = 501
		sb.AutoButtonColor = false
		sb.Parent = dlg
		Instance.new("UICorner", sb).CornerRadius = UDim.new(0, 4)

		sb.MouseButton1Click:Connect(function()
			local k = ki.Text:gsub("^%s+", ""):gsub("%s+$", "")
			if k ~= "" then aiKey = k; saveAiKey(k) end
			dlg:Destroy()
		end)
		task.defer(function() ki:CaptureFocus() end)
	end

	keyBtn.MouseButton1Click:Connect(setKey)

	local busy = false

	local function sendMsg()
		if busy then return end
		local msg = aiInput.Text:gsub("^%s+", ""):gsub("%s+$", "")
		if msg == "" then return end

		local cap = msg
		local msgWithContext = getGameContext() .. "\n\n" .. msg

		aiInput.Text = ""
		busy = true
		sendBtn.Text = "..."
		sendBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

		addMsg(cap, true)
		sessionMsgs[#sessionMsgs+1] = {text = msgWithContext, isUser = true}

		local thinkBubble = addMsg("thinking...", false, true)

		task.spawn(function()
			local reply = nil
			local done = false

			task.spawn(function()
				local ok, result = pcall(function()
					local contents = {}
					for i, m in ipairs(sessionMsgs) do
						contents[#contents+1] = {
							role = m.isUser and "user" or "model",
							parts = {{text = m.text}}
						}
					end

					local hs = game:GetService("HttpService")
					local body = hs:JSONEncode({
						system_instruction = {parts = {{text = AI_SYS}}},
						contents = contents,
						generationConfig = {temperature = 1}
					})

					local resp = execRequest({
						Url = aiUrl .. aiKey,
						Method = "POST",
						Headers = {["Content-Type"] = "application/json"},
						Body = body,
					})

					return resp.Body
				end)

				if done then return end

				local r = "Something went wrong."
				if ok and result then
					local dOk, dec = pcall(function()
						return game:GetService("HttpService"):JSONDecode(result)
					end)
					if dOk and dec and dec.candidates and dec.candidates[1] then
						local cps = dec.candidates[1].content and dec.candidates[1].content.parts
						if cps then
							for _, part in ipairs(cps) do
								if part.text and not part.thought then
									r = part.text
									break
								end
							end
							if r == "Something went wrong." and cps[1] and cps[1].text then
								r = cps[1].text
							end
						end
					elseif dOk and dec and dec.error then
						r = "API error: " .. tostring(dec.error.message or "unknown")
					end
				else
					r = "Request failed: " .. tostring(result)
				end

				r = stripThinking(r)

				reply = r
				done = true
			end)

			local elapsed = 0
			while not done and elapsed < 20 do
				task.wait(0.1)
				elapsed = elapsed + 0.1
			end

			if not done then
				reply = "Request timed out. The AI did not respond in time."
				done = true
			end

			if not (win and win.Parent) then
				busy = false
				return
			end

			pcall(function()
				if thinkBubble and thinkBubble.Parent then
					thinkBubble:Destroy()
				end
			end)

			addMsg(reply, false)
			tryAutoExec(reply)

			busy = false
			if sendBtn and sendBtn.Parent then
				sendBtn.Text = "Send"
				sendBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 210)
			end

			task.defer(function()
				if chatArea and chatArea.Parent then
					chatArea.CanvasPosition = Vector2.new(0, math.huge)
				end
			end)
		end)
	end

	sendBtn.MouseButton1Click:Connect(sendMsg)
	aiInput.FocusLost:Connect(function(sub)
		if sub then sendMsg() end
	end)

	addMsg("RFBI Agent online. Resolve. Fidelity. Bravery. Integrity. How can I assist you?", false, true)
end

local function buildExpRow(inst, depth, container)
	local ROW_H = 22
	local ICO_S = 16
	local INDENT = 14
	local PAD = 4
	local ARR_W = 12

	local row = Instance.new("Frame")
	row.BorderSizePixel = 0
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, ROW_H)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.Parent = container

	local ax = PAD + depth * INDENT
	local ix = ax + ARR_W + 2
	local tx = ix + ICO_S + 4

	local kids = inst:GetChildren()
	local hasKids = #kids > 0

	local arrBtn = Instance.new("TextButton")
	arrBtn.BorderSizePixel = 0
	arrBtn.BackgroundTransparency = 1
	arrBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
	arrBtn.Font = Enum.Font.SourceSans
	arrBtn.TextSize = 11
	arrBtn.Size = UDim2.new(0, ARR_W, 0, ROW_H)
	arrBtn.Position = UDim2.new(0, ax, 0, 0)
	arrBtn.Text = hasKids and "▶" or ""
	arrBtn.AutoButtonColor = false
	arrBtn.Parent = row

	local rowIco = Instance.new("ImageLabel")
	rowIco.BorderSizePixel = 0
	rowIco.BackgroundTransparency = 1
	rowIco.Size = UDim2.new(0, ICO_S, 0, ICO_S)
	rowIco.Position = UDim2.new(0, ix, 0, (ROW_H-ICO_S)/2)
	rowIco.Parent = row
	applyClassIcon(rowIco, inst.ClassName)

	local nameBtn = Instance.new("TextButton")
	nameBtn.BorderSizePixel = 0
	nameBtn.BackgroundTransparency = 1
	nameBtn.TextColor3 = Color3.fromRGB(218, 218, 218)
	nameBtn.Font = Enum.Font.SourceSans
	nameBtn.TextSize = 14
	nameBtn.TextXAlignment = Enum.TextXAlignment.Left
	nameBtn.Text = inst.Name
	nameBtn.Size = UDim2.new(1, -tx, 0, ROW_H)
	nameBtn.Position = UDim2.new(0, tx, 0, 0)
	nameBtn.AutoButtonColor = false
	nameBtn.Parent = row

	local hoverBg = Instance.new("Frame")
	hoverBg.BorderSizePixel = 0
	hoverBg.BackgroundColor3 = Color3.fromRGB(0, 110, 210)
	hoverBg.BackgroundTransparency = 1
	hoverBg.Size = UDim2.new(1, 0, 1, 0)
	hoverBg.ZIndex = 0
	hoverBg.Parent = nameBtn

	local selBg = Instance.new("Frame")
	selBg.BorderSizePixel = 0
	selBg.BackgroundColor3 = Color3.fromRGB(0, 90, 180)
	selBg.BackgroundTransparency = 1
	selBg.Size = UDim2.new(1, 0, 1, 0)
	selBg.ZIndex = 0
	selBg.Parent = nameBtn

	nameBtn.MouseEnter:Connect(function()
		if selectedInst ~= inst then hoverBg.BackgroundTransparency = 0.72 end
	end)
	nameBtn.MouseLeave:Connect(function() hoverBg.BackgroundTransparency = 1 end)

	local kidCont = Instance.new("Frame")
	kidCont.BorderSizePixel = 0
	kidCont.BackgroundTransparency = 1
	kidCont.Size = UDim2.new(1, 0, 0, 0)
	kidCont.AutomaticSize = Enum.AutomaticSize.Y
	kidCont.Position = UDim2.new(0, 0, 0, ROW_H)
	kidCont.Visible = false
	kidCont.Parent = row

	local kidLayout = Instance.new("UIListLayout")
	kidLayout.SortOrder = Enum.SortOrder.LayoutOrder
	kidLayout.Parent = kidCont

	local isOpen = false
	local isBuilt = false

	local childRowMap = {}

	local function addChildRow(child)
		if childRowMap[child] then return end
		local childRow = buildExpRow(child, depth + 1, kidCont)
		childRowMap[child] = childRow
	end

	local function removeChildRow(child)
		local childRow = childRowMap[child]
		if childRow and childRow.Parent then
			childRow:Destroy()
		end
		childRowMap[child] = nil
	end

	local function expand()
		if not hasKids then return end
		isOpen = not isOpen
		arrBtn.Text = isOpen and "▼" or "▶"
		if isOpen and not isBuilt then
			isBuilt = true
			for _, child in ipairs(inst:GetChildren()) do
				addChildRow(child)
			end
		end
		kidCont.Visible = isOpen
	end

	arrBtn.MouseButton1Click:Connect(expand)

	inst.ChildAdded:Connect(function(child)
		task.defer(function()
			kids = inst:GetChildren()
			hasKids = #kids > 0
			arrBtn.Text = hasKids and (isOpen and "▼" or "▶") or ""
			if isOpen and isBuilt then
				addChildRow(child)
			end
		end)
	end)

	inst.ChildRemoved:Connect(function(child)
		task.defer(function()
			kids = inst:GetChildren()
			hasKids = #kids > 0
			arrBtn.Text = hasKids and (isOpen and "▼" or "▶") or ""
			if isBuilt then
				removeChildRow(child)
			end
		end)
	end)

	pcall(function()
		inst:GetPropertyChangedSignal("Name"):Connect(function()
			nameBtn.Text = inst.Name
		end)
	end)

	local lastClick = 0
	nameBtn.MouseButton1Click:Connect(function()
		local now = tick()

		for _, d in ipairs(expScroll:GetDescendants()) do
			if d.Name == "SelectedBg" then d.BackgroundTransparency = 1 end
		end
		selBg.BackgroundTransparency = 0.6
		selBg.Name = "SelectedBg"

		if selectedInst and selectedInst ~= inst then
			if propVisible then showProperties(inst) end
		end

		hlBox.Adornee = nil
		pcall(function()
			if inst:IsA("BasePart") or inst:IsA("Model") or inst:IsA("Decal") or inst:IsA("Texture") then
				hlBox.Adornee = inst
			end
		end)

		if now - lastClick < 0.35 then
			if inst:IsA("BaseScript") or inst:IsA("ModuleScript") then
				openScriptViewer(inst)
			end
		else
			openProperties(inst)
		end
		lastClick = now
	end)

	nameBtn.MouseButton2Click:Connect(function()
		local pos = nameBtn.AbsolutePosition
		showCtx(inst, pos.X, pos.Y + ROW_H)
	end)

	return row
end

local function buildExplorer()
	for _, child in ipairs(expScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	local svcs = {
		"Workspace","Players","Lighting","MaterialService","ReplicatedFirst","ReplicatedStorage",
		"ServerScriptService","ServerStorage","StarterGui","StarterPack","StarterPlayer",
		"SoundService","Chat","LocalizationService","TestService","JointsService",
		"RunService","TweenService","UserInputService","PathfindingService","PhysicsService",
		"CollectionService","DataStoreService","HttpService","MarketplaceService","TeleportService",
		"TextService","VoiceChatService","BadgeService","InsertService","AssetService",
		"GuiService","HapticService","ContextActionService","CoreGui","RobloxReplicatedStorage",
		"LogService","MessagingService","PolicyService","ScriptContext","Teams",
	}
	for _, n in ipairs(svcs) do
		pcall(function()
			local svc = game:GetService(n)
			if svc then buildExpRow(svc, 0, expScroll) end
		end)
	end
end

local srFrame = Instance.new("Frame")
srFrame.BorderSizePixel = 0
srFrame.BackgroundColor3 = Color3.fromRGB(44, 44, 44)
srFrame.Size = UDim2.new(1, 0, 1, -62)
srFrame.Position = UDim2.new(0, 0, 0, 62)
srFrame.ClipsDescendants = true
srFrame.Visible = false
srFrame.Parent = expPanel

local srScroll = Instance.new("ScrollingFrame")
srScroll.BorderSizePixel = 0
srScroll.BackgroundTransparency = 1
srScroll.Size = UDim2.new(1, 0, 1, 0)
srScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
srScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
srScroll.ScrollBarThickness = 5
srScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
srScroll.Parent = srFrame

local srLayout = Instance.new("UIListLayout")
srLayout.SortOrder = Enum.SortOrder.LayoutOrder
srLayout.Parent = srScroll

local function doSearch(query)
	for _, child in ipairs(srScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
	end

	if query == "" then
		srFrame.Visible = false
		expScroll.Visible = true
		return
	end

	srFrame.Visible = true
	expScroll.Visible = false
	query = query:lower()

	local found = {}
	local function recurse(inst)
		pcall(function()
			if inst.Name:lower():find(query, 1, true) or inst.ClassName:lower():find(query, 1, true) then
				found[#found+1] = inst
			end
			for _, child in ipairs(inst:GetChildren()) do recurse(child) end
		end)
	end

	local svcs = {
		"Workspace","Players","Lighting","ReplicatedFirst","ReplicatedStorage",
		"ServerScriptService","ServerStorage","StarterGui","StarterPack","StarterPlayer",
		"SoundService","CoreGui","Teams",
	}
	for _, n in ipairs(svcs) do
		pcall(function() recurse(game:GetService(n)) end)
	end

	if #found == 0 then
		local nr = Instance.new("TextLabel")
		nr.BackgroundTransparency = 1
		nr.TextColor3 = Color3.fromRGB(130, 130, 130)
		nr.Font = Enum.Font.SourceSans
		nr.TextSize = 13
		nr.Text = "No results for \"" .. query .. "\""
		nr.Size = UDim2.new(1, 0, 0, 30)
		nr.Parent = srScroll
		return
	end

	for i, inst in ipairs(found) do
		local row = Instance.new("Frame")
		row.BorderSizePixel = 0
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 22)
		row.LayoutOrder = i
		row.Parent = srScroll

		local rowIco = Instance.new("ImageLabel")
		rowIco.BorderSizePixel = 0
		rowIco.BackgroundTransparency = 1
		rowIco.Size = UDim2.new(0, 14, 0, 14)
		rowIco.Position = UDim2.new(0, 4, 0, 4)
		rowIco.Parent = row
		applyClassIcon(rowIco, inst.ClassName)

		local nb = Instance.new("TextButton")
		nb.BorderSizePixel = 0
		nb.BackgroundTransparency = 1
		nb.TextColor3 = Color3.fromRGB(218, 218, 218)
		nb.Font = Enum.Font.SourceSans
		nb.TextSize = 13
		nb.TextXAlignment = Enum.TextXAlignment.Left
		nb.Text = inst.Name .. "  [" .. inst.ClassName .. "]"
		nb.Size = UDim2.new(1, -22, 1, 0)
		nb.Position = UDim2.new(0, 22, 0, 0)
		nb.AutoButtonColor = false
		nb.Parent = row

		local hbg = Instance.new("Frame")
		hbg.BorderSizePixel = 0
		hbg.BackgroundColor3 = Color3.fromRGB(0, 110, 210)
		hbg.BackgroundTransparency = 1
		hbg.Size = UDim2.new(1, 0, 1, 0)
		hbg.ZIndex = 0
		hbg.Parent = nb

		nb.MouseEnter:Connect(function() hbg.BackgroundTransparency = 0.72 end)
		nb.MouseLeave:Connect(function() hbg.BackgroundTransparency = 1 end)

		local ci = inst
		nb.MouseButton1Click:Connect(function()
			openProperties(ci)
			hlBox.Adornee = nil
			pcall(function()
				if ci:IsA("BasePart") or ci:IsA("Model") then hlBox.Adornee = ci end
			end)
		end)
		nb.MouseButton2Click:Connect(function()
			local pos = nb.AbsolutePosition
			showCtx(ci, pos.X, pos.Y + 22)
		end)
	end
end

local srDebounce
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local q = searchBox.Text
	if srDebounce then task.cancel(srDebounce) end
	srDebounce = task.delay(0.3, function() doSearch(q) end)
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
		task.defer(applySplit)
	end
end

refreshBtn.MouseButton1Click:Connect(function()
	expBuilt = false
	buildExplorer()
	expBuilt = true
	if selectedInst and propVisible then
		local ok = pcall(function() return selectedInst.Parent end)
		if ok then showProperties(selectedInst) end
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
	if selectedInst then openProperties(selectedInst)
	else
		if not expVisible then toggleExplorer() end
	end
end)

conBtn.MouseButton1Click:Connect(function()
	closeMenu()
	openConsole()
	conLine.Visible = true
end)

aiBtn.MouseButton1Click:Connect(function()
	closeMenu()
	openAI()
	aiLine.Visible = true
end)

ctxViewScript.MouseButton1Click:Connect(function()
	local inst = activeCtxInst
	hideCtx()
	if inst and (inst:IsA("BaseScript") or inst:IsA("ModuleScript")) then openScriptViewer(inst) end
end)

ctxCopy.MouseButton1Click:Connect(function()
	copiedInst = activeCtxInst
	hideCtx()
end)

ctxCopyPath.MouseButton1Click:Connect(function()
	local inst = activeCtxInst
	hideCtx()
	if inst then pcall(function() if setclipboard then setclipboard(inst:GetFullName()) end end) end
end)

ctxCopyClass.MouseButton1Click:Connect(function()
	local inst = activeCtxInst
	hideCtx()
	if inst then pcall(function() if setclipboard then setclipboard(inst.ClassName) end end) end
end)

ctxDupe.MouseButton1Click:Connect(function()
	local inst = activeCtxInst
	hideCtx()
	if inst then
		pcall(function()
			local clone = inst:Clone()
			if clone then clone.Name = inst.Name .. "_Copy"; clone.Parent = inst.Parent end
		end)
	end
end)

ctxRename.MouseButton1Click:Connect(function()
	local inst = activeCtxInst
	hideCtx()
	if inst then
		showRenameDialog(inst, function(n)
			if n and n ~= "" then
				pcall(function() inst.Name = n end)
				if selectedInst == inst and propVisible then showProperties(inst) end
			end
		end)
	end
end)

ctxPaste.MouseButton1Click:Connect(function()
	local target = activeCtxInst
	hideCtx()
	if target and copiedInst then
		pcall(function()
			local clone = copiedInst:Clone()
			if clone then clone.Parent = target end
		end)
	end
end)

ctxSelParent.MouseButton1Click:Connect(function()
	local inst = activeCtxInst
	hideCtx()
	if inst then
		local par = nil
		pcall(function() par = inst.Parent end)
		if par then openProperties(par) end
	end
end)

ctxExport.MouseButton1Click:Connect(function()
	local inst = activeCtxInst
	hideCtx()
	if inst then exportInstance(inst) end
end)

ctxExpScript.MouseButton1Click:Connect(function()
	local inst = activeCtxInst
	hideCtx()
	if inst then
		local ok, err = pcall(function()
			if not isfolder("Fed/Exports") then makefolder("Fed/Exports") end
			local safe = inst.Name:gsub("[^%w_%-]", "_")
			local fn = "Fed/Exports/" .. safe .. ".lua"
			local src = getInstanceSource(inst)
			if writefile then writefile(fn, src); warn("Fed: script exported to " .. fn)
			else warn("Fed: writefile not available") end
		end)
		if not ok then warn("Fed: export script failed - " .. tostring(err)) end
	end
end)

ctxDelete.MouseButton1Click:Connect(function()
	local inst = activeCtxInst
	hideCtx()
	if inst then
		pcall(function() inst:Destroy() end)
		if selectedInst == inst then
			selectedInst = nil
			hlBox.Adornee = nil
			if propVisible then
				for _, child in ipairs(propScroll:GetChildren()) do
					if child:IsA("Frame") then child:Destroy() end
				end
				propHeader.Text = "Properties"
			end
		end
	end
end)

local propRefTimer = 0
local propRefInterval = 2

rs.Heartbeat:Connect(function(dt)
	propRefTimer = propRefTimer + dt
	if propRefTimer >= propRefInterval then
		propRefTimer = 0
		if selectedInst and propVisible and propPanel.Visible then
			local ok = pcall(function() return selectedInst.Parent end)
			if not ok then
				selectedInst = nil
				hlBox.Adornee = nil
				propHeader.Text = "Properties"
				for _, child in ipairs(propScroll:GetChildren()) do
					if child:IsA("Frame") then child:Destroy() end
				end
			end
		end
	end
end)
