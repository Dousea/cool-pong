function love.conf(game)
	game.title = "Cool Pong"
	game.version = "11.1"
	game.console = false
	game.window.width = 640
	game.window.height = 480
	game.window.fullscreen = false
	game.window.fullscreentype = "exclusive"
	game.window.vsync = false
	game.modules.joystick = false
end