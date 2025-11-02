pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
debug = true

nmes = {} //enemies
twrs = {} //towers
frm = 0   //frames since start
sec = 0   //seconds since start

etypes = {} //enemy types
lanes = {}  //game board lanes

function _init() 
  cls()
  init_types()
  
  create_nme(12, 12)
	 create_nme(28, 12)
  create_nme(44, 12)
  create_nme(60, 12)
  create_nme(76, 12)
  create_nme(92, 12)
  create_nme(108, 12)
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
  for x=1,#nmes do
    e = nmes[x]
    if sec % 2 == 0 then
      cf = e.i
    else
      cf = e.i + 1
    end
    spr(cf, e.x, e.y)
  end
  
  //draw debug info
  if debug then
  		print("sec: ", 10, 10, 7)
  		print(sec, 28, 10, 7)
  
  		print("frm: ", 10, 20, 7)
  		print(frm, 28, 20, 7)
  end
end

function init_types()
  t1 = {}
  t1.name = "tank"
  t1.hp = 10
  t1.ftm = 100
  t1.i = 1
  etypes[t1.name] = t1
  
  t2 = {}
  t2.name = "buggy"
  t2.hp = 3
  t2.ftm = 35
  t2.i = 3
  etypes[t2.name] = t2
  
  t3 = {}
  t3.name = "droid"
  t3.hp = 5
  t3.ftm = 70
  t3.i = 5
  etypes[t3.name] = t3
    
  t4 = {}
  t4.name = "mech"
  t4.hp = 6
  t4.ftm = 45
  t4.i = 7
  etypes[t4.name] = t4
end

function get_random_etype()
  local values = {}
  for _, v in pairs(etypes) do
    add(values, v)
  end
  return values[flr(rnd(#values)) + 1]
end

function create_nme(x,y)
  t = get_random_etype()
  e = {}
  e.x = x        
  e.y = y
  e.i = t.i      //key sprite
  e.ftm = t.ftm  //frames to move
  e.cftm = t.ftm //current frames to move
  add(nmes, e)
end

function move_enemies()
  for x=1,#nmes do
    e = nmes[x]
    e.cftm = e.cftm - 1
    if e.cftm <= 0 then
      e.y = e.y + 4
      e.cftm = e.ftm
    end
  end
end
__gfx__
00000000000000000000000000000000000000000000004000000400000000000000000000000000000000000000000000000000000000000000000000000000
0000000000d000000d00000000222000002220000099990000999900000cc000000cc00000000000000000000000000000000000000000000000000000000000
0070070000d0000000d000000025500000255000095666900956669000cc2c0000cc2c0000000000000000000000000000000000000000000000000000000000
00077000000dddd2000dddd2222222202222222009495690094596900c0cc0c00c0cc0c000000000000000000000000000000000000000000000000000000000
0007700000dddd0000dddd002222222a2222222a0945969009495690050cc0dd050cc0d000000000000000000000000000000000000000000000000000000000
00700700055555500555555052522252252225254944459449444594000ee000000ee00d00000000000000000000000000000000000000000000000000000000
0000000056767675576767650600056556500060409999044099990400e00e00000e0e0000000000000000000000000000000000000000000000000000000000
000000000555555005555550505000500500050540000040040000040e00e00000e00e0000000000000000000000000000000000000000000000000000000000
