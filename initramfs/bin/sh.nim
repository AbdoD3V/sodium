import std/[os, strutils, osproc, envvars, tables, parseutils]
import commands

setControlCHook(proc() {.noconv.} = discard)

const envFile = "envs.var"
var commandHistory: seq[string] = @[]
var fileEnvs = initTable[string, string]()

proc loadFileEnvs() =
  fileEnvs.clear()
  if fileExists(envFile):
    try:
      for line in lines(envFile):
        let stripped = line.strip()
        if stripped.len == 0: continue
        let parts = stripped.split('=', maxsplit = 1)
        if parts.len == 2:
          fileEnvs[parts[0].strip()] = parts[1].strip()
    except CatchableError:
      discard

proc saveFileEnvs() =
  try:
    let f = open(envFile, fmWrite)
    for k, v in fileEnvs.pairs:
      f.writeLine(k & "=" & v)
    f.close()
  except CatchableError:
    discard

proc getCustomEnv(name: string): string =
  if fileEnvs.hasKey(name):
    return fileEnvs[name]
  if name == "HOME":
    return "/userspace"
  return getEnv(name)

proc resetStdin() =
  try:
    stdin.close()
    stdin = open(if defined(windows): "CONIN$" else: "/dev/tty", fmRead)
  except CatchableError:
    discard

proc parseTokensWithQuotes(input: string): seq[string] =
  result = @[]
  var i = 0
  let length = input.len
  while i < length:
    while i < length and input[i] in {' ', '\t'}:
      inc(i)
    if i >= length: break
    if input[i] == '"':
      inc(i)
      var token = ""
      while i < length and input[i] != '"':
        token.add(input[i])
        inc(i)
      if i < length: inc(i)
      result.add(token)
    else:
      var token = ""
      while i < length and not (input[i] in {' ', '\t'}):
        token.add(input[i])
        inc(i)
      result.add(token)

proc expandEnvVars(tokens: seq[string]): seq[string] =
  result = @[]
  for token in tokens:
    if token.startsWith("$") and token.len > 1:
      let varName = token[1..^1]
      let value = getCustomEnv(varName)
      if value.len > 0:
        result.add(value)
      else:
        result.add(token)
    else:
      result.add(token)

proc handleCustomEnvCmds(cmd: string, args: seq[string]): bool =
  if cmd == "setenv":
    if args.len < 2:
      echo "NaSH [setenv error]: Usage: setenv KEY VALUE"
      return true
    let key = args[0]
    let val = args[1..^1].join(" ")
    fileEnvs[key] = val
    saveFileEnvs()
    return true
  elif cmd == "delenv":
    if args.len < 1:
      echo "NaSH [delenv error]: Usage: delenv KEY"
      return true
    fileEnvs.del(args[0])
    saveFileEnvs()
    return true
  elif cmd == "env":
    for k, v in fileEnvs.pairs:
      echo k, "=", v
    return true
  return false
# i cant read the top part anymore, fuck
proc handleHistoryBuiltins(cmd: string): bool =
  if cmd == "history":
    for idx, oldCmd in commandHistory:
      echo idx, "\t", oldCmd
    return true
  return false

proc routeAndExecute(input: string) =
  let cleaned = input.strip()
  if cleaned.len == 0: return

  commandHistory.add(cleaned)

  let rawTokens = parseTokensWithQuotes(cleaned)
  let expandedTokens = expandEnvVars(rawTokens)
  
  if expandedTokens.len == 0: return
  let cmd = expandedTokens[0]
  let args = if expandedTokens.len > 1: expandedTokens[1..^1] else: @[]

  if handleHistoryBuiltins(cmd): return
  if handleCustomEnvCmds(cmd, args): return
  if handleBuiltins(cmd, args): return

  echo "NaSH: command not found: ", cmd

try:
  setCurrentDir("/userspace")
except OSError:
  discard

loadFileEnvs()
stdout.write("\e[2J\e[H")
stdout.flushFile()

echo "NaSH V1.0.0, SodiumOS"

while true:
  try:
    let currentPath = getCurrentDir()
    stdout.write("NaSH [", currentPath, "]}> ")
    stdout.flushFile()
    
    let input = readLine(stdin)
    routeAndExecute(input)
    
  except EOFError:
    echo "" 
    resetStdin()
    sleep(100)