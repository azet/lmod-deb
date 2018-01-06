User Guide for Lmod
--------------------

The guide here explains how to use modules. The User's tour of the
module command covers the basic uses of modules. The other sections
can be read at a later date as issues come up. The Advance user's
guide is for users needing to create their own modulefiles.

User's Tour of the Module Command
_________________________________

The module command sets the appropriate environment variable
independent of the user's shell.  Typically the system will load a
default set of modules.  A user can list the modules loaded by: ::

    $ module list

To find out what modules are available to be loaded a user can do: ::

    $ module avail

To load packages a user simply does: ::

    $ module load package1 package2 ...

To unload packages a user does: ::

    $ module unload package1 package2 ...

A user might wish to change from one compiler to another: ::

    $ module swap gcc intel

The above command is short for: ::

    $ module unload gcc
    $ module load intel

If a module is not available then an error message is produced: ::

    $ module load packageXYZ
    Warning: Failed to load: packageXYZ

It is possible to try to load a module with no error message if it
does not exist: ::

    $ module try-load packageXYZ

Modulefiles can contain help messages.  To access a modulefile's help
do: ::

    $ module help packageName

To get a list of all the commands that module knows about do: ::

    $ module help

The module avail command has search capabilities: ::

   $ module avail cc

will list for any modulefile where the name contains the string "cc".

Modulefiles can have a description section know as "whatis".  It is
accessed by: ::

   $ module whatis pmetis
   pmetis/3.1	: Name: ParMETIS
   pmetis/3.1	: Version: 3.1
   pmetis/3.1	: Category: library, mathematics
   pmetis/3.1	: Description: Parallel graph partitioning..

Finally, there is a keyword search tool: ::

   $ module keyword word1 word2 ...

This will search any help or whatis description for the word(s) given on the command line.

Another way to search for modules is with the "module spider" command.
This command searches the entire list of possible modules.  The
difference between "module avail" and "module spider" is explained in
the "Module Hierarchy" and "Searching for Modules" section. ::

    $ module spider


ml: A convenient tool
^^^^^^^^^^^^^^^^^^^^^

For those of you who can't type the *mdoule*, *moduel*, err *module*
command correctly, Lmod has a tool for you.  With **ml** you won't
have to type the module command again.  The two most common commands
are *module list*and *module load <something>* and **ml** does both::

  $ ml

means *module list*. And::

  $ ml foo

means *module load foo* while::

  $ ml -bar

means *module unload bar*.  It won't come as a surprise that you can
combine them::

  $ ml foo -bar

means *module unload bar; module load foo*.  You can do all the module
commands::

  $ ml spider
  $ ml avail
  $ ml show foo

If you ever have to load a module name *spider* you can do::

  $ ml load spider

If you are ever force to type the module command instead of **ml**
then that is a bug and should be reported.

SAFETY FEATURES
^^^^^^^^^^^^^^^

(1): Users can only have one version active.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If a user does: ::

     $ module avail xyz

     --------------- /opt/apps/modulefiles ----------------
     xyz/8.1   xyz/11.1 (D)   xyz/12.1

     $ module load xyz
     $ module load xyz/12.0

The first load command will load the 11.1 version of xyz. In the
second load, the module command knows that the user already has
xyz/11.1 loaded so it unloads that and then loads xyz/12.0. This
protection is only available with Lmod. 

(2) : Users can only load one compiler or MPI stack at a time.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Lmod provides an additional level of protection.  If each of the
compiler modulefiles add a line: ::

    family("compiler")

Then Lmod will not load another compiler modulefile.   Another benefit
of the modulefile family directive is that an environment variable
"LMOD_COMPILER_FAMILY" is assigned the name (and not the
version). This can be useful specifying different options for
different compilers. In the High Performance Computing (HPC) world,
the message passing interface (MPI) libraries are important.  The mpi
modulefiles can contain a family("MPI") directive which will prevent
users from loading more than one MPI implementation at a time.  Also
the environment variable "LMOD_FAMILY_MPI" is defined to the name of
the mpi library.  

Module Hierarchy
^^^^^^^^^^^^^^^^

Libraries built with one compiler need to be linked with applications
with the same compiler version. If sites are going to provide
libraries, then there will be more than one version of the library,
one for each compiler version. Therefore, whether it is the Boost library or
an mpi library, there are multiple versions. 

There are two main choices for system administrators. For the XYZ
library compiled with either the UCC compiler or the GCC compiler,
there could be the xyz-ucc modulefile and the xyz-gcc module
file. This gets much more complicated when there are multiple versions
of the XYZ library and different compilers. How does one label the
various versions of the library and the compiler? Even if one makes
sense of the version labeling, when a user changes compilers, the user
will have to remember to unload the ucc and the xyz-ucc modulefiles
when changing to gcc and xyz-gcc. If users have mismatched modules,
their programs are going to fail in very mysterious ways. 

A much saner strategy is to use a module hierarchy. Each compiler module
adds to the MODULEPATH a compiler version modulefile directory. Only
modulefiles that exist in that directory are packages that have been
built with that compiler. When a user loads a particular compiler,
that user only sees modulefile(s) that are valid for that compiler. 

Similarly, applications that use libraries depending on MPI
implementations must be built with the same compiler - MPI
pairing. This leads to modulefile hierarchy. Therefore, as users start with
the minimum set of loaded modules, all they will see are compilers,
not any of the packages that depend on a compiler. Once they load a
compiler they will see the modules that depend on that compiler. After
choosing an MPI implementation, the modules that depend on that
compiler-MPI pairing will be available. One of the nice features of
Lmod is that it handles the hierarchy easily. If a user swaps
compilers, then Lmod automatically unloads any modules that depends on
the old compiler and reloads those modules that are dependent on the
new compiler. ::

    $ module list

    1) gcc/4.4.5 2) boost/1.45.0

    $ module swap gcc ucc

    Due to MODULEPATH changes the follow modules have been reloaded: 1) boost

If a modulefile is not available with the new compiler, then the
module is marked as inactive. Every time MODULEPATH changes, Lmod
attempts to reload any inactive modules. 

Searching For Modules
^^^^^^^^^^^^^^^^^^^^^

When a user enters: ::

   $ module avail

Lmod reports only the modules that are in the current
MODULEPATH. Those are the only modules that the user can load. If
there is a modulefile hierarchy, then a package the user wants may be
available but not with the current compiler version. Lmod offers a new
command:  ::

   $ module spider

which lists all possible modules and not just the modules that can be
seen in the current MODULEPATH. This command has three modes. The
first mode is:  ::

   $ module spider

   lmod: lmod/lmod
   Lmod: An Environment Module System

   ucc: ucc/11.1, ucc/12.0, ...
   Ucc: the ultimate compiler collection

   xyz: xyz/0.19, xyz/0.20, xyz/0.31
   xyz: Solves any x or y or z problem.

This is a compact listing of all the possible modules on the
system. The second mode describes a particular module:  ::

    $ module spider ucc
    ----------------------------------------------------------------------------
    ucc:
    ----------------------------------------------------------------------------

    Description:
    Ucc: the ultimate compiler collection

    Versions:
    ucc/11.1
    ucc/12.0

The third mode reports on a particular module version and where it can
be found: ::

   $ module spider parmetis/3.1.1
   ----------------------------------------------------------------------------
   parmetis: parmetis/3.1.1
   ----------------------------------------------------------------------------
   Description:
   Parallel graph partitioning and fill-reduction matrix ordering routines

   This module can be loaded through the following modules:
   ucc/12.0, openmpi/1.4.3
   ucc/11.1, openmpi/1.4.3
   gcc/4.4.5, openmpi/1.4.3

   Help:
   The parmetis module defines the following environment variables: ...
   The module parmetis/3.1.1 has been compiled by three different versions of the ucc compiler and one MPI implementation.

Controlling Modules During Login
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Normally when a user logs in, there are a standard set of modules that
are automatically loaded. Users can override and add to this standard
set in two ways. The first is adding module commands to their personal
startup files. The second way is through the "module save"
command. 

To add module commands to users' startup scripts requires a few
steps. Bash users can put the module commands in either their
``~/.profile`` file or their ``~/.bashrc`` file. It is simplest to place the
following in their ``~/.profile`` file: ::

    if [ -f ~/.bashrc ]; then
       .   ~/.bashrc
    fi

and place the following in their ``~/.bashrc`` file: ::

    if [ -z "$BASHRC_READ" ]; then
       export BASHRC_READ=1
       # Place any module commands here
       # module load git
    fi  

By wrapping the module command in an if test, the module commands need
only be read in once. Any sub-shell will inherit the PATH and other
environment variables automatically. On login shells the ``~/.profile``
file is read which, in the above setup, causes the ``~/.bashrc`` file to
be read. On interactive non-login shells, the ``~/.bashrc`` file is read
instead. Obviously, having this setup means that module commands need
only be added in one file and not two. 

Csh users need only specify the module commands in their ``~/.cshrc`` file
as that file is always sourced:  ::

    if ( ! $?CSHRC_READ ) then
       setenv CSHRC_READ 1
       # Place any module command here
       # module load git
    endif

User defined initial list of login modules:

Assuming that the system administrators have installed Lmod correctly,
there is a second way which is much easier to setup. A user logs in
with the standard modules loaded. Then the user modifies the default
setup through the standard module commands:  ::

      $ module unload XYZ
      $ module swap gcc ucc
      $ module load git

Once users have the desired modules load then they issue::

      $ module save

This creates a file called ``~/.lmod.d/default`` which has the list of
desired modules. Once this is setup a user can issue::

      $ module restore

and only the desired modules will be loaded during login.

Users can have as many collections as they like.  They can save to a
named collection with::

      $ module save <collection_name>

and restore that named collection with::
  
      $ module restore <collection_name>

Finally a user can print the contents of a collection with::

      $ module describe <collection_name>
