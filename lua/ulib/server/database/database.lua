local Database = {}
Database.__index = Database

-- Metatable should be created at ULib.database

function Database:new(dbtype, host, port, user, password, database) 
    -- If type mysql then create new database connection and set its meta
    local connectionData = {
        dbtype = dbtype or "sqlite",
        host = host or "localhost",
        port = port or 3306,
        user = user or "ulib",
        password = password or "ulib",
        database = database or "ulib"
    }

    setmetatable(connectionData, Database)

    if dbtype == "mysqloo" and (not file.Exists( "bin/gmsv_mysqloo_linux.dll", "LUA" ) or not file.Exists( "bin/gmsv_mysqloo_win32.dll", "LUA" ) or not file.Exists( "bin/gmsv_mysqloo_linux64.dll", "LUA" ) or not file.Exists( "bin/gmsv_mysqloo_win64.dll", "LUA" )) then
        self.dbtype = "sqlite"
        ULib.error("[ULib] MySQLoo has not been installed. Resorting back to sqlite storage")
    end

    return connectionData
end

function Database:query( sql )
    -- return new query
end

function Database:prepare( sql )
    -- return new prepared query
end

function Database:createTransaction()
    -- return new transaction
end

function Database:escape( str )
    -- return escaped string
end

function Database:connect()
    if self.dbtype == "mysqloo" then
        require("mysqloo")
        self.mysqloo = mysqloo.connect( self.host, self.username, self.password, self.database, self.port)
        self.mysqloo.onConnected = function( db )
            self.connected = true
            self.onConnected( db )
        end
        self.onConnectionFailed = function( db, err )
            self.connected = false
            self.onConnectionFailed( db, err )
        end
        self.mysqloo:connect()
    elseif self.dbtype == "sqlite" then
        self.connected = true
        self.onConnected()
    end
end

function Database:disconnect()
    if self.dbtype == "mysqloo" and self.connected then
        self.mysqloo:disconnect()
        self.connected = false
    elseif self.dbtype == "sqlite" then
        self.connected = false
    end
end

function Database:getDBType()
    return self.dbtype
end

function Database:getMysqlooDb()
    return self.mysqloo or false
end

function Database.onConnected( db ) end

function Database.onConnectionFailed( db, err ) end

setmetatable( Database, {__call = Database.new})