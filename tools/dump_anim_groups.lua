-- Print every animation group the mod can play, with its fallbacks.
--   python3 tools/luarun.py tools/dump_anim_groups.lua
--
-- check_anims.py reads this instead of grepping the Lua for quoted names. The
-- tables are the authority on what gets played, and a regex over them answers
-- a different question -- which is how the group list came to be hand-passed
-- on the command line, leaving a plain run reporting "0 group(s) unplayable"
-- without having looked at anything.
--
-- Output, one line per group:  <group> TAB <fallback,fallback,...>  TAB <use>
package.preload['openmw.core'] = function() return {
    getGameTime = function() return 0 end, getSimulationTime = function() return 0 end,
    contentFiles = { list = {} } } end
package.preload['openmw.types'] = function() return {} end
package.preload['openmw.util'] = function() return {} end
package.preload['openmw.vfs'] = function() return { fileExists = function() return true end } end
package.path = './?.lua;' .. package.path

local seats = dofile('scripts/take_a_seat/sitAnim_shared.lua')

local uses = {}
local function add(group, use)
    if not group then return end
    uses[group] = uses[group] or {}
    uses[group][#uses[group] + 1] = use
end

for name, seatType in pairs(seats.SEAT_TYPE) do
    add(seats.idleAnimFor(seats.TARGET_KIND.SEAT, seatType), 'seat/' .. name .. '/idle')
    add(seats.enterAnimFor(seats.TARGET_KIND.SEAT, seatType), 'seat/' .. name .. '/enter')
    add(seats.exitAnimFor(seats.TARGET_KIND.SEAT, seatType), 'seat/' .. name .. '/exit')
end

-- Beds and misc items only matter when they are wired; idleAnimFor returns nil
-- for a kind with no table, so an unwired one contributes nothing.
for name, bedType in pairs(seats.BED_TYPE or {}) do
    add(seats.idleAnimFor(seats.TARGET_KIND.BED, bedType), 'bed/' .. name .. '/idle')
    add(seats.enterAnimFor(seats.TARGET_KIND.BED, bedType), 'bed/' .. name .. '/enter')
    add(seats.exitAnimFor(seats.TARGET_KIND.BED, bedType), 'bed/' .. name .. '/exit')
end
for name, miscType in pairs(seats.MISC_TYPE or {}) do
    add(seats.idleAnimFor(seats.TARGET_KIND.MISC, miscType), 'misc/' .. name .. '/idle')
    add(seats.enterAnimFor(seats.TARGET_KIND.MISC, miscType), 'misc/' .. name .. '/enter')
    add(seats.exitAnimFor(seats.TARGET_KIND.MISC, miscType), 'misc/' .. name .. '/exit')
end

local names = {}
for group in pairs(uses) do names[#names + 1] = group end
table.sort(names)

for _, group in ipairs(names) do
    local alts = seats.groupFallbacks(group) or {}
    print(string.format('%s\t%s\t%s', group, table.concat(alts, ','),
                        table.concat(uses[group], ' ')))
end
