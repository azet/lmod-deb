.. _lua_modulefile_functions-label:


Lua Modulefile Functions
========================

Lua is an efficient language built on simple syntax. Readers wanting
to know more about lua can see http://www.lua.org/. This simple description
given here should be sufficient to write all but the most complex
modulefiles. 

It is important to understand that modulefiles are written in the
positive. That is one writes the actions necessary to activate the
package. A modulefile contains commands to add to the PATH or set
environment variables. When loading a modulefile the commands are
followed. When unloading a modulefile the actions are reversed. That
is the element that was added to the PATH during loading, is removed
during unloading. The environment variables set during loading are
unset during unloading.

**prepend_path** ("PATH","*/path/to/pkg/bin*"):
   prepend to a path variable the value.

**append_path** ("PATH","*/path/to/pkg/bin*"):
   append to a path variable the value.

**remove_path** ("PATH","*/path/to/pkg/bin*"):
   remove value from path.  This command is a no-op when the mode is unload.

**setenv** ("NAME", "*value*"):
   assigns to the environment variable "NAME" the value.

**pushenv** ("NAME", "*value*"):
   sets **NAME** to *value* just like **setenv**.  In addition it
   saves the previous value in a hidden environment variable.  This
   way the previous state can be returned when a module is unloaded.

**unsetenv** ("NAME"):
   unset the value associated with "NAME".  This command is a no-op
   when the mode is unload.

**whatis** ("STRING"):
    The whatis string, can be called repeatedly with different strings. See the Administrator Guide for more details.

**help** ( [[ *help string* ]]):
     What is printed out when the help command is called. Note that
     the *help string* can be multi-lined.

**pathJoin** ("/a","b/c/","d/"):
     builds a path: "/a/b/c/d", It combines any number of strings with
     one slash and removes excess slashes. Note that trailing slash is
     removed. If you need a trailing slash then do
     **pathJoin("/a","b/c") .. "/"** to get "/a/b/c/".

**load** ("pkgA", "pkgB", "pkgC"):
     load all modules. Report error if unable to load.

**try_load** ("pkgA", "pkgB", "pkgC"):
     load all modules. No errors reported if unable to load.

**always_load** ("pkgA", "pkgB", "pkgC"):
     load all modules. However when this command is reversed it does nothing.

**set_alias** ("name","value"):
     define an alias to name with value.

**unload** ("pkgA", "pkgB"):
     When in load mode the modulefiles are unloaded.  It is not an
     error to unload modules that where not loaded.  When in unload
     mode, this command does nothing.

**family** ("name"):
     A user can only have one family "name" loaded at a time. For example family("compiler") would mean that a user could only have one compiler loaded at a time.
**prereq** ("name1", "name2"):
     The current modulefile will only load if **all** the listed modules are already loaded.
**prereq_any** ("name1", "name2"):
     The current modulefile will only load if **any** of the listed modules are already loaded.
**conflict** ("name1", "name2"):
     The current modulefile will only load if all listed modules are NOT loaded.


Extra functions
~~~~~~~~~~~~~~~

The entries below describe several useful commands that come with Lmod that can be used in modulefiles.

**os.getenv** ("NAME"):
    Ask for environment for the value of "NAME". Note that if the
    "NAME" might not be in the environment, then it is probably best
    to do::
    
       local foo=os.getenv("FOO") or ""

    otherwise ``foo`` will have the value of ``nil``.

**capture** ("string"):
    Run the "string" as a command and capture the output.
**isFile** ("name"):
    Returns true if "name" is a file.
**isDir** ("name"):
    Returns true if "name" is a directory.
**splitFileName** ("name"):
    Returns both the directory and the file name. ``local d,f=splitFileName("/a/b/c.ext")``. Then ``d="/a/b"``, ``f="c.ext"``
**LmodMessage** ("string",...):
    Prints a message to the user.
**LmodError** ("string","..."):
    Print Error string and exit without loading the modulefile.
**mode** ():
    Returns the string "load" when a modulefile is being loaded and "unload" when unloading.
**isLoaded** ("NAME"):
    Return true when module "NAME" is loaded.
**LmodVersion** ():
    The version of lmod.
**execute** {cmd="*<any command>*",modeA={"load"}}
    Run any command with a certain mode.  For example
    **execute** {cmd="ulimit -s unlimited",modeA={"load"}} will run
    the command **ulimit -s unlimited** as the last thing that the
    loading the module will do.


Modifier functions to prereq and loads
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**atleast** ("name","version"):
    This modifier function will only succeed if the module is
    "version" or newer.

**between** ("name","v1","v2"):
    This modifier function will only succeed if the module's version is
    equal to or between "v1" and "v2".  

**latest** ("name"):
    This modifier function will only succeed if the module has the
    highest version on the system.


Introspection Functions
~~~~~~~~~~~~~~~~~~~~~~~

The following functions allow for more generic modulefiles by finding
the name and version of a modulefile.

**myModuleName** ():
   Returns the name of the current modulefile without the version.

**myModuleVersion** ():
   Returns the version of the current modulefile.

**myModuleFullName** ():
   Returns the name and version of the current modulefile.

**myModuleUsrName** ():
   Returns the name the user specified to load a module.  So it could be the name or the name and version.

**myFileName** ():
   Returns the absolute file name of the current modulefile.

**myShellName** ():
   Returns the name of the shell the user specified on the
    command line.

**hierarchyA** ("fullName", level):
   Returns the hierarchy of the current module.  See the section on
   Generic Modules for more details.

