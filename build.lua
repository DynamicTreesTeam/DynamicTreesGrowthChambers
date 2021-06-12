----------------------------------------------------------------
-- MISC                                                       --
----------------------------------------------------------------

function stateTagString(state, tag)
  return state.block .. "[" .. state.data .. "]" .. "{" .. tag .. "}";
end

function stateString(state)
  return stateTagString(state, "");
end

----------------------------------------------------------------
-- TABLES                                                     --
----------------------------------------------------------------

function tableDump(t)
  print(textutils.serialize(t));
end

function testValues(t)
  local test = {};
  for i,e in pairs(t) do
    test[e] = true;
  end
  return test;
end

function fif(cond, a, b)
  if cond then
    return a;
  else
    return b;
  end
end

----------------------------------------------------------------
-- ERASE OR CREATE                                            --
----------------------------------------------------------------

erase = false;

function setErase(should)
  erase = should;
end

----------------------------------------------------------------
-- SYNC or ASYNC                                              --
----------------------------------------------------------------

sync = false;

function setSync(should)
  sync = should;
end

asyncCalled = false;

function wait()
  os.pullEvent("task_complete");
end

function waitAsync()
  if asyncCalled then
	wait();
	asyncCalled = false;
  end
end

----------------------------------------------------------------
-- COORDINATES                                                --
----------------------------------------------------------------

Coord = {}
Coord.__index = Coord;

function Coord:new(x, y, z)
    local coord = {}             -- our new object
    setmetatable(coord, Coord)  -- make Account handle lookup
    -- initialize our object
    coord.x = x;
    coord.y = y;
    coord.z = z;
   return coord
end

function coord(...)
  if #arg == 3 then return Coord:new(arg[1], arg[2], arg[3]); end
  return Coord:new(0, 0, 0);
end

function Coord:__tostring()
  return "coord: [" ..
    self.x .. ", " ..
    self.y .. ", " ..
    self.z .. "]";
end

function Coord:cpy()
  return Coord:new(self.x, self.y, self.z);
end

function Coord:scale(amount)
  return Coord:new(self.x * amount, self.y * amount, self.z * amount);
end

function Coord:print()
  print(self);
  return self;
end

function Coord:get()
  local x, y, z = commands.getBlockPosition();
  return Coord:new(x, y, z);
end

function Coord:add(c)
  return Coord:new(self.x + c.x, self.y + c.y, self.z + c.z);
end

function Coord:sub(c)
  return Coord:new(self.x - c.x, self.y - c.y, self.z - c.z);
end

function Coord:mul(c)
  return Coord:new(self.x * c.x, self.y * c.y, self.z * c.z);
end

function Coord:rot(qturns, a)
  qturns = qturns or 1;
  local c = self;
  if a ~= nil then c = c:sub(a); end
  qturns = qturns % 4;
  if qturns == 0 then c = Coord:new( c.x, c.y,  c.z); end;
  if qturns == 1 then c = Coord:new(-c.z, c.y,  c.x); end;
  if qturns == 2 then c = Coord:new(-c.x, c.y, -c.z); end;
  if qturns == 3 then c = Coord:new( c.z, c.y, -c.x); end;
  if a ~= nil then c = c:add(a); end
  return c;
end

function Coord:mir(axis, a)
  local c = self;
  if a ~= nil then c = c:sub(a); end
  if axis.x ~= 0 then c = Coord:new(-c.x,  c.y,  c.z); end
  if axis.y ~= 0 then c = Coord:new( c.x, -c.y,  c.z); end
  if axis.z ~= 0 then c = Coord:new( c.x,  c.y, -c.z); end
  if a ~= nil then c = c:add(a); end
  return c;
end

function Coord:up(amount)
  return self:add(Coord:new(0, amount or 1, 0));
end

function Coord:dwn(amount)
  amount = amount or 1;
  return self:up(-amount);
end

function Coord:trn(turns, mirAxis, pos)
  return self:rot(turns or 0):mir(mirAxis or coord()):add(pos or coord());
end

function Coord:eq(other)
  return self.x == other.x and self.y == other.y and self.z == other.z;
end

----------------------------------------------------------------
-- DIRECTIONS                                                 --
----------------------------------------------------------------

AXIS = {
 X = Coord:new(1, 0, 0),
 Y = Coord:new(0, 1, 0),
 Z = Coord:new(0, 0, 1)
};

DIR = {
  D = {x =  0, y = -1, z =  0, n = "down", a = 'y'},
  U = {x =  0, y =  1, z =  0, n = "up", a = 'y'},
  N = {x =  0, y =  0, z = -1, n = "north", a = 'z'},
  S = {x =  0, y =  0, z =  1, n = "south", a = 'z'},
  W = {x = -1, y =  0, z =  0, n = "west", a = 'x'},
  E = {x =  1, y =  0, z =  0, n = "east", a = 'x'}
};
DIR.HORIZONTALS = { DIR.N, DIR.S, DIR.W, DIR.E };
DIR.OPPOSITES = { [DIR.N] = DIR.S, [DIR.S] = DIR.N, [DIR.W] = DIR.E, [DIR.E] = DIR.W };
DIR.ROTATE = { [DIR.D] = DIR.D, [DIR.U] = DIR.U, [DIR.N] = DIR.E, [DIR.S] = DIR.W, [DIR.W] = DIR.N, [DIR.E] = DIR.S };

function dirName(dir)
  return dir.n;
end

function dirLetter(dir)
  return string.sub(dirName(dir), 1, 1);
end

function dirAxis(dir)
  return dir.a;
end

function dirCoord(dir)
  return coord(dir.x, dir.y, dir.z);
end

function dirOpposite(dir)
  return DIR.OPPOSITES[dir];
end

function dirOppositeTable(dir)
  local r = {};
  for k,v in pairs(dirs) do
    r[k] = dirOpposite(v);
  end
  return r;
end

function dirRotate(dir, qturns)
  qturns = qturns or 1;
  qturns = qturns % 4;
  for i = 0, qturns - 1 do
    dir = DIR.ROTATE[dir];
  end
  return dir;
end

function dirRotateTable(dirs, qturns)
  local r = {};
  for k,v in pairs(dirs) do
    r[k] = dirRotate(v, qturns);
  end
  return r;
end

function dirMirror(dir, axis)
  if dir.a == axis then return dirOpposite(dir); end
  return dir;
end

function dirMirrorTable(dir, axis)
  local r = {};
  for k,v in pairs(dir) do
    r[k] = dirMirror(v, axis);
  end
  return r;
end

function dirMap(turns)
  turns = turns or 0;
  return
    dirRotate(DIR.D, turns),
    dirRotate(DIR.U, turns),
    dirRotate(DIR.N, turns),
    dirRotate(DIR.S, turns),
    dirRotate(DIR.W, turns),
    dirRotate(DIR.E, turns);
end

function Coord:off(dir, amount)
  dir = dir or DIR.U;
  amount = amount or 1;
  return self:add(coord(dir.x * amount, dir.y * amount, dir.z * amount));
end

----------------------------------------------------------------
-- BLOCKSTATES                                                --
----------------------------------------------------------------

function blockState(block, data)
  local a = {};
  a.block = block;
  a.data = data or "";
  return a;
end

function makeStairs(block, fillBlock)
  local s = {};
  s.n = blockState(block, "half=bottom,facing=north");
  s.s = blockState(block, "half=bottom,facing=south");
  s.w = blockState(block, "half=bottom,facing=west");
  s.e = blockState(block, "half=bottom,facing=east");
  s.ni = blockState(block, "half=top,facing=north");
  s.si = blockState(block, "half=top,facing=south");
  s.wi = blockState(block, "half=top,facing=west");
  s.ei = blockState(block, "half=top,facing=east");
  s.f = fillBlock;
  return s;
end

function makeSolidStairs(block, fillBlock)
  local s = {};
  s.n = block;
  s.s = block;
  s.w = block;
  s.e = block;
  s.ni = block;
  s.si = block;
  s.wi = block;
  s.ei = block;
  s.f = fillBlock;
  return s;
end

function makeSlabs(block)
  local s = {};
  s.t = blockState(block, "type=top");
  s.b = blockState(block, "type=bottom");
  return s;
end

air = blockState("minecraft:air");
stone = blockState("minecraft:stone");
stoneBrick = blockState("minecraft:stone_brick");
dirt = blockState("minecraft:dirt");
water = blockState("minecraft:water");

colFill = stone;
colBody = stone;
colHead = stone;
colFoot = stone;
colBase = stone;
colCrwn = stone;

tileOdd = stone;
tileEven = stone;

railing = stone;

stairs = makeStairs("minecraft:stone_brick_stairs");
slab = makeSlabs("minecraft:stone_slab");
smoothslab = makeSlabs("minecraft:stone_slab");


----------------------------------------------------------------
-- CUBOIDS                                                    --
----------------------------------------------------------------

function sort(v1, v2)
  if(v1 > v2) then return v2, v1; else return v1, v2; end
end

Cuboid = {}
Cuboid.__index = Cuboid;

function Cuboid:new(c1, c2)
  local cuboid = {};             -- our new object
  setmetatable(cuboid, Cuboid);  -- make handle lookup
  c1 = c1:cpy();
  c2 = c2:cpy();
  c1.x, c2.x = sort(c1.x, c2.x);
  c1.y, c2.y = sort(c1.y, c2.y);
  c1.z, c2.z = sort(c1.z, c2.z);
  cuboid[1] = c1;
  cuboid[2] = c2;
  return cuboid;
end

function cuboid(...)
  if #arg == 1 then return Cuboid:new(arg[1], arg[1]); end
  if #arg == 2 then return Cuboid:new(arg[1], arg[2]); end
  if #arg == 6 then return Cuboid:newAll(arg[1], arg[2], arg[3], arg[4], arg[5], arg[6]); end
  return Cuboid:newAll(0, 0, 0, 0, 0, 0);
end

function Coord:cub()
  return cuboid(self);
end

function Cuboid:__tostring()
  return "cuboid: [" ..
    self[1].x .. "," ..
    self[1].y .. "," ..
    self[1].z .. "," ..
    self[2].x .. "," ..
    self[2].y .. "," ..
    self[2].z .. "]";
end

function Cuboid:newAll(x1, y1, z1, x2, y2, z2)
  return Cuboid:new(Coord:new(x1, y1, z1), Coord:new(x2, y2, z2));
end

function Cuboid:print()
  print(self);
  return self;
end

function Cuboid:cpy()
  return Cuboid:new(self[1], self[2]);
end

function Cuboid:add(o)
  return Cuboid:new(self[1]:add(o), self[2]:add(o));
end

function Cuboid:sub(o)
  return Cuboid:new(self[1]:sub(o), self[2]:sub(o));
end

function Cuboid:rot(qturns, a)
  return Cuboid:new(self[1]:rot(qturns, a), self[2]:rot(qturns, a));
end

function Cuboid:mir(axis, a)
  return Cuboid:new(self[1]:mir(axis, a), self[2]:mir(axis, a));
end

function Cuboid:miriter(axis, a)
  result = {};
  result[0] = self:cpy();
  result[1] = mir(axis, a);
  return result;
end

function Cuboid:gro(dir, amount)
  amount = amount or 1;
  if dir == nil then
    return self:gro(coord(1, 1, 1), amount):gro(coord(-1, -1, -1), amount)
  end
  local c = self:cpy();
  if dir.x < 0 then c[1].x = c[1].x - amount; end
  if dir.y < 0 then c[1].y = c[1].y - amount; end
  if dir.z < 0 then c[1].z = c[1].z - amount; end
  if dir.x > 0 then c[2].x = c[2].x + amount; end
  if dir.y > 0 then c[2].y = c[2].y + amount; end
  if dir.z > 0 then c[2].z = c[2].z + amount; end
  return c;
end

function Cuboid:shr(dir, amount)
  amount = amount or 1;
  return self:gro(dir, -amount);
end

function Cuboid:off(dir, amount)
  dir = dir or DIR.U;
  amount = amount or 1;
  return self:add(coord(dir.x * amount, dir.y * amount, dir.z * amount));
end

function Cuboid:uni(c)
  return Cuboid:newAll(
    math.min(self[1].x, c[1].x),
    math.min(self[1].y, c[1].y),
    math.min(self[1].z, c[1].z),
    math.max(self[2].x, c[2].x),
    math.max(self[2].y, c[2].y),
    math.max(self[2].z, c[2].z)
  );
end

function Cuboid:fac(dir)
  local c = self:cpy();
  if dir.x > 0 then c = Cuboid:new(coord(c[2].x, c[1].y, c[1].z), c[2]); end
  if dir.y > 0 then c = Cuboid:new(coord(c[1].x, c[2].y, c[1].z), c[2]); end
  if dir.z > 0 then c = Cuboid:new(coord(c[1].x, c[1].y, c[2].z), c[2]); end
  if dir.x < 0 then c = Cuboid:new(c[1], coord(c[1].x, c[2].y, c[2].z)); end
  if dir.y < 0 then c = Cuboid:new(c[1], coord(c[2].x, c[1].y, c[2].z)); end
  if dir.z < 0 then c = Cuboid:new(c[1], coord(c[2].x, c[2].y, c[1].z)); end
  return c;
end

function Cuboid:cnr(c)
  return self:fac(Coord:new(-1, 0, -1):rot(c or 0));
end

function Cuboid:cnriter()
  corners = {};
  for c = 0,3 do
    corners[c] = self:cnr(c);
  end
  return pairs(corners);
end

function Cuboid:top()
  return self:fac(DIR.U);
end

function Cuboid:bot()
  return self:fac(DIR.D);
end

function Cuboid:up(amount)
  return self:off(DIR.U, amount);
end

function Cuboid:dwn(amount)
  return self:off(DIR.D, amount);
end

function Cuboid:trn(turns, mirAxis, pos)
  return self:rot(turns or 0):mir(mirAxis or coord()):add(pos or coord());
end

function Cuboid:dunswe(d, u, n, s, w, e, t)
  t = t or 0;
  return self
    :gro(dirRotate(DIR.D, t), d)
    :gro(dirRotate(DIR.U, t), u)
    :gro(dirRotate(DIR.N, t), n)
    :gro(dirRotate(DIR.S, t), s)
    :gro(dirRotate(DIR.W, t), w)
    :gro(dirRotate(DIR.E, t), e)
end

function Cuboid:grohor(amount)
  amount = amount or 1;
  return self:gro(coord(-1, 0, -1), amount):gro(coord(1, 0, 1), amount);
end

function Cuboid:shrhor(amount)
  amount = amount or 1;
  return self:grohor(-amount);
end

function Cuboid:mid()
  local x = math.floor((self[1].x + self[2].x) / 2);
  local y = math.floor((self[1].y + self[2].y) / 2);
  local z = math.floor((self[1].z + self[2].z) / 2);
  return Cuboid:newAll(x, y, z, x, y, z);
end

function Cuboid:pos()
  return self:mid()[1]:cpy();
end

function Cuboid:xlen()
  return self[2].x - self[1].x + 1;
end

function Cuboid:ylen()
  return self[2].y - self[1].y + 1;
end

function Cuboid:zlen()
  return self[2].z - self[1].z + 1;
end

function Cuboid:len(axis)
  if axis.x ~= 0 then return self:xlen(); end;
  if axis.y ~= 0 then return self:ylen(); end;
  if axis.z ~= 0 then return self:zlen(); end;
end

function Cuboid:vol()
  return self:xlen() * self:ylen() * self:zlen();
end

----------------------------------------------------------------
-- BLOCK SETTERS                                              --
----------------------------------------------------------------

function Coord:putnbt(state, tag)
  commands.setblock(self.x, self.y, self.z, stateTagString(state, tag), "replace");
  return self;
end

function Cuboid:fill(state)
  if state == nil then
    print("fill attempt for nil state: " .. tostring(self));
    state = air;
  end
  if erase then state = air; end
  
  if sync then
    com = commands;
  else
    com = commands.async;
	asyncCalled = true;
  end

  if self:vol() == 1 then
    com.setblock(self[1].x, self[1].y, self[1].z, stateString(state));
  else
    com.fill(self[1].x, self[1].y, self[1].z, self[2].x, self[2].y, self[2].z, stateString(state));
  end

  return self;
end

function Cuboid:dirt()
  return self:fill(dirt);
end

function Cuboid:erase()
  return self:fill(air);
end

function Cuboid:pillar(pBody, pFoot, pHead)
  self:fill(pBody or colBody);
  self:fac(DIR.D):fill(pFoot or colFoot);
  self:fac(DIR.U):fill(pHead or colHead);
  return self;
end

function Cuboid:checker()
  self:face(DIR.D):fill(tileOdd);
  for z = self[1].z, self[2].z do
    for x = self[1].x, self[2].x do
      if( ((x + z) % 2) == 0) then
        Coord:new(x, self[1].y, z):put(tileEven);
      end
    end
  end
  return self;
end

function Cuboid:fillcrn(state)
  for _,c in self:cnriter() do c:fill(state); end
  return self;
end

function Cuboid:loop(state, corners, sides)
  state = state or stone;
  sides = sides or {DIR.N, DIR.S, DIR.W, DIR.E};
  for _,side in pairs(sides) do
    local k = self:fac(side):fill(state);
    if(corners ~= nil) then k:fillcrn(corners); end
  end
  return self;
end

function Cuboid:fence(sides)
  sides = sides or {DIR.N, DIR.S, DIR.W, DIR.E};
  local work = self:bot();
  
  work:loop(stonerailing, stonerailing, sides);
  
  local xlen = work:len(AXIS.X) / 2;
  local zlen = work:len(AXIS.Z) / 2;
  local y = self[1].y + 1;
  
  for _,side in pairs(sides) do
    if(side == DIR.N) then
      for i = 0, xlen, 3 do
        coord(work[1].x + i, y, work[1].z):cub():fill(stonerailing);
        coord(work[2].x - i, y, work[1].z):cub():fill(stonerailing);
      end
    elseif(side == DIR.S) then
      for i = 0, xlen, 3 do
        coord(work[1].x + i, y, work[2].z):cub():fill(stonerailing);
        coord(work[2].x - i, y, work[2].z):cub():fill(stonerailing);
      end
    elseif(side == DIR.W) then
      for i = 0, zlen, 3 do
        coord(work[1].x, y, work[1].z + i):cub():fill(stonerailing);
        coord(work[1].x, y, work[2].z - i):cub():fill(stonerailing);
      end
    elseif(side == DIR.E) then
      for i = 0, zlen, 3 do
        coord(work[2].x, y, work[1].z + i):cub():fill(stonerailing);
        coord(work[2].x, y, work[2].z - i):cub():fill(stonerailing);
      end
    end
  end
  
end

function Cuboid:box(pFill, pBase, pCrwn, pBody, pFoot, pHead)
  self:fill(pFill or colFill); --Base Cuboid
  self:bot():loop(pBase or colBase); --Bottom Border
  self:top():loop(pCrwn or colCrwn); --Top Border
  for qturn = 0, 3 do
    self:cnr(qturn):pillar(pBody or colBody, pFoot or colFoot, pHead or colHead);
  end
  return self;
end

local rset2 = {
 { 0, 0 }, --1
 { 0, 0 }, --2
 { 0, 0, 1 }, --3
 { 0, 0, 0, 1 }, --4
 { 0, 0, 0, 1 }, --5
 { 0, 0, 0, 1, 1 }, --6
 { 0, 0, 0, 1, 1, 2 }, --7
 { 0, 0, 0, 1, 1, 2, 2 }, --8
 { 0, 0, 0, 0, 1, 1, 2 }, --9
 { 0, 0, 0, 0, 1, 1, 2, 3 }, --10
 { 0, 0, 0, 0, 1, 1, 2, 2, 3 }, --11
 { 0, 0, 0, 0, 1, 1, 2, 2, 3 }, --12
 { 0, 0, 0, 0, 1, 1, 1, 2, 3, 3 }, --13
 { 0, 0, 0, 0, 1, 1, 1, 2, 2, 3, 4 }, --14
 { 0, 0, 0, 0, 1, 1, 1, 2, 2, 3, 4 }, --15
 { 0, 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4 } --16
}

function Coord:cylinder(block, r, h, fill)
  h = h - 1;
  local sel = rset2[r];
  if fill then
    for i,d in ipairs(sel) do
      local x = r - d;
      local y = i - 1;
      cuboid(self):off(DIR.N, y):dunswe(0, h, 0, 0, x, x):fill(block);
      cuboid(self):off(DIR.N, x):dunswe(0, h, 0, 0, y, y):fill(block);
      cuboid(self):off(DIR.S, y):dunswe(0, h, 0, 0, x, x):fill(block);
      cuboid(self):off(DIR.S, x):dunswe(0, h, 0, 0, y, y):fill(block);
    end
  else
    for i,d in ipairs(sel) do
      local x = r - d;
      local y = i - 1;
      self:add(coord( x, 0,-y)):cub():gro(DIR.U, h):fill(block);
      self:add(coord(-x, 0,-y)):cub():gro(DIR.U, h):fill(block);
      self:add(coord( x, 0, y)):cub():gro(DIR.U, h):fill(block);
      self:add(coord(-x, 0, y)):cub():gro(DIR.U, h):fill(block);
      self:add(coord( y, 0,-x)):cub():gro(DIR.U, h):fill(block);
      self:add(coord(-y, 0,-x)):cub():gro(DIR.U, h):fill(block);
      self:add(coord( y, 0, x)):cub():gro(DIR.U, h):fill(block);
      self:add(coord(-y, 0, x)):cub():gro(DIR.U, h):fill(block);
    end
  end
  return self;
end

function Coord:circle(block, r, fill)
  self:cylinder(block, r, 1, fill);
  return self;
end


function getStairs(dir, inv, stairsblocks)
  stairsblocks = stairsblocks or stairs;
  inv = inv or false;
  return stairsblocks[dirLetter(dir) .. fif(inv, "i", "")];
end

function Cuboid:roof(stairBlocks, sides)
  sides = sides or DIR.HORIZONTALS;
  local xlen = self:len(AXIS.X);
  local zlen = self:len(AXIS.Z);
  
  test = testValues(sides);
  
  if(test[DIR.W] and test[DIR.E]) then xlen = math.floor(xlen / 2); end
  if(test[DIR.N] and test[DIR.S]) then zlen = math.floor(zlen / 2); end
  
  local h = math.min(xlen, zlen);
  
  if(#sides == 1) then
    local lens = {x = xlen, z = zlen};
    local axis = sides[next(sides)].a;
    h = lens[axis];
  end
  local p = self:fac(DIR.D); --get bottom face

  for i = 1, h do
    for _,side in pairs(sides) do
      p:fac(side):fill(stairBlocks[dirLetter(dirOpposite(side))]);
      if p:len(side) > 1 then
        p = p:gro(side, -1);
      end
    end
    p = p:up(); --move up one block
  end
  
  return self;
end


function Cuboid:stairs(stairBlocks, sides, filler)
  sides = sides or DIR.HORIZONTALS;
  filler = filler or stairBlocks.f;
  
  local xlen = self:len(AXIS.X);
  local zlen = self:len(AXIS.Z);
  
  test = testValues(sides);
  
  if(test[DIR.W] and test[DIR.E]) then xlen = math.floor(xlen / 2); end
  if(test[DIR.N] and test[DIR.S]) then zlen = math.floor(zlen / 2); end

  local h = math.min(xlen, zlen);
  
  if(#sides == 1) then
    local lens = {x = xlen, z = zlen};
    local axis = sides[next(sides)].a;
    h = lens[axis];
  end
  
  local p = self:fac(DIR.D); --get bottom face

  for i = 1, h do
    for _,side in pairs(sides) do
      p:fill(filler);
      p:fac(side):fill(stairBlocks[dirLetter(dirOpposite(side))]);
      if p:len(side) > 1 then
        p = p:gro(side, -1);
      end
    end
    p = p:up(); --move up one block
  end
  return self;
end


function Cuboid:stairsinv(stairBlocks, sides, filler)
  sides = sides or DIR.HORIZONTALS;
  filler = filler or stairBlocks.f;

  local xlen = self:len(AXIS.X);
  local zlen = self:len(AXIS.Z);
  
  test = testValues(sides);
  
  if(test[DIR.W] and test[DIR.E]) then xlen = math.floor(xlen / 2); end
  if(test[DIR.N] and test[DIR.S]) then zlen = math.floor(zlen / 2); end
  
  local h = math.min(xlen, zlen);

  if(#sides == 1) then
    local lens = {x = xlen, z = zlen};
    local axis = sides[next(sides)].a;
    h = lens[axis];
  end
  
  local p = self:fac(DIR.U); --get top face

  for i = 1, h do
    for _,side in pairs(sides) do
      if filler ~= 0 then
        p:fill(filler);
      end
      p:fac(side):fill(stairBlocks[dirLetter(dirOpposite(side)) .. 'i']);
      if p:len(side) > 1 then
        p = p:gro(side, -1);
      end
    end
    p = p:dwn(); --move down one block
  end
  return self;
end

function Coord:lamp(dir)
  return self:cub():fill(blockState("rustic:iron_lantern", "facing=" .. dir.n));
end

function Coord:lamppost(h)
  h = h or 3;
  self:cub():gro(DIR.U, h - 1):fill(lattice):top()[1]:lamp(DIR.U);
end