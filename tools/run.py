import lupa.lua51 as l, sys, os
L=l.LuaRuntime()
if len(sys.argv)>1: L.execute('LOCALE="%s"'%sys.argv[1])
f=L.eval('function(p) return loadfile(p) end')('harness.lua')
try:
  f(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
except Exception as e:
  print('ERROR:', e); sys.exit(1)
