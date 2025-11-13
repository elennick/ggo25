pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
debug = true

nmes = {} //enemies
twrs = {} //towers
game = {} //game info
frm = 0   //frames since start
sec = 0   //seconds since start

etypes = {} //enemy types
ttypes = {} //tower types
lanes = {}  //game board lanes

function _init() 
  cls()
  init_nme_types()
  init_twr_types()
  
  game.fsls = 0 //frames since last enemy spawn
  game.sr = 150 //enemy spawn rate in frames
  game.sn = 2   //number of enemies per spawn

	 create_nme(2)
  create_nme(3)
  create_nme(5)
  create_nme(7)
  
  create_twr(1, "gatling")
  create_twr(2, "spread")
  create_twr(3, "laser")
  create_twr(4, "gatling")
  create_twr(5, "laser")
  create_twr(6, "spread")
  create_twr(7, "gatling")
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
end

function _draw()
  cls()
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
    local ey = e.y 
    spr(cf, ex, ey)
    if debug then
      print(e.hp, ex, ey + 8, 7)
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
  
  //draw debug info
  if debug then
  		print("sec: ", 10, 10, 7)
  		print(sec, 28, 10, 7)
  
  		print("frm: ", 10, 20, 7)
  		print(frm, 28, 20, 7)
  end
end

function get_random_etype()
  local values = {}
  for _, v in pairs(etypes) do
    add(values, v)
  end
  return values[flr(rnd(#values)) + 1]
end

function create_nme(lane)
  if lane == nil then
    lane = flr(rnd(6)) + 1
  end

  local t = get_random_etype()
  local e = {}
  e.lane = lane 
  e.hp = t.hp      
  e.y = 12
  e.type = t
  e.i = t.i      //key sprite
  e.ftm = t.ftm  //frames to move
  e.cftm = t.ftm //current frames to move
  add(nmes, e)
end

function create_twr(lane, tt)
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
//init functions below

function init_nme_types()
  local t1 = {}
  t1.name = "tank"
  t1.hp = 250
  t1.ftm = 80
  t1.i = 1
  etypes[t1.name] = t1
  
  local t2 = {}
  t2.name = "buggy"
  t2.hp = 75
  t2.ftm = 25
  t2.i = 3
  etypes[t2.name] = t2
  
  local t3 = {}
  t3.name = "droid"
  t3.hp = 100
  t3.ftm = 55
  t3.i = 5
  etypes[t3.name] = t3
    
  local t4 = {}
  t4.name = "mech"
  t4.hp = 150
  t4.ftm = 35
  t4.i = 7
  etypes[t4.name] = t4
end

function init_twr_types()
  //single target, med damage
  //can shoot into neighbor rows
  local t1 = {}
  t1.name = "gatling"
  t1.range = 1
  t1.i = 18
  t1.dmg = 2
  t1.rof = 10 //frames, lower is better
  t1.deal_damage = function(twr)
    for i, e in ipairs(nmes) do
      if abs(twr.lane - e.lane) <= t1.range then
        e.hp -= t1.dmg
      end
      if e.hp <= 0 then
        del(nmes, e)
      end
    end
  end
  t1.has_targets = function(twr)
    return true
  end
  ttypes[t1.name] = t1
  
  //single target, high damage
  //but only targets same row
  local t2 = {}
  t2.name = "laser"
  t2.range = 0
  t2.i = 16
  t2.dmg = 10
  t2.rof = 40
  t2.deal_damage = function(twr)
    for i, e in ipairs(nmes) do
      if abs(twr.lane - e.lane) <= t2.range then
        e.hp -= t2.dmg
      end
      if e.hp <= 0 then
        del(nmes, e)
      end
    end  
  end
  t2.has_targets = function(twr)
    return true
  end
  ttypes[t2.name] = t2
  
  //aoe, low damage
  //can hit every row
  local t3 = {}
  t3.name = "spread"
  t3.range = 6
  t3.i = 20
  t3.dmg = 1
  t3.rof = 25
  t3.deal_damage = function(twr)
    for i, e in ipairs(nmes) do
      e.hp -= t3.dmg
      if e.hp <= 0 then
        del(nmes, e)
      end
    end 
  end
  t3.has_targets = function(twr)
    return true
  end
  ttypes[t3.name] = t3
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
0000000000098000000000006009a00500000000c1cd1d1c00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000009800000000000059a9a000000000000dcc10000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000980000067670000767606300e8003300d100300000000000000000000000000000000000000000000000000000000000000000000000000000000
0001100000011000006767005076765033eee83333eee83300000000000000000000000000000000000000000000000000000000000000000000000000000000
0022220000222200006767000076760003eee83003eee83000000000000000000000000000000000000000000000000000000000000000000000000000000000
02266220022662200dddddd00dddddd000bbb30000bbb30000000000000000000000000000000000000000000000000000000000000000000000000000000000
02625620026256208888888888888888000b3000000b300000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222a98a98a9a98a98a9000b3000000b300000000000000000000000000000000000000000000000000000000000000000000000000000000000
