# Please do not change this if you are not sure what youre doing
# This was made by AbdoD3V on github

import std/[os, strutils, osproc]

proc printError*(cmd: string, msg: string) =
  echo "NaSH [", cmd, " error]: ", msg

proc tryRunSystemBinary(cmd: string, args: seq[string]): bool =
  # supports binary paths
  if cmd.contains("/") or cmd.startsWith("."):
    if fileExists(cmd):
      try:
        let p = startProcess(cmd, args = args, options = {poParentStreams})
        discard p.waitForExit()
        p.close()
        return true
      except OSError as e:
        printError(cmd, "execution failed: " & e.msg)
        return true
    return false

  # /bin is for system binaries, and /uib is for binaries that the user has manually installed
  let searchPaths = ["/bin/" & cmd, "/bin/uib/" & cmd]
  for binaryPath in searchPaths:
    if fileExists(binaryPath):
      try:
        let p = startProcess(binaryPath, args = args, options = {poParentStreams})
        discard p.waitForExit()
        p.close()
        return true
      except OSError as e:
        printError(cmd, "execution failed: " & e.msg)
        return true
  return false

# ==========================================
# the command router
# ==========================================
proc handleBuiltins*(cmd: string, args: seq[string]): bool =
  case cmd

  # ==========================================
  # cd, changes directory
  # ==========================================
  of "cd":
    let target = if args.len > 0: args[0] else: "/userspace"
    try:
      setCurrentDir(target)
    except OSError as e:
      printError(cmd, e.msg)
    return true

  # ==========================================
  # .. does the job
  # ==========================================
  of "..":
    try:
      setCurrentDir("..")
    except OSError as e:
      printError("cd ..", e.msg)
    return true

  # ==========================================
  # ls, list directory contents
  # ==========================================
  of "ls":
    let path = if args.len > 0: args[0] else: getCurrentDir()
    try:
      for kind, item in walkDir(path):
        let name = item.extractFilename()
        if name.startsWith("."):
          continue
        if kind in {pcDir, pcLinkToDir}:
          echo name, "/"
        else:
          echo name
    except OSError as e:
      printError(cmd, e.msg)
    return true

  # ==========================================
  # crfile, creates a blank file
  # ==========================================
  of "crfile":
    if args.len == 0:
      printError(cmd, "file name can't be blank")
      return true
    try:
      let f = open(args[0], fmWrite)
      f.close()
    except CatchableError as e:
      printError(cmd, e.msg)
    return true

  # ==========================================
  # rmfile, removes file
  # ==========================================
  of "rmfile":
    if args.len == 0:
      printError(cmd, "file name can't be blank")
      return true
    try:
      removeFile(args[0])
    except OSError as e:
      printError(cmd, e.msg)
    return true

  # ==========================================
  # crdir, creates directory
  # ==========================================
  of "crdir":
    if args.len == 0:
      printError(cmd, "dir name can't be blank")
      return true
    try:
      createDir(args[0])
    except OSError as e:
      printError(cmd, e.msg)
    return true

  # ==========================================
  # rmdir, removes dir
  # ==========================================
  of "rmdir":
    if args.len == 0:
      printError(cmd, "dir name can't be blank")
      return true
    try:
      removeDir(args[0])
    except OSError as e:
      printError(cmd, e.msg)
    return true
  
  of "wrfile":
    if args.len < 2:
      printError(cmd, "usage: wrfile FILENAME CONTENT")
      return true
    try:
      let f = open(args[0], fmWrite)
      f.write(args[1])
      f.close()
    except CatchableError as e:
      printError(cmd, e.msg)
    return true

  else:
    if tryRunSystemBinary(cmd, args):
      return true
    return false