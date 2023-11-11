local file = {}

-- http://lua-users.org/wiki/FileInputOutput
function file.file_exists(path)
	 -- Return true if file exists and is readable.
	 local f = io.open(path, "rb")
	 if f then f:close() end
	 return f ~= nil
end

function file.readall(filename)
	 -- Read an entire file.
	 -- Use "a" in Lua 5.3; "*a" in Lua 5.1 and 5.2
	 local fh = assert(io.open(filename, "rb"))
	 local contents = assert(fh:read(_VERSION <= "Lua 5.2" and "*a" or "a"))
	 fh:close()
	 return contents
end

function file.write(filename, contents)
	 -- Write a string to a file.
	 local fh = assert(io.open(filename, "wb"))
	 fh:write(contents)
	 fh:flush()
	 fh:close()
end

function file.modify(filename, modify_func)
	 -- Read, process file contents, write.
	 local contents = file.readall(filename)
	 contents = modify_func(contents)
	 file.write(filename, contents)
end

function file.dirname(path)
	if path:match(".-/.-") then
		local name = string.gsub(path, "(.*/)(.*)", "%1")
		return name
	else
		return ''
	end
end

function file.filename(path)
      return path:match("^.+/(.+)$")
end

return file
