local timetableHelper = require "celmi/timetables/timetable_helper"

--[[
timetable = {
    line = {
        stations = { stationinfo }
        hasTimetable = true
    }
}

stationInfo = {
    
    conditions = {condition :: Condition},
    inboundTime = 1 :: int
}

conditions = {
    type = "None"| "ArrDep" | "minWait" | "debounce" | "moreFancey"
    ArrDep = {}
    minWait = {}
    debaunce  = {}
    moreFancey = {}
}
--]]
local timetable = { }
local timetableObject = { }
local currentlyWaiting = { }


function timetable.getTimetableObject()
    return timetableObject
end

function timetable.setTimetableObject(t)
    if t then
        timetableObject = t
    end
end

function timetable.setConditionType(line, stationNumber, type)
    stationID = timetableHelper.getStationID(line, stationNumber)
    if not(line and stationNumber) then return -1 end
    if timetableObject[tostring(line)] and timetableObject[tostring(line)].stations[stationNumber] then
        timetableObject[tostring(line)].stations[stationNumber].conditions.type = type
        local conditionObject = timetableObject[tostring(line)].stations[stationNumber].conditions[type] 
        if not conditionObject then  timetableObject[tostring(line)].stations[stationNumber].conditions[type] = {} end
        timetableObject[tostring(line)].stations[stationNumber].stationID = stationID
    else
        if not timetableObject[tostring(line)] then 
            timetableObject[tostring(line)] = { hasTimetable = false, stations = {}}
        end
        
        timetableObject[tostring(line)].stations[stationNumber] = {inboundTime = 0,stationID = stationID, conditions = {type = type}}
        local conditionObject = timetableObject[tostring(line)].stations[stationNumber].conditions[type] 
        if not conditionObject then  timetableObject[tostring(line)].stations[stationNumber].conditions[type] = {} end
    end
end

function timetable.getConditionType(line, stationNumber)
    if not(line and stationNumber) then return "ERROR" end
    if timetableObject[tostring(line)] and timetableObject[tostring(line)].stations[stationNumber] then 
        if timetableObject[tostring(line)].stations[stationNumber].conditions.type then
            return timetableObject[tostring(line)].stations[stationNumber].conditions.type
        else 
            timetableObject[tostring(line)].stations[stationNumber].conditions.type = "None"
            return "None"
        end
    else
        return "None"
    end
end


function timetable.getAllConditionsOfStaion(stationID)
    res = { }
    for k,v in pairs(timetableObject) do
        for k2,v2 in pairs(v.stations) do
            if v2.stationID and v2.conditions and  v2.conditions.type and not (v2.conditions.type == "None") and tostring(v2.stationID) == tostring(stationID+1) then
                res[k] = {
                    stationID = v2.stationID,
                    conditions = v2.conditions
                }
            end
        end
    end
    return res
end

function timetable.getAllConditionsOfAllStations()
    res = { }
    for k,v in pairs(timetableObject) do
        for k2,v2 in pairs(v.stations) do
            if v2.stationID and v2.conditions and  v2.conditions.type and not (v2.conditions.type == "None")  then
                if not res[v2.stationID] then res[v2.stationID] = {} end
                res[v2.stationID][k] = {
                    conditions = v2.conditions
                }
            end
        end
    end
    return res
end

function timetable.getConditions(line, stationNumber, type)
    if not(line and stationNumber) then return -1 end
    if timetableObject[tostring(line)] and timetableObject[tostring(line)].stations[stationNumber] and timetableObject[tostring(line)].stations[stationNumber].conditions[type] then 
        return timetableObject[tostring(line)].stations[stationNumber].conditions[type]
    else
        return -1
    end
end


-- TEST: timetable.addCondition(1,1,{type = "ArrDep", ArrDep = {{12,14,14,14}}})
function timetable.addCondition(line, stationNumber, condition)
    stationID = timetableHelper.getStationID(line, stationNumber)
    if not(line and stationNumber and condition) then return -1 end

    if timetableObject[tostring(line)] and timetableObject[tostring(line)].stations[stationNumber] then
        if condition.type == "ArrDep" then
            timetable.setConditionType(line, stationNumber, condition.type)
            local mergedArrays = timetableHelper.mergeArray(timetableObject[tostring(line)].stations[stationNumber].conditions.ArrDep, condition.ArrDep)
            timetableObject[tostring(line)].stations[stationNumber].conditions.ArrDep = mergedArrays
        elseif condition.type == "minWait" then
            timetableObject[tostring(line)].stations[stationNumber].conditions.type = "minWait"
            timetableObject[tostring(line)].stations[stationNumber].conditions.minWait = condition.minWait
        elseif condition.type == "debounce" then
            timetableObject[tostring(line)].stations[stationNumber].conditions.type = "debounce"
            timetableObject[tostring(line)].stations[stationNumber].conditions.debounce = condition.debounce
        elseif condition.type == "moreFancey" then
            timetableObject[tostring(line)].stations[stationNumber].conditions.type = "moreFancey"
            timetableObject[tostring(line)].stations[stationNumber].conditions.moreFancey = condition.moreFancey     
        end
        timetableObject[tostring(line)].stations[stationNumber].stationID = stationID

    else
        if not timetableObject[tostring(line)] then 
            timetableObject[tostring(line)] = {hasTimetable = false, stations = {}}
        end
        timetableObject[tostring(line)].stations[stationNumber] = {inboundTime = 0, stationID = stationID, conditions = condition}
    end
end

function timetable.updateArrDep(line, station, indexKey, indexValue, value)
    if not (line and station and indexKey and indexValue and value) then return -1 end
    if timetableObject[tostring(line)] and 
       timetableObject[tostring(line)].stations[station] and 
       timetableObject[tostring(line)].stations[station].conditions and 
       timetableObject[tostring(line)].stations[station].conditions.ArrDep and 
       timetableObject[tostring(line)].stations[station].conditions.ArrDep[indexKey] and
       timetableObject[tostring(line)].stations[station].conditions.ArrDep[indexKey][indexValue] then
       timetableObject[tostring(line)].stations[station].conditions.ArrDep[indexKey][indexValue] = value
        return 0
    else
        return -2
    end
end

function timetable.updateDebounce(line, station, indexKey, value)
    if not (line and station and indexKey and value) then return -1 end
    if timetableObject[tostring(line)] and 
       timetableObject[tostring(line)].stations[station] and 
       timetableObject[tostring(line)].stations[station].conditions and 
       timetableObject[tostring(line)].stations[station].conditions.debounce then
       timetableObject[tostring(line)].stations[station].conditions.debounce[indexKey] = value
        return 0
    else
        return -2
    end
end

function timetable.removeCondition(line, station, type, index)
    if not(line and station and index) or (not (timetableObject[tostring(line)] and timetableObject[tostring(line)].stations[station])) then return -1 end

    if type == "ArrDep" then 
        
        local tmpTable = timetableObject[tostring(line)].stations[station].conditions.ArrDep
        if tmpTable and tmpTable[index] then return table.remove(tmpTable, index) end
    else
        -- just remove the whole condition
        local tmpTable = timetableObject[tostring(line)].stations[station].conditions[type]
        if tmpTable and tmpTable[index] then tmpTable = {} end
        return 0
    end
    return -1
end

function timetable.hasTimetable(line)
    
    if timetableObject[tostring(line)] then
        return timetableObject[tostring(line)].hasTimetable
    else
        return false
    end
end

function timetable.waitingRequired(vehicle)
    
    local time = timetableHelper.getTime()
    local currentLine = timetableHelper.getCurrentLine(vehicle)
    local currentStop = timetableHelper.getCurrentStation(vehicle)
    if not timetableObject[tostring(currentLine)] then return false end
    if not timetableObject[tostring(currentLine)].stations[currentStop] then return false end
    if not timetableObject[tostring(currentLine)].stations[currentStop].conditions then return false end
    if not timetableObject[tostring(currentLine)].stations[currentStop].conditions.type then return false end

    if timetableHelper.getTimeUntilDeparture(vehicle) >= 2 then return false end

    if not currentlyWaiting[tostring(currentLine)] then currentlyWaiting[tostring(currentLine)] = {stations = {}} end
    if not currentlyWaiting[tostring(currentLine)].stations[currentStop] then currentlyWaiting[tostring(currentLine)].stations[currentStop] = { currentlyWaiting = {}} end
    if timetableObject[tostring(currentLine)].stations[currentStop].conditions.type == "ArrDep" then 
        -- am I currently waiting or just arrived?
        
        if not (currentlyWaiting[tostring(currentLine)].stations[currentStop].currentlyWaiting[vehicle]) then
            -- check if is about to depart

            if currentlyWaiting[tostring(currentLine)].stations[currentStop].outboundTime and (currentlyWaiting[tostring(currentLine)].stations[currentStop].outboundTime + 40) > time then
                return false
            end

            -- just arrived
            local nextConstraint = timetable.getNextConstraint(timetableObject[tostring(currentLine)].stations[currentStop].conditions.ArrDep, time)
            if not nextConstraint then 
                -- no constraints set
                currentlyWaiting[tostring(currentLine)].stations[currentStop].currentlyWaiting = {}
                return false 
            end
            if timetable.beforeDepature(nextConstraint, time) then
                -- Constraint set and I need to wait
                currentlyWaiting[tostring(currentLine)].stations[currentStop].currentlyWaiting[vehicle] = {type = "ArrDep", arrivalTime = time,  constraint = nextConstraint}
                return true
            else
                -- Constraint set and its time to depart
                currentlyWaiting[tostring(currentLine)].stations[currentStop].outboundTime = time
                currentlyWaiting[tostring(currentLine)].stations[currentStop].currentlyWaiting = {}
                return false
            end
        else
            -- already waiting
            local arivvalTime = currentlyWaiting[tostring(currentLine)].stations[currentStop].currentlyWaiting[vehicle].arrivalTime
            local constraint = timetable.getNextConstraint(timetableObject[tostring(currentLine)].stations[currentStop].conditions.ArrDep, arivvalTime)
            if timetable.beforeDepature(constraint, time) then
                -- need to continue waiting
                return true
            else
                -- done waiting
                currentlyWaiting[tostring(currentLine)].stations[currentStop].outboundTime = time
                currentlyWaiting[tostring(currentLine)].stations[currentStop].currentlyWaiting = {}
                return false
            end
        end
        -- edge cases, should not happen
        currentlyWaiting[tostring(currentLine)].stations[currentStop].outboundTime = time
        currentlyWaiting[tostring(currentLine)].stations[currentStop].currentlyWaiting = {}
        return false

    --------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------- DEBOUNCE ------------------------------------------------------------------------------------
    
    elseif timetableObject[tostring(currentLine)].stations[currentStop].conditions.type == "debounce" then
        local previousDepartureTime = timetableHelper.getPreviousDepartureTime(tonumber(vehicle)) 
        condition = timetable.getConditions(currentLine, currentStop, "debounce")
        if not condition[1] then condition[1] = 0 end
        if not condition[2] then condition[2] = 0 end
        if time > previousDepartureTime + ((condition[1] * 60)  + condition[2]) then
            currentlyWaiting[tostring(currentLine)].stations[currentStop].currentlyWaiting = {}
            return false
        else
            return true
        end
    else 
        currentlyWaiting[tostring(currentLine)].stations[currentStop].currentlyWaiting = {}
        return false
    end
end

function timetable.setHasTimetable(line, bool)
    
    if timetableObject[tostring(line)] then
        timetableObject[tostring(line)].hasTimetable = bool
    else 
        timetableObject[tostring(line)] = {stations = {} , hasTimetable = bool}
    end
    return bool
end



-------------- UTILS FUNCTIONS ----------

function timetable.beforeDepature(constraint, time)
    
    timeMin = tonumber(os.date('%M', time))
    timeSec = tonumber(os.date('%S', time))

    return not (timeMin == constraint[3] and timeSec >= constraint[4]) and not (timeMin - 1 == constraint[3]) and not (timeMin - 2 == constraint[3]) and not  (timeMin - 3 == constraint[3]) and not (timeMin - 4 == constraint[3]) and not (timeMin - 5 == constraint[3])
end

--tests: timetable.getNextConstraint({{30,0,59,0},{9,0,59,0} },1200000)
function timetable.getNextConstraint(constraint, time)
    res = {diff = 40000, value = nil}
    timeMin = tonumber(os.date('%M', time))
    timeSec = tonumber(os.date('%S', time))
    for k,v in pairs(constraint) do
        arrMin = v[1]
        arrSec = v[2]
        diffMin = timetable.getDifference(timeMin, arrMin)
        diffSec = timetable.getDifference(timeSec, arrSec)
        diff = (diffMin * 60) + diffSec
        if(diff < res.diff) then
            res = {diff = diff, value = v}
        end
    end

    return res.value
end

-- returns a value between 0 and 30
function timetable.getDifference(a,b) 
    if math.abs(a - b) < 30 then
        return math.abs(a - b)
    else 
        return 60 - math.abs(a - b)
    end
end



return timetable

