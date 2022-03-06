local serpent = require("serpent")
local UnresolvedVocab = require("vocab")

DEBUG = true

VOCAB = {}

MODE_KOREAN = "k"
MODE_ROMAJA = "r"
MODE_ENGLISH = "e"

SPEECH_FAST = "fast"
SPEECH_SLOW = "slow"

KOREAN_WORD_DISPLAY_SIZE = 84
KOREAN_FONT_SELECTOR_SIZE = 48

Options = {
	TextColor = {1, 1, 1, 1},
	SlowSpeech = false,
	LevelRange = {{0, 0}, {0, 0}}, -- will be computed later
}

---------- ---------- ----------

local function DebugPrint(fmt, ...)
	if DEBUG then
		print(string.format(fmt, ...))
	end
end

--[['rect' is a list: {x, y, width, height}]]
local function IsInsideRect(x, y, rect)
	local rect_x, rect_y, rect_width, rect_height = unpack(rect)
	return x >= rect_x and x <= rect_x+rect_width and y >= rect_y and y <= rect_y+rect_height
end

---------- ---------- ----------

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
	return korean_fonts[korean_font_names[korean_font_index]]
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

--[[Updates several tables: a lookup table from fontname->font, but also a
plain list of font names. This allows us to step through the list of fonts and
also have easy access to their names. And then we also maintain a list of smaller
fonts for the "font selector" widget.]]
local function AddKoreanFont(name, path)
	if not korean_fonts then korean_fonts = {} end
	if not korean_font_names then korean_font_names = {} end
	if not korean_fontselectors then korean_fontselectors = {} end
	DebugPrint("ADDING FONT %q", name)
	table.insert(korean_font_names, name)
	korean_fonts[name] = love.graphics.newFont(path, KOREAN_WORD_DISPLAY_SIZE)
	table.insert(korean_fontselectors, {Font=love.graphics.newFont(path, KOREAN_FONT_SELECTOR_SIZE), Current=false})
end

local function LoadFonts()
	AddKoreanFont("Apple Gothic", "fonts/AppleGothic.ttf")
	AddKoreanFont("Apple Myungjo", "fonts/AppleMyungjo.ttf")
	AddKoreanFont("Apple SD Gothic Neo", "fonts/AppleSDGothicNeo.ttc")
	AddKoreanFont("Gunseouche", "fonts/Gungseouche.ttf")
	AddKoreanFont("Headline A", "fonts/HeadlineA.ttf")
	AddKoreanFont("Nanum Gothic", "fonts/NanumGothic.ttc")
	AddKoreanFont("Nanum Myeongjo", "fonts/NanumMyeongjo.ttc")
	AddKoreanFont("Nanum Script", "fonts/NanumScript.ttc")
	AddKoreanFont("PC Myeongjo", "fonts/PCmyoungjo.ttf")
	AddKoreanFont("Pilgiche", "fonts/Pilgiche.ttf")
	english_font = love.graphics.newFont(72)
	menu_font = love.graphics.newFont(18)
end

--[[Sets the current Korean font index, and also updates the fontselect
widget so we know how to graphically convey which font is now the current
one.]]
local function SetKoreanFontIndex(index)
	korean_font_index = index

	for i, fontinfo in ipairs(korean_fontselectors) do
		if i == index then
			fontinfo.Current = true
		else
			fontinfo.Current = false
		end
	end
end

local function IncrKoreanFontIndex()
	SetKoreanFontIndex(korean_font_index + 1)
end

local function DecrKoreanFontIndex()
	SetKoreanFontIndex(korean_font_index - 1)
end


--[[Correctly wraps around the end of the list for you.]]
local function NextKoreanFont()
	if korean_font_index == #korean_font_names then
		SetKoreanFontIndex(1)
	else
		IncrKoreanFontIndex()
	end
end

--[[Correctly wraps around the end of the list for you.]]
local function PreviousKoreanFont()
	if korean_font_index == 1 then
		SetKoreanFontIndex(#korean_font_names)
	else
		DecrKoreanFontIndex()
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

--[[Computes what the range should be if you wanted to try out *every* vocab
word, and returns it.]]
local function MaximumLevelRange()
	local min_level = 0
	local min_lesson = 1
	local max_level = 99
	local max_lesson = 99

	for _, entry in ipairs(UnresolvedVocab) do
		if entry.level < min_level then min_level = entry.level end
		if entry.lesson < min_lesson then min_lesson = entry.lesson end
		if entry.level > max_level then max_level = entry.level end
		if entry.lesson > max_lesson then max_lesson = entry.lesson end
	end

	return {min_level, min_lesson}, {max_level, max_lesson}
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

local function DrawFontBar()
	x = 10
	y = 10
	for i, fontselector in ipairs(korean_fontselectors) do
		if fontselector.Current then
			love.graphics.setColor(1, 1, 0, 1)
			love.graphics.setLineWidth(1)
			love.graphics.rectangle("line", x-5, y-5, fontselector.Font:getWidth("한")*1.25, fontselector.Font:getHeight()*1.25)
		end
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.setFont(fontselector.Font)
		love.graphics.print("한", x, y)
		x = x + fontselector.Font:getWidth("한")*1.5
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
			love.graphics.print("FONT: "..korean_font_names[korean_font_index], 15, menu_font:getHeight())
			love.graphics.print("SPEED: " ..SpeechSpeed(), 15, menu_font:getHeight()*2.5)
			local r1 = Options.LevelRange[1]
			local r2 = Options.LevelRange[2]
			love.graphics.print(string.format("LEVEL RANGE: %d.%d -> %d.%d", r1[1], r1[2], r2[1], r2[2]), 15,menu_font:getHeight()*4)
		end)
	end

	love.graphics.draw(menu_canvas, 0, love.graphics.getHeight()/4)
	DrawFontBar()
end

local function PlayCurrentWordSound()
	local path = "audio/"..(current_word.r).."-"..SpeechSpeed()..".ogg"
	if love.filesystem.getInfo(path) then
		DebugPrint("PLAYING %s", path)
		love.audio.newSource(path, "static"):play()
	end
end

---------- ---------- ----------

function love.load()
	love.window.setMode(1280, 720)
	love.window.setTitle("한극어")

	ResolveVocab()
	DebugPrint(serpent.line(VOCAB))

	LoadFonts()

	SetQuizMode(MODE_KOREAN, MODE_ENGLISH)
	--SetLevelRange(MaximumLevelRange()) -- XXX CHARLOTTE
	SetLevelRange({0,1}, {0,2})

	current_word = RandomEntry()
	current_mode = QuizMode.From
	SetKoreanFontIndex(1)

	show_menu = false
	NewWordTouchRegion = {love.graphics.getWidth()*4/5, 0, love.graphics.getWidth()/5, love.graphics.getHeight()}
end

function love.mousepressed(x, y, button, istouch, npresses)
	if button == 1 then
		if show_menu then return end
		--[[None of the following will work while the menu is displayed:]]

		if IsInsideRect(x, y, NewWordTouchRegion) then
			current_word = RandomEntry()
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

	if key == "tab" then
		show_menu = not show_menu
	end

	if key == "f" then
		if love.keyboard.isDown("lshift", "rshift") then
			PreviousKoreanFont()
		else
			NextKoreanFont()
		end
	end

	if key == "s" then
		ToggleSpeechSpeed()
	end

	if show_menu then return end
	--[[None of the following will work while the menu is displayed:]]

	if key == "return" then
		current_word = RandomEntry()
	end

	if key == "space" then
		current_mode = QuizMode.To
	end

	if key == "p" then
		PlayCurrentWordSound()
	end
end

function love.keyreleased(key, scancode)
	if show_menu then return end
	--[[None of the following will work while the menu is displayed:]]

	if key == "space" then
		current_mode = QuizMode.From
	end
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
