-- pgproc module
-- 
-- © 2010, 2013 David J Goehrig <dave@dloh.org>
--
-- Copyright (c) 2010, 2013, David J Goehrig <dave@dloh.org>
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without modification, are permitted provided that the 
-- following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice, this list of conditions and the following 
-- disclaimer. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and 
-- the following disclaimer in the documentation and/or other materials provided with the distribution.
--
-- Neither the name of the project nor the names of its contributors may be used to endorse or promote products derived
-- from this software without specific prior written permission.  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
-- CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
-- MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
-- CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--

module("pgproc",package.seeall)

local pg = {}

local ffi = require('ffi')
ffi.cdef([[
typedef enum { CONNECTION_OK, CONNECTION_BAD, CONNECTION_STARTED, CONNECTION_MADE, CONNECTION_AWAITING_RESPONSE, CONNECTION_AUTH_OK, CONNECTION_SETENV, CONNECTION_SSL_STARTUP, CONNECTION_NEEDED } ConnStatusType;

typedef enum { PGRES_EMPTY_QUERY = 0, PGRES_COMMAND_OK, PGRES_TUPLES_OK, PGRES_COPY_OUT, PGRES_COPY_IN, PGRES_BAD_RESPONSE, PGRES_NONFATAL_ERROR, PGRES_COPY_BOTH } ExecStatusType;

typedef struct pg_conn PGconn;
typedef struct pg_result PGresult;
typedef struct pg_cancel PGcancel;
typedef char pqbool;

typedef struct pgNotify { char *relname; int be_pid; char *extra; struct pgNotify *next; } PGnotify;

typedef void (*PQnoticeReceiver) (void *arg, const PGresult *res);
typedef void (*PQnoticeProcessor) (void *arg, const char *message);

extern PGconn *PQconnectdb(const char *conninfo);
extern void PQfinish(PGconn *conn);
extern void PQclear(PGresult *res);
extern void PQfreemem(void *ptr);
extern ExecStatusType PQresultStatus(const PGresult *res);
extern char *PQgetvalue(const PGresult *res, int tup_num, int field_num);
extern char *PQresultErrorMessage(const PGresult *res);
extern PGresult *PQexec(PGconn *conn, const char *query);
extern ExecStatusType PQresultStatus(const PGresult *res);
extern int PQntuples(const PGresult *res);
extern int PQnfields(const PGresult *res);
extern char *PQfname(const PGresult *res, int field_num);
extern size_t PQescapeStringConn(PGconn *conn,char *to, const char *from, size_t length, int *error);
extern ConnStatusType PQstatus(const PGconn *conn);

]])

local sql = ffi.load('libpq')
pg.ffi = ffi
pg.sql = sql
pg.connection = nil

function pg.connect(connstr)
	pg.connstr = connstr or os.getenv('DB_CONNECT_STRING') 
	pg.connection = sql.PQconnectdb(pg.connstr)
	if not sql.PQstatus(pg.connection) == sql.CONNECTION_OK then
		pg.connection = nil
		return nil
	end
end

function pg.reset()
	sql.PQclear(pg.result) 
	pg.result = nil
end

function pg.error()
	return ffi.string(sql.PQresultErrorMessage(pg.result))
end

function pg.query(Q)
	if not pg.connection then pg.connect() end
	if pg.result then pg.reset() end
	pg.result = sql.PQexec(pg.connection,Q)
	pg.status = sql.PQresultStatus(pg.result)
	if pg.status == sql.PGRES_EMPTY_QUERY or pg.status == sql.PGRES_COMMAND_OK then
		pg.reset()
		return 0
	end
	if pg.status == sql.PGRES_TUPLES_OK then
		return sql.PQntuples(pg.result)
	end
	print(pg.error())
	pg.reset()
	return -1
end

function pg.fields()
	if not pg.result then return 0 end
	return sql.PQnfields(pg.result)
end

function pg.field(I)
	if not pg.result then return nil end
	return ffi.string(sql.PQfname(pg.result,I))
end

function pg.fetch(Row,Column)
	if not pg.result then return nil end
	return ffi.string(sql.PQgetvalue(pg.result,Row,Column))	
end
	
function pg.close()
	sql.PQfinish(pg.connection)
	pg.connection = nil
	pg.reset()
end

function pg.quote(S)
	if not pg.connection then return nil end
	local error = ffi.new('int[1]')
	local buffer = ffi.new('char[?]', 2*#S)
	local len = sql.PQescapeStringConn(pg.connection,buffer,S,#S,error)
	if error[0] then 
		print("Failed to escape " .. S) 
		return nil
	end
	return ffi.string(buffer,len)
end

function pg.bind(schema)
	local query = "select proc.proname::text from pg_proc proc join pg_namespace namesp on proc.pronamespace = namesp.oid where namesp.nspname = '" .. schema .. "'"
	_G[schema] = {}
	local rows = pg.query(query)
	if rows < 0 then
		print(pg.error())
		return -1
	end
	local i = 0
	while i < rows do
		local proc = pg.fetch(i,0);
		local F = function() 
			local query = "select * from  " .. schema .. "." .. proc .. "('"
			return function(...)	
				local Q  = query .. table.concat({...},"','") .."')"
				print (Q)
				local rows = pg.query(Q)
				local R = {}
				local k,j = 0,0
				while k < rows do
					while j < pg.fields() do
						local key = pg.field(j)
						local value = pg.fetch(k,j)
						print(key .. " => " .. value)
						R[key] = value
						j = j+1
					end
					k = k+1
				end
				return R
      			end
		end
		_G[schema][proc] = F()
		i = i+1
	end	
end

return pg
