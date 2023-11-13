local argparse = require "lib.argparse"
--local h        = require "lib.helper"
local f        = require "lib.file"
local k        = require "lib.knauel"

local parser   = argparse()
   :name "knauel"
   :description [[
  The purpose of this script is to write all your config files in a single
  centralized file and the program will create the separated
  files making it simpler to share your setups or configure several small files.

  It utilizes the emacs org-mode tags \n#%+begin_src\n and \n#%+end_src\n .
  Unlike org-mode this tags don't support parameters and begin and end with a
  line break.

  You can run your own custom functions to alter the file before its parsed by
  creating a code block \n#%+begin_code\n and \n#%+end_code\n and putting your
  lua function inside those tags, the code can alter the global variable “file”
  to the desired output. See the example code_execution.org

]]
   :epilog "  Author: beemo.ceniza@gmail.com"

local default_dir = os.getenv("HOME").."/.knauel/"
parser:option("-c --config", "Config file. ", default_dir.."knauel.org")
local version = "version v 0.1.9"
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

function execute_string_function(str)
	 local fn, err = loadstring(str)
	 if fn == nil then
			error(err)
	 else
			return fn()
	 end
end

local code = k.parse_text_between_tags(file, "\n#%+begin_code\n", "\n#%+end_code\n")
if code  ~= "" then
	 --io.write(code)
	 io.write("code block found! executing code\n")
	 local fn = execute_string_function(code)
	 io.write(fn())
end

local t, t_total = k.insert_tokens(file)

if t_total == 0 then
	 io.write("error: no valid tokens found \n")
	 os.exit()
end

if t_total % 2  ~= 0 then
	 io.write("error: missing a closure token\n")
	 os.exit()
end
local files = k.extract_data(t, t_total, file)


function containsAnyDuplicate(table)
    local n = #table

    for i = 1, n - 1 do
        for j = i + 1, n do
            if table[i] == table[j] then
                return true  -- Found a duplicate
            end
        end
    end

    return false  -- No duplicate found
end

local filenames = {}
for i = 1, t_total/2 do
	 filenames[i] = f.filename(files[i][1])
end

if containsAnyDuplicate(filenames) then
	 --h.print(filenames)
	 print("warrning: there are duplicate filenames may produce unexpected side effects")
end

if args.remove == true then
	 k.clean_files(t_total, files, path, args)
else
	 k.write_files(t_total, files, path, args)
end
