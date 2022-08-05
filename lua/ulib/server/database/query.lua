local Query = {}
Query.__index = Query

function Query:new( sql ) end

function Query:setDBType( dbtype ) end

function Query:start() end

function Query:isRunning() end

function Query:getData() end
function Query:abort() end
function Query:error() end
function Query:wait() end
function Query:hasMoreResults() end
function Query:getNextResults() end

function Query.onAborted( q ) end
function Query.onError( q, err, sql ) end
function Query.onSuccess( q, data ) end
function Query.onData( q, data ) end

setmetatable( Transaction, {__call = Query.new} )