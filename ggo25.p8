pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
debug = false

nmes = {} //enemies
twrs = {} //towers
lvls = {} //levels
hits = {} //hit animations
game = {} //game info
frm = 0   //frames since start
sec = 0   //seconds since start

cpos = 0  //cursor position (lane)

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
  
  game.fsls = 0 //frames since last enemy spawn
  game.sr = 100 //enemy spawn rate in frames
  game.sn = 5   //number of enemies per spawn
  game.score = 0
  game.money = 0
  game.curlvl = nil

  load_level(1)
end

function _update()
		frm += 1
  sec = flr(time())
  
  game.fsls += 1
  if game.fsls > game.sr then
  		for i=1,game.sn do
    		create_nme()
    end
    game.fsls = 0
  end
  
  move_enemies()
  fire_towers()
  
  for i,h in ipairs(hits) do
	 		if h.lifetime <= 0 then
	 		  del(hits, h)
	 		end
	 end
	 
	 if btnp(1) then
	   cpos = min(cpos + 1, 6)
	 elseif  btnp(0) then
	   cpos = max(cpos - 1, 0)
	 end
	 
	 if btnp(4) or btnp(5) then
	   create_twr(cpos + 1, "gatling")
	 end
end

function _draw()
  cls(1)
  
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
  		spr(i, (t.lane * 16) - 4, 120)
	 end
	 
	 //draw hits
	 for i=1,#hits do
	   local h = hits[i]
	   spr(h.i, h.lane * 16 - 4, h.y)
	   h.lifetime -= 1
	 end

  //draw score/money
  print("score: ", 4, 4, 0)
  print(game.score, 28, 4, 0)
  print("score: ", 5, 5, 7)
  print(game.score, 29, 5, 7)
  
  print("money:$", 4, 14, 0)
  print(game.money, 33, 14, 0)
  print("money:$", 5, 15, 7)
  print(game.money, 34, 15, 7)
  
  //draw cursor
  rect((cpos * 16) + 8, 111, (cpos * 16) + 23, 127, 11)
  
  //draw debug text
  if debug then
  		print("sec: ", 10, 10, 7)
  		print(sec, 28, 10, 7)
  
  		print("frm: ", 10, 20, 7)
  		print(frm, 28, 20, 7)
  end
end

function load_level(l)
  game.curlvl = lvls[l]
  game.money = lvls[l].money
end

function get_random_etype()
  local values = {}
  
  for i, tname in ipairs(game.curlvl.nmes) do
    local t = etypes[tname]
    add(values, t)
  end
  return values[flr(rnd(#values)) + 1]
end

function create_nme(lane)
  if lane == nil then
    lane = flr(rnd(7)) + 1
  end

  local t = get_random_etype()
  local e = {}
  e.lane = lane 
  e.hp = t.hp      
  e.y = -8
  e.type = t
  e.i = t.i      //key sprite
  e.ftm = t.ftm  //frames to move
  e.cftm = t.ftm //current frames to move
  add(nmes, e)
end

function create_twr(lane, tt)
  for i=1,#twrs do
    local t = twrs[i]
    if t.lane == lane then
      return
    end
  end

  local t = {}  
  t.type = ttypes[tt]
  t.lane = lane
  t.y = 120
  t.tsf = t.type.rof
  t.firing = false
  add(twrs, t)
end

function fire_towers()
  for i=1,#twrs do
    local t = twrs[i]
    t.tsf -= 1
    if t.tsf <= 0 and t.type.has_targets(t) then
      t.firing = true
      t.tsf = t.type.rof
      t.type.deal_damage(t)
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
-->8
//init types below

function init_nme_types()
  local t1 = {}
  t1.name = "tank"
  t1.hp = 250
  t1.ftm = 80
  t1.i = 1
  t1.value = 25
  etypes[t1.name] = t1
  
  local t2 = {}
  t2.name = "buggy"
  t2.hp = 75
  t2.ftm = 25
  t2.i = 3
  t2.value = 15
  etypes[t2.name] = t2
  
  local t3 = {}
  t3.name = "droid"
  t3.hp = 100
  t3.ftm = 55
  t3.i = 5
  t3.value = 20
  etypes[t3.name] = t3
    
  local t4 = {}
  t4.name = "mech"
  t4.hp = 150
  t4.ftm = 35
  t4.i = 7
  t4.value = 10
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
  t1.dmg = 2
  t1.rof = 20 //frames, lower is better
  t1.deal_damage = function(twr)
    for i, e in ipairs(nmes) do
      if abs(twr.lane - e.lane) <= t1.range then
        h = {}
        h.lane = e.lane
        h.y = e.y
        h.i = 34
        h.lifetime = 4
        add(hits, h)
     
        e.hp -= t1.dmg   
        check_nme_death(e)
      end
    end
  end
  t1.has_targets = function(twr)
    return true
  end
  ttypes[t1.name] = t1
  
  //single target, high damage
  //but only targets same row
  //penetrates the whole lane
  local t2 = {}
  t2.name = "laser"
  t2.range = 0
  t2.i = 16
  t2.dmg = 10
  t2.rof = 75
  t2.deal_damage = function(twr)
    for i, e in ipairs(nmes) do
      if abs(twr.lane - e.lane) <= t2.range then
        h = {}
        h.lane = e.lane
        h.y = e.y
        h.i = 32
        h.lifetime = 15
        add(hits, h)
        
        e.hp -= t2.dmg
        check_nme_death(e)
      end
    end  
  end
  t2.has_targets = function(twr)
    return true
  end
  ttypes[t2.name] = t2
  
  //aoe, low damage
  //can hit every enemy in every row
  local t3 = {}
  t3.name = "scatter"
  t3.range = 2
  t3.i = 20
  t3.dmg = 1
  t3.rof = 25
  t3.deal_damage = function(twr)
    for i, e in ipairs(nmes) do
      local inrange = abs(twr.lane - e.lane) and e.y > 50
      if inrange then
        h = {}
        h.lane = e.lane
        h.y = e.y
        h.i = 36
        h.lifetime = 10
        add(hits, h)
        
        e.hp -= t3.dmg
        check_nme_death(e)
      end
    end 
  end
  t3.has_targets = function(twr)
    return true
  end
  ttypes[t3.name] = t3
end 

function check_nme_death(e)
  if e.hp <= 0 then
    game.score += e.type.value
    del(nmes, e)
  end
end

function init_levels()
  local l1 = {}
  l1.money = 100
  l1.nmes = { "mech", "buggy" }
  l1.twrs = { "gatling" }
  add(lvls, l1)
end
__gfx__
00000000000000000000000000000898000088980000004000000400000000000000000000000000000000000000000000000000000000000000000000000000
0000000000d000000d000000000899a9008999a80099990000999900000cc000000cc00000000000000000000000000000000000000000000000000000000000
0070070000d0000000d000000777779807777798095666900956669000cc2c0000cc2c0000000000000000000000000000000000000000000000000000000000
00077000000dddd2000dddd2007707980077079009495690094596900c0cc0c00c0cc0c000000000000000000000000000000000000000000000000000000000
0007700000dddd0000dddd0007777780077777800945969009495690050cc0dd050cc0d000000000000000000000000000000000000000000000000000000000
00700700055555500555555000676880006768004944459449444594000ee000000ee00d00000000000000000000000000000000000000000000000000000000
0000000056767675576767650076700000000000409999044099990400e00e00000e0e0000000000000000000000000000000000000000000000000000000000
000000000555555005555550000000000076700040000040040000040e00e00000e00e0000000000000000000000000000000000000000000000000000000000
00000000000c8000000000006009a005000000008989a89800000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000c800000000000059a9a00000660000a8669a000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000c80000067670000767606000660000096680000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055000000550000067670050767650000550000005500000000000000000000000000000000000000000000000000000000000000000000000000000000000
00222200002222000067670000767600005555000055550000000000000000000000000000000000000000000000000000000000000000000000000000000000
02266220022662200dddddd00dddddd0004444000044440000000000000000000000000000000000000000000000000000000000000000000000000000000000
02625620026256208888888888888888004654000046540000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222a98a98a9a98a98a9004654000046540000000000000000000000000000000000000000000000000000000000000000000000000000000000
c00c0008000000000a00800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c00c080000000000000090a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c00800000000000090800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0808c00c000000000008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
800c80c0000000000008089000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c00800000000000809000000000000a000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c08008000000000a000000000000000890000980000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c000800800000000000080a00000000008a99a800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
