local mlib = require 'mlib'
local shine = require 'shine'

function love.load()
	love.graphics.setNewFont('consola.ttf', 24)
	
	effect = shine.scanlines{opacity = 0.5, pixel_size = 1.5, center_fade = 0, line_height = 0.15}
	text = love.graphics.newText(love.graphics.getFont(), '')
	
	text:setf('cool pong', love.graphics.getWidth(), 'center')
	
	score = {
		{0, love.graphics.newText(love.graphics.newFont('consola.ttf', 32), '0')},
		{0, love.graphics.newText(love.graphics.newFont('consola.ttf', 32), '0')}
	}
	paddle = {}
	paddle.ai = {
		reactiontime = 0.2, -- in seconds
		timetoact = 0.75 -- in seconds
	}
	paddle.player = {}
	
	for index = 1, 2 do
		paddle.player[index] = {
			visibility = true,
			width = 10, height = love.graphics.getHeight() / 15,
			powerup = {
				enabled = false,
				type = 0,
				time = 0
			},
			reactiontime = 0,
			timetoact = 0
		}
		paddle.player[index].speed = paddle.player[index].height * 15
	end
	
	paddle.player[1].type = 'ai'
	paddle.player[1].control = {'up', 'down'}
	paddle.player[2].type = 'ai'
	paddle.player[2].control = {'w', 's'}
	
	ball = {}
	
	function updateBall(dt)
		ball.x, ball.y = ball.x + math.cos(ball.angle) * ball.speed * dt, ball.y + math.sin(ball.angle) * ball.speed * dt
		
		if ball.x < 0 or ball.x > love.graphics.getWidth() then
			local index = ball.x < 0 and 1 or 2
			score[index][1] = score[index][1] + 1
			
			score[index][2]:set(score[index][1])
			reset(index)
			
			return
		end
		
		if ball.y - ball.radius < 0 then
			ball.angle = -ball.angle
			ball.y = ball.radius + .1
		elseif ball.y + ball.radius > love.graphics.getHeight() then
			ball.angle = -ball.angle
			ball.y = love.graphics.getHeight() - ball.radius - .1
		end
		
		do
			local player = paddle.player[1]
			
			if ball.x - ball.radius < player.x + player.width / 2 and ball.x - ball.radius > player.x and
			   ball.y + ball.radius >= player.y - player.height / 2 and ball.y - ball.radius <= player.y + player.height / 2 then
				if ball.y > player.y then
					ball.angle = math.pi - ball.angle + love.math.random(20) * math.pi / 180
				else
					ball.angle = math.pi - ball.angle - love.math.random(20) * math.pi / 180
				end
				
				ball.x = player.x + ball.radius + player.width / 2 + .1
				ball.from = 1
			end
			
			player = paddle.player[2]
			
			if ball.x + ball.radius > player.x - player.width / 2 and ball.x + ball.radius < player.x and
			   ball.y + ball.radius >= player.y - player.height / 2 and ball.y - ball.radius <= player.y + player.height / 2 then
				if ball.y > player.y then
					ball.angle = math.pi - ball.angle + love.math.random(20) * math.pi / 180
				else
					ball.angle = math.pi - ball.angle - love.math.random(20) * math.pi / 180
				end
				
				ball.x = player.x - ball.radius - player.width / 2 - .1
				ball.from = 2
			end
		end
	end
	
	function updatePlayer(dt, index)
		local player = paddle.player[index]
		
		if player.type == 'human' then
			local direction = 0
			
			if love.keyboard.isDown(player.control[1]) then
				direction = -1
			elseif love.keyboard.isDown(player.control[2]) then
				direction = 1
			end
			
			player.y = player.y + player.speed * direction * dt
		else
			if not player.reaction then
				player.reactiontime = player.reactiontime + dt
				
				if player.reactiontime >= paddle.ai.reactiontime then
					player.reaction = true
					player.reactiontime = 0
					player.timetoact = paddle.ai.timetoact
				end
			else
				player.timetoact = player.timetoact - dt
				
				if player.timetoact > 0 then
					local direction = 0
					
					if ball.y + ball.radius > player.y + player.height / 2 then
						direction = 1
					elseif ball.y - ball.radius < player.y - player.height / 2 then
						direction = -1
					end
					
					player.y = player.y + player.speed * direction * dt
				else
					player.timetoact = 0
					player.reaction = nil
				end
			end
		end
		
		if player.y < player.height / 2 then
			player.y = math.floor(player.height / 2)
		elseif player.y > love.graphics.getHeight() - player.height / 2 then
			player.y = math.floor(love.graphics.getHeight() - player.height / 2)
		end
	end
	
	function updatePlayerPowerUp(dt, index)
		local player = paddle.player[index]
		local enemy = paddle.player[index == 1 and 2 or 1]
		
		if player.powerup.enabled then
			local type = player.powerup.type
			player.powerup.time = player.powerup.time - dt
			
			if player.powerup.time > 0 then
				if type == 3 then
					ball.speed = love.graphics.getWidth() / 2
					
					if ball.from == index then
						ball.speed = ball.speed + (1 / 2) * ball.speed
					end
				elseif type == 4 then
					if ball.from == index then
						local width = love.graphics.getWidth() / 4
						enemy.visibility = not ((index == 2 and ball.x > width) or
						   (index == 1 and ball.x < love.graphics.getWidth() - width))
					end
				elseif type == 5 then
					local width = love.graphics.getWidth() / 4
					ball.visibility = not (ball.from == index and ball.x > width and ball.x < love.graphics.getWidth() - width)
				end
			else
				resetPlayerPowerUp(index)
			end
		end
	end
	
	function resetPlayerPowerUp(index)
		local player = paddle.player[index]
		local enemy = paddle.player[index == 1 and 2 or 1]
		local type = player.powerup.type
		
		if type == 1 then
			player.height = player.height / 2
		elseif type == 2 then
			enemy.height = enemy.height * 2
		elseif type == 3 then
			ball.speed = love.graphics.getWidth() / 2
		elseif type == 4 then
			enemy.visibility = true
		elseif type == 5 then
			ball.visibility = true
		end
		
		player.powerup.enabled = false
		player.powerup.time = 0
		player.powerup.type = 0
	end
	
	function setPlayerPowerUp(type, index)
		local player = paddle.player[index]
		local enemy = paddle.player[index == 1 and 2 or 1]
		
		resetPlayerPowerUp(index)
		
		player.powerup.enabled = true
		player.powerup.type = type
		player.powerup.time = 10 -- seconds
		
		if type == 1 then
			player.height = player.height * 2
		elseif type == 2 then
			enemy.height = enemy.height / 2
		elseif type == 4 then
			player.powerup.time = 20 -- seconds
		elseif type == 5 then
			player.powerup.time = 20 -- seconds
		end
	end
	
	powerup = {}
	
	function setPowerUpName()
		powerup.tohidename = false
		powerup.timetohidename = 5 -- seconds
		local str = pastfirsttime and 'cool pong' or '[space] plays/pauses\n[up/down] readies left paddle\n[w/s] readies right paddle'
		
		text:setf(str, love.graphics.getWidth(), 'center')
		
		if not pastfirsttime then
			pastfirsttime = true
		end
	end
	
	function setPowerUp()
		powerup.type = 0
		powerup.exists = false
		powerup.timetoexists = love.math.random(10, 15)
	end
	
	function updatePowerUp(dt)
		-- For the fucking name..
		if powerup.tohidename then
			powerup.timetohidename = powerup.timetohidename - dt
			
			if powerup.timetohidename < 0 then
				setPowerUpName()
			end
		end
		
		if not powerup.exists then
			powerup.timetoexists = powerup.timetoexists - dt
			
			if powerup.timetoexists <= 0 then
				powerup.exists = true
				--[=[
				1: bigger own paddle
				2: smaller enemy's paddle
				3: speed up the ball
				4: occasionally hides the paddle
				5: occasionally hides the ball
				]=]
				powerup.type = love.math.random(1, 5)
				powerup.width = love.math.random(love.graphics.getWidth() / 20 - 20, love.graphics.getWidth() / 20)
				powerup.height = powerup.width
				powerup.x = math.floor(love.graphics.getWidth() / 2 - powerup.width / 2)
				powerup.y = love.math.random(math.floor(powerup.height / 2), math.floor(love.graphics.getHeight() / 2 - powerup.height / 2))
				powerup.direction = love.math.random(0, 1) == 1 and 1 or -1
			end
		else
			if powerup.y <= 0 or powerup.y >= love.graphics.getHeight() - powerup.height then
				powerup.direction = powerup.direction == -1 and 1 or -1
			end
			
			powerup.y = powerup.y - powerup.direction * 200 * dt
			
			if mlib.circle.isCircleInsidePolygon(ball.x, ball.y, ball.radius,
				powerup.x, powerup.y,
				powerup.x + powerup.width, powerup.y,
				powerup.x + powerup.width, powerup.y + powerup.height,
				powerup.x, powerup.y + powerup.height) then
				if ball.from ~= 0 then
					powerup.tohidename = true
					
					text:setf(({
						'big paddle',
						'mini-paddle',
						'super-ball',
						'invisible paddle',
						'invisible ball'
					})[powerup.type], love.graphics.getWidth(), 'center')
					setPlayerPowerUp(powerup.type, ball.from)
					setPowerUp()
				end
			end
		end
	end
	
	setPowerUp()
	
	function reset(win)
		state = 0 -- 0: not playing, 1: playing
		
		paddle.player[1].x, paddle.player[1].y = 15, math.floor(love.graphics.getHeight() / 2)
		paddle.player[2].x, paddle.player[2].y = love.graphics.getWidth() - 15, math.floor(love.graphics.getHeight() / 2)
		
		ball.visibility = true
		ball.radius = 10
		ball.speed = love.graphics.getWidth() / 2
		ball.angle = 0
		
		repeat
			ball.angle = love.math.random(360) * 2 * math.pi / 360
		until math.abs(math.cos(ball.angle)) < .7
		
		ball.angle = ball.angle + math.pi / 2
		ball.from = 0
		
		if win == 1 then
			ball.x = paddle.player[1].x + ball.radius * 2
		elseif win == 2 then
			ball.x = paddle.player[2].x - ball.radius * 2
		else
			ball.x = love.graphics.getWidth() / 2
		end
		
		ball.y = love.graphics.getHeight() / 2
		
		setPowerUpName()
	end
	
	function draw()
		love.graphics.setColor(0, 0.75, 0, 1)
		
		if state == 0 then
			love.graphics.rectangle('fill', 10, 10, 10, 30)
			love.graphics.rectangle('fill', 30, 10, 10, 30)
		end
		
		local size = text:getHeight() / 2 + 5
		
		love.graphics.line(love.graphics.getWidth() / 2, 0, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2 - size)
		love.graphics.line(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2 + size, love.graphics.getWidth() / 2, love.graphics.getHeight())
		love.graphics.draw(text, 0, love.graphics.getHeight() / 2 - text:getHeight() / 2)
		
		if ball.visibility then
			love.graphics.circle('fill', ball.x, ball.y, ball.radius)
		end
		
		for index = 1, 2 do
			local player = paddle.player[index]
			
			if player.type == 'ai' then
				love.graphics.setColor(0.75, 0, 0, 1)
			else
				love.graphics.setColor(0, 0.75, 0, 1)
			end
			
			if player.visibility then
				love.graphics.rectangle('fill', player.x - player.width / 2, player.y - player.height / 2, player.width, player.height)
			end
		end
		
		love.graphics.setColor(0, 0.75, 0, 1)
		
		if powerup.exists then
			love.graphics.rectangle('fill', powerup.x, powerup.y, powerup.width, powerup.height)
		end
		
		love.graphics.draw(score[2][2], love.graphics.getWidth() / 4 - score[2][2]:getWidth() - 10, 10)
		love.graphics.draw(score[1][2], love.graphics.getWidth() - love.graphics.getWidth() / 4 + 10, 10)
	end
	
	reset(0)
end

function love.keypressed(key)
	if key == 'space' then
		state = state == 0 and 1 or 0
		local str = state == 0 and '[space] plays/pauses\n[up/down] readies left paddle\n[w/s] readies right paddle' or 'cool pong'
		
		text:setf(str, love.graphics.getWidth(), 'center')
	else
		if state == 0 then
			for i = 1, 2 do
				if paddle.player[i].type == 'ai' then
					for j = 1, 2 do
						if key == paddle.player[i].control[j] then
							paddle.player[i].type = 'human'
							
							break
						end
					end
				end
			end
		end
	end
end

function love.update(dt)
	if state == 0 then return end
	
	for index = 1, 2 do
		updatePlayer(dt, index)
		updatePlayerPowerUp(dt, index)
	end
	
	updateBall(dt)
	updatePowerUp(dt)
end

function love.draw()
	effect(draw)
end