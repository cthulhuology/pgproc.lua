pgproc.lua
==========

pgproc.lua is a Luajit module that binds stored procedures in a Postgresql database schema to native Lua closures.
This module is designed so that application programmers need not worry about the complexities of the underlying
datamodel, but can consume a procedural API designed by the data curator.  For large teams, where not everyone
working with the data model is a competent SQL programmer, this means the DB Architect can design an interface
that meets the needs of all of the team members, without exposing the complexities of the underlying database.

Dependencies
============

* postgresql 9.x
* luajit 2.x.x

Getting Started
===============

The simplest way to bind a 'test' schema to a native 'test' table is:

	require('pgproc').bind('test')

This will extract the database connection string from an environment variable DB_CONNECT_STRING and will initialize
a connection and bind to the assocaited database.  For those who wish to have more control over the connection,
loading it from a file or the like, you can use the more complete interface:

	pg = require('pgproc')
	pg.connect('dbname=testdb')
	pg.bind('test')

If you create a 'testdb' database on your machine and load the 'test.sql' you can play around with seeing how it 
works:

	createdb testdb
	psql -f ./test.sql testdb
	export DB_CONNECT_STRING="dbname=testdb"
	luajit test.lua

The code to the 'test.lua' file is as follows:

	require('pgproc').bind('test')
	print(test.fun('world!')['fun'])
	print(test.create('{ "some" : "json" }')['create'])
		
If you run this, and then look in the test.objects table in the testdb database you'll see your sample data there.

If you get an error about uuid_generate_v4() missing it is because you are missing the uuid-ossp extension, which can
be installed on Redhat, CentOS, Debian, or Ubuntu by installing the postgresql-contrib RPM or DEB for your platform.

License
=======

pgproc.lua

© 2010, 2013 David J Goehrig <dave@dloh.org>
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the 
following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following 
disclaimer. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and 
the following disclaimer in the documentation and/or other materials provided with the distribution.

Neither the name of the project nor the names of its contributors may be used to endorse or promote products derived
from this software without specific prior written permission.  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

