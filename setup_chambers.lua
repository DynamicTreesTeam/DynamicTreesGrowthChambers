-- Sets up the world.
commands.gamerule("commandBlockOutput", false);
commands.gamerule("logAdminCommands", false);
commands.gamerule("doDaylightCycle", false);
commands.gamerule("doWeatherCycle", false);
commands.gamerule("randomTickSpeed", 1000);
commands.time("set", 6000);
 
local files = {};
files["s2xgQWtY"]="blocks";
files["rETVzHM5"]="makeChamber";
files["KwKTukEX"]="runChamber";
files["Ct6MXCZ9"]="build";
 
for code, file in pairs(files) do
  shell.run("pastebin", "get", code, file);
end
 
-- Create Startup File
local s = fs.open("startup", "w");
s.write("shell.run(\"runChamber\");");
s.close();
 
-- Create Config File
local c = fs.open("config", "w");
c.write("height=20; -- The height of the chamber structure.\n");
c.write("codesPerRad=20; -- Codes to generate per radius. 20 is recommended.\n");
c.close();
 
-- Create Growing Chamber
shell.run("makeChamber");