local timetable = require "celmi/timetables/timetable"
local timetableHelper = require "celmi/timetables/timetable_helper"

local gui = require "gui"

local clockstate = nil

local menu = {window = nil, lineTableItems = {}}

local count = 0

local UIState = { 
    currentlySelectedLineTableIndex = nil ,
    currentlySelectedStationIndex = nil,
    currentlySelectedConstraintType = nil
}

local state = nil
-------------------------------------------------------------
---------------------- SETUP --------------------------------
-------------------------------------------------------------

function initLineTable() 
    if menu.scrollArea then UIState.boxlayout2:removeItem(menu.scrollArea) end
    if menu.lineHeader then UIState.boxlayout2:removeItem(menu.lineHeader) end

    menu.lineHeader = api.gui.comp.Table.new(6, 'None')
    local sortAll   = api.gui.comp.ToggleButton.new(api.gui.comp.TextView.new('All'))    
    local sortBus   = api.gui.comp.ToggleButton.new(api.gui.comp.ImageView.new("ui/icons/game-menu/hud_filter_road_vehicles.tga"))
    local sortTram  = api.gui.comp.ToggleButton.new(api.gui.comp.ImageView.new("ui/TimetableTramIcon.tga"))
    local sortRail  = api.gui.comp.ToggleButton.new(api.gui.comp.ImageView.new("ui/icons/game-menu/hud_filter_trains.tga"))
    local sortWater = api.gui.comp.ToggleButton.new(api.gui.comp.ImageView.new("ui/icons/game-menu/hud_filter_ships.tga"))
    local sortAir   = api.gui.comp.ToggleButton.new(api.gui.comp.ImageView.new("ui/icons/game-menu/hud_filter_planes.tga"))

    menu.lineHeader:addRow({sortAll,sortBus,sortTram,sortRail,sortWater,sortAir})
    
    menu.scrollArea = api.gui.comp.ScrollArea.new(api.gui.comp.TextView.new('LineOverview'), "timetable.LineOverview")
    menu.lineTable = api.gui.comp.Table.new(3, 'SINGLE')
    menu.lineTable:setColWidth(0,28)

    menu.lineTable:onSelect(function(index)
        if not index == -1 then UIState.currentlySelectedLineTableIndex = index end
        UIState.currentlySelectedStationIndex = 0
        fillStationTable(index, true)
    end)

    menu.lineTable:setColWidth(1,240)

    menu.scrollArea:setMinimumSize(api.gui.util.Size.new(300, 670))
    menu.scrollArea:setMaximumSize(api.gui.util.Size.new(300, 670))
    menu.scrollArea:setContent(menu.lineTable)
    

    UIState.boxlayout2:addItem(menu.lineHeader,0,0)
    UIState.boxlayout2:addItem(menu.scrollArea,0,1)
    fillLineTable()
    
    sortAll:onToggle(function(bool)
        for k,v in pairs(menu.lineTableItems) do       
            v[1]:setVisible(true,false)
            v[2]:setVisible(true,false)
            v[3]:setVisible(true,false)
        end
        sortBus:setSelected(false,false)
        sortTram:setSelected(false,false)
        sortRail:setSelected(false,false)
        sortWater:setSelected(false,false)
        sortAir:setSelected(false,false)
        sortAll:setSelected(true,false)
    end)

    sortBus:onToggle(function(bool)
        linesOfType = timetableHelper.isLineOfType("ROAD")
        for k,v in pairs(menu.lineTableItems) do
            v[1]:setVisible(linesOfType[k],false)
            v[2]:setVisible(linesOfType[k],false)
            v[3]:setVisible(linesOfType[k],false)
        end
        sortBus:setSelected(true,false)
        sortTram:setSelected(false,false)
        sortRail:setSelected(false,false)
        sortWater:setSelected(false,false)
        sortAir:setSelected(false,false)
        sortAll:setSelected(false,false)
    end)

    sortTram:onToggle(function(bool)
        linesOfType = timetableHelper.isLineOfType("TRAM")
        for k,v in pairs(menu.lineTableItems) do
            v[1]:setVisible(linesOfType[k],false)
            v[2]:setVisible(linesOfType[k],false)
            v[3]:setVisible(linesOfType[k],false)
        end
        sortBus:setSelected(false,false)
        sortTram:setSelected(true,false)
        sortRail:setSelected(false,false)
        sortWater:setSelected(false,false)
        sortAir:setSelected(false,false)
        sortAll:setSelected(false,false)
    end)
    sortRail:onToggle(function(bool)
        linesOfType = timetableHelper.isLineOfType("RAIL")
        for k,v in pairs(menu.lineTableItems) do
            v[1]:setVisible(linesOfType[k],false)
            v[2]:setVisible(linesOfType[k],false)
            v[3]:setVisible(linesOfType[k],false)
        end
        sortBus:setSelected(false,false)
        sortTram:setSelected(false,false)
        sortRail:setSelected(true,false)
        sortWater:setSelected(false,false)
        sortAir:setSelected(false,false)
        sortAll:setSelected(false,false)
    end)
    sortWater:onToggle(function(bool)
        linesOfType = timetableHelper.isLineOfType("WATER")
        for k,v in pairs(menu.lineTableItems) do
            v[1]:setVisible(linesOfType[k],false)
            v[2]:setVisible(linesOfType[k],false)
            v[3]:setVisible(linesOfType[k],false)
        end
        sortBus:setSelected(false,false)
        sortTram:setSelected(false,false)
        sortRail:setSelected(false,false)
        sortWater:setSelected(true,false)
        sortAir:setSelected(false,false)
        sortAll:setSelected(false,false)
    end)
    sortAir:onToggle(function(bool)
        linesOfType = timetableHelper.isLineOfType("AIR")
        for k,v in pairs(menu.lineTableItems) do
            v[1]:setVisible(linesOfType[k],false)
            v[2]:setVisible(linesOfType[k],false)
            v[3]:setVisible(linesOfType[k],false)
        end
        sortBus:setSelected(false,false)
        sortTram:setSelected(false,false)
        sortRail:setSelected(false,false)
        sortWater:setSelected(false,false)
        sortAir:setSelected(true,false)
        sortAll:setSelected(false,false)
    end)
end

function initStationTable() 
    if menu.stationScrollArea then UIState.boxlayout2:removeItem(menu.stationScrollArea) end

    menu.stationScrollArea = api.gui.comp.ScrollArea.new(api.gui.comp.TextView.new('stationScrollArea'), "timetable.stationScrollArea")
    menu.stationTable = api.gui.comp.Table.new(4, 'SINGLE')
    menu.stationTable:setColWidth(0,40)
    menu.stationTable:setColWidth(1,120)
    menu.stationScrollArea:setMinimumSize(api.gui.util.Size.new(500, 700))
    menu.stationScrollArea:setMaximumSize(api.gui.util.Size.new(500, 700))
    menu.stationScrollArea:setContent(menu.stationTable)
    UIState.boxlayout2:addItem(menu.stationScrollArea,0.5,0)
end

function initConstraintTable()
    if menu.scrollAreaConstraint then UIState.boxlayout2:removeItem(menu.scrollAreaConstraint) end

    menu.scrollAreaConstraint = api.gui.comp.ScrollArea.new(api.gui.comp.TextView.new('scrollAreaConstraint'), "timetable.scrollAreaConstraint")
    menu.constraintTable = api.gui.comp.Table.new(1, 'NONE')  
    menu.scrollAreaConstraint:setMinimumSize(api.gui.util.Size.new(300, 700))
    menu.scrollAreaConstraint:setMaximumSize(api.gui.util.Size.new(300, 700))
    menu.scrollAreaConstraint:setContent(menu.constraintTable)
    UIState.boxlayout2:addItem(menu.scrollAreaConstraint,1,0)
end

function showLineMenu()
    if menu.window ~= nil then
        initLineTable()
        return menu.window:setVisible(true, true)  
    end
    -- new folting layout to arrange all members
    local floatingLayout = api.gui.layout.FloatingLayout.new(0,1)
    floatingLayout:setId("timetable.floatingLayout")
    
    UIState.boxlayout2 = api.gui.util.getById('timetable.floatingLayout')
    UIState.boxlayout2:setGravity(-1,-1)

    initLineTable()
    initStationTable() 
    initConstraintTable()


    -- create final window
    menu.window = api.gui.comp.Window.new('Timetables',  floatingLayout)
    menu.window:addHideOnCloseHandler()
    menu.window:setMovable(true)
    menu.window:setPinButtonVisible(true)
    menu.window:setResizable(false)
    menu.window:setSize(api.gui.util.Size.new(1100, 740))
    menu.window:setPosition(200,200)

end

-------------------------------------------------------------
---------------------- LEFT TABLE ---------------------------
-------------------------------------------------------------

function fillLineTable()
    menu.lineTable:deleteRows(0,menu.lineTable:getNumRows())
    print("filling line table")
    local lineNames = {}
    for k,v in pairs(timetableHelper.getAllRailLines()) do
        local lineColour = api.gui.comp.TextView.new("●")
        lineColour:setName("timetable-linecolour-" .. timetableHelper.getLineColour(v.id))
        lineColour:setStyleClassList({"timetable-linecolour"})
        lineName = api.gui.comp.TextView.new(v.name)
        lineNames[k] = v.name
        lineName:setName("timetable-linename")
        local buttonImage = api.gui.comp.ImageView.new("ui/checkbox0.tga")
        if timetable.hasTimetable(v.id) then buttonImage:setImage("ui/checkbox1.tga", false) end
        local button = api.gui.comp.Button.new(buttonImage, true)
        button:setStyleClassList({"timetable-avtivateTimetableButton"})
        button:setGravity(1,0.5)
        button:onClick(function()
            imageVeiw = buttonImage
            hasTimetable = timetable.hasTimetable(v.id)
            if  hasTimetable then
                timetable.setHasTimetable(v.id,false)
                imageVeiw:setImage("ui/checkbox0.tga", false)
            else
                timetable.setHasTimetable(v.id,true)
                imageVeiw:setImage("ui/checkbox1.tga", false)
            end
        end)
        menu.lineTableItems[#menu.lineTableItems + 1] = {lineColour, lineName, button}
        menu.lineTable:addRow({lineColour,lineName, button})
    end

    local order = timetableHelper.getOrderOfArray(lineNames)
    menu.lineTable:setOrder(order)
end

-------------------------------------------------------------
---------------------- Middle TABLE -------------------------
-------------------------------------------------------------

-- params
-- index: index of currently selected line
-- bool: emit select signal when building table
function fillStationTable(index, bool)
    --initial checks
    if not index then return end
    if not(timetableHelper.getAllRailLines()[index+1]) or (not menu.stationTable)then return end
    
    -- initial cleanup
    menu.stationTable:deleteAll()

    UIState.currentlySelectedLineTableIndex = index
    local lineID = timetableHelper.getAllRailLines()[index+1].id
    
    

    --iterate over all stations to display them
    for k, v in pairs(timetableHelper.getAllStations(lineID)) do
        local lineImage = api.gui.comp.ImageView.new("ui/timetable_line.tga")
        local station = timetableHelper.getStation(v)
        local stationNumber = api.gui.comp.TextView.new(tostring(k))
        stationNumber:setStyleClassList({"timetable-stationcolour"})
        stationNumber:setName("timetable-stationcolour-" .. timetableHelper.getLineColour(lineID))
        stationNumber:setMinimumSize(api.gui.util.Size.new(30, 30))
        
        

        local conditionType = timetable.getConditionType(lineID, k)
        local conditionString = api.gui.comp.TextView.new(timetableHelper.conditionToString(timetable.getConditions(lineID, k, conditionType), conditionType))
        conditionString:setName("conditionString")
              

        conditionString:setMinimumSize(api.gui.util.Size.new(285,50))
        conditionString:setMaximumSize(api.gui.util.Size.new(285,50))

      
        menu.stationTable:addRow({stationNumber,api.gui.comp.TextView.new(station.name), lineImage, conditionString})       
    end

    menu.stationTable:onSelect(function (index)
        if not (index == -1) then 
            debugPrint(timetable.getTimetableObject())
            UIState.currentlySelectedStationIndex = index 
            initConstraintTable()
            fillConstraintTable(index,lineID,index) 
        end
        
    end)

    -- keep track of currently selected station and resets if nessesarry
    if UIState.currentlySelectedStationIndex then 
        if menu.stationTable:getNumRows() > UIState.currentlySelectedStationIndex and not(menu.stationTable:getNumRows() == 0)  then
            menu.stationTable:select(UIState.currentlySelectedStationIndex, bool)
        end
    else
        --menu.stationTable:select(0, bool)
    end

end

-------------------------------------------------------------
---------------------- Right TABLE --------------------------
-------------------------------------------------------------

function clearConstraintWindow() 
    -- initial cleanup
    menu.constraintTable:deleteRows(1, menu.constraintTable:getNumRows())
end

function fillConstraintTable(index,lineID, lineNumber)
    --initial cleanup
    if index == -1 then
        menu.constraintTable:deleteAll()
        return 
    end
    index = index + 1
    menu.constraintTable:deleteAll()
    

    -- combobox setup
    local comboBox = api.gui.comp.ComboBox.new()
    comboBox:addItem("No Timetable")
    comboBox:addItem("Arrival/Departure")
    comboBox:addItem("Minimum Wait")
    comboBox:addItem("Unbunch")
    comboBox:addItem("Every X minutes")
    comboBox:setGravity(1,0)

    constraintIndex = timetableHelper.constraintStringToInt(timetable.getConditionType(lineID, index))

     
    
         
    comboBox:onIndexChanged(function (i)
        if i == -1 then return end
        timetable.setConditionType(lineID, index, timetableHelper.constraintIntToString(i))
        initStationTable()
        fillStationTable(UIState.currentlySelectedLineTableIndex, false)
        currentlySelectedConstraintType = i

        clearConstraintWindow() 
        if i == 1 then
            makeArrDepWindow(lineID, index) 
        end
    end)

    infoImage = api.gui.comp.ImageView.new("ui/info_small.tga")
    infoImage:setTooltip(
        "You can add timetable constraints to each station.\n" ..
        "When a train arrives at the station it will try to \n" ..
        "keep the constraints. The following constraints are awailabe: \n" ..
        "  - Arrival/Departure: Set multiple Arr/Dep times and the train \n"..
        "                                      chooses the closes arrival time"
    )
    infoImage:setName("timetable-info-icon")

    local table = api.gui.comp.Table.new(2, 'NONE')
    table:addRow({infoImage,comboBox})
    menu.constraintTable:addRow({table})
    
    comboBox:setSelected(constraintIndex, true)
end

function makeArrDepWindow(lineID, stationID) 
    if not menu.constraintTable then return end 
    conditions = timetable.getConditions(lineID,stationID, "ArrDep")

    -- setup add button
    local addButton = api.gui.comp.Button.new(api.gui.comp.TextView.new("Add") ,true)
    addButton:setGravity(1,0)
    addButton:onClick(function() 
        timetable.addCondition(lineID,stationID, {type = "ArrDep", ArrDep = {{0,0,0,0}}})
        clearConstraintWindow() 
        makeArrDepWindow(lineID, stationID)
        initStationTable()
        fillStationTable(UIState.currentlySelectedLineTableIndex, false)
    end)

    --setup header
    headerTable = api.gui.comp.Table.new(4, 'NONE')
    headerTable:setColWidth(0,125)
    headerTable:setColWidth(1,78)
    headerTable:setColWidth(2,38)
    headerTable:setColWidth(3,50)
    headerTable:addRow({api.gui.comp.TextView.new(""),api.gui.comp.TextView.new("min"),api.gui.comp.TextView.new("sec"),addButton})
    menu.constraintTable:addRow({headerTable}) 



    -- setup arrival and depature content
    for k,v in pairs(conditions) do
        menu.constraintTable:addRow({api.gui.comp.Component.new("HorizontalLine")})


        linetable = api.gui.comp.Table.new(5, 'NONE')
        arivalLabel =  api.gui.comp.TextView.new("Arrival:  ")
        arivalLabel:setMinimumSize(api.gui.util.Size.new(80, 30))
        arivalLabel:setMaximumSize(api.gui.util.Size.new(80, 30))

        arrivalMin = api.gui.comp.DoubleSpinBox.new()
        arrivalMin:setMinimum(0,false)
        arrivalMin:setMaximum(59,false)
        arrivalMin:setValue(v[1],false)
        arrivalMin:onChange(function(value)
            timetable.updateArrDep(lineID, stationID, k, 1, value)
            initStationTable()
            fillStationTable(UIState.currentlySelectedLineTableIndex, false) 
        end)

        arrivalSec = api.gui.comp.DoubleSpinBox.new()
        arrivalSec:setMinimum(0,false)
        arrivalSec:setMaximum(59,false)
        arrivalSec:setValue(v[2],false)
        arrivalSec:onChange(function(value) 
            timetable.updateArrDep(lineID, stationID, k, 2, value)
            initStationTable()
            fillStationTable(UIState.currentlySelectedLineTableIndex, false) 
        end)

        deleteButton = api.gui.comp.Button.new(api.gui.comp.TextView.new("X") ,true)
        deleteButton:onClick(function()
            timetable.removeCondition(lineID, stationID, "ArrDep", k)
            clearConstraintWindow()
            makeArrDepWindow(lineID, stationID) 
            initStationTable()
            fillStationTable(UIState.currentlySelectedLineTableIndex, false) 

        end)

        linetable:addRow({
            arivalLabel,  
            arrivalMin,
            api.gui.comp.TextView.new(":"),
            arrivalSec,
            deleteButton
        })
        menu.constraintTable:addRow({linetable})

        

        departureLabel =  api.gui.comp.TextView.new("Departure:  ")
        departureLabel:setMinimumSize(api.gui.util.Size.new(80, 30))
        departureLabel:setMaximumSize(api.gui.util.Size.new(80, 30))
        departureMin = api.gui.comp.DoubleSpinBox.new()
        departureMin:setMinimum(0,false)
        departureMin:setMaximum(59,false)
        departureMin:setValue(v[3],false)
        departureMin:onChange(function(value) 
            timetable.updateArrDep(lineID, stationID, k, 3, value)
            initStationTable()
            fillStationTable(UIState.currentlySelectedLineTableIndex, false) 
        end)

        departureSec = api.gui.comp.DoubleSpinBox.new()
        departureSec:setMinimum(0,false)
        departureSec:setMaximum(59,false)
        departureSec:setValue(v[4],false)
        departureSec:onChange(function(value) 
            timetable.updateArrDep(lineID, stationID, k, 4, value)
            initStationTable()
            fillStationTable(UIState.currentlySelectedLineTableIndex, false) 
        end)


        deletePlaceholder = api.gui.comp.TextView.new(" ")
        deletePlaceholder:setMinimumSize(api.gui.util.Size.new(12, 30))
        deletePlaceholder:setMaximumSize(api.gui.util.Size.new(12, 30))

        linetable2 = api.gui.comp.Table.new(5, 'NONE')
        linetable2:addRow({
            departureLabel,  
            departureMin,
            api.gui.comp.TextView.new(":"),
            departureSec,
            deletePlaceholder
        })
        menu.constraintTable:addRow({linetable2})


        menu.constraintTable:addRow({api.gui.comp.Component.new("HorizontalLine")})
    end
    
    

end 

-------------------------------------------------------------
--------------------- OTHER ---------------------------------
-------------------------------------------------------------
function data()
    return {
        --engine Thread

        handleEvent = function (src, id, name, param)
            if id == "timetableUpdate" then
                if state == nil then state = {timetable = {}} end
                state.timetable = param
                timetable.setTimetableObject(state.timetable) 
            end
        end,

        save = function()
            return state
        end,
        
        load = function(loadedState)
            if loadedState == nil  or next(loadedState) == nil then  return end
            if loadedState.timetable then 
                if state == nil then 
                    timetable.setTimetableObject(loadedState.timetable) 
                end
            end
            state = loadedState or {timetable = {}}
        end,

        update = function()
            if count == nil then count = 0 end
            count = count + 1
            if count == 10 then 
                -- go through all vehicles and enforce waiting if neccesarry
                for vehicle,line in pairs(timetableHelper.getAllRailVehicles()) do
                    if timetableHelper.isInStation(vehicle) then
                        if timetable.hasTimetable(line) and timetable.waitingRequired(vehicle) then
                            timetableHelper.stopVehicle(vehicle)
                        else
                            timetableHelper.startVehicle(vehicle)
                        end
                    end
                end    
                count = 0
            end
            if state == nil then state = {timetable = {}} end
            state.timetable = timetable.getTimetableObject()
            
        end,

        guiUpdate = function()
            game.interface.sendScriptEvent("timetableUpdate", "", timetable.getTimetableObject() )
            
			
            if not clockstate then
				-- element for the divider
				local line = api.gui.comp.Component.new("VerticalLine")
				-- element for the icon
                local icon = api.gui.comp.ImageView.new("ui/clock_small.tga")	
                -- element for the time
				clockstate = api.gui.comp.TextView.new("gameInfo.time.label")

                
                local buttonLabel = gui.textView_create("gameInfo.timetables.label", "Timetable")
                local button = gui.button_create("gameInfo.timetables.button", buttonLabel)
                button:onClick(showLineMenu)
                game.gui.boxLayout_addItem("gameInfo.layout", button.id)
				-- add elements to ui
				local gameInfoLayout = api.gui.util.getById("gameInfo"):getLayout()
				gameInfoLayout:addItem(line) 
				gameInfoLayout:addItem(icon) 
				gameInfoLayout:addItem(clockstate)
            end
          
            local time = timetableHelper.getTime() 
            
            if clockstate and time then
                clockstate:setText(os.date('%M:%S', time))
            end     
        end
    }
end
