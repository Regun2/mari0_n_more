megabowser = class:new()

function megabowser:init(x, y, i)
	--PHYSICS STUFF
	self.x = x + 4
	self.y = y - 81/16  -- 3x taller offset
	self.level = i or marioworld
	self.startx = x + 12
	self.starty = y
	self.speedy = 0
	self.speedx = 0
	self.width = 90/16   -- 3x width
	self.height = 84/16  -- 3x height
	self.static = false
	self.active = true
	self.emancipatecheck = true
	self.category = 16

	self.mask = {	true,
					false, false, false, false, true,
					false, true, false, true, false,
					false, false, true, true, false,
					true, true, false, false, true,
					false, true, true, false, false,
					true, false, true, true, true}

	self.gravity = bowsergravity

	--IMAGE STUFF
	self.drawable = true
	self.graphic = bowserimg
	self.quad = bowserquad[1][1]
	self.walkframe = 1
	self.offsetX = 42       -- 3x
	self.offsetY = -6       -- 3x
	self.quadcenterX = 48   -- 3x
	self.quadcenterY = 36   -- 3x

	self.rotation = 0
	self.jump = false

	self.animationtimer = 0
	self.animationdirection = "right"
	self.fireframe = 1
	self.timer = 0
	self.hammertimer = 0
	self.hammertime = 0.6  -- faster hammer rate
	self.hammers = true    -- always has hammers

	-- MEGA STATS
	self.hp = bowserhealth * 5  -- 5x health
	self.maxhp = self.hp

	self.shot = false
	self.fall = false

	-- PHASE SYSTEM
	self.phase = 1           -- 1 = normal, 2 = enraged, 3 = desperate
	self.phasetransitioning = false
	self.phasetimer = 0
	self.phaseflash = 0

	-- GROUND POUND
	self.groundpounding = false
	self.groundpoundcooldown = 0
	self.groundpounddelay = 4  -- seconds between ground pounds
	self.groundpoundwindup = 0
	self.shakescreen = 0
	self.shakex = 0
	self.shakey = 0

	-- CHARGE ATTACK
	self.charging = false
	self.chargetimer = 0
	self.chargecooldown = 0
	self.chargedelay = 6
	self.chargedirection = "left"
	self.chargespeed = bowserspeedforwards * 5
	self.chargewindup = 0
	self.chargewinduptime = 1.0

	-- FIRE BREATH (sustained)
	self.firebreathing = false
	self.firebreathtimer = 0
	self.firebreathcooldown = 0
	self.firebreathdelay = 5
	self.firebreathduration = 2.5
	self.firebreathparticles = {}

	-- ROAR / SHOCKWAVE
	self.roaring = false
	self.roartimer = 0
	self.roarcooldown = 0
	self.roardelay = 8
	self.roarradius = 0
	self.roarmaxradius = 8
	self.roarduration = 1.5

	-- STOMP SHOCKWAVE (on landing)
	self.stompwave = false
	self.stompwaveradius = 0
	self.stompwavemaxradius = 6

	-- MINION SUMMONING
	self.summoncount = 0
	self.summoncooldown = 0
	self.summondelay = 10
	self.maxminions = 3

	-- TAIL SWIPE
	self.tailswiping = false
	self.tailswipetimer = 0
	self.tailswipecooldown = 0
	self.tailswipedelay = 7
	self.tailswipeangle = 0
	self.tailswipeduration = 0.8

	-- FIREBALL BURST
	self.burstcooldown = 0
	self.burstdelay = 5
	self.bursting = false
	self.bursttimer = 0
	self.burstcount = 0
	self.burstmax = 5

	-- SHIELD
	self.shielded = false
	self.shieldtimer = 0
	self.shieldcooldown = 0
	self.shielddelay = 15
	self.shieldduration = 4
	self.shieldopacity = 0

	-- SLAM PILLARS
	self.slampillars = {}
	self.slampillarcooldown = 0
	self.slampillardelay = 9

	-- VISUAL EFFECTS
	self.scale = 3
	self.flashtimer = 0
	self.hittimer = 0
	self.drawscale = 3
	self.drawoffsetY = 0
	self.eyeglow = 0
	self.auraparticles = {}
	self.trailparticles = {}
	self.deathexplosions = {}
	self.deathtimer = 0
	self.dying = false
	self.deathphase = 0
	self.invincibletimer = 0

	-- MOVEMENT ENHANCEMENT
	self.dashtrail = {}
	self.targetchangetimer = 0
	self.aggressiontimer = 0

	self:newtargetx("right")
end

function megabowser:update(dt)
	-- Update screen shake
	if self.shakescreen > 0 then
		self.shakescreen = self.shakescreen - dt
		self.shakex = math.random(-2, 2)
		self.shakey = math.random(-2, 2)
		if self.shakescreen <= 0 then
			self.shakex = 0
			self.shakey = 0
		end
	end

	-- Update aura particles
	self:updateauraparticles(dt)
	-- Update trail particles
	self:updatetrailparticles(dt)

	-- DEATH SEQUENCE
	if self.dying then
		self:updatedeath(dt)
		return false
	end

	-- SHOT (defeated by fireballs flung off)
	if self.shot then
		self.speedy = self.speedy + shotgravity * dt
		self.x = self.x + self.speedx * dt
		self.y = self.y + self.speedy * dt

		if self.speedy > bowserfallspeed then
			self.speedy = bowserfallspeed
		end

		-- Spawn death explosions
		self.deathtimer = self.deathtimer + dt
		if self.deathtimer > 0.1 then
			self.deathtimer = self.deathtimer - 0.1
			table.insert(self.deathexplosions, {
				x = self.x + math.random() * self.width,
				y = self.y + math.random() * self.height,
				timer = 0.5
			})
		end

		return false
	end

	-- HIT FLASH
	if self.hittimer > 0 then
		self.hittimer = self.hittimer - dt
		self.flashtimer = self.flashtimer + dt
	end

	-- INVINCIBILITY after hit
	if self.invincibletimer > 0 then
		self.invincibletimer = self.invincibletimer - dt
	end

	-- PHASE TRANSITIONS
	self:updatephase(dt)

	if self.phasetransitioning then
		self.phasetimer = self.phasetimer + dt
		self.phaseflash = self.phaseflash + dt
		self.shakescreen = 0.1
		if self.phasetimer > 2.0 then
			self.phasetransitioning = false
			self.phasetimer = 0
		end
		return false
	end

	-- SPEED FALLOFF
	if self.speedy > bowserfallspeed then
		self.speedy = bowserfallspeed
	end

	-- PORTAL ROTATION ALIGNMENT
	self.rotation = math.fmod(self.rotation, math.pi * 2)
	if self.rotation > 0 then
		self.rotation = self.rotation - portalrotationalignmentspeed * dt
		if self.rotation < 0 then self.rotation = 0 end
	elseif self.rotation < 0 then
		self.rotation = self.rotation + portalrotationalignmentspeed * dt
		if self.rotation > 0 then self.rotation = 0 end
	end

	-- ================================================
	-- ABILITY COOLDOWNS
	-- ================================================
	self.groundpoundcooldown = math.max(0, self.groundpoundcooldown - dt)
	self.chargecooldown = math.max(0, self.chargecooldown - dt)
	self.firebreathcooldown = math.max(0, self.firebreathcooldown - dt)
	self.roarcooldown = math.max(0, self.roarcooldown - dt)
	self.summoncooldown = math.max(0, self.summoncooldown - dt)
	self.tailswipecooldown = math.max(0, self.tailswipecooldown - dt)
	self.burstcooldown = math.max(0, self.burstcooldown - dt)
	self.shieldcooldown = math.max(0, self.shieldcooldown - dt)
	self.slampillarcooldown = math.max(0, self.slampillarcooldown - dt)

	-- ================================================
	-- SPECIAL ABILITY UPDATES
	-- ================================================

	-- SHIELD
	if self.shielded then
		self.shieldtimer = self.shieldtimer + dt
		self.shieldopacity = 0.4 + 0.2 * math.sin(self.shieldtimer * 6)
		if self.shieldtimer >= self.shieldduration then
			self.shielded = false
			self.shieldtimer = 0
			self.shieldcooldown = self.shielddelay
			self.shieldopacity = 0
		end
	end

	-- GROUND POUND
	if self.groundpounding then
		self:updategroundpound(dt)
		return false
	end

	-- CHARGE ATTACK
	if self.charging then
		self:updatecharge(dt)
		return false
	end

	-- FIRE BREATH (sustained)
	if self.firebreathing then
		self:updatefirebreath(dt)
		-- don't return, allow movement
	end

	-- ROAR / SHOCKWAVE
	if self.roaring then
		self:updateroar(dt)
		return false
	end

	-- TAIL SWIPE
	if self.tailswiping then
		self:updatetailswipe(dt)
		return false
	end

	-- FIREBALL BURST
	if self.bursting then
		self:updateburst(dt)
	end

	-- STOMP WAVE
	if self.stompwave then
		self.stompwaveradius = self.stompwaveradius + 12 * dt
		if self.stompwaveradius >= self.stompwavemaxradius then
			self.stompwave = false
			self.stompwaveradius = 0
		else
			-- Hurt players in radius
			self:damageplayersinradius(self.stompwaveradius, 0.3)
		end
	end

	-- SLAM PILLARS
	self:updateslampillars(dt)

	-- ================================================
	-- MAIN BEHAVIOR
	-- ================================================
	if not self.fall then
		-- WALKING ANIMATION (slower for mega)
		self.animationtimer = self.animationtimer + dt
		while self.animationtimer > bowseranimationspeed * 1.5 do
			self.animationtimer = self.animationtimer - bowseranimationspeed * 1.5
			if self.walkframe == 1 then
				self.walkframe = 2
			else
				self.walkframe = 1
			end
		end

		-- MOVEMENT
		if self.x < self.targetx then
			self.speedx = bowserspeedforwards * 0.8
			if self.x + self.speedx * dt >= self.targetx then
				self:newtargetx("left")
			end
		else
			self.speedx = -bowserspeedforwards * 0.8
			if self.x + self.speedx * dt <= self.targetx then
				self:newtargetx("right")
			end
		end

		-- HAMMERS (more frequent in later phases)
		if self.hammers and self.backwards == false then
			self.hammertimer = self.hammertimer + dt
			local hammerinterval = self.hammertime
			if self.phase >= 2 then hammerinterval = hammerinterval * 0.6 end
			if self.phase >= 3 then hammerinterval = hammerinterval * 0.5 end

			while self.hammertimer > hammerinterval do
				-- Throw multiple hammers in spread pattern
				local numhammers = self.phase + 1
				for h = 1, numhammers do
					local offsety = -0.5 + (h - 1) * 0.5
					table.insert(objects["hammer"], hammer:new(self.x + 4/16, self.y + 0.5 + offsety, "left"))
				end
				self.hammertimer = self.hammertimer - hammerinterval
				self.hammertime = bowserhammertable[math.random(#bowserhammertable)]
			end
		end

		-- ================================================
		-- ABILITY DECISION MAKING
		-- ================================================
		self.aggressiontimer = self.aggressiontimer + dt

		-- Phase 1: basic attacks
		if self.phase >= 1 and self.aggressiontimer > 2 then
			self:chooseability()
			self.aggressiontimer = 0
		end
	end

	-- FIRE FRAME
	if self.backwards == false and firestarted and firetimer > firedelay - 0.5 then
		self.fireframe = 2
		self.speedx = 0
	else
		if not self.firebreathing then
			self.fireframe = 1
		end
	end

	self.quad = bowserquad[self.fireframe][self.walkframe]

	-- PLAYER TRACKING
	if not self.fall and not self.charging and not self.groundpounding then
		local closestplayer = objects["player"][getclosestplayer(self.x + self.width/2)]
		if closestplayer.x > self.x + self.width/2 and self.jump == false then
			self.animationdirection = "left"
			self.speedx = bowserspeedbackwards * 0.8
			self.backwards = true
		else
			self.backwards = false
			self.animationdirection = "right"
			self.timer = self.timer + dt
			local jumpdelay = bowserjumpdelay
			if self.phase >= 2 then jumpdelay = jumpdelay * 0.7 end
			if self.phase >= 3 then jumpdelay = jumpdelay * 0.5 end

			if self.timer > jumpdelay and self.jump == false then
				self.speedy = -bowserjumpforce * 1.3  -- higher jumps
				self.jump = true
				self.timer = self.timer - jumpdelay
				playsound(jumpsound)
			end
		end
	end

	-- Add trail particles while moving
	if math.abs(self.speedx) > 0.5 then
		table.insert(self.trailparticles, {
			x = self.x + self.width/2 + math.random() * self.width/2 - self.width/4,
			y = self.y + self.height - 0.5,
			vx = 0,
			vy = -1 - math.random() * 2,
			life = 0.4 + math.random() * 0.3,
			maxlife = 0.7,
			r = 1, g = 0.4, b = 0.1, a = 0.8,
			size = 2 + math.random() * 2
		})
	end

	return false
end

-- ================================================
-- PHASE MANAGEMENT
-- ================================================
function megabowser:updatephase(dt)
	local hppercent = self.hp / self.maxhp

	if self.phase == 1 and hppercent <= 0.66 then
		self.phase = 2
		self.phasetransitioning = true
		self.phasetimer = 0
		self.groundpounddelay = 3
		self.chargedelay = 4.5
		self.firebreathdelay = 4
		self.roardelay = 6
		self.summondelay = 8
		self.burstdelay = 3.5
		-- Reset cooldowns for immediate aggression
		self.groundpoundcooldown = 0
		self.chargecooldown = 0
	elseif self.phase == 2 and hppercent <= 0.33 then
		self.phase = 3
		self.phasetransitioning = true
		self.phasetimer = 0
		self.groundpounddelay = 2
		self.chargedelay = 3
		self.firebreathdelay = 3
		self.roardelay = 4
		self.summondelay = 6
		self.burstdelay = 2.5
		self.shielddelay = 10
		self.firebreathduration = 3.5
		self.chargespeed = bowserspeedforwards * 7
		self.groundpoundcooldown = 0
		self.chargecooldown = 0
		self.roarcooldown = 0
	end
end

-- ================================================
-- ABILITY CHOOSER
-- ================================================
function megabowser:chooseability()
	local abilities = {}

	-- Build list of available abilities
	if self.groundpoundcooldown <= 0 and not self.jump then
		table.insert(abilities, "groundpound")
	end
	if self.chargecooldown <= 0 and not self.jump then
		table.insert(abilities, "charge")
	end
	if self.firebreathcooldown <= 0 then
		table.insert(abilities, "firebreath")
	end
	if self.phase >= 2 and self.roarcooldown <= 0 and not self.jump then
		table.insert(abilities, "roar")
	end
	if self.phase >= 2 and self.summoncooldown <= 0 then
		table.insert(abilities, "summon")
	end
	if self.phase >= 2 and self.tailswipecooldown <= 0 and not self.jump then
		table.insert(abilities, "tailswipe")
	end
	if self.burstcooldown <= 0 then
		table.insert(abilities, "burst")
	end
	if self.phase >= 3 and self.shieldcooldown <= 0 and not self.shielded then
		table.insert(abilities, "shield")
	end
	if self.phase >= 2 and self.slampillarcooldown <= 0 then
		table.insert(abilities, "slampillar")
	end

	if #abilities == 0 then return end

	local choice = abilities[math.random(#abilities)]

	if choice == "groundpound" then
		self:startgroundpound()
	elseif choice == "charge" then
		self:startcharge()
	elseif choice == "firebreath" then
		self:startfirebreath()
	elseif choice == "roar" then
		self:startroar()
	elseif choice == "summon" then
		self:summonminions()
	elseif choice == "tailswipe" then
		self:starttailswipe()
	elseif choice == "burst" then
		self:startburst()
	elseif choice == "shield" then
		self:startshield()
	elseif choice == "slampillar" then
		self:startslampillars()
	end
end

-- ================================================
-- GROUND POUND
-- ================================================
function megabowser:startgroundpound()
	self.groundpounding = true
	self.groundpoundwindup = 0
	self.speedy = -bowserjumpforce * 2  -- Jump very high
	self.speedx = 0
	playsound(jumpsound)
end

function megabowser:updategroundpound(dt)
	self.groundpoundwindup = self.groundpoundwindup + dt

	if self.groundpoundwindup < 0.6 then
		-- Rising phase
		self.speedy = self.speedy + self.gravity * dt * 0.5
	else
		-- Slamming down phase
		self.speedy = bowserfallspeed * 3
	end

	self.x = self.x + self.speedx * dt
	self.y = self.y + self.speedy * dt
end

function megabowser:finishgroundpound()
	self.groundpounding = false
	self.groundpoundcooldown = self.groundpounddelay
	self.shakescreen = 0.5

	-- Create stomp wave
	self.stompwave = true
	self.stompwaveradius = 0

	-- Spawn debris / hammers in all directions
	local numhammers = 3 + self.phase * 2
	for i = 1, numhammers do
		local dir = (i % 2 == 0) and "left" or "right"
		local hx = self.x + self.width/2 + (math.random() - 0.5) * 2
		table.insert(objects["hammer"], hammer:new(hx, self.y - 1, dir))
	end

	playsound(blockhitsound)
end

-- ================================================
-- CHARGE ATTACK
-- ================================================
function megabowser:startcharge()
	self.charging = true
	self.chargetimer = 0
	self.chargewindup = 0

	local closestplayer = objects["player"][getclosestplayer(self.x + self.width/2)]
	if closestplayer.x < self.x + self.width/2 then
		self.chargedirection = "left"
	else
		self.chargedirection = "right"
	end
end

function megabowser:updatecharge(dt)
	self.chargewindup = self.chargewindup + dt

	if self.chargewindup < self.chargewinduptime then
		-- Windup: vibrate in place
		self.speedx = math.sin(self.chargewindup * 60) * 2
		self.fireframe = 2
		self.quad = bowserquad[self.fireframe][self.walkframe]
		-- Flash red
		self.phaseflash = self.phaseflash + dt
	else
		-- CHARGING!
		self.chargetimer = self.chargetimer + dt

		if self.chargedirection == "left" then
			self.speedx = -self.chargespeed
			self.animationdirection = "right"
		else
			self.speedx = self.chargespeed
			self.animationdirection = "left"
		end

		-- Trail particles
		for i = 1, 3 do
			table.insert(self.trailparticles, {
				x = self.x + self.width/2,
				y = self.y + self.height/2 + (math.random() - 0.5) * self.height,
				vx = -self.speedx * 0.3,
				vy = (math.random() - 0.5) * 2,
				life = 0.3 + math.random() * 0.2,
				maxlife = 0.5,
				r = 1, g = 0.2, b = 0.1, a = 1,
				size = 3 + math.random() * 3
			})
		end

		-- Fast animation
		self.animationtimer = self.animationtimer + dt * 3
		while self.animationtimer > bowseranimationspeed do
			self.animationtimer = self.animationtimer - bowseranimationspeed
			self.walkframe = (self.walkframe == 1) and 2 or 1
		end
		self.quad = bowserquad[1][self.walkframe]

		-- End charge after duration or hitting a wall
		if self.chargetimer > 1.5 then
			self:finishcharge()
		end
	end
end

function megabowser:finishcharge()
	self.charging = false
	self.chargetimer = 0
	self.chargecooldown = self.chargedelay
	self.speedx = 0
	self.fireframe = 1
	self.shakescreen = 0.2

	-- Scatter hammers on impact
	for i = 1, self.phase + 2 do
		local dir = (math.random(2) == 1) and "left" or "right"
		table.insert(objects["hammer"], hammer:new(self.x + self.width/2, self.y + math.random() * self.height/2, dir))
	end
end

-- ================================================
-- SUSTAINED FIRE BREATH
-- ================================================
function megabowser:startfirebreath()
	self.firebreathing = true
	self.firebreathtimer = 0
	self.fireframe = 2
	self.speedx = 0
end

function megabowser:updatefirebreath(dt)
	self.firebreathtimer = self.firebreathtimer + dt

	self.fireframe = 2
	self.quad = bowserquad[self.fireframe][self.walkframe]
	self.speedx = 0

	-- Spawn fire projectiles rapidly
	local firerate = 0.15
	if self.phase >= 3 then firerate = 0.08 end

	if math.floor(self.firebreathtimer / firerate) > math.floor((self.firebreathtimer - dt) / firerate) then
		-- Spawn a fire at mouth position
		local fx = self.x - 1
		local fy = self.y + self.height * 0.3
		if self.animationdirection == "left" then
			fx = self.x + self.width + 1
		end

		-- Fire with slight spread
		local spread = (math.random() - 0.5) * 2
		if objects["fireball"] then
			-- Use the game's fire system
		end

		-- Fire breath particles
		for p = 1, 5 do
			local dir = (self.animationdirection == "right") and -1 or 1
			table.insert(self.firebreathparticles, {
				x = fx,
				y = fy + spread * 0.3,
				vx = dir * (8 + math.random() * 4),
				vy = (math.random() - 0.5) * 3 + spread,
				life = 0.5 + math.random() * 0.3,
				maxlife = 0.8,
				r = 1, g = 0.5 + math.random() * 0.5, b = 0, a = 1,
				size = 3 + math.random() * 4
			})
		end

		-- Damage players near fire breath
		for i, p in pairs(objects["player"]) do
			local px = p.x
			local py = p.y
			local inrange = false
			if self.animationdirection == "right" then
				inrange = px < self.x and px > self.x - 6 and math.abs(py - fy) < 2
			else
				inrange = px > self.x + self.width and px < self.x + self.width + 6 and math.abs(py - fy) < 2
			end
			if inrange then
				p:die("fire")
			end
		end
	end

	-- Update fire particles
	for i = #self.firebreathparticles, 1, -1 do
		local p = self.firebreathparticles[i]
		p.x = p.x + p.vx * dt
		p.y = p.y + p.vy * dt
		p.life = p.life - dt
		p.a = p.life / p.maxlife
		p.g = p.g - dt * 0.5
		if p.g < 0 then p.g = 0 end
		p.size = p.size - dt * 3
		if p.life <= 0 or p.size <= 0 then
			table.remove(self.firebreathparticles, i)
		end
	end

	if self.firebreathtimer >= self.firebreathduration then
		self:finishfirebreath()
	end
end

function megabowser:finishfirebreath()
	self.firebreathing = false
	self.firebreathtimer = 0
	self.firebreathcooldown = self.firebreathdelay
	self.fireframe = 1
end

-- ================================================
-- ROAR / SHOCKWAVE
-- ================================================
function megabowser:startroar()
	self.roaring = true
	self.roartimer = 0
	self.roarradius = 0
	self.speedx = 0
	self.shakescreen = self.roarduration
	playsound(bowserfallsound)
end

function megabowser:updateroar(dt)
	self.roartimer = self.roartimer + dt
	self.roarradius = (self.roartimer / self.roarduration) * self.roarmaxradius

	self.fireframe = 2
	self.quad = bowserquad[self.fireframe][self.walkframe]

	-- Push players away
	for i, p in pairs(objects["player"]) do
		local dx = p.x - (self.x + self.width/2)
		local dy = p.y - (self.y + self.height/2)
		local dist = math.sqrt(dx*dx + dy*dy)
		if dist < self.roarradius and dist > 0 then
			local pushforce = 15 * dt
			p.x = p.x + (dx/dist) * pushforce
		end
	end

	-- Roar ring particles
	for a = 0, math.pi * 2, math.pi / 8 do
		table.insert(self.auraparticles, {
			x = self.x + self.width/2 + math.cos(a) * self.roarradius,
			y = self.y + self.height/2 + math.sin(a) * self.roarradius,
			vx = math.cos(a) * 2,
			vy = math.sin(a) * 2,
			life = 0.2,
			maxlife = 0.2,
			r = 1, g = 0.8, b = 0.2, a = 0.8,
			size = 2
		})
	end

	if self.roartimer >= self.roarduration then
		self.roaring = false
		self.roarcooldown = self.roardelay
		self.fireframe = 1
	end
end

-- ================================================
-- MINION SUMMONING
-- ================================================
function megabowser:summonminions()
	self.summoncooldown = self.summondelay

	local numminions = 1 + self.phase
	if numminions > self.maxminions then numminions = self.maxminions end

	for i = 1, numminions do
		local sx = self.x + self.width/2 + (math.random() - 0.5) * 6
		local sy = self.y - 2

		-- Spawn goombas or koopas based on phase
		if self.phase <= 2 then
			if objects["goomba"] then
				table.insert(objects["goomba"], goomba:new(sx * 16, sy * 16))
			end
		else
			if objects["koopa"] then
				table.insert(objects["koopa"], koopa:new(sx * 16, sy * 16))
			end
		end
	end

	-- Visual effect
	self.shakescreen = 0.3
	for i = 1, 10 do
		table.insert(self.auraparticles, {
			x = self.x + self.width/2 + (math.random() - 0.5) * 4,
			y = self.y + (math.random() - 0.5) * self.height,
			vx = (math.random() - 0.5) * 6,
			vy = -3 - math.random() * 3,
			life = 0.5 + math.random() * 0.3,
			maxlife = 0.8,
			r = 0.5, g = 0, b = 1, a = 1,
			size = 3 + math.random() * 2
		})
	end
end

-- ================================================
-- TAIL SWIPE
-- ================================================
function megabowser:starttailswipe()
	self.tailswiping = true
	self.tailswipetimer = 0
	self.tailswipeangle = 0
	self.speedx = 0
end

function megabowser:updatetailswipe(dt)
	self.tailswipetimer = self.tailswipetimer + dt
	self.tailswipeangle = (self.tailswipetimer / self.tailswipeduration) * math.pi * 2

	-- Damage players in a wide arc
	local tailreach = self.width * 1.5
	local tailx = self.x + self.width/2 + math.cos(self.tailswipeangle) * tailreach
	local taily = self.y + self.height/2 + math.sin(self.tailswipeangle) * tailreach * 0.5

	for i, p in pairs(objects["player"]) do
		local dx = p.x - tailx
		local dy = p.y - taily
		local dist = math.sqrt(dx*dx + dy*dy)
		if dist < 1.5 then
			p:die("enemy")
		end
	end

	-- Trail particles for tail
	table.insert(self.trailparticles, {
		x = tailx, y = taily,
		vx = 0, vy = 0,
		life = 0.3, maxlife = 0.3,
		r = 0.3, g = 0.8, b = 0.2, a = 1,
		size = 4
	})

	if self.tailswipetimer >= self.tailswipeduration then
		self.tailswiping = false
		self.tailswipecooldown = self.tailswipedelay
	end
end

-- ================================================
-- FIREBALL BURST
-- ================================================
function megabowser:startburst()
	self.bursting = true
	self.bursttimer = 0
	self.burstcount = 0
	self.burstmax = 3 + self.phase * 2
	self.fireframe = 2
end

function megabowser:updateburst(dt)
	self.bursttimer = self.bursttimer + dt

	local burstrate = 0.2
	if self.phase >= 3 then burstrate = 0.12 end

	if self.bursttimer >= burstrate then
		self.bursttimer = self.bursttimer - burstrate
		self.burstcount = self.burstcount + 1

		-- Shoot hammer in a fan pattern
		local angle = -0.5 + (self.burstcount / self.burstmax) * 1.0
		local hx = self.x
		local hy = self.y + self.height * 0.3 + angle
		table.insert(objects["hammer"], hammer:new(hx, hy, "left"))

		-- Also throw one to the right sometimes
		if self.phase >= 3 and self.burstcount % 2 == 0 then
			table.insert(objects["hammer"], hammer:new(self.x + self.width, hy, "right"))
		end

		-- Burst particle
		for p = 1, 3 do
			table.insert(self.auraparticles, {
				x = hx, y = hy,
				vx = -5 + math.random() * 2,
				vy = (math.random() - 0.5) * 4,
				life = 0.3, maxlife = 0.3,
				r = 1, g = 0.6, b = 0, a = 1,
				size = 2 + math.random() * 2
			})
		end
	end

	if self.burstcount >= self.burstmax then
		self.bursting = false
		self.burstcooldown = self.burstdelay
		self.fireframe = 1
	end
end

-- ================================================
-- SHIELD
-- ================================================
function megabowser:startshield()
	self.shielded = true
	self.shieldtimer = 0
	self.shieldcooldown = self.shielddelay

	-- Shield activation particles
	for i = 1, 20 do
		local angle = (i / 20) * math.pi * 2
		table.insert(self.auraparticles, {
			x = self.x + self.width/2 + math.cos(angle) * 3,
			y = self.y + self.height/2 + math.sin(angle) * 3,
			vx = -math.cos(angle) * 3,
			vy = -math.sin(angle) * 3,
			life = 0.5, maxlife = 0.5,
			r = 0.2, g = 0.5, b = 1, a = 1,
			size = 3
		})
	end
end

-- ================================================
-- SLAM PILLARS (fire pillars from ground)
-- ================================================
function megabowser:startslampillars()
	self.slampillarcooldown = self.slampillardelay

	local numpillars = 3 + self.phase
	local closestplayer = objects["player"][getclosestplayer(self.x + self.width/2)]

	for i = 1, numpillars do
		local px = closestplayer.x + (i - numpillars/2) * 2.5
		table.insert(self.slampillars, {
			x = px,
			y = self.y + self.height,
			timer = 0,
			delay = 0.3 + i * 0.2,  -- staggered timing
			active = false,
			height = 0,
			maxheight = 4 + self.phase,
			duration = 1.5,
			warning = true
		})
	end
end

function megabowser:updateslampillars(dt)
	for i = #self.slampillars, 1, -1 do
		local p = self.slampillars[i]
		p.timer = p.timer + dt

		if p.warning and p.timer < p.delay then
			-- Warning particles
			if math.floor(p.timer * 10) % 2 == 0 then
				table.insert(self.auraparticles, {
					x = p.x + (math.random() - 0.5),
					y = p.y - 0.5,
					vx = 0, vy = -2,
					life = 0.3, maxlife = 0.3,
					r = 1, g = 0.3, b = 0, a = 0.6,
					size = 2
				})
			end
		elseif p.timer >= p.delay and not p.active then
			p.active = true
			p.warning = false
			p.timer = 0
			playsound(blockhitsound)
		end

		if p.active then
			-- Pillar rising
			if p.height < p.maxheight then
				p.height = p.height + p.maxheight * dt * 4
				if p.height > p.maxheight then p.height = p.maxheight end
			end

			-- Damage players touching pillar
			for _, pl in pairs(objects["player"]) do
				if pl.x > p.x - 0.5 and pl.x < p.x + 0.5 then
					if pl.y > p.y - p.height and pl.y < p.y then
						pl:die("fire")
					end
				end
			end

			-- Pillar particles
			if math.random() > 0.7 then
				table.insert(self.auraparticles, {
					x = p.x + (math.random() - 0.5) * 0.8,
					y = p.y - math.random() * p.height,
					vx = (math.random() - 0.5) * 2,
					vy = -1 - math.random() * 2,
					life = 0.3, maxlife = 0.3,
					r = 1, g = 0.4 + math.random() * 0.3, b = 0, a = 0.8,
					size = 2 + math.random() * 2
				})
			end

			-- Duration
			if p.timer > p.duration then
				p.height = p.height - p.maxheight * dt * 3
				if p.height <= 0 then
					table.remove(self.slampillars, i)
				end
			end
		end
	end
end

-- ================================================
-- DAMAGE PLAYERS IN RADIUS
-- ================================================
function megabowser:damageplayersinradius(radius, precision)
	for i, p in pairs(objects["player"]) do
		local dx = p.x - (self.x + self.width/2)
		local dy = p.y - (self.y + self.height/2)
		local dist = math.sqrt(dx*dx + dy*dy)
		if dist < radius then
			p:die("enemy")
		end
	end
end

-- ================================================
-- PARTICLE SYSTEMS
-- ================================================
function megabowser:updateauraparticles(dt)
	-- Phase-based ambient aura
	if self.phase >= 2 and not self.shot and not self.dying then
		if math.random() > 0.7 then
			local r, g, b = 1, 0.3, 0
			if self.phase >= 3 then r, g, b = 1, 0.1, 0.1 end
			table.insert(self.auraparticles, {
				x = self.x + math.random() * self.width,
				y = self.y + self.height,
				vx = (math.random() - 0.5) * 1,
				vy = -2 - math.random() * 2,
				life = 0.5 + math.random() * 0.5,
				maxlife = 1,
				r = r, g = g, b = b, a = 0.6,
				size = 2 + math.random() * 3
			})
		end
	end

	for i = #self.auraparticles, 1, -1 do
		local p = self.auraparticles[i]
		p.x = p.x + p.vx * dt
		p.y = p.y + p.vy * dt
		p.life = p.life - dt
		p.a = (p.life / p.maxlife) * p.a
		if p.life <= 0 then
			table.remove(self.auraparticles, i)
		end
	end
end

function megabowser:updatetrailparticles(dt)
	for i = #self.trailparticles, 1, -1 do
		local p = self.trailparticles[i]
		p.x = p.x + p.vx * dt
		p.y = p.y + p.vy * dt
		p.life = p.life - dt
		p.a = p.life / p.maxlife
		p.size = math.max(0, p.size - dt * 4)
		if p.life <= 0 then
			table.remove(self.trailparticles, i)
		end
	end
end

-- ================================================
-- DEATH SEQUENCE
-- ================================================
function megabowser:updatedeath(dt)
	self.deathtimer = self.deathtimer + dt
	self.shakescreen = 0.1

	-- Explosions everywhere
	if math.floor(self.deathtimer * 10) > math.floor((self.deathtimer - dt) * 10) then
		for i = 1, 3 do
			table.insert(self.deathexplosions, {
				x = self.x + math.random() * self.width,
				y = self.y + math.random() * self.height,
				timer = 0.5 + math.random() * 0.3
			})
			playsound(blockhitsound)
		end
	end

	-- Update explosions
	for i = #self.deathexplosions, 1, -1 do
		self.deathexplosions[i].timer = self.deathexplosions[i].timer - dt
		if self.deathexplosions[i].timer <= 0 then
			table.remove(self.deathexplosions, i)
		end
	end

	-- Final death after delay
	if self.deathtimer > 3.0 then
		self:firedeath()
	end
end

-- ================================================
-- DRAW
-- ================================================
function megabowser:draw()
	local sx = self.shakex or 0
	local sy = self.shakey or 0

	-- Draw slam pillars
	for _, p in ipairs(self.slampillars) do
		if p.active and p.height > 0 then
			love.graphics.setColor(1, 0.4, 0, 0.9)
			local px = math.floor((p.x - xscroll) * 16 * scale) + sx
			local py = math.floor((p.y) * 16 * scale) + sy
			local pw = math.floor(0.8 * 16 * scale)
			local ph = math.floor(p.height * 16 * scale)
			love.graphics.rectangle("fill", px - pw/2, py - ph, pw, ph)

			-- Brighter core
			love.graphics.setColor(1, 0.8, 0.2, 0.7)
			love.graphics.rectangle("fill", px - pw/4, py - ph, pw/2, ph)
		elseif p.warning then
			-- Warning indicator
			love.graphics.setColor(1, 0, 0, 0.3 + 0.3 * math.sin(p.timer * 20))
			local px = math.floor((p.x - xscroll) * 16 * scale) + sx
			local py = math.floor(p.y * 16 * scale) + sy
			love.graphics.rectangle("fill", px - 8*scale, py - 4*scale, 16*scale, 4*scale)
		end
	end

	love.graphics.setColor(1, 1, 1, 1)

	-- Draw aura particles
	for _, p in ipairs(self.auraparticles) do
		love.graphics.setColor(p.r, p.g, p.b, p.a)
		local px = math.floor((p.x - xscroll) * 16 * scale) + sx
		local py = math.floor(p.y * 16 * scale) + sy
		love.graphics.circle("fill", px, py, p.size * scale)
	end

	-- Draw trail particles
	for _, p in ipairs(self.trailparticles) do
		love.graphics.setColor(p.r, p.g, p.b, p.a)
		local px = math.floor((p.x - xscroll) * 16 * scale) + sx
		local py = math.floor(p.y * 16 * scale) + sy
		love.graphics.circle("fill", px, py, p.size * scale)
	end

	-- Draw fire breath particles
	for _, p in ipairs(self.firebreathparticles) do
		love.graphics.setColor(p.r, p.g, p.b, p.a)
		local px = math.floor((p.x - xscroll) * 16 * scale) + sx
		local py = math.floor(p.y * 16 * scale) + sy
		love.graphics.circle("fill", px, py, p.size * scale)
	end

	-- Draw stomp wave
	if self.stompwave then
		local r = self.stompwaveradius * 16 * scale
		local cx = math.floor((self.x + self.width/2 - xscroll) * 16 * scale) + sx
		local cy = math.floor((self.y + self.height) * 16 * scale) + sy
		local alpha = 1 - (self.stompwaveradius / self.stompwavemaxradius)
		love.graphics.setColor(1, 0.5, 0, alpha * 0.6)
		love.graphics.setLineWidth(3 * scale)
		love.graphics.circle("line", cx, cy, r)
		love.graphics.setColor(1, 0.8, 0.2, alpha * 0.3)
		love.graphics.circle("fill", cx, cy, r)
		love.graphics.setLineWidth(1)
	end

	-- Draw roar shockwave
	if self.roaring then
		local r = self.roarradius * 16 * scale
		local cx = math.floor((self.x + self.width/2 - xscroll) * 16 * scale) + sx
		local cy = math.floor((self.y + self.height/2) * 16 * scale) + sy
		local alpha = 1 - (self.roarradius / self.roarmaxradius)
		love.graphics.setColor(1, 1, 0.5, alpha * 0.5)
		love.graphics.setLineWidth(4 * scale)
		love.graphics.circle("line", cx, cy, r)
		love.graphics.setLineWidth(2 * scale)
		love.graphics.setColor(1, 0.9, 0.3, alpha * 0.3)
		love.graphics.circle("line", cx, cy, r * 0.7)
		love.graphics.setLineWidth(1)
	end

	-- Draw tail swipe arc
	if self.tailswiping then
		local tailreach = self.width * 1.5 * 16 * scale
		local cx = math.floor((self.x + self.width/2 - xscroll) * 16 * scale) + sx
		local cy = math.floor((self.y + self.height/2) * 16 * scale) + sy
		local tx = cx + math.cos(self.tailswipeangle) * tailreach
		local ty = cy + math.sin(self.tailswipeangle) * tailreach * 0.5
		love.graphics.setColor(0.3, 0.8, 0.2, 0.8)
		love.graphics.setLineWidth(4 * scale)
		love.graphics.line(cx, cy, tx, ty)
		love.graphics.circle("fill", tx, ty, 6 * scale)
		love.graphics.setLineWidth(1)
	end

	-- Draw shield
	if self.shielded then
		local cx = math.floor((self.x + self.width/2 - xscroll) * 16 * scale) + sx
		local cy = math.floor((self.y + self.height/2) * 16 * scale) + sy
		local sr = math.max(self.width, self.height) * 16 * scale * 0.7
		love.graphics.setColor(0.2, 0.5, 1, self.shieldopacity)
		love.graphics.circle("fill", cx, cy, sr)
		love.graphics.setColor(0.4, 0.7, 1, self.shieldopacity + 0.2)
		love.graphics.setLineWidth(2 * scale)
		love.graphics.circle("line", cx, cy, sr)
		love.graphics.setLineWidth(1)
	end

	love.graphics.setColor(1, 1, 1, 1)

	-- Draw death explosions
	for _, e in ipairs(self.deathexplosions) do
		love.graphics.setColor(1, 0.6 + math.random() * 0.4, 0, 0.9)
		local ex = math.floor((e.x - xscroll) * 16 * scale) + sx
		local ey = math.floor(e.y * 16 * scale) + sy
		local er = (e.timer / 0.8) * 12 * scale
		love.graphics.circle("fill", ex, ey, er)
	end
	love.graphics.setColor(1, 1, 1, 1)

	-- HAMMER DRAW (scaled up)
	if not self.fall and not self.backwards and not self.shot and not self.dying then
		if self.hammertimer > self.hammertime - bowserhammerdrawtime then
			love.graphics.draw(hammerimg, hammerquad[spriteset][1],
				math.floor((self.x - xscroll) * 16 * scale) + sx,
				(self.y - 0.5 - 11/16) * 16 * scale + sy,
				0, scale * self.scale, scale * self.scale)
		end
	end

	-- Draw HP bar
	if not self.shot and not self.dying then
		self:drawhpbar(sx, sy)
	end

	-- Phase indicator
	if self.phasetransitioning then
		local cx = math.floor((self.x + self.width/2 - xscroll) * 16 * scale) + sx
		local cy = math.floor((self.y - 1) * 16 * scale) + sy
		love.graphics.setColor(1, 0, 0, 0.5 + 0.5 * math.sin(self.phasetimer * 15))
		love.graphics.circle("fill", cx, cy, 30 * scale * (self.phasetimer / 2))
		love.graphics.setColor(1, 1, 1, 1)
	end

	-- Hit flash
	if self.hittimer > 0 then
		if math.floor(self.flashtimer * 20) % 2 == 0 then
			love.graphics.setColor(1, 0.3, 0.3, 0.5)
		end
	end

	-- Phase color tinting
	if self.phase == 2 then
		love.graphics.setColor(1, 0.8, 0.7, 1)
	elseif self.phase == 3 then
		love.graphics.setColor(1, 0.5, 0.5, 1)
	end

	love.graphics.setColor(1, 1, 1, 1)
end

-- ================================================
-- HP BAR
-- ================================================
function megabowser:drawhpbar(sx, sy)
	local barwidth = self.width * 16 * scale
	local barheight = 4 * scale
	local bx = math.floor((self.x - xscroll) * 16 * scale) + sx
	local by = math.floor((self.y - 1.5) * 16 * scale) + sy

	-- Background
	love.graphics.setColor(0, 0, 0, 0.7)
	love.graphics.rectangle("fill", bx - 2, by - 2, barwidth + 4, barheight + 4)

	-- HP fill
	local hppercent = self.hp / self.maxhp
	local r, g, b = 0, 1, 0
	if hppercent < 0.66 then r, g = 1, 1 end
	if hppercent < 0.33 then r, g, b = 1, 0, 0 end

	love.graphics.setColor(r, g, b, 0.9)
	love.graphics.rectangle("fill", bx, by, barwidth * hppercent, barheight)

	-- Border
	love.graphics.setColor(1, 1, 1, 0.8)
	love.graphics.rectangle("line", bx - 1, by - 1, barwidth + 2, barheight + 2)

	-- Phase markers
	love.graphics.setColor(0, 0, 0, 0.5)
	love.graphics.line(bx + barwidth * 0.66, by, bx + barwidth * 0.66, by + barheight)
	love.graphics.line(bx + barwidth * 0.33, by, bx + barwidth * 0.33, by + barheight)

	love.graphics.setColor(1, 1, 1, 1)
end

-- ================================================
-- NEWTARGETX (wider range for mega size)
-- ================================================
function megabowser:newtargetx(dir)
	if dir == "right" then
		self.targetx = self.startx - 2 - math.random(3)
	else
		self.targetx = self.startx - 10 - math.random(3)
	end
end

-- ================================================
-- DAMAGE / DEATH
-- ================================================
function megabowser:shotted(dir)
	if self.invincibletimer > 0 then return end

	if self.shielded then
		-- Shield absorbs damage but weakens
		self.shieldduration = self.shieldduration - 0.5
		playsound(blockhitsound)
		-- Shield hit particles
		for i = 1, 8 do
			table.insert(self.auraparticles, {
				x = self.x + math.random() * self.width,
				y = self.y + math.random() * self.height,
				vx = (math.random() - 0.5) * 6,
				vy = (math.random() - 0.5) * 6,
				life = 0.3, maxlife = 0.3,
				r = 0.3, g = 0.6, b = 1, a = 1,
				size = 3
			})
		end
		return
	end

	self.hp = self.hp - 1
	self.hittimer = 0.5
	self.flashtimer = 0
	self.invincibletimer = 0.5

	-- Hit particles
	for i = 1, 12 do
		table.insert(self.auraparticles, {
			x = self.x + math.random() * self.width,
			y = self.y + math.random() * self.height,
			vx = (math.random() - 0.5) * 8,
			vy = -2 - math.random() * 4,
			life = 0.4, maxlife = 0.4,
			r = 1, g = 1, b = 0, a = 1,
			size = 2 + math.random() * 2
		})
	end

	playsound(blockhitsound)

	if self.hp <= 0 then
		self.dying = true
		self.deathtimer = 0
		self.speedx = 0
		self.speedy = 0
		self.active = false
	end
end

function megabowser:firedeath()
	playsound(shotsound)
	playsound(bowserfallsound)
	self.shot = true
	self.dying = false
	self.speedy = -shotjumpforce * 1.5
	self.direction = dir or "right"
	self.active = false
	self.gravity = shotgravity
	self.speedx = 0

	addpoints(firepoints["bowser"] * 3, self.x + self.width/2, self.y)

	-- Massive explosion particles
	for i = 1, 40 do
		table.insert(self.auraparticles, {
			x = self.x + math.random() * self.width,
			y = self.y + math.random() * self.height,
			vx = (math.random() - 0.5) * 12,
			vy = -4 - math.random() * 8,
			life = 1 + math.random(),
			maxlife = 2,
			r = 1, g = math.random() * 0.5, b = 0, a = 1,
			size = 4 + math.random() * 6
		})
	end

	self.shakescreen = 1.5

	-- Image change (decoy reveal)
	if marioworld <= 7 then
		self.graphic = decoysimg
		self.quad = decoysquad[marioworld]
	end
end

-- ================================================
-- COLLISION
-- ================================================
function megabowser:leftcollide(a, b)
	if a == "player" then
		return false
	end
	if self.charging then
		self:finishcharge()
	end
end

function megabowser:rightcollide(a, b)
	if a == "player" then
		return false
	end
	if self.charging then
		self:finishcharge()
	end
end

function megabowser:ceilcollide(a, b)
	if a == "player" then
		return false
	end
end

function megabowser:floorcollide(a, b)
	if self.jump then
		self.jump = false
		self.timer = 0
	end

	if self.groundpounding then
		self:finishgroundpound()
	end

	-- Stomp damage on landing from any big jump
	if self.speedy > bowserfallspeed * 0.5 and not self.groundpounding then
		self.shakescreen = 0.15
	end

	if a == "player" then
		return false
	end
end

function megabowser:startfall()
	self.jump = true
end

function megabowser:emancipate(a)
	self:shotted()
end
