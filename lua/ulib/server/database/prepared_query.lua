--[[
    PreparedQuery metatable
    
    @author Aperture Development <developers@aperture-development.de>
    @license by-nc-sa 3.0
    @since NOT-YET-IMPLEMENTED
]]
local PreparedQuery = {}
PreparedQuery.__index = PreparedQuery

--[[
    checkVarType

    local function to help determine if the given variable is of type varType

    @tparam any var Any variable to check the type for
    @tparam string varType The variable type
    @raise Error when the given variable is not of type varType
]]
local function checkVarType( var, varType )
    if type(var) == varType then
        error( varType .. " expected, got " .. type(var))
    end
end

--[[
    PreparedQuery:new
  
    Initializes a new prepared query object  

    @tparam string sql the sql string of the prepared statement
    @tparam string dbtype What db type the prepared query should use. @see ULib.VALID_DB_TYPES for valid values
    @tparam database database The database object which initialized this prepared statement
    @treturn table The Prepared Statement metatable

    @todo dbtype should be a global to not constantly need to pass it to every sub function
]]
function PreparedQuery:new( sql, dbtype, database )
    if not ULib.VALID_DB_TYPES[dbtype] then dbtype = nil end

    local EmptyQuery = {
        query = sql or "",
        dbtype = dbtype or "sqlite",
        database = database
    }

    if self.dbtype == "mysqloo" then
        self.preparedStatement = self.database:getMysqlooDB():prepare(sql)
    end

    setmetatable(EmptyQuery, PreparedQuery)

    return EmptyQuery
end

--[[
    PreparedQuery:start

    Starts the prepared statement
]]
function PreparedQuery:start()
    if self.dbtype == "mysqloo" then
        self.preparedStatement.onAborted = function( q ) self.onAborted( self ) end

        self.preparedStatement.onError = function( q, err, sql )
            self.raisedError = err
            self.onError( self, err, sql )
        end

        self.preparedStatement.onSuccess = function( q, data )
            self.results = data
            self.onSuccess( self, data )
        end

        self.preparedStatement.onData = function( q, data )
            self.results = data
            self.onData( self, data )
        end

        self.preparedStatement:start()
    elseif self.dbtype == "sqlite" then
        -- SQLite functionality
        -- First replace all values which have been defined using the set functions
        local query = string.format( self.query, unpack(self.queryValues) )
        -- Then run the query
        self.results = sql.Query( query )
        -- Check for erros and execute appropriate callback functions
        if self.results == false then
            self.raisedError = sql.LastError()
            self.onError( self, self.raisedError, self.query )
            return
        elseif self.results ~= nil then
            self.resultStack = util.Stack()
            for _, v in pairs(self.results) do
                self.resultStack:Push( v )
            end

            self.onData( self, self.results )
        end
        self.onSuccess( self, self.results )
    end
end

--[[
    PreparedQuery:isRunning

    Returns a boolean to determine if the query is still running or not

    @treturn boolean With mysqloo it determins if the database has finished the query and returns true if so. With sqlite this function returns always false  
]]
function PreparedQuery:isRunning()
    if self.dbtype == "mysqloo" then
        return self.preparedStatement:isRunning()
    elseif self.dbtype == "sqlite" then
        return false
    end
end

--[[
    PreparedQuery:getData

    Returns the data returned by the query.
    WARNING: with mysqloo this function will make the server wait for a response by mysql. This may cause lag spikes. Use this function carefully

    @treturn table The data returned by the query
]]
function PreparedQuery:getData()
    if self.dbtype == "mysqloo" then
        self.preparedStatement:wait()
        return self.preparedStatement:getData()
    elseif self.dbtype == "sqlite" then
        -- SQLite functionality
        return self.results
    end
end

--[[
    PreparedQuery:abort

    Aborts the query execution with mysqloo, does nothing with sqlite
]]
function PreparedQuery:abort()
    if self.dbtype == "mysqloo" then
        -- mysqloo functionality
        self.preparedStatement:abort()
        self.onAborted( self )
    elseif self.dbtype == "sqlite" then
        -- SQLite functionality
        self.onAborted( self )
    end
end

--[[
    PreparedQuery:error

    Returns any error which may have occured while executing this query.

    @treturn string The sql error
]]
function PreparedQuery:error()
    if self.dbtype == "mysqloo" then
        -- mysqloo functionality
        return self.preparedStatement:error()
    elseif self.dbtype == "sqlite" then
        -- SQLite functionality
        return self.raisedError
    end
end

--[[
    PreparedQuery:wait

    Causes the server to wait for the query to be completed. This function has no effect with sqlite
]]
function PreparedQuery:wait()
    if self.dbtype == "mysqloo" then
        -- mysqloo functionality
        self.preparedStatement:wait()
    end
end

--[[
    PreparedQuery:hasMoreResults

    Returns a boolean if there are still elements left in the results

    @treturn boolean True when there is still data left to be poped, false if not
]]
function PreparedQuery:hasMoreResults()
    if self.dbtype == "mysqloo" then
        -- mysqloo functionality
        return self.preparedStatement:hasMoreResults()
    elseif self.dbtype == "sqlite" then
        -- SQLite functionality
        if self.resultStack:Size() >= 1 then
            return true
        else
            return false
        end
    end
end

--[[
    PreparedQuery:getNextResults

    Pops a row off of the result set of the query

    @treturn table A result set if there are still results left
    @raise Error when there are no more results left to be poped
]]
function PreparedQuery:getNextResults()
    if self.dbtype == "mysqloo" then
        -- mysqloo functionality
        return self.preparedStatement:getNextResults()
    elseif self.dbtype == "sqlite" then
        -- SQLite functionality
        return self.resultStack:Pop()
    end
end

--[[
    PreparedQuery:setNumber

    Sets a number value at the specified index

    @tparam number index The index to place the number at
    @tparam number number The number value to place at the given index
]]
function PreparedQuery:setNumber( index, number )
    checkVarType(index, "number")
    checkVarType(number, "number")

    if self.dbtype == "mysqloo" then
        self.preparedStatement:setNumber( index, number )
    elseif self.dbtype == "sqlite" then
        -- SQLite functionality
        self.queryValues[index] = number
    end
end

--[[
    PreparedQuery:setString

    Sets a string value at the specified index

    @tparam number index The index to place the string at
    @tparam string string The string value to place at the given index
]]
function PreparedQuery:setString( index, str )
    checkVarType(index, "number")
    checkVarType(str, "string")

    if self.dbtype == "mysqloo" then
        self.preparedStatement:setString( index, str )
    elseif self.dbtype == "sqlite" then
        -- SQLite functionality
        self.queryValues[index] = sql.SQLStr( str )
    end
end

--[[
    PreparedQuery:setBoolean

    Sets a boolean value at the specified index

    @tparam number index The index to place the boolean at
    @tparam boolean bool The boolean value to place at the given index
]]
function PreparedQuery:setBoolean( index, bool )
    checkVarType(index, "number")
    checkVarType(bool, "boolean")

    if self.dbtype == "mysqloo" then
        self.preparedStatement:setBoolean( index, bool )
    elseif self.dbtype == "sqlite" then
        -- SQLite functionality
        self.queryValues[index] = bool
    end
end

--[[
    PreparedQuery:setNull

    Sets a null value at the specified index

    @tparam number index The index to place the null value at
]]
function PreparedQuery:setNull( index )
    checkVarType(index, "number")

    if self.dbtype == "mysqloo" then
        self.preparedStatement:setNull( index )
    elseif self.dbtype == "sqlite" then
        -- SQLite functionality
        self.queryValues[index] = "null"
    end
end

--[[
    PreparedQuers:clearParameters

    Clears all paramaters from the prepared query and reverts it back to its original value
]]
function PreparedQuery:clearParameters()
    if self.dbtype == "mysqloo" then
        -- mysqloo functionality
        self.preparedStatement:clearParameters()
    elseif self.dbtype == "sqlite" then
        -- SQLite functionality
        self.queryValues[index] = {}
    end
end

--[[
    PreparedQuery.onAborted

    Placeholder function to be replaced by the user to wait for the query asynchroniously.
    This placeholder is executed when the query has been aborted

    @tparam table q This query object
]]
function PreparedQuery.onAborted( q ) end

--[[
    PreparedQuery.onError

    Placeholder function to be replaced by the user to wait for the query asynchroniously.
    This placeholder is executed when the query has errored

    @tparam table q This query object
    @tparam string err The error
    @tparam string sql The query
]]
function PreparedQuery.onError( q, err, sql ) end

--[[
    PreparedQuery.onSuccess

    Placeholder function to be replaced by the user to wait for the query asynchroniously.
    This placeholder is executed when the query has finished successfully

    @tparam table q This query object
    @tparam table data The data returned by this query. this value can be nil is the query has not returned any data
]]
function PreparedQuery.onSuccess( q, data ) end

--[[
    PreparedQuery.onData

    Placeholder function to be replaced by the user to wait for the query asynchroniously.
    This placeholder is executed when the query has finished successfully and returned data

    @tparam table q This query object
    @tparam table data The data returned by this query
]]
function PreparedQuery.onData( q, data ) end

setmetatable( Transaction, {__call = PreparedQuery.new} )