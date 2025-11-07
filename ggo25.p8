pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
debug = true

nmes = {} //enemies
twrs = {} //towers
frm = 0   //frames since start
sec = 0   //seconds since start

etypes = {} //enemy types
ttypes = {} //tower types
lanes = {}  //game board lanes

function _init() 
  cls()
  init_nme_types()
  init_twr_types()
  
	 create_nme(2)
  create_nme(3)
  create_nme(5)
  create_nme(7)
  
  create_twr(1, "gatling")
  create_twr(2, "laser")
  create_twr(3, "spread")
  create_twr(4, "laser")
  create_twr(5, "gatling")
  create_twr(6, "spread")
  create_twr(7, "gatling")
end

function _update()
		frm = frm + 1
  sec = flr(time())
  
  move_enemies()
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
    spr(cf, (e.row * 16) - 4, e.y)
  end
  
  //draw towers
  for i=1,#twrs do
  		local t = twrs[i]
    spr(t.type.i, (t.row * 16) - 4, 120)
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

function create_nme(row)
  local t = get_random_etype()
  local e = {}
  e.row = row        
  e.y = 12
  e.type = t
  e.i = t.i      //key sprite
  e.ftm = t.ftm  //frames to move
  e.cftm = t.ftm //current frames to move
  add(nmes, e)
end

function create_twr(row, tt)
  local tower = {}  
  tower.type = ttypes[tt]
  tower.row = row
  tower.y = 120
  add(twrs, tower)
end

function move_enemies()
  for x=1,#nmes do
    local e = nmes[x]
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
  t1.hp = 10
  t1.ftm = 100
  t1.i = 1
  etypes[t1.name] = t1
  
  local t2 = {}
  t2.name = "buggy"
  t2.hp = 3
  t2.ftm = 35
  t2.i = 3
  etypes[t2.name] = t2
  
  local t3 = {}
  t3.name = "droid"
  t3.hp = 5
  t3.ftm = 70
  t3.i = 5
  etypes[t3.name] = t3
    
  local t4 = {}
  t4.name = "mech"
  t4.hp = 6
  t4.ftm = 45
  t4.i = 7
  etypes[t4.name] = t4
end

function init_twr_types()
  //single target, med damage
  //can shoot into neighbor rows
  local t1 = {}
  t1.name = "gatling"
  t1.range = 1
  t1.i = 16
  t1.dmg = 10
  t1.rof = 10
  ttypes[t1.name] = t1
  
  //single target, high damage
  //but only targets same row
  local t2 = {}
  t2.name = "laser"
  t2.range = 0
  t2.i = 18
  t2.dmg = 50
  t2.rof = 20
  ttypes[t2.name] = t2
  
  //aoe, low damage
  //can hit every row
  local t3 = {}
  t3.name = "spread"
  t3.range = 6
  t3.i = 20
  t3.dmg = 5
  t3.rof = 5
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
0000000060a9a9060000000050a9a905000000000dcccc1000000000000000000000000000000000000000000000000000000000000000000000000000000000
000650000606506000000000500a90500000000000dcc10000000000000000000000000000000000000000000000000000000000000000000000000000000000
00065000000650000067670005767650300e8003300d100300000000000000000000000000000000000000000000000000000000000000000000000000000000
0022220000222200006767000076760033eee83333eee83300000000000000000000000000000000000000000000000000000000000000000000000000000000
0222222002222220006767000076760003eee83003eee83000000000000000000000000000000000000000000000000000000000000000000000000000000000
02266220022662200dddddd00dddddd000bbb30000bbb30000000000000000000000000000000000000000000000000000000000000000000000000000000000
22625622226256228888888888888888000b3000000b300000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222a98a98a9a98a98a9000b3000000b300000000000000000000000000000000000000000000000000000000000000000000000000000000000
