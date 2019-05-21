function countNeighbors(cell, val)
	if val == nil then
		return #cell:getNeighborhood()
	end

	local count = 0
	forEachNeighbor(cell, function(neigh)
		if neigh.past.state == val then
			count = count + 1
		end
	end)
	return count
end

function machophRule(cell)
    forEachNeighbor(cell, function(neigh)
        if cell.state == "macrophagesOff" and neigh.state == "Tcell" then
            cell.state = "macrophagesON"
        elseif cell.state == "macrophagesON" and (neigh.state == "bacteriaS" or neigh.state == "bacteriaF") then
            neigh.state = "empty"
        elseif cell.state == "macrophagesOff" and (neigh.state == "bacteriaS" or neigh.state == "bacteriaF") then
            neigh.state = "bacteriaF"
            --todo explosao dos macrofagos
            --todo antibiotico
        end

    end)
end

function populateBacteria(cell)
    local v = countNeighbors(cell, "bacteria")
            if v > 2  then
                cell.state = "empty"   
            end
end

function populateVessels(cell)
    local v = countNeighbors(cell, "vessels")
            if v > 1  then
                cell.state = "empty"   
            end
    forEachNeighbor(cell, function(neigh)
            if cell.state == "vessels" or cell.oxygen == 1 then
                cell.oxygen = 100  
            end
            if cell.state ~= "vessels" and cell.oxygen == 100 then
                cell.oxygen = 0
            end  
    end)
end

function insertOxygenLevel(cell)

    forEachNeighbor(cell, function(neighbour)

        for i=100,10,-10 do
            if cell.oxygen == i  and neighbour.oxygen == 0 then
                neighbour.oxygen = i-10
            end
        end
    end)
end

function bacteriaUpdate(cell)
    if cell.state == "bacteriaS" and cell.oxygen > 50 then
        cell.state = "bacteriaF"
    elseif cell.state == "bacteriaF" and cell.oxygen < 50 then
        cell.state = "bacteriaS"
    end
end

function oxygenUpdate(cell)
    if cell.state == "bacteriaS" or cell.state == "bacteriaF" then
        cell.oxygen = cell.oxygen-1
    end

    forEachNeighbor(cell, function(neighbour)

        for i=90,10,-10 do
            if cell.oxygen == i  and neighbour.oxygen == 0 then
                neighbour.oxygen = i-1
            end
        end
    end)
end

function TcellUpdate(cell,model)
    local count = 0
    forEachCell(model.cs, function(cell)
        if cell.state == "bacteriaF" or cell.state == "bacteriaF" then
            count = count + 1
        end
    end)
    if count >= model.tenter then
        if cell.state == "empty" then
            cell.state = Random{"empty", "Tcell"}:sample()
        end
    end
    local v = countNeighbors(cell, "Tcell")
    if v > 1 and cell.state == "Tcell" then
        cell.state = "empty"   
    end
end

function moveCells(cell)
    forEachNeighbor(cell, function(neighbour)
        if neighbour.state == "empty" and cell.state ~= "empty" then
            neighbour.state = cell.state
        end
    end)

end
init = function(model)
    local firstrun = true
    local count = 0
    model.cell = Cell{
        init = function(cell)
         cell.state = Random{"empty", "vessels","macrophagesOff","bacteriaF","bacteriaS"}:sample()
         cell.oxygen = Random():integer()
        end,

        execute = function(cell)
            populateVessels(cell)
            insertOxygenLevel(cell)
            machophRule(cell)
            populateBacteria(cell)
            bacteriaUpdate(cell)
            oxygenUpdate(cell)
            TcellUpdate(cell,model)
            moveCells(cell)
     end
    }

   
    model.cs = CellularSpace{
        xdim = model.dim,
        instance = model.cell,
    }

    model.cs:createNeighborhood()

    model.map = Map{
        target = model.cs,
        select = "state",
        value = {"vessels","macrophagesON","bacteriaF","bacteriaS","Tcell","macrophagesOff"},
        color = {"red","purple","green","darkGreen","blue","darkGray"}
    }
    --YlGnBu
    model.map2 = Map{
        target = model.cs,
        select = "oxygen",
        color  = "YlGnBu",
        min = 0,
        max = 100,
        slices = 10
    }

   --[[ model.chart = Chart{
        target = model.cs,
        select = {"oxygen"},
        title ="Oxygen x Time",
        yLabel = "#individual",
        color = {"blue"}
    }]]--

    model.timer = Timer{
        Event{action = model.cs},
        Event{action = model.map},
        Event{action = model.map2}
    }
end
hybridMultiscale = Model {
    finalTime = 1000,
    dim = 50, -- size of grid
    bloodVessels = 49, -- number of blood vessels
    oxygenBacteria = nil, -- Oxygen consumption rate of bacteria
    oxygenMr = nil, -- Oxygen consumption rate of Mr
    oxygenMa = nil, -- Oxygen consumption rate of Ma
    oxygenMi = nil, -- Oxygen consumption rate of Mi
    oxygenMci = nil, -- Oxygen consumption rate of Mci
    oxygenTcells = nil, -- Oxygen consumption rate of T cells
    drugBacteria = nil, -- Antibiotic consumption rate of extracellular bacteria
    drugMacrophages = nil, -- Antibiotic consumption rate of infected macrophages
    repF = Choice{min = 15, max = 32}, -- Replication rate of fast-growing bacteria
    repS = Choice{min = 48, max = 96}, -- Replication rate of slow-growing bacteria
    oLow = 6, -- O 2 threshold for fast → slow-growing bacteria
    oHigh = 65, -- O 2 threshold for slow → fast-growing bacteria
    mrInit = 105, -- Initial number of Mr in the domain
    mrMa = 9, -- Probability of Mr → Ma (multiplied by no. of T cells in neighbourhood)
    nIci = 10, --Number of bacteria needed for Mi → Mci
    nCib = 20, -- Number of bacteria needed for Mci to burst
    mLife = Choice{min = 0, max = 100}, --Lifespan of Mr, Mi and Mci
    maLife = 10, --Lifespan of Ma
    tMoveMr = 20, --Time interval for Mr movement
    tmoveMa = 7.8, --Time interval for Ma movement 7.8 ( Segovia-Juarez et al., 2004 )
    tMoveMi = 24, --Time interval for Mi/Mci movement
    mrRecr = 0.07, -- Probability of Mr recruitment
    tenter = 50, -- Bacteria needed for T cells to enter the system
    tRecr = 0.02, -- Probability of T cell recruitment
    tLife = Choice{min = 0, max = 3},--Lifespan of T cells
    tKill = 0.75, --Probability of T cell killing Mi/Mci
    tMoveT = 10, --Time interval for T cell movement
    tDrug = Choice{min = 168, max = 2160},--Time at which drug is administered
    drugKillF = 2, -- Drug needed to kill fast-growing bacteria
    drugkillS = 10, -- Drug needed to kill slow-growing bacteria
    drugKillMi = 20, --Drug needed to kill intracellular bacteria
    init = init

}

hybridMultiscale:run()


