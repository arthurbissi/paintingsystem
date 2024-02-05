-- This script was made by ArthurBissi (discord: arth._.)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
 
local PlayerGui = player:WaitForChild("PlayerGui")
local PaintingGUI = PlayerGui:WaitForChild("PaintingGUI")
local ToolsFrame = PaintingGUI:WaitForChild("ToolsFrame")
local BrushButtonFrame = ToolsFrame:WaitForChild("BrushButtonFrame")
local BrushButton = BrushButtonFrame:WaitForChild("BrushButton")
local BucketButtonFrame = ToolsFrame:WaitForChild("BucketButtonFrame")
local BucketButton = BucketButtonFrame:WaitForChild("BucketButton")
local EraserButtonFrame = ToolsFrame:WaitForChild("EraserButtonFrame")
local EraserButton = EraserButtonFrame:WaitForChild("EraserButton")

local CanvasFrame = script.Parent
local Values = CanvasFrame:WaitForChild("Values")
local FinishedAddingPixels = Values:WaitForChild("FinishedAddingPixels")

local totalPixelsAmountX = (CanvasFrame.AbsoluteSize.X / 20)
local totalPixelsAmountY = (CanvasFrame.AbsoluteSize.Y / 20)

local holdingMouseButton = false
local lastPaintedPixelX = nil
local lastPaintedPixelY = nil
local currentColor = player:WaitForChild("Values"):WaitForChild("CurrentColor")
local pixelsChanged = {}
local toolEquipped = ""

local function numbersInRange(x0, x1, y0, y1) -- Get Coordinates of pixels inbetween 2 of them
	local pixels = {}
	local dx = math.abs(x1 - x0)
	local dy = math.abs(y1 - y0)
	local sx = x0 < x1 and 1 or -1
	local sy = y0 < y1 and 1 or -1
	local err = dx - dy

	while true do
		table.insert(pixels, {X = x0, Y = y0})

		if x0 == x1 and y0 == y1 then
			break
		end

		local e2 = 2 * err
		if e2 > -dy then
			err = err - dy
			x0 = x0 + sx
		end

		if e2 < dx then
			err = err + dx
			y0 = y0 + sy
		end
	end

	return pixels
end

local function paintLine(v, color)
	if holdingMouseButton then
		v.BackgroundColor3 = color -- Set the background color of the button (pixel)

		table.insert(pixelsChanged, {Name = v.Name, BackgroundColor3 = v.BackgroundColor3}) -- insert the pixel into the table that contains all the pixels that were changed

		ReplicatedStorage.Remotes.SendCurrentDrawingToServer:FireServer(pixelsChanged) -- Send all the pixels changed to the server so it can change it on the actual canvas model

		if lastPaintedPixelX and lastPaintedPixelY then
			local lastPaintedPixelPos = lastPaintedPixelX + totalPixelsAmountX * (lastPaintedPixelY - 1)
			local currentPixelPos = v:WaitForChild("GridX").Value + totalPixelsAmountX * (v:WaitForChild("GridY").Value - 1)

			if math.abs(currentPixelPos - lastPaintedPixelX) >= 2 then
				for k, nextPixelXY in pairs(numbersInRange(lastPaintedPixelX, v:WaitForChild("GridX").Value, lastPaintedPixelY, v:WaitForChild("GridY").Value)) do
					local nextPixelX = nextPixelXY.X or v:WaitForChild("GridX").Value
					local nextPixelY = nextPixelXY.Y or v:WaitForChild("GridY").Value

					local nextPixel = CanvasFrame:FindFirstChild("Pixel"..tostring(nextPixelX + totalPixelsAmountX * (nextPixelY - 1)))

					if nextPixel then
						nextPixel.BackgroundColor3 = color

						table.insert(pixelsChanged, {Name = nextPixel.Name, BackgroundColor3 = nextPixel.BackgroundColor3})
					end
				end
			end
		end

		lastPaintedPixelX = v:WaitForChild("GridX").Value
		lastPaintedPixelY = v:WaitForChild("GridY").Value
	else
		lastPaintedPixelX = nil
		lastPaintedPixelY = nil
	end
end

FinishedAddingPixels.Changed:Wait()

for i, v in CanvasFrame:GetChildren() do -- puts a mouseEnter event into all the pixels that are inside canvas frame
	if v:IsA("TextButton") then
		v.MouseEnter:Connect(function()
			if toolEquipped == "brush" then -- if we have the tool brush selected, paint a line with the selected color
				paintLine(v, currentColor.Value)
			elseif toolEquipped == "eraser" then
				paintLine(v, Color3.new(255, 255, 255)) -- if we have the eraser selected, paint a line with white
			end
		end)
		
		v.MouseButton1Down:Connect(function()
			if toolEquipped == "brush" then
				v.BackgroundColor3 = currentColor.Value

				table.insert(pixelsChanged, {Name = v.Name, BackgroundColor3 = v.BackgroundColor3})

				ReplicatedStorage.Remotes.SendCurrentDrawingToServer:FireServer(pixelsChanged)
			elseif toolEquipped == "bucket" then
				local alreadyCheckedPixels = {}
				local originalColor = v.BackgroundColor3
				
				local function paintClosePixels(gridX, gridY) -- this function will loop through the nearest pixels to the last pixel painted so it can paint every pixel that is connected to them and making a bucket tool
					for i, k in pairs({"down", "right", "up", "left"}) do
						local nextPos
						
						if k == "left" then
							nextPos = {X = gridX - 1, Y = gridY}
						elseif k == "right" then
							nextPos = {X = gridX + 1, Y = gridY}
						elseif k == "up" then
							nextPos = {X = gridX, Y = gridY - 1}
						elseif k == "down" then
							nextPos = {X = gridX, Y = gridY + 1}
						end
						
						local gridToPixel = nextPos.X + totalPixelsAmountX * (nextPos.Y - 1)
						
						if (table.find(alreadyCheckedPixels, gridToPixel)) or not (nextPos.X >= 1 and nextPos.X <= totalPixelsAmountX and nextPos.Y >= 1 and nextPos.Y <= totalPixelsAmountY) then
							continue
						end
						
						table.insert(alreadyCheckedPixels, gridToPixel)
						
						local pixel = CanvasFrame:FindFirstChild("Pixel"..tostring(gridToPixel))

						if pixel then
							if pixel.BackgroundColor3 == originalColor then
								pixel.BackgroundColor3 = currentColor.Value

								table.insert(pixelsChanged, {Name = pixel.Name, BackgroundColor3 = pixel.BackgroundColor3})

								paintClosePixels(nextPos.X, nextPos.Y)
							end
						end
					end
				end
				
				v.BackgroundColor3 = currentColor.Value
				table.insert(pixelsChanged, {Name = v.Name, BackgroundColor3 = v.BackgroundColor3})
				paintClosePixels(v:WaitForChild("GridX").Value, v:WaitForChild("GridY").Value)
				
				ReplicatedStorage.Remotes.SendCurrentDrawingToServer:FireServer(pixelsChanged)
			elseif toolEquipped == "eraser" then
				v.BackgroundColor3 = Color3.fromHSV(0, 0, 1)
				
				table.insert(pixelsChanged, {Name = v.Name, BackgroundColor3 = v.BackgroundColor3})

				ReplicatedStorage.Remotes.SendCurrentDrawingToServer:FireServer(pixelsChanged)
			end
		end)
	end
end

CanvasFrame.MouseLeave:Connect(function()
	lastPaintedPixelX = nil
	lastPaintedPixelY = nil
end)

UIS.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		holdingMouseButton = true
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		holdingMouseButton = false
	end
end)

PaintingGUI:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not PaintingGUI.Enabled then
		pixelsChanged = {}
		lastPaintedPixelX = nil
		lastPaintedPixelY = nil
	end
end)

local function removeColorFromAllChildren(parent)
	for i, v in pairs(parent:GetChildren()) do
		if v:IsA("ImageButton") then
			v.ImageColor3 = Color3.fromRGB(0, 0, 0)
		end
		
		if #v:GetChildren() > 0 then
			removeColorFromAllChildren(v)
		end
	end
end

BrushButton.MouseButton1Click:Connect(function()
	removeColorFromAllChildren(ToolsFrame)
	
	if toolEquipped == "brush" then
		toolEquipped = ""
	else
		toolEquipped = "brush"
		BrushButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
	end
end)

BucketButton.MouseButton1Click:Connect(function()
	removeColorFromAllChildren(ToolsFrame)

	if toolEquipped == "bucket" then
		toolEquipped = ""
	else
		toolEquipped = "bucket"
		BucketButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
	end
end)

EraserButton.MouseButton1Click:Connect(function()
	removeColorFromAllChildren(ToolsFrame)

	if toolEquipped == "eraser" then
		toolEquipped = ""
	else
		toolEquipped = "eraser"
		EraserButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
	end
end)
