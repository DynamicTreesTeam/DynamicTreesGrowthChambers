os.loadAPI("build");
 
-- API Aliases
function dirMap(turns) return build.dirMap(turns); end
 
dofile("config");
dofile("blocks");
 
local D, U, N, S, W, E = dirMap(0);
 
local radius = 8;
local compy = build.Coord:get();
local center = compy:off(N, radius + 3);
local vol = build.cuboid(center):grohor(radius + 3);
 
build.cuboid(compy:up()):gro(U, 2):grohor():erase(); -- Erase Monitors
 
build.cuboid(compy):grohor():loop(air); -- Erase Base Around Computer
vol:gro(U, height + 2):shrhor():erase();
vol:gro(D, 2):dwn():fill(sandstone);
 
--error(); -- Uncomment to bail after erasing
 
vol:dwn():loop(hazardBlock);
 
vol = vol:shrhor():fill(platBlock);
vol = vol:shrhor():up():loop(frameBlock);
vol:gro(U, height + 1):box(air, frameBlock, frameBlock, frameBlock, frameBlock, frameBlock);
vol:shrhor():fill(floorBlock);
 
-- TODO: Make glass ceiling
 
center = center:up();
 
build.cuboid(center):grohor():fill(ventBlock);
 
center:cub():fill(dirt);
 
-- Chamber walls
center:up():cylinder(wallBlock, radius, height);
 
build.cuboid(compy:up()):dunswe(0, 2, 1, 0, 2, 2):fill(frameBlock);
build.cuboid(compy):grohor():loop(platBlock):grohor():loop(platBlock);
build.cuboid(compy):off(S):dunswe(0, 0, 0, 1, 2, 2):erase();
 
-- Make monitors TODO:  Make monitor placement library
compy:up(2):off(W):putnbt(build.blockState("computercraft:monitor_advanced", "state=rd,facing=south"), "Width:3,Height:2,XIndex:0,YIndex:1");
compy:up(2):putnbt(build.blockState("computercraft:monitor_advanced", "state=lrd,facing=south"), "Width:3,Height:2,XIndex:1,YIndex:1");
compy:up(2):off(E):putnbt(build.blockState("computercraft:monitor_advanced", "state=ld,facing=south"), "Width:3,Height:2,XIndex:2,YIndex:1");
compy:up():off(W):putnbt(build.blockState("computercraft:monitor_advanced", "state=ru,facing=south"), "Width:3,Height:2,XIndex:0,YIndex:0");
compy:up():putnbt(build.blockState("computercraft:monitor_advanced", "state=lru,facing=south"), "Width:3,Height:2,XIndex:1,YIndex:0");
compy:up():off(E):putnbt(build.blockState("computercraft:monitor_advanced", "state=lu,facing=south"), "Width:3,Height:2,XIndex:2,YIndex:0");
 
os.reboot();