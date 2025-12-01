pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
//init stuff

debug = false
start_lvl = 1
tdelay = .4

nmes = {} //enemies
twrs = {} //towers
lvls = {} //levels
hits = {} //hit animations
game = {} //game info
frm = 0   //frames since start
sec = 0   //seconds since start

cpos = 0    //cursor position (lane)
csel = nil  //cursor selection

etypes = {} //enemy types
ttypes = {} //tower types

// controls
// left/right to move cursor
// up/down to change tower 
// o/x button to select tower

function _init() 
  cls()
  init_nme_types()
  init_twr_types()
  init_levels()
  
  game.curlvl = nil
  game.curscreen = nil
  game.fsls = 0  //frames since last enemy spawn
  game.sr = 999  //enemy spawn rate in frames
  game.sn = 0    //number of enemies per spawn
  game.money = 0
  game.frm = 0   //frames since lvl start
  game.sec = 0   //seconds since lvl start
  poke(0x5f5c, 255)  //set button repeat delay

  load_level(start_lvl)
  show_screen("title")
end

-->8
//update functions

function _update()
		frm += 1
		game.frm += 1
		
  sec = flr(time())
  game.sec = game.frm / 30
  
  if game.curscreen == "title" then
    update_title_screen()
  elseif game.curscreen == "intro" then
    update_intro_screen()
  elseif game.curscreen == "game" then
    update_game_screen()  
  elseif game.curscreen == "lose" then
    update_lose_screen()
  else
    //win screen
  end
end

function update_title_screen()
  if btnp() > 0 and game.sec > tdelay then
    game.curscreen = "intro"
    game.frm = 0
    game.sec = 0
    sfx(3, 0)
    music(0)
  end
end

function update_intro_screen()
  if btnp() > 0 and game.sec > tdelay then
    game.curscreen = "game"
    game.frm = 0
    game.sec = 0
    sfx(3, 0)
  end
end

function update_lose_screen()
  if btnp() > 0 and game.sec > tdelay then
    load_level()
    game.curscreen = "game"
    game.frm = 0
    game.sec = 0
    sfx(3, 0)
  end
end

function update_game_screen()
  game.fsls += 1
  if game.fsls > game.sr then
    spawn_enemies()
    game.fsls = 0
  end

  fire_towers()  
  move_enemies()
  
  //check if any enemies are at the bottom
  for i,e in ipairs(nmes) do
    if e.y > 120 then
      if game.curlvl.num == 10 then
        game.lkt = game.sec
      else
        game.lkt = nil
      end
      show_screen("lose")
    end
  end  
  
  //clean up any hit animations that are done
  for i,h in ipairs(hits) do
	 		if h.lifetime <= 0 then
	 		  del(hits, h)
	 		end
	 end
	 
	 //clean up towers that are out of ammo
  for i,t in ipairs(twrs) do
	 		if t.ammo <= 0 then
	 		  del(twrs, t)
	 		end
	 end	 
	 
	 //handle input
	 if btnp(➡️) then
	   cpos = min(cpos + 1, 6)
	 elseif  btnp(⬅️) then
	   cpos = max(cpos - 1, 0)
	 end
	 
	 if btnp(4) or btnp(5) then
	   local twr_name = game.curlvl.twrs[csel]
	   if twr_name != nil then
	     create_twr(cpos + 1, twr_name)  
	   end
	 end
	 
	 if btnp(⬆️) then
	   csel = min(csel+1,#game.curlvl.twrs)
	 elseif btnp(⬇️) then
	   csel = max(csel-1,1)
	 end
end

-->8
//draw functions

function _draw()
  cls(1)

  if game.curscreen == "title" then
    draw_title_screen()
  elseif game.curscreen == "intro" then
    draw_intro_screen()
  elseif game.curscreen == "game" then
    draw_game_screen()  
  elseif game.curscreen == "lose" then
    draw_lose_screen()
  else
    draw_win_screen()
  end
end

function draw_game_screen()
  line(0,0,0,127,1)
  line(127,0,127,127,1)
  
  //draw enemy sprites
  for i=1,#nmes do
    local e = nmes[i]
    local cf
    if sec % 2 == 0 then
      cf = e.i
    else
      cf = e.i + 1
    end
    
    local ex = (e.lane * 16) - 4
    spr(cf, ex, e.y)
    
    if debug then
      print(e.hp, ex, e.y + 8, 7)
    end
  end
  
  //draw towers
  for i=1,#twrs do
  		local t = twrs[i]
  		local i
  		if t.firing == false then
  		  i = t.type.i
  		else
  		  i = t.type.i + 1
  		end
  		spr(i, (t.lane * 16) - 4, 116)
	   t.type.drawmore(t)
	 
	   //draw ammo timer
	   local x1 = (t.lane * 16) - 4
	   local am = t.ammo / t.type.ammo
	   local x2 = x1 + (7 * am)
	   
    local clr
	   if am >= .5 then
	     clr = 11
	   elseif am < .5 and am > .2 then
	     clr = 10
	   else
	     clr = 8
	   end 
	   line(x1, 126, x2, 126, clr)
	 end
	 
  //draw cursor
  rect((cpos * 16) + 8, 111, (cpos * 16) + 23, 127, 11)
  local csel_name = game.curlvl.twrs[csel]
		local tsi
		local tcost
		if csel_name == "laser" then
		  tsi = 22
		  tcost = ttypes["laser"].cost
		elseif csel_name == "gatling" then
		  tsi = 23
		  tcost = ttypes["gatling"].cost
		else
		  tsi = 24
		  tcost = ttypes["scatter"].cost
		end
		spr(tsi, (cpos * 16) + 12, 116)
  print("$", (cpos * 16) + 8, 105, 7)
  print(tcost, (cpos * 16) + 13, 105, 7)
  
	 //draw hits
	 for i=1,#hits do
	   local h = hits[i]
	   spr(h.i, h.lane * 16 - 4, h.y)
	   h.lifetime -= 1
	 end

  //draw level status text
  print_shadowed("money:$",4,4)
  print_shadowed(game.money,34,4)
  if game.curlvl.gtext == nil then
    print_shadowed("kills: ",4,14)
    print_shadowed(game.kills,28,14)
  else
    print_shadowed(game.curlvl.gtext(game),4,14)
  end
  
  //draw debug text
  if debug then
  		print_shadowed("tsec: ", 85, 4)
  		print_shadowed(sec, 107, 4)
    print_shadowed("tfrm: ", 85, 14)
    print_shadowed(frm, 107, 14)
    print_shadowed("lsec: ", 85, 24)
  		print_shadowed(game.sec, 107, 24)
    print_shadowed("lfrm: ", 85, 34)
    print_shadowed(game.frm, 107, 34)
  end
  
  //check win condition
  if game.curlvl.fc(game) then
    local nxt_lvl = game.curlvl.num + 1
    load_level(nxt_lvl)
    show_screen("intro")
  end
end

function draw_intro_screen()
  print(game.curlvl.name, 50, 25, 3)
  print(game.curlvl.desc, 10, 45, 7)
  print("goal: ", 25, 90, 7)
  print(game.curlvl.goal, 50, 90, 13)
  print("press ❎ to continue!", 22, 105, 7)
end

function draw_title_screen()
  //enemies
  spr(1, 20, 20)
  spr(3, 45, 20)
  spr(5, 75, 20)
  spr(7, 100, 20)
  
  //title
  spr(10, 40, 40, 6, 5)
  
  //towers
  spr(17, 30, 105)
  spr(19, 60, 105)
  spr(21, 90, 105)
  
  //text
  print("press ❎ to play!", 30, 85, 7)
end

function draw_lose_screen()
  print("you lost!", 50, 45, 3)
  if game.lkt != nil then
    print("you made it " .. flr(game.lkt) .. " seconds!", 22, 58, 7)
  end
  print("press ❎ to retry!", 30, 75, 7)
end

function draw_win_screen()
  print("you won!", 10, 45, 7)
end

-->8
//init types and data

function init_nme_types()
  local t1 = {}
  t1.name = "tank"
  t1.hp = 500
  t1.ftm = 100
  t1.i = 1
  t1.value = 100
  etypes[t1.name] = t1
  
  local t2 = {}
  t2.name = "buggy"
  t2.hp = 4
  t2.ftm = 5
  t2.i = 3
  t2.value = 25
  etypes[t2.name] = t2
  
  local t3 = {}
  t3.name = "droid"
  t3.hp = 75
  t3.ftm = 55
  t3.i = 5
  t3.value = 50
  etypes[t3.name] = t3
    
  local t4 = {}
  t4.name = "mech"
  t4.hp = 125
  t4.ftm = 35
  t4.i = 7
  t4.value = 75
  etypes[t4.name] = t4
end

function init_twr_types()
  //single target, med damage
  //can shoot into neighbor rows
  //does not penetrate
  local t1 = {}
  t1.name = "gatling"
  t1.range = 1
  t1.i = 18
  t1.s = 1
  t1.dmg = 10
  t1.rof = 30 //frames, lower is better
  t1.ammo = 50
  t1.cost = 200
  t1.deal_damage = function(twr)
				local cn = {}
    for i, e in ipairs(nmes) do
      if abs(twr.lane - e.lane) <= t1.range then
        if cn[e.lane] == nil or cn[e.lane].y < e.y then
          cn[e.lane] = e
        end           
      end
    end
    for i, e in pairs(cn) do
      create_hit(e,34,4,t1.dmg)
    end
  end
  t1.has_targets = function(twr)
    for i, e in ipairs(nmes) do
      if abs(twr.lane - e.lane) <= t1.range then
        return true
      end
    end
    return false  
  end
  t1.drawmore = function(twr)
  
  end
  ttypes[t1.name] = t1
  
  //single target, high damage
  //but only targets same row
  //penetrates the whole lane
  local t2 = {}
  t2.name = "laser"
  t2.range = 0
  t2.i = 16
  t2.s = 0
  t2.dmg = 250
  t2.rof = 300
  t2.ammo = 10
  t2.cost = 100
  t2.deal_damage = function(twr)
    for i, e in ipairs(nmes) do
      if abs(twr.lane - e.lane) <= t2.range then
        create_hit(e,32,15,t2.dmg)
      end
    end  
  end
  t2.has_targets = function(twr)
    for i, e in ipairs(nmes) do
      if e.lane == twr.lane then
        return true
      end
    end
    return false
  end
  t2.drawmore = function(twr)
    if twr.firing then
      local x = (twr.lane * 16) - 1
      line(x, 0, x, 115, 12)
      line(x+1, 0, x+1, 115, 8)
    end
  end
  ttypes[t2.name] = t2
  
  //low damage, short range, wide spread
  //can hit many enemies in close range
  local t3 = {}
  t3.name = "scatter"
  t3.range = 2
  t3.i = 20
  t3.s = 2
  t3.dmg = 1
  t3.rof = 20
  t3.ammo = 100
  t3.cost = 50
  t3.deal_damage = function(twr)
    for i, e in ipairs(nmes) do
      local inrange = abs(twr.lane - e.lane) <= twr.type.range and e.y > 50
      if inrange then
        create_hit(e,36,7,t3.dmg)
      end
    end 
  end
  t3.has_targets = function(twr)
    for i, e in ipairs(nmes) do
      local inrange = abs(twr.lane - e.lane) <= twr.type.range and e.y > 50
      if inrange then
        return true
      end
    end
    return false  
  end
  t3.drawmore = function(twr)
    //if twr.firing then
      //twr_x = twr.lane * 16
      //line(twr_x - 5, twr.y - 5, twr_x - 20, twr.y - 20, 9)
      //line(twr_x + 5, twr.y - 5, twr_x + 20, twr.y - 20, 9)
    //end
  end
  ttypes[t3.name] = t3
end 

function check_nme_death(e)
  if e.hp <= 0 then
    game.money += e.type.value
    del(nmes, e)
    game.kills += 1
  end
end

function init_levels()
  local l1 = {}
  l1.num = 1
  l1.money = 1400
  l1.nmes = { "mech", "droid" }
  l1.twrs = { "gatling" }
  l1.name = "lesson 1"
  l1.desc = "the gatling gun is a great\nall around weapon! it\nwill hit neighboring lanes\nbut only hits the enemy\nin the front.. try it out!"
  l1.ssr = 120  //starting spawn rate in frames
  l1.ssn = 6    //starting spawn num of nmes
  l1.goal = "get 20 kills"
  l1.gtext = function(game)
    return "kills:" .. game.kills .. "/20"
  end
  l1.fc = function(game)
    return game.kills >= 20
  end
  add(lvls, l1)
  
  local l2 = {}
  l2.num = 2
  l2.money = 350
  l2.nmes = { "buggy" }
  l2.twrs = { "scatter" }
  l2.name = "lesson 2"
  l2.desc = "the scatter shot does\nweak damage and only hits\nclose enemies but it's\ncheap!!! try it out!"
  l2.ssr = 120
  l2.ssn = 5
  l2.goal = "get 20 kills"
  l2.gtext = function(game)
    return "kills:" .. game.kills .. "/20"
  end
  l2.fc = function(game)
    return game.kills >= 20
  end
  add(lvls, l2)
  
  local l3 = {}
  l3.num = 3
  l3.money = 700
  l3.nmes = { "tank" }
  l3.twrs = { "laser" }
  l3.name = "lesson 3"
  l3.desc = "the laser fires very\nslow but it does\nmega damage! try it out!"
  l3.ssr = 240
  l3.ssn = 3
  l3.goal = "get 5 kills"
  l3.gtext = function(game)
    return "kills:" .. game.kills .. "/5"
  end
  l3.fc = function(game)
    return game.kills >= 5
  end
  add(lvls, l3)
  
  local l4 = {}
  l4.num = 4
  l4.money = 1000
  l4.nmes = { "droid", "buggy", "mech" }
  l4.twrs = { "gatling", "scatter" }
  l4.name = "lesson 4"
  l4.desc = "you can choose what tower\nto place using the ⬆️\nand ⬇️ keys. try it out!"
  l4.ssr = 180
  l4.ssn = 5
  l4.goal = "get 20 kills"
  l4.gtext = function(game)
    return "kills:" .. game.kills .. "/20"
  end
  l4.fc = function(game)
    return game.kills > 20
  end
  add(lvls, l4)
  
  local l5 = {}
  l5.num = 5
  l5.money = 250
  l5.nmes = { "droid", "buggy", "mech" }
  l5.twrs = { "gatling", "scatter", "laser" }
  l5.name = "lesson 5"
  l5.desc = "you have to spend money\nto make money! every\ntower costs to build and\nhas limited ammo but\nevery kill earns you $$$!"
  l5.ssr = 240
  l5.ssn = 5
  l5.goal = "have $1000"
  l5.gtext = function(game)
    return "money:$" .. game.money .. "/1000"
  end
  l5.fc = function(game)
    return game.money >= 1000
  end
  add(lvls, l5)
  
  local l6 = {}
  l6.num = 6
  l6.money = 400
  l6.nmes = { "droid", "buggy" }
  l6.twrs = { "gatling", "scatter", "laser" }
  l6.name = "challenge 1"
  l6.desc = "your first real challenge!\nyou have access to all\ntowers and fast enemies\nwill be gunning for you!"
  l6.ssr = 180
  l6.ssn = 4
  l6.goal = "survive 2 minutes"
  l6.gtext = function(game)
    return "time:" .. flr(game.sec) .. "/120"
  end
  l6.fc = function(game)
    return game.sec >= 120
  end
  add(lvls, l6)
  
  local l7 = {}
  l7.num = 7
  l7.money = 400
  l7.nmes = { "mech", "laser" }
  l7.twrs = { "gatling", "scatter", "laser" }
  l7.name = "challenge 2"
  l7.desc = "how will you deal with\nonly tanky enemies??"
  l7.ssr = 240
  l7.ssn = 3
  l7.goal = "survive 2 minutes!"
  l7.gtext = function(game)
    return "time:" .. flr(game.sec) .. "/120"
  end
  l7.fc = function(game)
    return game.sec >= 120
  end
  l7.slogic = function(game)
    local m1 = flr(rnd(2)) + 1
    local t1 = flr(rnd(3)) + 3
    local m2 = flr(rnd(2)) + 6
    create_nme(m1,"mech")
    create_nme(t1,"tank")
    create_nme(m2,"mech")
  end
  add(lvls, l7)
  
  local l8 = {}
  l8.num = 8
  l8.money = 250
  l8.nmes = { "buggy" }
  l8.twrs = { "gatling", "scatter", "laser" }
  l8.name = "challenge 3"
  l8.desc = "here comes the fast\nand furious skulls!"
  l8.ssr = 50
  l8.ssn = 5
  l8.goal = "get 150 kills"
  l8.gtext = function(game)
    return "kills:" .. game.kills .. "/150"
  end
  l8.fc = function(game)
    return game.kills >= 150
  end
  l8.slogic = function(game)
    create_nme(1,"buggy")
    create_nme(2,"buggy")
    create_nme(3,"buggy")
    create_nme(4,"buggy")
    create_nme(5,"buggy")
    create_nme(6,"buggy")
    create_nme(7,"buggy")
  end
  add(lvls, l8)

  local l9 = {}
  l9.num = 9
  l9.money = 400
  l9.nmes = { "mech", "droid" }
  l9.twrs = { "gatling", "scatter", "laser" }
  l9.name = "challenge 4"
  l9.desc = "can you handle waves\nof all mechanized enemies?"
  l9.ssr = 180
  l9.ssn = 4
  l9.goal = "get 75 kills"
  l9.gtext = function(game)
    return "kills:" .. game.kills .. "/75"
  end
  l9.fc = function(game)
    return game.kills >= 75
  end
  add(lvls, l9)

  local l10 = {}
  l10.num = 10
  l10.money = 800
  l10.nmes = { "mech", "droid", "tank", "buggy" }
  l10.twrs = { "gatling", "scatter", "laser" }
  l10.name = "endless!"
  l10.desc = "this is the final challenge!\nthere is no time limit, you\nmust simply last as long as\npossible!"
  l10.ssr = 50
  l10.ssn = 5
  l10.goal = "stay alive!"
  l10.gtext = function(game)
    return flr(game.sec) .. " sec"
  end
  l10.fc = function(game)
    return false
  end
  add(lvls, l10)

end
-->8
//misc functions

function reset_level()
  game.fsls = 0 //frames since last enemy spawn
  game.sr = 999 //enemy spawn rate in frames
  game.sn = 0   //number of enemies per spawn
  game.money = 0
  game.frm = 0  //frames since lvl start
  game.sec = 0  //seconds since lvl start
  game.kills = 0
end

function show_screen(s)
  //screen types
  //"title" - title screen
  //"intro" - level intro
  //"game" - gameplay
  //"win" - player won
  //"lose" - game over
  game.curscreen = s
end

function load_level(l)
  nmes = {}
  twrs = {}
  hits = {}
  reset_level()
  
  if l != nil then
    game.curlvl = lvls[l]
  end  
    
  csel = 1
  cpos = 0
  game.sr = game.curlvl.ssr
  game.sn = game.curlvl.ssn
  game.money = game.curlvl.money
end

function get_random_etype()
  local values = {}
  
  for i, tname in ipairs(game.curlvl.nmes) do
    local t = etypes[tname]
    add(values, t)
  end
  return values[flr(rnd(#values)) + 1]
end

function create_nme(lane, nme_type)
  if lane == nil then
    lane = flr(rnd(7)) + 1
  end

  local t
  if nme_type == nil then
    t = get_random_etype()
  else
    t = etypes[nme_type]
  end
  
  local e = {}
  e.lane = lane 
  e.hp = t.hp      
  e.y = -4
  e.type = t
  e.ammo = t.ammo
  e.i = t.i      //key sprite
  e.ftm = t.ftm  //frames to move
  e.cftm = t.ftm //current frames to move
  add(nmes, e)
end

function create_twr(lane, tt)
  if game.money < ttypes[tt].cost then
    return
  end
  
  //delete any tower already in this spot
  for i=1,#twrs do
    local t = twrs[i]
    if t.lane == lane then
      del(twrs, t)
      break
    end
  end
  
  //create new tower
  local t = {}  
  t.type = ttypes[tt]
  t.lane = lane
  t.y = 120
  t.tsf = 0
  t.ammo = t.type.ammo
  t.firing = false
  add(twrs, t)
  
  game.money -= t.type.cost
end

function fire_towers()
  for i=1,#twrs do
    local t = twrs[i]
    t.tsf = max(t.tsf - 1, 0)
    if t.tsf <= 0 and t.type.has_targets(t) then
      t.firing = true
      t.tsf = t.type.rof
      t.type.deal_damage(t)
      t.ammo -= 1
      sfx(t.type.s, 1)
    elseif t.tsf <= t.type.rof - 5 then
      t.firing = false
    end
  end
end

function move_enemies()
  for i=1,#nmes do
    local e = nmes[i]
    e.cftm = e.cftm - 1
    if e.cftm <= 0 then
      e.y = e.y + 4
      e.cftm = e.ftm
    end
  end
end

function print_shadowed(t,x,y)
  print(t,x,y,0)
  print(t,x+1,y+1,7)
end

function create_hit(e,i,l,d)
  local h = {}
  h.lane = e.lane
  h.y = e.y
  h.i = i
  h.lifetime = l
  add(hits, h)
     
  e.hp -= d   
  check_nme_death(e)
end

function spawn_enemies()
  if game.curlvl.slogic == nil then
  		for i=1,game.sn do
  		  create_nme()
    end
  else
    game.curlvl.slogic(game)
  end
end
__gfx__
00000000000000000000000000000898000088980000004000000400000000000000000000000000000000000000000000000000000000000000000000000000
0000000000d000000d000000000899a9008999a80099990000999900000cc000000cc00000000000000888880000000000000000000000000000000000000000
0070070000d0000000d000000777779807777798095666900956669000cc2c0000cc2c0000000000008000008800000000000080000000000000000000000000
00077000000dddd2000dddd2007707980077079009495690094596900c0cc0c00c0cc0c000000000008000000880080008000088888800088888800088888000
0007700000dddd0000dddd0007777780077777800945969009495690050cc0dd050cc0d000000000008000000000080008000080000800088000800080008000
00700700055555500555555000676880006768004944459449444594000ee000000ee00d00000000008800000000080008000880000880008000000080008800
0000000056767675576767650076700000000000409999044099990400e00e00000e0e0000000000000888888000080008000880000080008000000080000800
000000000555555005555550000000000076700040000040040000040e00e00000e00e0000000000000000008000080008000880000880008888800080008800
0000000000cc8008000000006009a005000000000009a00000000000000000000000000000000000000000000800080008000880000800008000000088880000
00000000c00c880000000000059a9a00000660000a8a99a000000000000000000006600000000000000880000800080008800888888800008000000088880000
000000000c0c80800067670000767606000660000096680000000000006565000006600000000000000088000800080008800880000000008800000008088000
00055000000550000067670050767650000550000005500000055000006565000005500000000000000008888800088088000880000000008888000008008000
00222200002222000067670000767600005555000055550000555500006565000055550000000000000000000000008880000880000c00000000888008000800
02266220022662200dddddd00dddddd0004444000044440005566550055555500055550000000000000000000000000000000880000c00000000000008000880
026256200262562088888888888888880046540000465400056556505555555500555500000000000cccccccccccc00000000000000c00ccccccc00000000000
2222222222222222a98a98a9a98a98a90046540000465400555555555555555500555500000000000000c00000000000c0000000000cc0cc0000000ccccccc00
c00c0008000000000a0080000000000000a0540000000000000000000000000000000000000000000000c000ccccc000c00000000000c00c000c000c00000c00
0c00c080000000000000090a000000004500008500000000000000000000000000000000000000000000c000c000cc00cc0000c00000c00ccccc000c0000cc00
00c008000000000000908000000000000005000000000000000000000000000000000000000000000000c000c0000c000c0000c0000cc00c0000000ccc0cc000
0808c00c000000000008800000000000508004a000000000000000000000000000000000000000000000c000c0000c000c0000c0000c000c0000000ccccc0000
800c80c0000000000008089000000000090a005000000000000000000000000000000000000000000000c000cccccc000ccc0cccc0cc0000ccccc00c00ccc000
00c008000000000008090000000000000400900000000000000000000000000000000000000000000000000000000000000ccc000c0000000000000c0000cc00
0c08008000000000a000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000cc0
c000800800000000000080a00000000050805005000000000000000000000000000000000000000000bbbbbbb000000000000000000000000000000c00000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000bb00000000000000000bbb00000000000000000b
0000000000000000000000000000000000000000000000000000000000000000000000000000000000b0000000b000b000000000bbbb0000000000000000bbbb
0000000000000000000000000000000000000000000000000000000000000000000000000000000000b0000000b000bbbbbbb00bb000000000bbbb00bbb0b000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b00b00000000b00000bbbb0b00b0bb000b000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b00b00000000b00000b0000b00b0b0000b000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b00b00000000b00000b0000b00b0b0000b000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b00bbbbbb000bbbb00bbb00b00b0bb000bbb0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000b00b00000000b00000b0000b00b00bb000b00
0000000000000000000000000000000000000000000000000000000000000000000000000000000000b0000000bb00b00000000b00000b0000b00b0000bb0b00
0000000000000000000000000000000000000000000000000000000000000000000000000000000000b000000bb000b00000000b00000b0000b00b00000b0b00
0000000000000000000000000000000000000000000000000000000000000000000000000000000000b0000bb00000b00000000b00000b0000b00b00000b0b00
0000000000000000000000000000000000000000000000000000000000000000000000000000000000b000bb000000bbbbbbb00b00000bbb00b00b0000bb0b00
0000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbb0000000000000000b0000000000000b00bb000bbb
__sfx__
3f01000019050190501b0501c0501b040190501507000060000700006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d0200001b6441c6441d6441f6441f644000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000181521f1521d1520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002404329000280002d000280003000028000310002800037000280003b0002800028000280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110200018043240002a000320001a64329000300002300018043180431c000300001a6431a0002d0001f000180432d00017000300001a643000000000000000180430000018043000001a643000001c6431c643
011000002b143000002b14300000341430000000000000002b1432b143000002b1430000034143281430000024143000002414300000341430000000000000002b1432b143000002b14300000341432814300000
05100000233421f34200000000001c542000000000000000193420000000000000001f34200000213420000024342243420000000000233422334200000000002134221342000000000024442000000000000000
__music__
01 04454344
00 04054344
00 04054344
00 04064344
00 04064344
02 04050644

