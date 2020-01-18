local VOCAB = require("vocab")

DEBUG = true

MODE_KOREAN = "k"
MODE_ROMAJA = "r"
MODE_ENGLISH = "e"

SPEECH_FAST = "fast"
SPEECH_SLOW = "slow"

Options = {
	SlowSpeech = false,
	LevelRange = {{1, 1}, {1, 100}},
}

--[[Returns a random word-tuple from the data list.]]
--XXX needs to respect the LevelRange
local function RandomEntry()
	local word = VOCAB[love.math.random(#VOCAB)]
	if DEBUG then
		print(word.k, word.r, word.e)
	end
	return word
end

--[[Returns a LOVE Font object.]]
local function current_korean_font()
	return korean_fonts[korean_font_names[current_korean_font_index]]
end

--[[Force the menu-canvas to be recomputed.]]
local function ResetMenuCanvas()
	menu_canvas = nil 
end

--[[Figures out which font should be used for drawing text based on the current
mode, and then sets that font.]]
local function set_font()
	if current_mode == MODE_KOREAN then
		current_font = current_korean_font()
	else
		current_font = english_font
	end
	love.graphics.setFont(current_font)
	ResetMenuCanvas()
end

--[[Updates two tables: a lookup table from fontname->font, but also a plain
list of font names. This allows us to step through the list of fonts and also
have easy access to their names.]]
local function AddKoreanFont(name, ...)
	if not korean_fonts then korean_fonts = {} end
	if not korean_font_names then korean_font_names = {} end
	print(string.format("ADDING FONT %q", name))
	table.insert(korean_font_names, name)
	korean_fonts[name] = love.graphics.newFont(...)
end

local function load_fonts()
	AddKoreanFont("Apple Gothic", "fonts/AppleGothic.ttf", 84)
	AddKoreanFont("Apple Myungjo", "fonts/AppleMyungjo.ttf", 84)
	AddKoreanFont("Apple SD Gothic Neo", "fonts/AppleSDGothicNeo.ttc", 84)
	AddKoreanFont("Gunseouche", "fonts/Gungseouche.ttf", 84)
	AddKoreanFont("Headline A", "fonts/HeadlineA.ttf", 84)
	AddKoreanFont("Nanum Gothic", "fonts/NanumGothic.ttc", 84)
	AddKoreanFont("Nanum Myeongjo", "fonts/NanumMyeongjo.ttc", 84)
	AddKoreanFont("Nanum Script", "fonts/NanumScript.ttc", 84)
	AddKoreanFont("PC Myeongjo", "fonts/PCmyoungjo.ttf", 84)
	AddKoreanFont("Pilgiche", "fonts/Pilgiche.ttf", 84)
	english_font = love.graphics.newFont(84)
	menu_font = love.graphics.newFont(18)
end

--[[Correctly wraps around the end of the list for you.]]
local function next_korean_font()
	if current_korean_font_index == #korean_font_names then
		current_korean_font_index = 1
	else
		current_korean_font_index = current_korean_font_index + 1
	end
end

--[[Correctly wraps around the end of the list for you.]]
local function previous_korean_font()
	if current_korean_font_index == 1 then
		current_korean_font_index = #korean_font_names
	else
		current_korean_font_index = current_korean_font_index - 1
	end
end

local function SetQuizMode(from, to)
	if from == to then
		print(string.format("Invalid quiz mode: %q -> %q", from, to))
		return false
	end
	QuizMode = {From=from, To=to}
end

local function SpeechSpeed()
	if Options.SlowSpeech then
		return SPEECH_SLOW
	else
		return SPEECH_FAST
	end
end

local function ToggleSpeechSpeed()
	local old = SpeechSpeed()
	Options.SlowSpeech = not Options.SlowSpeech
	local new = SpeechSpeed()
	print(string.format("SPEECH SPEED %s -> %s", old, new))
end

function love.load()
	love.window.setMode(1280, 720) -- XXX best way to set this for mobile?
	love.window.setTitle("한극어")

	load_fonts()

	SetQuizMode(MODE_KOREAN, MODE_ENGLISH)

	current_word = RandomEntry()
	current_mode = QuizMode.From
	current_korean_font_index = 1

	show_menu = false
end

--[['region' is a list: {x, y, width, height}]]
local function is_inside_touch_region(x, y, region)
	local region_x, region_y, region_width, region_height = unpack(region)
	return x >= region_x and x <= region_x+region_width and y >= region_y and y <= region_y+region_height
end

function love.mousepressed(x, y, button, istouch, npresses)
	if button == 1 then
		if is_inside_touch_region(x, y, {love.graphics.getWidth()*2/3, 0, love.graphics.getWidth()/3, love.graphics.getHeight()}) then
			RandomEntry()
		else
			current_mode = QuizMode.To
		end
	end
end

function love.mousereleased(x, y, button, istouch, npresses)
	if button == 1 then
		current_mode = QuizMode.From
	end
end

function love.keypressed(key, scancode)
	if key == "escape" then
		love.event.quit()
	end

	if key == "return" then
		current_word = RandomEntry()
	end

	if key == "space" then
		current_mode = QuizMode.To
	end

	if key == "tab" then
		if not show_menu then show_menu = true end
	end

	if key == "f" then
		next_korean_font()
	end

	if key == "p" then
		local path = "audio/"..(current_word.r).."-"..SpeechSpeed()..".ogg"
		print(path)
		if love.filesystem.getInfo(path) then
			print("PLAYING " .. path)
			love.audio.newSource(path, "static"):play()
		end
	end

	if key == "s" then
		ToggleSpeechSpeed()
	end
end

function love.keyreleased(key, scancode)
	if key == "space" then
		current_mode = QuizMode.From
	end

	if key == "tab" then
		if show_menu then show_menu = false end
	end
end

local function DrawMenu()
	if not menu_canvas then
		menu_canvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight()/2)
		menu_canvas:renderTo(function()
			love.graphics.setColor(0.5, 0, 0, 0.75)
			love.graphics.rectangle("fill", 0, 0, menu_canvas:getWidth(), menu_canvas:getHeight())

			love.graphics.setFont(menu_font)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.print("FONT: "..korean_font_names[current_korean_font_index], 15, menu_font:getHeight())
			love.graphics.print("SPEED: " ..SpeechSpeed(), 15, menu_font:getHeight()*2.5)
		end)
	end

	love.graphics.draw(menu_canvas, 0, love.graphics.getHeight()/4)
end

function love.draw()
	set_font()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(
		current_word[current_mode],
		0, love.graphics.getHeight()/2-current_font:getHeight()/2,
		love.graphics.getWidth(),
		"center"
	)

	if show_menu then
		DrawMenu()
	end
end
