--local pl       = require 'pl.pretty' -- pl.dump(tn)
local argparse = require "argparse"
local f        = require "file"
local parser   = argparse()
   :name "knauel"
   :description [[
  The purpose of this script is to write all your config files in a single
  centralized file and the program will create the separated
  files making it simpler to share your setups or configure several small files.

  It utilizes the emacs org-mode tags \n#%+begin_src\n and \n#%+end_src\n .
  Unlike org-mode this tags don't support parameters and being and end with a
  line break.

  You can run your own custom functions to alter the file before its parsed by
  creating a code block \n#%+begin_code\n and \n#%+end_code\n and putting your
  lua function inside those tags, the code can alter the global variable “file”
  to the desired output. See the example code_execution.org

]]
   :epilog "  Author: beemo.ceniza@gmail.com"

local default_dir = os.getenv("HOME").."/.knauel/"
parser:option("-c --config", "Config file. ", default_dir.."knauel.org")
local version = "version v 0.1.0"
parser:flag("-v --version", version)
parser:flag("-r --remove", "clean files and links if -l is set")
parser:flag("-l --link", "links the created files to their paths")
local args     = parser:parse()

local path  = args.config

if  args.version == true then
	 io.write(version .. "\n")
	 os.exit()
end


-- Check if file exists, if not fall back to default file
if (f.file_exists(path)) == false then
	 io.write("error: file " .. path .. " not found.\n")
	 io.write("warrn: fall back to default file.\n")

	 path = os.getenv("HOME") .. "/.knauel/knauel.org"
	 io.write(path.."\n")
	 if (f.file_exists(path)) == false then
			io.write("error: file " .. path .. " not found.\n")
			os.exit()
	 end
end

-- Read file
file = f.readall(path)

-- Finds the corresponding tokens in file
local function insert_tokens()
	 local token = "\n#%+begin_src\n"
	 local t = {}; local x = 1; local y = 1; local i = -1
	 while x ~= nil and y ~= nil  do
			x, y  = file:find(token, y)
			table.insert(t, {token, x, y})
			i = i + 1;
			if token == "\n#%+begin_src\n" then
				 token = "\n#%+end_src\n"
			else
				 token = "\n#%+begin_src\n"
			end
	 end
	 table.remove(t)
	 return t, i
end


-- extract text and put it in a separate table
local function extract_data(t, t_total)
	 local x=1; local files = {}; local filename
	 local z, y
	 for i=1, t_total, 2 do
			if string.sub(file, t[x][3]+1, t[x][3]+2) == "[[" then
				 z, y = file:find("]]", t[x][3]+3)
				 if z ~= nil or y ~= nil then
						if y > t[x+1][2]-1 then
							 io.write(y .. " " .. t[x+1][2]-1 .. "\n")
							 io.write(i ..": warrn: no codeblock found \n")
							 y = t[x][3]-1
							 filename = "empty"
						else
							 filename = string.sub(file,  t[x][3]+3, z-1)
						end
				 else
						io.write("warrn: no codeblock found \n")
						y = t[x][3]+1
						filename = "empty"
				 end
			else
				 y = t[x][3]+1
				 filename = "empty"
			end
			local content = string.sub(file, y+2, t[x+1][2]-1)
			table.insert(files, { filename, content})
			x = x + 2
	 end

	 return files
end


-- write config files into disc
local function write_files(t_total, files)

	 local f_total = t_total/2
	 for i=1, f_total, 1 do
			local file2
			if f.filename(files[i][1]) == nil then
				 file2 = files[i][1]
			else
				 file2 = f.filename(files[i][1])
			end
			local filename = f.dirname(path) .. file2
			f.write(filename, files[i][2])
			io.write("file created: ".. filename .."\n")
			if  args.link == true and file2 ~= files[i][1] then
				 local err = os.execute("ln -s " .. filename .. " " .. files[i][1])
				 if err == nil then
						err = ""
						io.write(err .. "\n")
				 else
						io.write("link: ".. files[i][1] .. "\n")
				 end
				 io.write("\n")
			end
	 end
end


-- clean files and links
local function clean_files(t_total, files)

	 local f_total = t_total/2
	 for i=1, f_total, 1 do
			local file2
			if f.filename(files[i][1]) == nil then
				 file2 = files[i][1]
			else
				 file2 = f.filename(files[i][1])
			end
			local filename = f.dirname(path) .. file2
			os.execute("rm " ..  filename)
			io.write("file deleted: ".. filename.."\n")
			if  args.link == true  then
				 local err = os.execute("unlink " ..  files[i][1])
				 if err == nil then
						err = ""
						io.write(err .. "\n")
				 else
						io.write("link: ".. files[i][1] .. "\n")
				 end
				 io.write("\n")
			end
	 end
end


local function execute_string_function(str)
	 local fn, err = loadstring(str)
	 if fn == nil then
			error(err)
	 else
			return fn()
	 end
end


local function parse_text_between_tags(text, startTag, endTag)
	 local startPos, endPos = string.find(text, startTag)
	 if not startPos then
			return ""
	 end

	 startPos = endPos + 1 -- exclude the start tag itself

	 endPos, _ = string.find(text, endTag, startPos)
	 if not endPos then
			return ""
	 end

	 return string.sub(text, startPos, endPos - 1)
end

local code = parse_text_between_tags(file, "\n#%+begin_code\n", "\n#%+end_code\n")
if code  ~= "" then
	 --io.write(code)
	 io.write("code block found! executing code\n")
	 local fn = execute_string_function(code)
	 io.write(fn())
end

local t, t_total = insert_tokens()

if t_total == 0 then
	 io.write("error: no valid tokens found \n")
	 os.exit()
end

if t_total % 2  ~= 0 then
	 io.write("error: missing a closure token\n")
	 os.exit()
end
local files = extract_data(t, t_total)

if args.remove == true then
	 clean_files(t_total, files)
else
	 write_files(t_total, files)
end
