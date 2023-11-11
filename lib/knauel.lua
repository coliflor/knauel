local f        = require "lib.file"

local knauel = {}

-- Finds the corresponding tokens in file
function knauel.insert_tokens(text)
	 local token = "\n#%+begin_src\n"
	 local t = {}; local x = 1; local y = 1; local i = -1
	 while x ~= nil and y ~= nil  do
			x, y  = text:find(token, y)
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
function knauel.extract_data(t, t_total, text)
	 local x=1; local files = {}; local filename
	 local z, y
	 for i=1, t_total, 2 do
			if string.sub(text, t[x][3]+1, t[x][3]+2) == "[[" then
				 z, y = text:find("]]", t[x][3]+3)
				 if z ~= nil or y ~= nil then
						if y > t[x+1][2]-1 then
							 io.write(y .. " " .. t[x+1][2]-1 .. "\n")
							 io.write(i ..": warrn: no codeblock found \n")
							 y = t[x][3]-1
							 filename = "empty"
						else
							 filename = string.sub(text,  t[x][3]+3, z-1)
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
			local content = string.sub(text, y+2, t[x+1][2]-1)
			table.insert(files, { filename, content})
			x = x + 2
	 end

	 return files
end

-- write config files into disc
function knauel.write_files(t_total, files, path, args)

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
function knauel.clean_files(t_total, files, path, args)

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

function knauel.parse_text_between_tags(text, startTag, endTag)
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


return knauel
