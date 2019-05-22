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

init = function(model)
    local OT = true
    local firstrun = true
    local count = 0
    local s = true
    local totMach = 0
    local totVessels = 0
    local totBacS = 0
    local totBacF = 0
    local macTime = 0
    local auxT = 0
    local countBacF = 0
    local countBacS = 0
    local TcellLifeTime = 0
    startRule = function(cell)
        random = Random()
       local  c = model.cs:sample()
        if c.state == "empty" and totVessels < model.bloodVessels then
            c.state = "vessels"
            c.oxygen = 100
            totVessels = totVessels + 1
        elseif c.state == "empty" and totBacS < 6 then
            c.state = "bacteriaS"
            totBacS = totBacS + 1
        elseif c.state == "empty" and totBacF < 6 then
            c.state = "bacteriaF"
            totBacF = totBacF + 1
        elseif c.state == "empty" and totMach < model.mrInit then
            c.state = "macrophagesOff"
            c.life = random:integer(0, 100)
            totMach = totMach + 1
        end
    end

    machophRule = function(cell)
        random = Random()
        forEachNeighbor(cell, function(neigh) 
        if (cell.macTime ~= nil and cell.state == "macrophagesMi") or (cell.macTime ~= nil and cell.state == "macrophagesMC")   then
            cell.macTime = cell.macTime + 1
        end

        if cell.state == "macrophagesOff" and neigh.state == "Tcell" then
            cell.state = "macrophagesON"
        elseif (cell.state == "macrophagesON" and neigh.state == "bacteriaS") or (cell.state == "macrophagesON" and neigh.state == "bacteriaF") then
            neigh.state = "empty"
        elseif (cell.state == "macrophagesOff" and neigh.state == "bacteriaS") or (cell.state == "macrophagesOff" and neigh.state == "bacteriaF") then
            cell.state = "macrophagesMi"
        elseif cell.state ==  "macrophagesMi" and cell.macTime == model.nIci then
            cell.state = "macrophagesMC"
        elseif cell.state == "macrophagesMC" and cell.macTime == model.nCib then
            cell.state = Random{"bacteriaS","bacteriaF"}:sample()
            cell.macTime = 0
        end
        
        if  (cell.oxygen > 0 and cell.state == "macrophagesOff") or
             (cell.oxygen > 0 and cell.state == "macrophagesON") or 
             (cell.oxygen > 0 and cell.state == "macrophagesMi") or 
             (cell.oxygen > 0 and cell.state == "macrophagesMC")  then
            cell.oxygen = cell.oxygen - 5  
        end

     end)
    end

    TcellUpdate= function(cell)
        if  (cell.oxygen > 0 and cell.state == "Tcell")  then
            cell.oxygen = cell.oxygen-5
        end

        if  (cell.oxygen == 0 and cell.state == "Tcell")  then
            cell.state = "empty"
        end
        
        auxT = 0
        forEachCell(model.cs, function(cell)
            if cell.state == "bacteriaS" or cell.state == "bacteriaF" then
                auxT = auxT + 1
            end           
        end)
        forEachNeighbor(cell, function(neigh)
            if cell.state == "Tcell" then
                random = Random()
                local value = random:number()
                if value > 0.75 then
                    if neigh.state == "macrophagesMi" or neigh.state == "macrophagesMC"  then
                        neigh.state = "empty"
                    end
                end
            end
        end)

        if auxT >= model.tenter then
            if cell.state == "vessels" then
                n = cell:sample():getNeighborhood()
                z = n:sample()
                if z.state == "empty"  then
                    z.state = "Tcell"
                end
                if z.state == "Tcell" then
                    z.life = random:integer(0, 3)
                end

                if cell.state == "Tcell" and TcellLifeTime > cell.life then
                    cell.state = "empty"
                end
            end            
        end
        TcellLifeTime = TcellLifeTime + 1
    end

    bacteriaUpdate = function(cell)
        n = cell:sample():getNeighborhood()
        z = n:sample()
        random = Random()
        local valueF = random:integer(15, 32)
        local valueS = random:integer(48, 96)
            if z.state == "empty" and countBacF >= valueF and cell.state == "bacteriaF" then
                z.state = cell.state
                countBacF = 0
            elseif  z.state == "empty" and countBacS >= valueS and cell.state == "bacteriaS" then
                z.state = cell.state
                countBacS = 0
            end

            if cell.state == "bacteriaS" and cell.oxygen >= model.oHigh then
                cell.state = "bacteriaF"
            elseif cell.state == "bacteriaF" and cell.oxygen <= model.oLow then
                cell.state = "bacteriaS"
            end
                if  (cell.oxygen > 0 and cell.state == "bacteriaS") or (cell.oxygen > 0 and cell.state == "bacteriaF")  then
                    cell.oxygen = cell.oxygen - 5  
                end
            if (cell.oxygen == 0 and cell.state == "bacteriaF") or (cell.oxygen == 0 and cell.state == "bacteriaS") then
                cell.state = "empty"
            end

            countBacF = countBacF + 1
            countBacS = countBacS + 1
    end

    insertOxygenLevel = function(cell)
        forEachNeighbor(cell,function(neigh)
            for i=100,10,-10 do
                if cell.oxygen == i  and neigh.oxygen == 0 then
                    neigh.oxygen = i-10
                end
            end
        end)
    end

    moveCells = function(cell)
        if cell.state ~= "vessels" then
            n = cell:sample():getNeighborhood()
            z = n:sample()
            if z.state == "empty" and  z.oxygen > 0  then
                z.state = cell.state
                cell.state = "empty"
            end
        end
    end

    updateLife = function(cell)
        if cell.life ~= nil then
            cell.life = cell.life -1
            if cell.life <= 0 then
                cell.state = "empty"
            end
        end


    end
    
    oxygenUpdate = function(cell)
        forEachNeighbor(cell,function(neigh)
            for i=100,10,-10 do
                if cell.oxygen == i  and neigh.oxygen == 0 then
                    neigh.oxygen = i-10
                end
            end
        end)
    end

    model.cell = Cell{
        init = function(cell)
         
         cell.state = "empty"
         cell.oxygen = 0 
         cell.macTime = 0
        --cell:synchronize()
        end,
        execute = function(cell)
        startRule(cell)
            insertOxygenLevel(cell)
            machophRule(cell)
            bacteriaUpdate(cell,model)
            oxygenUpdate(cell)
            TcellUpdate(cell)
            moveCells(cell)
            updateLife(cell)
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
        value = {"vessels","macrophagesON","macrophagesOff","macrophagesMi","macrophagesMC","bacteriaF","bacteriaS","Tcell"},
        color = {"red","purple","magenta","lightGray","darkGray","darkGreen","green","blue"}
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
    finalTime = 5000,
    dim = 40, -- size of grid
    bloodVessels = 49, -- number of blood vessels
    oLow = 5, -- O 2 threshold for fast → slow-growing bacteria
    oHigh = 65, -- O 2 threshold for slow → fast-growing bacteria
    mrInit = 105, -- Initial number of Mr in the domain
    tenter = 50, -- Bacteria needed for T cells to enter the system
    repF = Choice{min = 15, max = 32}, -- Replication rate of fast-growing bacteria
    repS = Choice{min = 48, max = 96}, -- Replication rate of slow-growing bacteria
    tLife = Choice{min = 0, max = 3},--Lifespan of T cells
    nIci = 10, --Number of bacteria needed for Mi → Mci
    nCib = 20, -- Number of bacteria needed for Mci to burst
   --[[ oxygenBacteria = nil, -- Oxygen consumption rate of bacteria
    oxygenMr = nil, -- Oxygen consumption rate of Mr
    oxygenMa = nil, -- Oxygen consumption rate of Ma
    oxygenMi = nil, -- Oxygen consumption rate of Mi
    oxygenMci = nil, -- Oxygen consumption rate of Mci
    oxygenTcells = nil, -- Oxygen consumption rate of T cells
    drugBacteria = nil, -- Antibiotic consumption rate of extracellular bacteria
    drugMacrophages = nil, -- Antibiotic consumption rate of infected macrophages
    repF = Choice{min = 15, max = 32}, -- Replication rate of fast-growing bacteria
    repS = Choice{min = 48, max = 96}, -- Replication rate of slow-growing bacteria


    mrMa = 9, -- Probability of Mr → Ma (multiplied by no. of T cells in neighbourhood)

    mLife = Choice{min = 0, max = 100}, --Lifespan of Mr, Mi and Mci
    maLife = 10, --Lifespan of Ma
    tMoveMr = 20, --Time interval for Mr movement
    tmoveMa = 7.8, --Time interval for Ma movement 7.8 ( Segovia-Juarez et al., 2004 )
    tMoveMi = 24, --Time interval for Mi/Mci movement
    mrRecr = 0.07, -- Probability of Mr recruitment
    
    tRecr = 0.02, -- Probability of T cell recruitment
    
    tKill = 0.75, --Probability of T cell killing Mi/Mci
    tMoveT = 10, --Time interval for T cell movement
    tDrug = Choice{min = 168, max = 2160},--Time at which drug is administered
    drugKillF = 2, -- Drug needed to kill fast-growing bacteria
    drugkillS = 10, -- Drug needed to kill slow-growing bacteria
    drugKillMi = 20, --Drug needed to kill intracellular bacteria
    --]]
    init = init

}

hybridMultiscale:run()


