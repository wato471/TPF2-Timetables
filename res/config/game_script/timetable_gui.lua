local timetable = require "celmi/timetables/timetable"
local timetableHelper = require "celmi/timetables/timetable_helper"

local gui = require "gui"

local clockstate = nil

local menu = {window = nil, lineTableItems = {}}

local count = 0

local UIState = { 
    currentlySelectedLineTableIndex = nil ,
    currentlySelectedStationIndex = nil,
    currentlySelectedConstraintType = nil,
    currentlySelectedStationTabStation = nil
}
local co = nil
local state = nil

-------------------------------------------------------------
---------------------- stationTab ---------------------------
-------------------------------------------------------------

function initStationTab()
    if menu.stationTabScrollArea then UIState.floatingLayoutStationTab:removeItem(menu.scrollArea) end

    --left table
    menu.stationTabScrollArea = api.gui.comp.ScrollArea.new(api.gui.comp.TextView.new('StationOverview'), "timetable.stationTabStationOverviewScrollArea")
    menu.stationTabStationTable = api.gui.comp.Table.new(1, 'SINGLE')
    menu.stationTabScrollArea:setMinimumSize(api.gui.util.Size.new(300, 700))
    menu.stationTabScrollArea:setMaximumSize(api.gui.util.Size.new(300, 700))
    menu.stationTabScrollArea:setContent(menu.stationTabStationTable)
    fillStationTabStationTable()
    UIState.floatingLayoutStationTab:addItem(menu.stationTabScrollArea,0,0)

    
    menu.stationTabLinesScrollArea = api.gui.comp.ScrollArea.new(api.gui.comp.TextView.new('LineOverview'), "timetable.stationTabLinesScrollArea")
    menu.stationTabLinesTable = api.gui.comp.Table.new(3, 'NONE')
    menu.stationTabLinesScrollArea:setMinimumSize(api.gui.util.Size.new(799, 700))
    menu.stationTabLinesScrollArea:setMaximumSize(api.gui.util.Size.new(799, 700))
    menu.stationTabLinesTable:setColWidth(0,23)
    menu.stationTabLinesTable:setColWidth(1,150)

    menu.stationTabLinesScrollArea:setContent(menu.stationTabLinesTable)
    UIState.floatingLayoutStationTab:addItem(menu.stationTabLinesScrollArea,1,0)

    

end

function fillStationTabStationTable()
    menu.stationTabStationTable:deleteAll()

    local lineNames2 ={}
    for k,v in pairs(timetable.getAllConditionsOfAllStations()) do
        stationName = timetableHelper.getStationName(k)
        if not (stationName == -1) then  
            menu.stationTabStationTable:addRow({api.gui.comp.TextView.new(tostring(stationName))})
            lineNames2[#lineNames2 + 1] = stationName
        end
    end
    menu.stationTabStationTable:onSelect(fillStationTabLineTable)

    local order = timetableHelper.getOrderOfArray(lineNames2)
    menu.stationTabStationTable:setOrder(order)
    -- select last station again
    if UIState.currentlySelectedStationTabStation and menu.stationTabStationTable:getNumRows() > UIState.currentlySelectedStationTabStation  then
        menu.stationTabStationTable:select(UIState.currentlySelectedStationTabStation, true)
    end
    
end

function fillStationTabLineTable(index)
    if index == - 1 then return end
    UIState.currentlySelectedStationTabStation = index
    menu.stationTabLinesTable:deleteAll()
    local i = 0
    for k,v in pairs(timetable.getAllConditionsOfAllStations()) do
        if i == index then 
            stationID = k
            constraints = v
            break
        end
        i = i + 1
    end
    local lineNames2 ={}
    for k,v in  pairs(constraints) do
        lineName = timetableHelper.getLineName(k)
        lineNames2[#lineNames2 + 1] = lineName

        local lineColour2 = api.gui.comp.TextView.new("●")

        lineColour2:setName("timetable-linecolour-" .. timetableHelper.getLineColour(tonumber(k)))
        lineColour2:setStyleClassList({"timetable-linecolour"})

        local type = timetableHelper.conditionToString(v.conditions[v.conditions.type], v.conditions.type) 
        local stConditionString = api.gui.comp.TextView.new(type)
        stConditionString:setName("conditionString")
        menu.stationTabLinesTable:addRow({lineColour2, api.gui.comp.TextView.new(lineName), stConditionString})
    end
    local order = timetableHelper.getOrderOfArray(lineNames2)
    menu.stationTabLinesTable:setOrder(order)
    
end

-------------------------------------------------------------
---------------------- SETUP --------------------------------
-------------------------------------------------------------

function initLineTable() 
    if menu.scrollArea then UIState.boxlayout2:removeItem(menu.scrollArea) end
    if menu.lineHeader then UIState.boxlayout2:removeItem(menu.lineHeader) end


    
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
    
    fillLineTable()

    UIState.boxlayout2:addItem(menu.scrollArea,0,1)
    
    
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

    -- Setting up Line Tab
    menu.tabWidget = api.gui.comp.TabWidget.new("NORTH")
    local wrapper = api.gui.comp.Component.new("wrapper")
    wrapper:setLayout(UIState.boxlayout2 )
    menu.tabWidget:addTab(api.gui.comp.TextView.new('Lines'), wrapper)


    -- seting up station Tab
    local floatingLayout = api.gui.layout.FloatingLayout.new(0,1)
    floatingLayout:setId("timetable.floatingLayoutStationTab")
    UIState.floatingLayoutStationTab = api.gui.util.getById('timetable.floatingLayoutStationTab')
    UIState.floatingLayoutStationTab:setGravity(-1,-1)

    initStationTab()
    local wrapper2 = api.gui.comp.Component.new("wrapper2")
    wrapper2:setLayout(UIState.floatingLayoutStationTab)
    menu.tabWidget:addTab(api.gui.comp.TextView.new('Stations'),wrapper2)

    menu.tabWidget:onCurrentChanged(function(i)
        if i == 1 then
            fillStationTabStationTable()
        end
    end)

    
    -- create final window
    menu.window = api.gui.comp.Window.new('Timetables',  menu.tabWidget)
    menu.window:addHideOnCloseHandler()
    menu.window:setMovable(true)
    menu.window:setPinButtonVisible(true)
    menu.window:setResizable(false)
    menu.window:setSize(api.gui.util.Size.new(1100, 780))
    menu.window:setPosition(200,200)
    menu.window:onClose(function()
        menu.lineTableItems = {}
    end)

end

-------------------------------------------------------------
---------------------- LEFT TABLE ---------------------------
-------------------------------------------------------------

function fillLineTable()
    menu.lineTable:deleteRows(0,menu.lineTable:getNumRows())
    if not (menu.lineHeader == nil) then menu.lineHeader:deleteRows(0,menu.lineHeader:getNumRows()) end

    menu.lineHeader = api.gui.comp.Table.new(6, 'None')
    local sortAll   = api.gui.comp.ToggleButton.new(api.gui.comp.TextView.new('All'))    
    local sortBus   = api.gui.comp.ToggleButton.new(api.gui.comp.ImageView.new("ui/icons/game-menu/hud_filter_road_vehicles.tga"))
    local sortTram  = api.gui.comp.ToggleButton.new(api.gui.comp.ImageView.new("ui/TimetableTramIcon.tga"))
    local sortRail  = api.gui.comp.ToggleButton.new(api.gui.comp.ImageView.new("ui/icons/game-menu/hud_filter_trains.tga"))
    local sortWater = api.gui.comp.ToggleButton.new(api.gui.comp.ImageView.new("ui/icons/game-menu/hud_filter_ships.tga"))
    local sortAir   = api.gui.comp.ToggleButton.new(api.gui.comp.ImageView.new("ui/icons/game-menu/hud_filter_planes.tga"))

    menu.lineHeader:addRow({sortAll,sortBus,sortTram,sortRail,sortWater,sortAir})

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
            if not(linesOfType[k] == nil) then
                v[1]:setVisible(linesOfType[k],false)
                v[2]:setVisible(linesOfType[k],false)
                v[3]:setVisible(linesOfType[k],false)
            end
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
            if not(linesOfType[k] == nil) then
                v[1]:setVisible(linesOfType[k],false)
                v[2]:setVisible(linesOfType[k],false)
                v[3]:setVisible(linesOfType[k],false)
            end
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
            if not(linesOfType[k] == nil) then
                v[1]:setVisible(linesOfType[k],false)
                v[2]:setVisible(linesOfType[k],false)
                v[3]:setVisible(linesOfType[k],false)
            end
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
            if not(linesOfType[k] == nil) then
                v[1]:setVisible(linesOfType[k],false)
                v[2]:setVisible(linesOfType[k],false)
                v[3]:setVisible(linesOfType[k],false)
            end
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
            if not(linesOfType[k] == nil) then
                v[1]:setVisible(linesOfType[k],false)
                v[2]:setVisible(linesOfType[k],false)
                v[3]:setVisible(linesOfType[k],false)
            end
        end
        sortBus:setSelected(false,false)
        sortTram:setSelected(false,false)
        sortRail:setSelected(false,false)
        sortWater:setSelected(false,false)
        sortAir:setSelected(true,false)
        sortAll:setSelected(false,false)
    end)

    UIState.boxlayout2:addItem(menu.lineHeader,0,0)
    
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
    

    local header1 = api.gui.comp.TextView.new("Frequency: " .. timetableHelper.getFrequency(lineID))
    local header2 = api.gui.comp.TextView.new("")
    local header3 = api.gui.comp.TextView.new("")
    local header4 = api.gui.comp.TextView.new("")
    menu.stationTable:setHeader({header1,header2, header3, header4})

    local stationLegTime = timetableHelper.getLegTimes(lineID) 
    --iterate over all stations to display them
    for k, v in pairs(timetableHelper.getAllStations(lineID)) do
        menu.lineImage = {}
        local vehiclePositions = timetableHelper.getTrainLocations(lineID) 
        if vehiclePositions[tostring(k-1)] then
            if vehiclePositions[tostring(k-1)].atTerminal then
                if vehiclePositions[tostring(k-1)].countStr == "MANY" then
                    menu.lineImage[k] = api.gui.comp.ImageView.new("ui/timetable_line_train_in_station_many.tga")
                else
                    menu.lineImage[k] = api.gui.comp.ImageView.new("ui/timetable_line_train_in_station.tga")
                end
            else 
                if vehiclePositions[tostring(k-1)].countStr == "MANY" then
                    menu.lineImage[k] = api.gui.comp.ImageView.new("ui/timetable_line_train_en_route_many.tga")
                else
                    menu.lineImage[k] = api.gui.comp.ImageView.new("ui/timetable_line_train_en_route.tga")
                end
            end
        else
            menu.lineImage[k] = api.gui.comp.ImageView.new("ui/timetable_line.tga")
        end
        local x = menu.lineImage[k]
        menu.lineImage[k]:onStep(function()
            if not x then print("ERRROR") return end
            local vehiclePositions = timetableHelper.getTrainLocations(lineID) 
            if vehiclePositions[tostring(k-1)] then
                if vehiclePositions[tostring(k-1)].atTerminal then
                    if vehiclePositions[tostring(k-1)].countStr == "MANY" then
                        x:setImage("ui/timetable_line_train_in_station_many.tga", false)
                    else
                        x:setImage("ui/timetable_line_train_in_station.tga", false)
                    end
                else 
                    if vehiclePositions[tostring(k-1)].countStr == "MANY" then
                        x:setImage("ui/timetable_line_train_en_route_many.tga", false)
                    else
                        x:setImage("ui/timetable_line_train_en_route.tga", false)
                    end
                end
            else
                x:setImage("ui/timetable_line.tga", false)
            end
        end)

        local station = timetableHelper.getStation(v)
     

        stationNumber = api.gui.comp.TextView.new(tostring(k)) 

        stationNumber:setStyleClassList({"timetable-stationcolour"})
        stationNumber:setName("timetable-stationcolour-" .. timetableHelper.getLineColour(lineID))
        stationNumber:setMinimumSize(api.gui.util.Size.new(30, 30))

        
        local stationName = api.gui.comp.TextView.new(station.name)
        stationName:setName("stationName")
        if (stationLegTime and stationLegTime[k]) then 
            jurneyTime = api.gui.comp.TextView.new("Journey Time: " .. os.date('%M:%S', stationLegTime[k]))
        else 
            jurneyTime = api.gui.comp.TextView.new("")
        end
        jurneyTime:setName("conditionString")

        local stationNameTable = api.gui.comp.Table.new(1, 'NONE')
        stationNameTable:addRow({stationName})
        stationNameTable:addRow({jurneyTime})
        stationNameTable:setColWidth(0,120)
        

        local conditionType = timetable.getConditionType(lineID, k)
        local conditionString = api.gui.comp.TextView.new(timetableHelper.conditionToString(timetable.getConditions(lineID, k, conditionType), conditionType))
        conditionString:setName("conditionString")
              

        conditionString:setMinimumSize(api.gui.util.Size.new(285,50))
        conditionString:setMaximumSize(api.gui.util.Size.new(285,50))

      
        menu.stationTable:addRow({stationNumber,stationNameTable, menu.lineImage[k], conditionString})       
    end

    menu.stationTable:onSelect(function (index)
        if not (index == -1) then 
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
    --comboBox:addItem("Minimum Wait")
    comboBox:addItem("Unbunch")
    --comboBox:addItem("Every X minutes")
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
        elseif i == 2 then
            makeDebounceWindow(lineID, index) 
        end
    end)

    infoImage = api.gui.comp.ImageView.new("ui/info_small.tga")
    infoImage:setTooltip(
        "You can add timetable constraints to each station.\n" ..
        "When a train arrives at the station it will try to \n" ..
        "keep the constraints. The following constraints are awailabe: \n" ..
        "  - Arrival/Departure: Set multiple Arr/Dep times and the train \n"..
        "                                      chooses the closes arrival time\n" ..
        "  - Unbunch: Set a time and vehicles will only depart the station in the given interval"
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

function makeDebounceWindow(lineID, stationID) 
    if not menu.constraintTable then return end 
    local condition2 = timetable.getConditions(lineID,stationID, "debounce")

    local debounceTable = api.gui.comp.Table.new(4, 'NONE')
    debounceTable:setColWidth(0,150)
    debounceTable:setColWidth(1,62)
    debounceTable:setColWidth(2,25)
    debounceTable:setColWidth(3,63)

    debounceMin = api.gui.comp.DoubleSpinBox.new()
    debounceMin:setMinimum(0,false)
    debounceMin:setMaximum(59,false)

    debounceMin:onChange(function(value) 
        timetable.updateDebounce(lineID, stationID,  1, value)
        initStationTable()
        fillStationTable(UIState.currentlySelectedLineTableIndex, false) 
    end)

    if condition2 and condition2[1] then
        debounceMin:setValue(condition2[1],false)
    end


    debounceSec = api.gui.comp.DoubleSpinBox.new()
    debounceSec:setMinimum(0,false)
    debounceSec:setMaximum(59,false)

    debounceSec:onChange(function(value) 
        timetable.updateDebounce(lineID, stationID, 2, value)
        initStationTable()
        fillStationTable(UIState.currentlySelectedLineTableIndex, false) 
    end)
    if condition2 and condition2[2] then
        debounceSec:setValue(condition2[2],false)
    end

    debounceTable:addRow({api.gui.comp.TextView.new("Unbunch Time:"), debounceMin,api.gui.comp.TextView.new(":"), debounceSec})

    menu.constraintTable:addRow({debounceTable})

end

-------------------------------------------------------------
--------------------- OTHER ---------------------------------
-------------------------------------------------------------

function timetableCoroutine() 
    while true do
        local lines = timetableHelper.getAllRailLines()
        for vehicle,line in pairs(timetableHelper.getAllRailVehicles()) do
            if timetableHelper.isInStation(vehicle) then
                if timetable.hasTimetable(line) and timetable.waitingRequired(vehicle) then
                    timetableHelper.stopVehicle(vehicle)
                else
                    timetableHelper.startVehicle(vehicle)
                end      
            end
            coroutine.yield()
        end
        coroutine.yield()
    end
end


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
            if state == nil then state = {timetable = {}}end
            if co == nil or coroutine.status(co) == "dead" then
                co = coroutine.create(timetableCoroutine)
            end
            for i = 0, 8 do
                local err, msg = coroutine.resume(co)
                if not err then print(msg) end
            end

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
                button:onClick(function () 
                    local err, msg = pcall(showLineMenu)
                    if not err then print(msg) end
                end)
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
