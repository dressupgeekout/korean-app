local serpent = require("serpent")
local UnresolvedVocab = require("vocab")

DEBUG = true

VOCAB = {}

MODE_KOREAN = "k"
MODE_ROMAJA = "r"
MODE_ENGLISH = "e"

SPEECH_FAST = "fast"
SPEECH_SLOW = "slow"

Options = {
	TextColor = {1, 1, 1, 1},
	SlowSpeech = false,
	LevelRange = {{1, 1}, {1, 100}},
}

---------- ---------- ----------

local function DebugPrint(fmt, ...)
	if DEBUG then
		print(string.format(fmt, ...))
	end
end

--[[Converts a word into a numerical 'difficulty level'.]]
local function WordScore(entry)
	return entry.level*100 + entry.lesson
end

--[[Creates a new table where vocab entires are identified by their
"difficulty".]]
local function ResolveVocab()
	for _, entry in ipairs(UnresolvedVocab) do
		local score = WordScore(entry)
		VOCAB[score] = VOCAB[score] or {}
		table.insert(VOCAB[score], entry)
	end
end

--[[Returns a random word-tuple from the data list while also respecting the
difficulty range.]]
local function RandomEntry()
	local min_level, min_lesson = unpack(Options.LevelRange[1])
	local max_level, max_lesson = unpack(Options.LevelRange[2])
	local min_score = WordScore({level=min_level, lesson=min_lesson})
	local max_score = WordScore({level=max_level, lesson=max_lesson})

	DebugPrint(serpent.line({min_score, max_score}))

	local score = love.math.random(min_score, max_score)

	--[[If the score does not exist, then try one lower until we get one that
	does exist.]]
	while (not VOCAB[score]) do
		score = score - 1
	end

	local word = VOCAB[score][love.math.random(#VOCAB[score])]
	DebugPrint("-> %s\t%s\t%s", word.k, word.r, word.e)

	return word
end

--[[Returns a LOVE Font object.]]
local function CurrentKoreanFont()
	return korean_fonts[korean_font_names[current_korean_font_index]]
end

--[[Force the menu-canvas to be recomputed.]]
local function ResetMenuCanvas()
	menu_canvas = nil 
end

--[[Figures out which font should be used for drawing text based on the current
mode, and then sets that font.]]
local function SetFont()
	if current_mode == MODE_KOREAN then
		current_font = CurrentKoreanFont()
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
	DebugPrint("ADDING FONT %q", name)
	table.insert(korean_font_names, name)
	korean_fonts[name] = love.graphics.newFont(...)
end

local function LoadFonts()
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

--[[Both arguments are ordered pairs, the first entry is the 'level' and the
second is the 'lesson']]
local function SetLevelRange(lower, upper)
	local old = Options.LevelRange
	Options.LevelRange = {lower, upper}
	local new = Options.LevelRange
	DebugPrint("LEVEL RANGE %s -> %s", serpent.line(old), serpent.line(new))
end

local function SetQuizMode(from, to)
	if from == to then
		DebugPrint("Invalid quiz mode: %q -> %q", from, to)
		return false
	end
	QuizMode = {From=from, To=to}
	return true
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
	DebugPrint("SPEECH SPEED %s -> %s", old, new)
	ResetMenuCanvas()
end

function love.load()
	love.window.setMode(1280, 720) -- XXX best way to set this for mobile?
	love.window.setTitle("한극어")

	ResolveVocab()
	DebugPrint(serpent.line(VOCAB))

	LoadFonts()

	--SetQuizMode(MODE_KOREAN, MODE_ENGLISH)
	SetQuizMode(MODE_ENGLISH, MODE_ROMAJA)

	current_word = RandomEntry()
	current_mode = QuizMode.From
	current_korean_font_index = 1

	show_menu = false
	NewWordTouchRegion = {love.graphics.getWidth()*4/5, 0, love.graphics.getWidth()/5, love.graphics.getHeight()}
end

--[['region' is a list: {x, y, width, height}]]
local function IsInsideTouchRegion(x, y, region)
	local region_x, region_y, region_width, region_height = unpack(region)
	return x >= region_x and x <= region_x+region_width and y >= region_y and y <= region_y+region_height
end

function love.mousepressed(x, y, button, istouch, npresses)
	if button == 1 then
		if IsInsideTouchRegion(x, y, NewWordTouchRegion) then
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

	if key == "`" then
		DEBUG = not DEBUG
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
		if love.filesystem.getInfo(path) then
			DebugPrint("PLAYING %s", path)
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
	SetFont()

	love.graphics.setColor(unpack(Options.TextColor))

	love.graphics.printf(
		current_word[current_mode],
		0, love.graphics.getHeight()/2-current_font:getHeight()/2,
		love.graphics.getWidth(),
		"center"
	)

	if DEBUG then
		love.graphics.setColor(0, 0.5, 0, 0.5)
		love.graphics.rectangle("fill", unpack(NewWordTouchRegion))
	end

	if show_menu then
		DrawMenu()
	end
end
