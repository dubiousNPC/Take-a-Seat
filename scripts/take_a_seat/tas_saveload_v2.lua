-- Take a Seat save/load, written against v0.42's actual contract:
--   * Activate is the ONLY sit/stand trigger (take_a_seat.lua:917-926)
--   * seated locks Controls + Jumping only          (take_a_seat.lua:561-562)
--   * the mod never touches collision               (no setCollision anywhere)
--   * controlsLocked is persisted across save/load  (take_a_seat.lua:1005,1017)
return function(c)
    local V = c.util.vector3
    local debug = require('openmw.debug')
    local camera = require('openmw.camera')
    local types = c.types

    local function offSwitches()
        local off = {}
        for name, sw in pairs(types.Player.CONTROL_SWITCH) do
            local ok, v = pcall(types.Player.getControlSwitch, c.self, sw)
            if ok and not v then table.insert(off, name) end
        end
        table.sort(off); return table.concat(off, ',')
    end
    local function activate()
        print('DRVKEY down space'); c.wait(0.12); print('DRVKEY up space')
    end

    if c.afterLoad then
        c.wait(2.0)
        c.log('AFTERLOAD seated=%s off=[%s] collision=%s',
              tostring(c.seated ~= nil), offSwitches(), tostring(debug.isCollisionEnabled()))
        c.result('a seated save loads standing, not seated', c.seated == nil,
                 'seated='..tostring(c.seated ~= nil))
        c.result('a seated save loads with the control lock released',
                 offSwitches() == '', 'off=['..offSwitches()..']')
        c.result('quickload leaves collision alone',
                 debug.isCollisionEnabled() == true, tostring(debug.isCollisionEnabled()))
        local p0 = c.self.position
        print('DRVKEY down s'); c.wait(1.2); print('DRVKEY up s'); c.wait(0.5)
        local d = (c.self.position - p0):length()
        c.result('the player can walk straight after the load', d > 40,
                 string.format('moved %.0f', d))
        return
    end

    c.wait(2)
    local cell = "Seyda Neen, Arrille's Tradehouse"
    local function sitAt()
        c.seated, c.stood = nil, nil
        c.core.sendGlobalEvent('Drv_Teleport', { cell = cell, pos = V(-551.7, -178.2 - 95, 406.3 + 5), yaw = 0 })
        c.wait(1.2)
        local cam = camera.getPosition()
        camera.setPitch(math.atan2(cam.z - 430, 95))
        c.wait(0.3)
        activate()
        return c.waitFor(function() return c.seated ~= nil end, 3.5)
    end

    c.result('sits on the barstool', sitAt())
    c.wait(1.2)
    c.result('seated locks Controls and Jumping, and nothing else',
             offSwitches() == 'Controls,Jumping', 'off=['..offSwitches()..']')
    c.result('seated leaves collision alone', debug.isCollisionEnabled() == true,
             tostring(debug.isCollisionEnabled()))

    -- Activate is the stand-up trigger, not movement
    c.stood = nil
    activate()
    local stood = c.waitFor(function() return c.stood end, 3)
    c.result('Activate stands the player up', stood,
             stood and 'stood' or 'no TakeASeat_Stood event')
    c.wait(0.6)
    c.result('standing releases every switch', offSwitches() == '', 'off=['..offSwitches()..']')

    c.result('sits again for the save', sitAt())
    c.wait(1.2)
    c.postLoadTag = 'seated-save'
    print('DRVKEY down F5'); c.wait(0.1); print('DRVKEY up F5')
    c.wait(2.5)
    print('DRVKEY down F9'); c.wait(0.1); print('DRVKEY up F9')
    c.wait(12)
    c.result('the quickload happened', false, 'still in the old session')
end
