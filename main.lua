local vocab = require("data")

DEBUG = true

MODE_KOREAN = "k"
MODE_ROMAJA = "r"
MODE_ENGLISH = "e"

local function random_entry()
	local word = vocab[love.math.random(#vocab)]
	if DEBUG then
		print(word.k, word.r, word.e)
	end
	return word
end

local function current_korean_font()
	return korean_fonts[korean_font_names[current_korean_font_index]]
end

local function set_font()
	if current_mode == MODE_KOREAN then
		current_font = current_korean_font()
	else
		current_font = english_font
	end
	love.graphics.setFont(current_font)
end

--[[Updates two tables: a lookup table from fontname->font, but also a plain
list of font names. This allows us to step through the list of fonts and also
have easy access to their names.]]
local function add_korean_font(name, ...)
	if not korean_fonts then korean_fonts = {} end
	if not korean_font_names then korean_font_names = {} end
	table.insert(korean_font_names, name)
	korean_fonts[name] = love.graphics.newFont(...)
end

local function load_fonts()
	add_korean_font("Apple Gothic", "fonts/AppleGothic.ttf", 84)
	add_korean_font("Apple Myungjo", "fonts/AppleMyungjo.ttf", 84)
	add_korean_font("Apple SD Gothic Neo", "fonts/AppleSDGothicNeo.ttc", 84)
	add_korean_font("Gunseouche", "fonts/Gungseouche.ttf", 84)
	add_korean_font("Headline A", "fonts/HeadlineA.ttf", 84)
	add_korean_font("Nanum Gothic", "fonts/NanumGothic.ttc", 84)
	add_korean_font("Nanum Myeongjo", "fonts/NanumMyeongjo.ttc", 84)
	add_korean_font("Nanum Script", "fonts/NanumScript.ttc", 84)
	add_korean_font("PC Myeongjo", "fonts/PCmyoungjo.ttf", 84)
	add_korean_font("Pilgiche", "fonts/Pilgiche.ttf", 84)
	english_font = love.graphics.newFont(84)
end

local function next_korean_font()
	if current_korean_font_index == #korean_font_names then
		current_korean_font_index = 1
	else
		current_korean_font_index = current_korean_font_index + 1
	end
end

local function previous_korean_font()
	if current_korean_font_index == 1 then
		current_korean_font_index = #korean_font_names
	else
		current_korean_font_index = current_korean_font_index - 1
	end
end

function love.load()
	love.window.setMode(1280, 720)
	love.window.setTitle("한극어")

	load_fonts()

	quiz_mode = {
		from = MODE_KOREAN,
		to = MODE_ROMAJA,
	}

	current_word = random_entry()
	current_mode = quiz_mode.from
	current_korean_font_index = 1
end

function love.keypressed(key, scancode)
	if key == "return" then
		current_word = random_entry()
	end

	if key == "space" then
		current_mode = quiz_mode.to
	end

	if key == "tab" then
		if not show_menu then show_menu = true end
	end

	if key == "f" then
		next_korean_font()
	end
end

function love.keyreleased(key, scancode)
	if key == "space" then
		current_mode = quiz_mode.from
	end

	if key == "tab" then
		if show_menu then show_menu = false end
	end
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
end
