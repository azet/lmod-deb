--------------------------------------------------------------------------
-- A collection of useful file operations.
-- @module fileOps

require("strict")

------------------------------------------------------------------------
--
--  Copyright (C) 2008-2014 Robert McLay
--
--  Permission is hereby granted, free of charge, to any person obtaining
--  a copy of this software and associated documentation files (the
--  "Software"), to deal in the Software without restriction, including
--  without limitation the rights to use, copy, modify, merge, publish,
--  distribute, sublicense, and/or sell copies of the Software, and to
--  permit persons to whom the Software is furnished to do so, subject
--  to the following conditions:
--
--  The above copyright notice and this permission notice shall be
--  included in all copies or substantial portions of the Software.
--
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
--  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
--  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
--  NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
--  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
--  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
--  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
--  THE SOFTWARE.
--
--------------------------------------------------------------------------

require("string_utils")
_G._DEBUG       = false                     -- Required by luaposix 33
local posix     = require("posix")
local lfs       = require("lfs")
local concatTbl = table.concat
local dbg       = require("Dbg"):dbg()

local function argsPack(...)
   local arg = { n = select("#", ...), ...}
   return arg
end
local pack        = (_VERSION == "Lua 5.1") and argsPack or table.pack
--------------------------------------------------------------------------
-- find the absolute path to an executable.
-- @param exec Name of executable
-- @param path The path to use. If nil then use env PATH.
function findInPath(exec, path)
   local result  = "unknown_path_for_" .. (exec or "unknown")
   if ( exec == nil) then return result end
   exec = exec:trim()
   local i = exec:find(" ")
   local cmd  = exec
   local tail = ""
   if (i) then
      cmd  = exec:sub(1,i-1)
      tail = exec:sub(i)
   end

   if (cmd:find("/")) then
      if (posix.access(cmd,"x")) then
         return exec
      else
         return result
      end
   end

   path    = path or os.getenv("PATH")
   for dir in path:split(":") do
      local fullcmd = pathJoin(dir, cmd)
      if (posix.access(fullcmd,"x")) then
         result = fullcmd .. tail
         break
      end
   end
   return result
end

--------------------------------------------------------------------------
-- find the absolute path to an executable or nil if not found
-- @param exec Name of executable
-- @param path The path to use. If nil then use env PATH.
function find_exec_path(exec, path)
   local result  = nil
   if ( exec == nil or exec == "" or exec:lower() == "none" ) then return result end
   exec = exec:trim()
   local i = exec:find(" ")
   local cmd  = exec
   local tail = ""
   if (i) then
      cmd  = exec:sub(1,i-1)
      tail = exec:sub(i)
   end

   if (cmd:find("/")) then
      if (posix.access(cmd,"x")) then
         return exec
      else
         return result
      end
   end

   path    = path or os.getenv("PATH")
   for dir in path:split(":") do
      local fullcmd = pathJoin(dir, cmd)
      if (posix.access(fullcmd,"x")) then
         result = fullcmd .. tail
         break
      end
   end
   return result
end

------------------------------------------------------------------------
-- Return true if path is a directory.  Note that a symlink to a
-- directory is not a directory.
-- @param d A file path
function isDir(d)
   if (d == nil) then return false end
   local t = posix.stat(d,"type")

   -- If the file is a link then adding a '/' on the end
   -- seems to tell stat to resolve the link to its final link.
   if (t == "link") then
      d = d .. '/'
      t = posix.stat(d,"type")
   end

   local result = (t == "directory")

   return result
end

--------------------------------------------------------------------------
-- Return true if file exists is and is a file or link.
-- @param fn A file path
function isFile(fn)
   if (fn == nil) then return false end
   local t = posix.stat(fn,"type")

   local result = ((t == "regular") or (t == "link"))

   return result
end

--------------------------------------------------------------------------
-- Returns true if file is readable and executable.
-- @param fn A file path
function isExec(fn)
   if (fn == nil) then return false end
   local result = posix.access(fn,"rx")
   return result
end

--------------------------------------------------------------------------
-- Return the directory part of path. Will return "./" if path is without a directory.
-- @param path A file path
function dirname(path)
   if (path == nil) then return nil end
   local result
   local i,j = path:find(".*/")
   if (i == nil) then
      result = "./"
   else
      result = path:sub(1,j)
   end
   return result
end

--------------------------------------------------------------------------
--- Return the extension of a file or "" if there is none.
--  @param path A file path
function extname(path)
   if (path == nil) then return nil end
   local result
   local i,j = path:find(".*/")
   i,j       = path:find(".*%.",j)
   if (i == nil) then
      result = ""
   else
      result = path:sub(j,-1)
   end
   return result
end

--------------------------------------------------------------------------
-- Remove extension from path.
-- @param path A file path

function removeExt(path)
   if (path == nil) then return nil end
   local result
   local i,j = path:find(".*/")
   i,j       = path:find(".*%.",j)
   if (i == nil) then
      result = path
   else
      result = path:sub(1,j-1)
   end
   return result
end

--------------------------------------------------------------------------
-- return the file name w/o any directory part.
-- @param path A file path

function barefilename(path)
   if (path == nil) then return nil end
   local result
   local i,j = path:find(".*/")
   if (i == nil) then
      result = path
   else
      result = path:sub(j+1,-1)
   end
   return result
end

--------------------------------------------------------------------------
-- split a path into a directory and a file.
-- @param path A file path
-- @return d A directory path
-- @return f a barefilename
function splitFileName(path)
   if (path == nil) then return nil, nil end
   local d, f
   local i,j = path:find(".*/")
   if (i == nil) then
      d = './'
      f = path
   else
      d = path:sub(1,j)
      f = path:sub(j+1,-1)
   end
   return d, f
end

--------------------------------------------------------------------------
-- Join argument into a path that has single slashes between directory
-- names and no trailing slash.
-- @return a file path with single slashes between directory names
-- and no trailing slash.

function pathJoin(...)
   local a = {}
   local arg = pack(...)
   for i = 1, arg.n  do
      local v = arg[i]
      if (v and v ~= '') then
         local vType = type(v)
         if (vType ~= "string") then
            local msg = "bad argument #" .. i .." (string expected, got " .. vType .. " instead)\n"
            assert(vType ~= "string", msg)
         end
      	 v = v:trim()
      	 if (v:sub(1,1) == '/' and i > 1) then
	    if (v:len() > 1) then
	       v = v:sub(2,-1)
	    else
	       v = ''
	    end
      	 end
      	 v = v:gsub('//+','/')
      	 if (v:sub(-1,-1) == '/') then
	    if (v:len() > 1) then
	       v = v:sub(1,-2)
	    elseif (i == 1) then
	       v = '/'
      	    else
	       v = ''
	    end
      	 end
      	 if (v:len() > 0) then
	    a[#a + 1] = v
	 end
      end
   end
   local s = concatTbl(a,"/")
   s = path_regularize(s)
   return s
end

--------------------------------------------------------------------------
-- Create a new directory recursively.
-- @param path A file path
function mkdir_recursive(path)
   local absolute
   if (path:sub(1,1) == '/') then
      absolute = true
      path = path:sub(2,-1)
   end

   local a = {}
   if (absolute) then
      a[#a + 1] = "/"
   end
   local d
   for v in path:split('/') do
      a[#a + 1] = v
      d         = concatTbl(a,'/')
      if (not isDir(d)) then
         lfs.mkdir(d)
      end
   end
end

--------------------------------------------------------------------------
-- find true path through symlinks.
-- @param path Input path
-- @param[opt] localDir If true then do not leave the current directory
-- when following symlinks
-- @return A absolute path.

function abspath (path, localDir)
   if (path == nil) then return nil end
   local cwd = lfs.currentdir()
   path = path:trim()

   if (path:sub(1,1) ~= '/') then
      path = pathJoin(cwd,path)
   end

   local dir    = dirname(path)
   local ival   = lfs.chdir(dir)

   local cdir   = lfs.currentdir()
   if (cdir == nil) then
      dbg.print{"lfs.currentdir(): is nil"}
   end

   dir          = cdir or dir


   path = pathJoin(dir, barefilename(path))
   local result = path

   local attr = lfs.symlinkattributes(path)
   if (attr == nil) then
      lfs.chdir(cwd)
      return nil
   elseif (attr.mode == "link") then
      local rl = posix.readlink(path)
      if (not rl) then
         lfs.chdir(cwd)
         return nil
      end
      if (localDir and (rl:sub(1,1) == "/" or rl:sub(1,3) == "../")) then
         lfs.chdir(cwd)
         return result
      end
      result = abspath(rl, localDir)
   end
   lfs.chdir(cwd)
   return result
end

--------------------------------------------------------------------------
-- Remove leading and trail spaces and extra slashes.
-- @param value A path
-- @return A clean canonical path.
function path_regularize(value)
   if value == nil then return nil end
   value = value:gsub("^%s+", "")
   value = value:gsub("%s+$", "")
   value = value:gsub("//+" , "/")
   value = value:gsub("/%./", "/")
   value = value:gsub("/$"  , "")
   if (value == '') then
      value = ' '
      return value
   end
   local t    = {}
   local icnt = 0
   for dir in value:split("/") do
      icnt = icnt + 1
      if (    dir == ".." and icnt > 1) then
         t[#t] = nil
      elseif (dir ~= "."  or icnt == 1) then
         t[#t+1] = dir
      end
   end
   value = concatTbl(t,"/")

   return value
end


local function _walk_dir(path)
   local dirA  = {}
   local fileA = {}
   for file in lfs.dir(path) do
      if ( file ~= '.' and file ~= '..') then
         local fn   = pathJoin(path,file)
         local mode = lfs.attributes(fn,'mode')
         if (mode == 'directory') then
            dirA[#dirA+1]   = file
         else
            fileA[#fileA+1] = file
         end
      end
   end
   return dirA, fileA
end

local function _walker(root)
   local dirA, fileA = _walk_dir(root)
   coroutine.yield(root,dirA,fileA)
   for i = 1, #dirA do
      _walker(pathJoin(root,dirA[i]))
   end
end

function dir_walk(path)
   return coroutine.wrap(function () _walker(path) end)
end
