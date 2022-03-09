minFuel = 5
minDepoFuel = 20
maxFuel = 50
digChunkSize = 4
stepsForwardBeforeDig = 3

Direction = {
    FORWARD = 1, -- x++
    LEFT = 2, -- z++
    BACK = 3,
    RIGHT = 4
}

currentPosition = {
    direction = Direction.FORWARD,
    x = 0,
    z = 0,
    -- y is up and down
    y = 0
}


-- https://stackoverflow.com/questions/640642/how-do-you-copy-a-lua-table-by-value
function shallowCopy(t)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
end


startPosition = shallowCopy(currentPosition)
startDigPosition = shallowCopy(startPosition)

function turnLeft()
    if currentPosition.direction == Direction.FORWARD then
        currentPosition.direction = Direction.LEFT
    elseif currentPosition.direction == Direction.LEFT then
        currentPosition.direction = Direction.BACK
    elseif currentPosition.direction == Direction.BACK then
        currentPosition.direction = Direction.RIGHT
    elseif currentPosition.direction == Direction.RIGHT then
        currentPosition.direction = Direction.FORWARD
    end
    turtle.turnLeft()
    print("Turning left")
end

function turnRight()
    if currentPosition.direction == Direction.FORWARD then
        currentPosition.direction = Direction.RIGHT
    elseif currentPosition.direction == Direction.RIGHT then
        currentPosition.direction = Direction.BACK
    elseif currentPosition.direction == Direction.BACK then
        currentPosition.direction = Direction.LEFT
    elseif currentPosition.direction == Direction.LEFT then
        currentPosition.direction = Direction.FORWARD
    end
    turtle.turnRight()
    print("Turning right")
end

function turnTo(dir)
    if dir == currentPosition.direction then
        return
    end
    if (dir + 1) == currentPosition.direction then
        turnLeft()
        return
    end
    if (dir - 1) == currentPosition.direction then
        turnRight()
        return
    end
    while dir ~= currentPosition.direction do
        turnLeft()
    end
    print("Direction: " .. currentPosition.direction .. "/" .. dir)
end

function refuel(waitingAtDepo)
    fuelRequiredToContinue = waitingAtDepo and minDepoFuel or minFuel
    while turtle.getFuelLevel() < fuelRequiredToContinue do
        turtle.select(1)
        turtle.refuel(1)
        print("Fuel level: " .. turtle.getFuelLevel() .. " / " .. maxFuel .. " / min fuel: " .. fuelRequiredToContinue)
    end
end

function goForward(distance)
    print("Going forward: " .. distance)
    if distance == 0 then
        return
    end
    while turtle.detect() do
        turtle.dig()
        sleep(1)
    end
    for i = 1, distance do
        refuel()
        turtle.forward()
        if currentPosition.direction == Direction.FORWARD then
            currentPosition.x = currentPosition.x + 1
        elseif currentPosition.direction == Direction.LEFT then
            currentPosition.z = currentPosition.z + 1
        elseif currentPosition.direction == Direction.BACK then
            currentPosition.x = currentPosition.x - 1
        elseif currentPosition.direction == Direction.RIGHT then
            currentPosition.z = currentPosition.z - 1
        end
    end
end

function goUp(distance)
    if distance == 0 then
        return
    end
    while turtle.detectUp() do
        turtle.digUp()
        sleep(1)
    end
    for i = 1, distance do
        turtle.up()
    end
end

function goDown(distance)
    if distance == 0 then
        return
    end
    while turtle.detectDown() do
        turtle.digDown()
        sleep(1)
    end
    for i = 1, distance do
        turtle.down()
    end
end

function goTo(targetPosition)
    deltaX = targetPosition.x - currentPosition.x
    deltaZ = targetPosition.z - currentPosition.z
    deltaY = targetPosition.y - currentPosition.y

    if deltaY > 0 then
        goUp(deltaY)
    elseif deltaY < 0 then
        goDown(-deltaY)
    end

    -- The turtle digs from side to side going forward (x++) so we
    -- move up and back to the first layer we dug out before
    -- moving to the right (z--) when going back to deposit
    if deltaX > 0 then
        turnTo(Direction.FORWARD)
        goForward(deltaX)
    elseif deltaX < 0 then
        turnTo(Direction.BACK)
        goForward(-deltaX)
    end
    
    if deltaZ > 0 then
        turnTo(Direction.LEFT)
        goForward(deltaZ)
    elseif deltaZ < 0 then
        turnTo(Direction.RIGHT)
        goForward(-deltaZ)
    end
    

    turnTo(targetPosition.direction)
end

function digStep()
    while turtle.detectUp() do
        -- to handle gravel, sand etc.
        turtle.digUp()
        if turtle.detectUp() then
            sleep(1)
        end
    end
    if turtle.detectDown() then
        turtle.digDown()
    end
    while turtle.detect() do
        -- to handle gravel, sand etc.
        turtle.dig()
        if turtle.detect() then
            sleep(1)
        end
    end
end

function digStepForward(times)
    for i = 1, times do
        goForward(1)
        digStep()
    end
end

  -- returns if inventory was dumped
function dumpInventoryIfFull()
    -- check if inventory is full except first slot (fuel slot)
    for i = 2, 16 do
        if turtle.getItemCount(i) == 0 then
            return false
        end
    end
    initialPosition = shallowCopy(currentPosition)
    print("Going to drop inventory")
    goTo(0, 0, 0)
    for i = 2, 16 do
        turtle.select(i)
        turtle.drop()
    end
    refuel(true)
    print("Going back")
    -- get clear of the tunnel
    goTo(startDigPosition)
    -- go back to mining
    goTo(initialPosition)
    return true
end

function makeStaircase()
    while turtle.detectUp() do
        turtle.dig()
        turtle.digUp()
        turtle.turnRight()
        turtle.up()
        sleep(2)
    end
end

makeStaircase()

function quarry()
    digStepForward(stepsForwardBeforeDig)
    startDigPosition = shallowCopy(currentPosition)
    refuel()
    while true do
        layerDigStartPosition = shallowCopy(currentPosition)
        distance = digChunkSize
        for i = 1, digChunkSize do
            turnLeft()
            digStepForward(distance)
            dumpInventoryIfFull()
            turnRight()
            digStepForward(1)
            dumpInventoryIfFull()
            turnRight()
            digStepForward(distance)
            dumpInventoryIfFull()
            turnLeft()
            digStepForward(1)
            dumpInventoryIfFull()
        end
        goTo(layerDigStartPosition)
        dumpInventoryIfFull()
        goDown(1)
        turtle.digDown()
        goDown(1)
        turtle.digDown()
        goDown(1)
    end
end
