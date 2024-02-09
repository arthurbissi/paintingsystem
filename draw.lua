-- This script was made by ArthurBissi (discord: arth._.)

-- Gets all the services needed
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get the current player executing the script
local player = Players.LocalPlayer
 
-- Gets the UI of the PlayerGui and stores it into variables
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

-- Calculates the amount of pixels in each axis
local totalPixelsAmountX = (CanvasFrame.AbsoluteSize.X / 20)
local totalPixelsAmountY = (CanvasFrame.AbsoluteSize.Y / 20)

local holdingMouseButton = false -- This variable will be set to true when the mousebutton is being hold
local lastPaintedPixelX = nil -- Is set to the coordinate of the last painted pixel on the X axis
local lastPaintedPixelY = nil -- Is set to the coordinate of the last painted pixel on the Y axis
local currentColor = player:WaitForChild("Values"):WaitForChild("CurrentColor")
local pixelsChanged = {} -- A table that contains all the pixels positions before being sent to the server to update the Canvas in the workspace
local toolEquipped = "" -- Will be the current tool equipped (example: brush, bucket, eraser, etc...)

-- THIS IS AN IMPLEMENTATION OF THE BRESENHAN'S ALGORITHM
local function numbersInRange(x0, x1, y0, y1) -- Get all Coordinates of pixels inbetween 2 given pixels in the arguments
	local pixels = {} -- A table that contains the pixels inbetween 2 of the given pixels in the arguments and will be returned at the end of the function
	local dx = math.abs(x1 - x0) -- Calculates the distance between the first pixel in X and the second one
	local dy = math.abs(y1 - y0) -- Calculates the distance between the first pixel in Y and the second one
	local sx = x0 < x1 and 1 or -1
	local sy = y0 < y1 and 1 or -1
	local err = dx - dy

	while true do
		table.insert(pixels, {X = x0, Y = y0}) -- This loop will run until all the pixels inbetween two of the given points are added to this table

		if x0 == x1 and y0 == y1 then -- If the two given pixels are the same, then we are going to break out of the loop because theres no more other points to calculate
			break
		end
		
		-- These are some math functions i got from the Bresenhan's Algorithm
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

	return pixels -- Here, we return all the pixels that are inbetween the two given points (x0, x1) and (y0, y1)
end

local function paintLine(v, color) -- This function paints a line between the last point you hold your left mouse button and your current mouse position
	if holdingMouseButton then -- If we are holding the mouse button
		v.BackgroundColor3 = color -- We set the background color of the button (pixel)

		table.insert(pixelsChanged, {Name = v.Name, BackgroundColor3 = v.BackgroundColor3}) -- And, we add the pixel info to the pixelsChanged table so we can send the information to the server more efficiently, since we dont have to send all the pixels information to the server every time

		ReplicatedStorage.Remotes.SendCurrentDrawingToServer:FireServer(pixelsChanged) -- Send all the pixels changed to the server so it can change it on the actual canvas model in the workspace

		if lastPaintedPixelX and lastPaintedPixelY then -- If we already painted a pixel previously and didnt release the mouse button, then lastPaintedPixelX and lastPaintedPixelY will have a value and this if statement will be true
			local lastPaintedPixelPos = lastPaintedPixelX + totalPixelsAmountX * (lastPaintedPixelY - 1) -- Here, we transform the X and Y pixel position of the lastPaintedPixels into a single number that represents the order of the pixels from left to right, and top to bottom
			local currentPixelPos = v:WaitForChild("GridX").Value + totalPixelsAmountX * (v:WaitForChild("GridY").Value - 1) -- Here, we transform the X and Y pixel positions again, but we transform the current pixel that we are hovering

			if math.abs(currentPixelPos - lastPaintedPixelX) >= 2 then -- If the distance between the last painted pixel and the current pixel is greater or equal to two, then we make a line, if not, we can just paint a single pixel
				for k, nextPixelXY in pairs(numbersInRange(lastPaintedPixelX, v:WaitForChild("GridX").Value, lastPaintedPixelY, v:WaitForChild("GridY").Value)) do -- We loop through all the pixels inbetween the last painted pixel and the current pixel (obtained by using the function "numbersInBetween", which was shown earlier in the code)
					local nextPixelX = nextPixelXY.X or v:WaitForChild("GridX").Value -- To ensure theres no errors, we will substitute the nextPixelXY.X if it has no value for the current pixel position
					local nextPixelY = nextPixelXY.Y or v:WaitForChild("GridY").Value -- To ensure theres no errors, we will substitute the nextPixelXY.Y if it has no value for the current pixel position

					local nextPixel = CanvasFrame:FindFirstChild("Pixel"..tostring(nextPixelX + totalPixelsAmountX * (nextPixelY - 1))) -- Here, we transform the X and Y pixel position of the nextPixelXY into a single number that represents the order of the pixels from left to right, and top to bottom and try to find it in the "CanvasFrame" which contains all the pixels that are in the player's UI

					if nextPixel then -- If we can find the pixel in the "CanvasFrame", we can proceed to paint it
						nextPixel.BackgroundColor3 = color -- Then, we set the pixel's color to the color that has been given in the function arguments

						table.insert(pixelsChanged, {Name = nextPixel.Name, BackgroundColor3 = nextPixel.BackgroundColor3}) -- And, we add the pixel info to the pixelsChanged table so we can send the information to the server more efficiently, since we dont have to send all the pixels information to the server every time
					end
				end
			end
		end

		lastPaintedPixelX = v:WaitForChild("GridX").Value -- Here, we set the lastPaintedPixelX to the pixel we are currently hovering
		lastPaintedPixelY = v:WaitForChild("GridY").Value -- Here, we set the lastPaintedPixelY to the pixel we are currently hovering
	else
		lastPaintedPixelX = nil -- And, if we're not holding the mouse button, we set the lastPaintedPixelX to nil
		lastPaintedPixelY = nil -- And, if we're not holding the mouse button, we set the lastPaintedPixelY to nil
	end
end

FinishedAddingPixels.Changed:Wait() -- We wait until the FinishedAddingPixels instance has been changed, meaning all the pixels have been added to the player's UI

for i, v in CanvasFrame:GetChildren() do -- Loop through all the pixels inside of the "CanvasFrame"
	if v:IsA("TextButton") then -- If the instance is a TextButton, it means it is a pixel, so we proceed

		v.MouseEnter:Connect(function() -- Here we add an event to the pixel that will be fired when the player hovers it
			if toolEquipped == "brush" then -- If we have the brush selected, we paint a line with the current color the player has selected
				paintLine(v, currentColor.Value)
			elseif toolEquipped == "eraser" then -- If we have the eraser selected, paint the line with white so we can erase the drawing
				paintLine(v, Color3.new(255, 255, 255))
			end
		end)
		
		v.MouseButton1Down:Connect(function() -- Adds an event that will fire when the player clicks on the pixel
			if toolEquipped == "brush" then -- If we have the brush tool equipped
				v.BackgroundColor3 = currentColor.Value -- We set the color of the pixel we clicked to the color the player has selected

				table.insert(pixelsChanged, {Name = v.Name, BackgroundColor3 = v.BackgroundColor3}) -- And, we add the pixel info to the pixelsChanged table so we can send the information to the server more efficiently, since we dont have to send all the pixels information to the server every time

				ReplicatedStorage.Remotes.SendCurrentDrawingToServer:FireServer(pixelsChanged) -- Here, we fire a remote event to send the drawing to the server so it can update the canvas model in the workspace
			elseif toolEquipped == "bucket" then -- If we have the bucket tool equipped
				local alreadyCheckedPixels = {} -- We create this table that will contain all the pixels that have already been checked
				local originalColor = v.BackgroundColor3 -- We store the original color of the pixel the player clicked so we can compare the close pixels
				
				local function paintClosePixels(gridX, gridY) -- This function will basically paint the pixels that are close to the original pixel, and if they have the same color as "originalColor" we will paint it, and do the same thing, but with the pixel we just painted
					for i, k in pairs({"down", "right", "up", "left"}) do -- We will check for the pixels in the right, left, up, and down
						local nextPos

						-- Here, we define what position each direction will have, (example: left will be currentX - 1, and the Y will remain currentY)
						if k == "left" then
							nextPos = {X = gridX - 1, Y = gridY}
						elseif k == "right" then
							nextPos = {X = gridX + 1, Y = gridY}
						elseif k == "up" then
							nextPos = {X = gridX, Y = gridY - 1}
						elseif k == "down" then
							nextPos = {X = gridX, Y = gridY + 1}
						end
						
						local gridToPixel = nextPos.X + totalPixelsAmountX * (nextPos.Y - 1) -- We transform the X and Y positions of the pixel into a single number from left to right, top to bottom
						
						if (table.find(alreadyCheckedPixels, gridToPixel)) or not (nextPos.X >= 1 and nextPos.X <= totalPixelsAmountX and nextPos.Y >= 1 and nextPos.Y <= totalPixelsAmountY) then -- If the current pixel being checked is already on the alreadyCheckedPixels table, or the pixel position is out of the range of the possible pixel positions, we will continue the loop to the next direction
							continue
						end
						
						table.insert(alreadyCheckedPixels, gridToPixel) -- Add the current pixel into the alreadyCheckedPixels
						
						local pixel = CanvasFrame:FindFirstChild("Pixel"..tostring(gridToPixel)) -- Try to find the current pixel in the "CanvasFrame"

						if pixel then -- If we find that pixel
							if pixel.BackgroundColor3 == originalColor then -- and the pixel color is the same as the original color the player clicked
								pixel.BackgroundColor3 = currentColor.Value -- We will set the pixel's color to the current color the player has selected

								table.insert(pixelsChanged, {Name = pixel.Name, BackgroundColor3 = pixel.BackgroundColor3}) -- And, we add the pixel info to the pixelsChanged table so we can send the information to the server more efficiently, since we dont have to send all the pixels information to the server every time

								paintClosePixels(nextPos.X, nextPos.Y) -- And we will execute this function again, but for the pixel we just painted, making a recursive function
							end
						end
					end
				end
				
				v.BackgroundColor3 = currentColor.Value -- We paint the actual pixel the player clicked
				table.insert(pixelsChanged, {Name = v.Name, BackgroundColor3 = v.BackgroundColor3}) -- And, we add the pixel info to the pixelsChanged table so we can send the information to the server more efficiently, since we dont have to send all the pixels information to the server every time
				
				paintClosePixels(v:WaitForChild("GridX").Value, v:WaitForChild("GridY").Value) -- Then, we run the paintClosePixels function with the arguments being the current pixel the player clicked
				
				ReplicatedStorage.Remotes.SendCurrentDrawingToServer:FireServer(pixelsChanged) -- Here, we fire a remote event to send the drawing to the server so it can update the canvas model in the workspace
			elseif toolEquipped == "eraser" then -- If the player has the eraser tool selected
				v.BackgroundColor3 = Color3.fromHSV(0, 0, 1) -- We will just set the color of the pixel they clicked to white
				
				table.insert(pixelsChanged, {Name = v.Name, BackgroundColor3 = v.BackgroundColor3}) -- And, we add the pixel info to the pixelsChanged table so we can send the information to the server more efficiently, since we dont have to send all the pixels information to the server every time

				ReplicatedStorage.Remotes.SendCurrentDrawingToServer:FireServer(pixelsChanged) -- Here, we fire a remote event to send the drawing to the server so it can update the canvas model in the workspace
			end
		end)
	end
end

CanvasFrame.MouseLeave:Connect(function() -- If the players mouse leave the canvas frame, we can set the lastPaintedPixelX and lastPaintedPixelY to nil
	lastPaintedPixelX = nil
	lastPaintedPixelY = nil
end)

UIS.InputBegan:Connect(function(input) -- If the player clicked on any button on their keyboard or mouse
	if input.UserInputType == Enum.UserInputType.MouseButton1 then -- If the player clicked on the left mouse button
		holdingMouseButton = true -- We set the holdingMouseButton variable to true
	end
end)

UIS.InputEnded:Connect(function(input) -- If the player released any button on their keyboard or mouse
	if input.UserInputType == Enum.UserInputType.MouseButton1 then -- If the player released the left mouse button
		holdingMouseButton = false -- We set the holdingMouseButton variable to false
	end
end)

PaintingGUI:GetPropertyChangedSignal("Enabled"):Connect(function() -- If PaintingGUI enabled property changes
	if not PaintingGUI.Enabled then -- And it is not enabled
		-- We can reset the lastPaintedPixels variables and the pixelsChanged table
		pixelsChanged = {}
		lastPaintedPixelX = nil
		lastPaintedPixelY = nil
	end
end)

local function removeColorFromAllChildren(parent) -- This function is used to loop through the children of a parent given in the arguments, and if it is an ImageButton, it sets its ImageColor to black
	for i, v in pairs(parent:GetChildren()) do
		if v:IsA("ImageButton") then
			v.ImageColor3 = Color3.fromRGB(0, 0, 0)
		end
		
		if #v:GetChildren() > 0 then -- Then we execute the function again, if the instance has any children
			removeColorFromAllChildren(v)
		end
	end
end

BrushButton.MouseButton1Click:Connect(function() -- If we click the BrushButtons
	removeColorFromAllChildren(ToolsFrame) -- It will set the color of all the buttons to black
	
	if toolEquipped == "brush" then -- If we already have the brush tool selected, it will just unequip it
		toolEquipped = ""
	else -- If we dont have the brush tool selected, we will set the toolEquipped variable to "brush", and set the button color to white
		toolEquipped = "brush"
		BrushButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
	end
end)

BucketButton.MouseButton1Click:Connect(function() -- If we click the BucketButton
	removeColorFromAllChildren(ToolsFrame) -- It will set the color of all the buttons to black

	if toolEquipped == "bucket" then -- If we already have the bucket tool selected, it will just unequip it
		toolEquipped = ""
	else -- If we dont have the bucket tool selected, we will set the toolEquipped variable to "bucket", and set the button color to white
		toolEquipped = "bucket"
		BucketButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
	end
end)

EraserButton.MouseButton1Click:Connect(function()  -- If we click the EraserButton
	removeColorFromAllChildren(ToolsFrame) -- It will set the color of all the buttons to black

	if toolEquipped == "eraser" then -- If we already have the eraser tool selected, it will just unequip it
		toolEquipped = ""
	else -- If we dont have the eraser tool selected, we will set the toolEquipped variable to "eraser", and set the button color to white
		toolEquipped = "eraser"
		EraserButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
	end
end)
