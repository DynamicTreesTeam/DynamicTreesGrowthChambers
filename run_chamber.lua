os.loadAPI("build");
 
-- API Aliases
 
function dirMap(turns) return build.dirMap(turns); end
function fif(cond, a, b) return build.fif(cond, a, b); end
 
dofile("config");
dofile("blocks");
 
local D, U, N, S, W, E = dirMap(0);
 
local compy = build.Coord:get();
local center = compy:off(N, 8 + 3):up();
local lockPos = compy:off(N):up();
 
grow = false;
local radius = 8;
count = codesPerRad;
 
local currModIdx = 1;
local currSpeciesIdx = 1;
 
local arrowL = string.char(17);
local arrowR = string.char(16);
 
monitor = peripheral.find("monitor");
monitor.setBackgroundColor(colors.black);
monitor.clear();
 
mainTimer = 0;
 
function startTimer()
  mainTimer = os.startTimer(0.5);
end
 
function stopTimer()
  os.cancelTimer(mainTimer);
end
 
function waitOn(func)
  parallel.waitForAll(func);
end
 
function pad(str, len, chr)
  chr = chr or " ";
  local miss = len - string.len(str);
  if miss > 0 then
    str = str .. string.rep(chr, miss);
  end
  if miss < 0 then
    str = string.sub(str, 1, len);
  end
  return str;
end
 
function padNum(num, len, chr)
  chr = chr or " ";
  local str = tonumber(num);
  local miss = len - string.len(str);
  if miss > 0 then
    str = string.rep(chr, miss) .. str;
  end
  return str;
end
 
function sound(snd)
  commands.playsound(snd, "block", "@a", compy.x, compy.y, compy.z);
end
 
function clicksound()
  sound("block.stone_button.click_on");
end
 
function getKeys(tab)
  local keyset={}
  for k,v in pairs(tab) do
    keyset[#keyset+1]=k
  end
  return keyset;
end
 
function getSpeciesList()
  local _, list = commands.dt("registry", "species", "list", true)
  return list;
end
 
local trees = {};
for k, v in pairs(getSpeciesList()) do
  local mod, species = string.match(v, "([^,]+):([^,]+)");
  if trees[mod] == nil then
    trees[mod] = {};
  end
  local s = trees[mod];
  s[#s+1]=species;
end
 
local mods = getKeys(trees);
table.sort(mods);
 
for k, v in pairs(trees) do
  table.sort(v);
end
 
 
----------------------------------------------------------------
-- BUTTONS                                                    --
----------------------------------------------------------------
 
Button = {}
Button.__index = Button;
 
function Button:new(x, y, w, text, color)
  color = color or colors.black;
  local button = {};             -- our new object
  setmetatable(button, Button);  -- make handle lookup
  button.coords = build.Coord:new(x, y, 0);
  button.width = w;
  button.text = text;
  button.color = color;
  button.monitor = monitor;
  return button;
end
 
function Button:setMonitor(m)
  self.monitor = m;
  return self;
end
 
function Button:draw()
  mon = self.monitor;
  mon.setCursorPos(self.coords.x, self.coords.y);
  -- mon.clearLine();
  mon.setBackgroundColor(self.color);
  -- mon.clearLine();
  mon.write(pad(self.text, self.width, " "));
  return self;
end
 
function Button:setText(text)
  if text ~= self.text then
    self.text = text;
    self:draw();
  end
  return self;
end
 
function Button:setColor(color)
  self.color = color;
  self:draw();
  return self;
end
 
function Button:click(x, y)
  if self:isInside(x, y) then
    if self.action ~= nil then 
      clicksound();
      self.action(self, x, y);
    end
  end
end
 
function Button:isInside(x, y)
  return y == self.coords.y and x >= self.coords.x and x < self.coords.x + self.width;
end
 
function Button:setAction(action)
  self.action = action;
  return self;
end
 
function open() waitOn(
  function ()
    sound("block.piston.extend");
    if radius <= 8 and radius >= 2 then
      center:up():cylinder(air, radius, height);
    end
    build.waitAsync();
  end);
end
 
function close() waitOn(
  function ()
    sound("block.piston.contract");
    if radius <= 8 and radius >= 2 then
      center:up():cylinder(wallBlock, radius, height);
    end
    build.waitAsync();
  end);
end
 
function kill() waitOn(
  function ()
    commands.dt("killtree", center.x, center.y, center.z);
    center:up():cub():erase();-- In the case of a sapling
    center:cub():fill(dirt); -- Place dirt over the rooty soil just in case
    commands.kill("@e[type=item]"); -- Gets rid of dropped seeds
  end);
end
 
function plant() 
  commands.dt("setcoordxor", math.random(0, 65535));
  commands.dt("settree", center.x, center.y, center.z, tree, "P"); -- synchronous
  setFertility(15); -- synchronous
end
 
function purge() waitOn(
  function ()
    center:up():cub():grohor(radius):gro(U, height):erase();
    build.waitAsync();
  end);
end
 
function push()
  if file_exists(treeFilename()) then
    print("pastebin: " .. treeFilename());
    shell.run("pastebin", "put", treeFilename());
  else
    print("error: " .. treeFilename() .. " not found");
  end
end
 
function setRadius(rad)
  open();
 
  if rad >= 8 then
    rad = 8;
  elseif rad <= 2 then
    rad = 2;
  end
 
  if rad ~= radius then
    radius = rad;
    count = codesPerRad;
    countButton:setCount(count);
    radiusButton:setRadius(radius);
  end
 
end
 
function radiusInc()
  setRadius(radius + 1);
end
 
function radiusDec()
  setRadius(radius - 1);
end
 
 
function treeFilename()
  local mod = mods[currModIdx];
  local spc = trees[mod][currSpeciesIdx];
  return mod .. "/" .. spc .. ".txt";
end
 
 
openButton   = Button:new(2, 2, 7, "[OPEN ]", colors.purple):setAction( open );
closeButton  = Button:new(2, 3, 7, "[CLOSE]", colors.blue):setAction( close );
plantButton  = Button:new(2, 4, 7, "[PLANT]", colors.lime):setAction( plant );
killButton   = Button:new(2, 5, 7, "[KILL ]", colors.orange):setAction( function() kill(); grow = false; end );
purgeButton  = Button:new(2, 6, 7, "[PURGE]", colors.brown):setAction( purge );
modButton    = Button:new(2, 8, 27, "       ", colors.gray);
treeButton   = Button:new(2, 9, 27, "      ", colors.gray);
radiusButton = Button:new(12, 2, 7, "       ", colors.gray);
growButton   = Button:new(12, 3, 7, "[START]", colors.green);
soilButton   = Button:new(12, 4, 11, "       ", colors.gray);
countButton  = Button:new(12, 5, 11, "       ", colors.gray);
pushButton  = Button:new(12, 6, 7, "[PUSH ]", colors.cyan):setAction( push );
 
growButton.stop = function(b) b:setColor(colors.green); b:setText("[START]"); grow = false; end
growButton.start = function(b) b:setColor(colors.red); b:setText("[STOP ]") grow = true; close(); end
growButton:setAction( function(b) if grow then b:stop(); else b:start(); end; end);
 
countButton.setCount = function(b, c) b:setText("REMAIN:" .. padNum(c, 4)); end;
countButton:setAction( function(b) count = codesPerRad; b:setCount(count); end );
countButton:setCount(count);
 
-- Radius Button Setup
radiusButton.setRadius = function(b, r) b:setText(arrowL .. arrowR .. " " .. "R:" .. r); end;
radiusButton.click = 
  function(b, x, y)
    if b:isInside(x, y) then
      x = x - b.coords.x + 1;
      if x == 1 then
        clicksound();
        radiusDec();
      elseif x == 2 then
        clicksound();
        radiusInc();
      end
    end
  end;
radiusButton:setRadius(radius);
 
function updateTree()
  local mod = mods[currModIdx];
  local spc = trees[mod][currSpeciesIdx];
  local newTree = mod .. ":" .. spc;
  if newTree ~= tree then
    tree = newTree;
    kill();
  end
end
 
-- Tree Button Setup
 
treeButton.setIdx = 
  function(b, idx)
    local arr = trees[mods[currModIdx]];
    idx = ((idx - 1) % #arr) + 1;
    b:setText(arrowL .. arrowR .. " " .. arr[idx]);
    currSpeciesIdx = idx;
    updateTree();
  end
 
treeButton.click = 
  function(b, x, y)
    if b:isInside(x, y) then
      x = x - b.coords.x + 1;
      if x == 1 then
        clicksound();
        b:setIdx(currSpeciesIdx - 1);
      elseif x == 2 then
        clicksound();
        b:setIdx(currSpeciesIdx + 1);
      end
    end
  end;
treeButton:setIdx(1);
 
 
-- Mod Button Setup
 
modButton.setIdx = 
  function(b, idx)
    local arr = mods;
    idx = ((idx - 1) % #arr) + 1;
    b:setText(arrowL .. arrowR .. " " .. arr[idx]);
    currModIdx = idx;
    treeButton:setIdx(1);
  end
 
modButton.click = 
  function(b, x, y)
    if b:isInside(x, y) then
      x = x - b.coords.x + 1;
      if x == 1 then
        clicksound();
        b:setIdx(currModIdx - 1);
      elseif x == 2 then
        clicksound();
        b:setIdx(currModIdx + 1);
      end
    end
  end;
modButton:setIdx(1);
 
 
-- fertility Button Setup
 
soilButton.setFertility = 
  function(b, life)
    local text;
    if life ~= nil and life >= 0 then
      text = padNum(life, 2, "0") .. "/15";
    else
      text = "--/--";
    end
    soilButton:setText("SOIL: " .. text);
  end
 
 
-- All Buttons
allButtons = { openButton, closeButton, growButton, plantButton, killButton, purgeButton, countButton, modButton, treeButton, radiusButton, soilButton, pushButton };
 
function drawScreen()
  for i, v in ipairs(allButtons) do
    v:draw();
  end
end
 
function clickScreen(x, y)
  for i, v in ipairs(allButtons) do
    v:click(x, y);
  end
end
 
drawScreen();
 
indicator = false;
 
function clearVines()
  -- Do nothing for now
end
 
function getFertility()
  pass, val = commands.dt("fertility", center.x, center.y, center.z, true);
  if (pass) then
    return tonumber(val[1]);
  end
  return -1;
end
 
function setFertility(life)
  pass, val = commands.dt("fertility", center.x, center.y, center.z, life);
end
 
function getCode()
  pass, val = commands.dt("gettree", center.x, center.y, center.z, true);
  if (pass) then
    return val[1];
  end
  return nil;
end
 
function storeCodeHttp(tree, code, radius)
  code = string.gsub(code, "+", "%%2b");
  http.request("http://127.0.0.1/trees/trees.php?".. "tree="..tree.."&code="..code.."&radius="..radius, nil);  
end
 
function storeCodeConsole(tree, code, radius)
  print(tree);
  print(radius .. ":" .. code);
  print("----------------------");
end
 
function storeCodeFile(tree, code, radius)
  local s = fs.open(treeFilename(), "a");
  s.write(radius .. ":" .. code .. "\n");
  s.close();
end
 
function storeCode(tree, code, radius)
  -- storeCodeHttp(tree, code, radius);
  storeCodeConsole(tree, code, radius);
  storeCodeFile(tree, code, radius);
end
 
function harvest()
  code = getCode();
  kill();
  sound("entity.item.pickup");
 
  local codes = {};
  codes[1] = code;
 
  for i = 1,3 do
    local _, c = commands.dt("rotatejocode", code, i);
    codes[i + 1] = c[1];
  end
 
  table.sort(codes);
  code = codes[1];
 
  storeCode(tree, code, radius);
end
 
function file_exists(name)
   local f=io.open(name,"r")
   if f ~= nil then io.close(f) return true else return false end
end
 
function finishHarvest()
  growButton:stop();
end
 
function onTimerEvent()
  local fertility = getFertility();
  soilButton:setFertility(fertility);
  if (fertility <= 0 and grow == true) then
 
    if(fertility == 0) then
      harvest();
      count = count - 1;
      if count <= 0 then
        if radius > 2 then
          radiusDec();
          close();
        else
          finishHarvest(); -- We're done
        end
      end
      countButton:setCount(count);
    end
 
    if grow then 
      plant();
    end
 
  end
end
 
spinner = 0;
spinnerSet = { 129, 130, 136, 259, 144, 132 };
 
function parallelTimer()
  startTimer();
  while true do
    event = os.pullEvent("timer");
    onTimerEvent();
    monitor.setCursorPos(28, 2);
    spinner = (spinner + 1) % 6;
    s = spinnerSet[spinner + 1];
    if s > 200 then
      s = s - 100;
      monitor.setBackgroundColor(colors.orange);
      monitor.setTextColor(colors.gray);
    else
      monitor.setBackgroundColor(colors.gray);
      monitor.setTextColor(colors.orange);
    end
    monitor.write(string.char(s));
    monitor.setTextColor(colors.white);
    startTimer();
  end
end
 
function parallelClick()
  while true do
    event, par1, xPos, yPos = os.pullEvent("monitor_touch");
    clickScreen(xPos, yPos);
  end
end
 
purge();
close();
parallel.waitForAll(parallelTimer, parallelClick);