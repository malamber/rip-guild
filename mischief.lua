print('====== Mischief =======')
print('version 0.1 beta')
print('by nerp, devthis, luu, wox')
print('GUILD VERSION')
print('=========================')

local mq        = require("mq")
local GIMP

local def  = {
    class = mq.TLO.Me.Class.ShortName(),
    name  = mq.TLO.Me.CleanName(),
    DEBUG = true,
    pulse = 500,

    cmd   = "/mischief"
}

local mezzer = {['BRD']=true, ['ENC']=true}

local mez_spells = {
    ['BRD'] = { [1]='Slumber of Suja' },
    ['ENC'] = { [1]='Chaotic Conundrum' }
}
local filtered_spawns = {}

local my_raid_spot
local waittime = 0
local next_toon
local DEBUG     = true
local MEZZING   = false
local BANK      = false

local loc_banner   = { "232 863" }
local runaway = 'locyxz 24 -285 147' --w door, south side
local run2 = 'locyxz 135 -420 120'
local my_spells = {}
local my_raid = {}
local pass_to = {['CLR']=false, ['SHM']=false, ['DRU']=false, ['MNK']=true,['BST']=true, 
    ['WIZ']= true, ['NEC']=true, ['MAG']=true, ['WAR']=false, ['SHD']=false,
    ['PAL']=false, ['ROG']=true, ['BER']=true, ['RNG'] = true,['BRD']=false
}

--bouncy balls = RoF (Collectors) Globe
local freetag_buff = "Freeze Tag"
local snowball     = ""
local potato       = "Magnificent Planar Gem"

local function debug(string)
    if(def.DEBUG) then print(string.format('DEBUG: %s',tostring(string))) end
end
local function debug_d(string)
    if def.DEBUG then mq.cmd.dgt(string.format('\agDEBUG: %s',tostring(string))) end
end

local function cwtn(string) mq.cmd('/'..def.class..' '..string) end
local function isclass_plugin_loaded()
    local cPlugin = { BER='mq2berzerker', BRD='mq2bard', BST='mq2bst', CLR='mq2cleric', DRU='mq2druid', 
        ENC='mq2enchanter', MAG='mq2mage', MNK='mq2monk', NEC='mq2necro', PAL='mq2paladin', RNG='mq2ranger',
        ROG='mq2rogue', SHD='mq2eskay', SHM='mq2shaman', WAR='mq2war', WIZ='mq2wizard'
    }
    return mq.TLO.Plugin(cPlugin[mq.TLO.Me.Class.ShortName()]).IsLoaded()
end
local function pause()
    if(isclass_plugin_loaded() ) then mq.cmdf("/%s pause on", mq.TLO.Me.Class.ShortName() )
    elseif(mq.TLO.Macro.Name() == "kissassist") then squelch("/mqp on")
    elseif(mq.TLO.Macro.Name() == "rgmercs") then squelch("/mqp on")        
    elseif(mq.TLO.Lua.Script('rgmercs').Status() == 'RUNNING') then squelch('/lua pause rgmercs') 
    elseif(mq.TLO.Me.Class.ShortName() == "WIZ") then squelch("/nuke pause")
    elseif(mq.TLO.Macro.Name() == "entropy") then squelch("/mqp on") end
    if(mq.TLO.Me.Class.ShortName() == "BRD") then
        squelch("/twist off")
        mq.delay(100)
        squelch("/stopsong") end
    if(mq.TLO.Lua.Script('rip/multihunter').Status() == 'RUNNING') then squelch('/lua pause rip/multihunter') end
    if(mq.TLO.Lua.Script('offtank').Status() == 'RUNNING') then squelch('/lua pause offtank') end
    if(mq.TLO.Lua.Script('rip/offtank').Status() == 'RUNNING') then squelch('/lua pause rip/offtank') end
    if(mq.TLO.Lua.Script('chase').Status() == 'RUNNING') then squelch('/lua pause chase') end
    mq.delay(10)
    squelch("/stick off")
end
local function resume()
    if(isclass_plugin_loaded() ) then mq.cmdf("/%s pause off", mq.TLO.Me.Class.ShortName() )
    elseif(mq.TLO.Macro.Name() == "kissassist") then squelch("/mqp off")
    elseif(mq.TLO.Macro.Name() == "rgmercs") then squelch("/mqp off")
    elseif(mq.TLO.Macro.Name() == "entropy") then squelch("/mqp off")
    elseif(mq.TLO.Me.Class.ShortName() == "WIZ") then squelch("/nuke resume") end
    if(mq.TLO.Lua.Script('rip/multihunter').Status() == 'PAUSED') then squelch('/lua pause rip/multihunter') end
    if(mq.TLO.Lua.Script('rip/offtank').Status() == 'PAUSED') then squelch('/lua pause rip/offtank') end
    if(mq.TLO.Lua.Script('offtank').Status() == 'PAUSED') then squelch('/lua pause offtank') end
    if(mq.TLO.Lua.Script('chase').Status() == 'PAUSED') then squelch('/lua pause chase') end
    if(mq.TLO.Lua.Script('rgmercs').Status() == 'PAUSED') then squelch('/lua pause rgmercs') end
end

local function distance_between(spawn1, spawn2)
    local dist
    local x = mq.TLO.Spawn(spawn1).X()
    local y = mq.TLO.Spawn(spawn1).Y()
    local Lx = mq.TLO.Spawn(spawn2).X()
    local Ly = mq.TLO.Spawn(spawn2).Y()
    if (x==nil or y==nil or Lx == nil or Ly == nil) then return -1 end
    dist = math.sqrt(math.pow(x - Lx, 2) + math.pow(y - Ly, 2))
    return dist
end

-- stub for freeze tag
local function unfreeze_ma()
    
end

-- Magnificent Planar Gem, Item ID: 89563
local function select_pass()
    local n = 2 --nearest spawn 1 = self
    local tmp
    next_toon = mq.TLO.NearestSpawn(n,'pc').CleanName()
    --local next = my_raid[next_toon]
    mq.cmdf('/tar pc %s',next_toon)
    local SEL = false
    while not SEL do
        local tmp = mq.TLO.NearestSpawn(n,'pc')
        local next_toon = tmp.CleanName()
        local next_toon_class = tmp.Class.ShortName()
        mq.cmdf('/tar pc %s',next_toon)
        if not pass_to[next_toon_class] then
            n= n+1
            debug_d("Skipping : "..mq.TLO.Target.CleanName().. " ")
        elseif(mq.TLO.Spawn(next_toon).Dead() ) then
            n= n+1
            debug("Cannot pass gem to a corpse: "..mq.TLO.Target.CleanName().. " ")
        else
            SEL = true
            return next_toon
        end
    end
end

local function pickup_item(item)
    mq.cmdf('/nomodkey /itemnotify "%s" leftmouseup', item)
    mq.delay(100)
    mq.cmd.autoinventory()
end

local function pass()
    debug('Passing')
    pause()
    mq.cmd.stopcast()
    mq.cmd.stopsong()
    mq.delay(250)

    next_toon = select_pass()

    mq.cmdf('/rs Passing Gem to ---> %s',next_toon)
    --mq.cmdf('/tell %s Passing you the Gem',next)

    mq.cmdf('/useitem "%s"', potato)
    mq.delay(1000)
    resume()
    if mq.TLO.FindItem(89563).ID() == 89563 then
        pickup_item('Magnificent Planar Gem')
    end
    if mq.TLO.FindItem(89563).ID() == 89563 then 
        mq.delay(750)
        debug_d('I still have the Gem, trying again')
        pass() 
    end
    mq.cmd('/target hand_of_the_king')
    HOLDING = false
end

local function pass2(line, arg1)
    if(string.match(arg1,def.name) == def.name ) then
        debug_d('-->Using Valia, passing now')
        mq.cmd('/useitem valia')
        pass()
    end
end

local function gem_toss(line, arg1)
    if HOLDING then return end
    if (mq.TLO.FindItem(89563).ID() == 89563) and not HOLDING then
        HOLDING = true
        mq.cmd('/popup I GOT THE THING!')
        print('I GOT THE THING! ')
        mq.cmd('/autoinv')
        debug('Passing Gem in 16s')
        waittime = mq.gettime() + 16000
        while(mq.gettime() < waittime) do
            mq.delay(2000)
            debug("passing in "..(waittime-mq.gettime() )/1000 .." seconds" )
        end
        mq.cmd('/autoinv')
        debug('Delay timer done, Passing Gem')
        pause()

        pass()

        HOLDING = false
        resume()
    end
end

local function bank_gem()
    if (mq.TLO.FindItem(89563).ID() == 89563) then
        if not mq.TLO.Spawn('banker')() then
            pause()
            mq.delay(250)
            mq.cmd('/alt act 8130')
        end
        pause()
        mq.cmd('/tar banker')
        --mq.cmd('/nav target')

        mq.delay(1000)
        mq.cmd('/usetarget')
        mq.delay(1000)
        mq.cmdf('/nomodkey /itemnotify "%s" leftmouseup', potato)
        mq.delay(500)
        mq.cmd('/notify BigBankWnd BIGB_Autobutton leftmouseup')
        mq.delay(2500)
        mq.cmd('/notify BigBankWnd BIGB_DoneButton leftmouseup')
    end
    if (mq.TLO.FindItem(89563).ID() == 89563) then bank_gem() end
    BANK = false
end

local function emote(command)
    pause()
    mq.cmd('/nav spawn bristlebane')
    mq.delay(1500)
    mq.cmd('/tar bristlebane')
    mq.delay(500)
    --local targ = tostring(mq.TLO.Target.CleanName())
    mq.cmdf('/%s bristlebane',command)
    mq.delay(500)
    mq.cmd('/target hand_of_the_king')
    resume()
    if GIMP or mezzer[def.class] then 
        mq.cmdf('/nav %s',run2)
    end
end

local function emote_cheer(line, arg1) emote('cheer') end
local function emote_bow(line, arg1) emote('bow') end
local function emote_dance(line, arg1) emote('dance') end
local function emote_raise(line, arg1) emote('raise') end
local function emote_clap(line, arg1) emote('clap') end
local function emote_kneel(line, arg1) emote('kneel') end

--Paper Nuke: Caster AE - 650k DD + Stun (range 100, duration 2s)
local function paper(line,arg1,arg2)
    --debug('Paper: line = '..tostring(line)..' arg1 = '..tostring(arg1))
    if(string.match(arg1,def.name) == def.name and mq.TLO.Group.MainTank() ~= def.name) then
        debug('Paper: match successful')
        pause()
        mq.delay(500)
        --mq.cmd('/nav spawn campfire')
        mq.cmd.nav(runaway)
        mq.delay(12000)
        if GIMP or mezzer[def.class] then 
            mq.cmdf('/nav %s',run2)
        else
            mq.cmd('/nav spawn hand_of_the_king')
        end
        resume()
    end
end

local function rock()
    if GIMP and mq.TLO.Spawn('Hand of the King').Distance() < 100 then
        if mq.TLO.CWTN.Mode() ~= 'Manual' then cwtn('mode 0') end
        mq.cmdf('/nav %s',run2)
    end
end

local function bind_raid(...)
    local args = {...}
    local key = args[1]
    local value = args[2]
    if( key ==  'banner') then
        mq.cmd('/nav spawn banner')
    elseif( key == 'campfire') then
        mq.cmd('/nav spawn campfire')
    elseif( key == 'come' and mq.TLO.CWTN.RaidMode()) then
        mq.cmd('/nav spawn '..tostring(value))
    elseif( key == "freezetag") then
        unfreeze_ma()
    elseif(key == 'bank') then
        BANK = BANK==false
        print('BANK set to '..tostring(BANK))
    elseif(key=='setup') then
        if GIMP or mezzer[def.class] then 
            mq.cmdf('/nav %s',run2)
        else
            mq.cmd('/nav spawn king')
        end
    end
end

local function Init()
	mq.bind(def.cmd, bind_raid)

    local em1 = "#*#Fizzlethorpe says, 'Come close and cheer my greatness#*#"
    local em2 = "#*#Fizzlethorpe says, 'Come close and bow to me#*#"
    local em3 = "#*#Fizzlethorpe says, 'Come close and dance for me#*#"
    local em4 = "#*#Fizzlethorpe says, 'Come close and raise your hands in praise of me#*#"
    local em5 = "#*#Fizzlethorpe says, 'Come close and clap for me#*#"
    local em6 = "#*#Fizzlethorpe says, 'Come close and kneel before me#*#"

    local ev2 = '#*#Hand of the King shoots paper at #1#.#*#'
    local ev2a = '#*#Hand of the King shoots paper at #1#.'
    local ev3 = "#*#Bidils shouts, 'Hang on to this for me for a minute.' He tosses a huge gem to #1#."

    
    local ev4 = '#*#What is the gem doing on the ground? How about you hold onto it this time, #1#.'
    local ev5 = '#*#A white rabbit appears#*#'  --don't need event, handled by spawn search
    local ev6 = '#*#Hand of the King shoots rock#*#' --back out or heal thru?
    local ev7 = '#*#Time for a little Freeze Tag! #1#.' --find and touch?
    local ev8 = '#*#A large gem appears in your hands. It starts to build power#*#'  --personal version
    mq.event('em1',em1, emote_cheer)
    mq.event('em2',em2, emote_bow)
    mq.event('em3',em3, emote_dance)
    mq.event('em4',em4, emote_raise)
    mq.event('em5',em5, emote_clap)
    mq.event('em6',em6, emote_kneel)
    --mq.event('ev1',ev1, emotes)
    mq.event('ev2',ev2, paper)
    mq.event('ev2a',ev2a, paper)
    --mq.event('ev3',ev3, gem_toss)
    mq.event('ev4',ev4,pass2)
    --mq.event('ev5',ev8, gem_toss)
    mq.event('ev6',ev6,rock)
end

local function Main()   
    while true do
        local cursor = mq.TLO.Cursor.ID()==89563
        mq.doevents()
        --this can change depending on death, we'll just monitor continuously
        if mq.TLO.Me.MaxHPs() < 540000 then 
            GIMP = true
        else 
            GIMP = false 
        end
        if(cursor or (mq.TLO.FindItem(89563).ID() == 89563) and not HOLDING ) then
            mq.cmd('/autoinv') 
            if BANK then
                bank_gem()
            else 
                gem_toss()
            end
        end
        if (mq.gettime() < waittime and HOLDING ) then
            pass()
        end 
        mq.delay(def.pulse)
    end
end

Init()
Main()

