require('pgproc').bind('test')
print(test.fun('world!')['fun'])
print(test.create('{ "some" : "json" }')['create'])

