local Transaction = {}
Transaction.__index = Transaction

function Transaction:new() end

function Transaction:addQuery( query ) end

function Transaction:getQueries() end

function Transaction:start() end

function Transaction.onError() end

function Transaction.onSuccess() end

setmetatable( Transaction, {__call = Transaction.new} )