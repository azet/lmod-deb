# -*- python -*-
import os, string
def module(command, *arguments):
  commands = os.popen('/usr/lmod/lmod/libexec/lmod python %s %s'\
                      % (command, string.join(arguments))).read()
  exec commands

