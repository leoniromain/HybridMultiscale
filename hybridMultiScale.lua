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

function populateVessels(cell)
    local v = countNeighbors(cell, "vessels")
            if v > 1  then
                cell.state = "oxygen"   
            end

  --[[  forEachNeighbor(cell, function(neigh)
    local v = countNeighbors(cell, neigh.oxygen)
            if v  >= 1    then
                cell.oxygen = 100  
            end
    end)
    ]]--
end

function insertOxygenLevel(cell)
    forEachNeighbor(cell, function(neighbour)
            if cell.state == "vessels" and neighbour.state == "oxygen" then
                neighbour.state = "o2"
            end
            if cell.state == "o2" and neighbour.state == "oxygen" then
                neighbour.state = "o3"
            end
            if cell.state == "o3" and neighbour.state == "oxygen" then
                neighbour.state = "o4"
            end     
    end)
    --[[forEachNeighbor(cell, function(neighbour)
        if cell.oxygen == 100 and neighbour.state == 0 then
            neighbour.oxygen = 10
        elseif cell.state == 10 and neighbour.state == 0 then
            neighbour.oxygen = 20
        elseif cell.state == 20 and neighbour.state == 0 then
            neighbour.state = 30
        end     
    end)]]--
end

function OxygenTransitions(cell)
    if cell.state == "o2" then 
        cell.state = "o4"
    elseif cell.state == "o3" then 
        cell.state = "o4"
    elseif cell.state == "o4" then 
        cell.state = "oxygen"
    end
end

init = function(model)
    local firstrun = true
    local count = 0
    model.cell = Cell{
        init = function(cell)
         cell.state = Random{"oxygen", "vessels"}:sample()
          --cell.colors = Random():integer(0, 8)
           -- cell.oxygen = Random():integer()
        end,

        execute = function(cell)
            populateVessels(cell)
            insertOxygenLevel(cell)
            OxygenTransitions(cell)
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
        value = {"vessels","oxygen","o2","o3","o4"},
        color = {"red","blue","yellow","green","purple"}
    }

    model.timer = Timer{
        Event{action = model.cs},
        Event{action = model.map}
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