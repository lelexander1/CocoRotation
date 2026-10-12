table.unpack=table.unpack or unpack
local CR={}
assert(loadfile('CocoRotation/Engine.lua'))('CocoRotation',CR)
assert(loadfile('CocoRotation/CocoRotation.lua'))
local count=0
local function test(label, expected, change, opts)
 local s={ready={wrath=true,starfire=true},target=true,health=1,mana=1,moonfire=12,sunfire=12,refresh=1.5,direction='moon',enemies=1,combat=true}
 local o={mode='pve',health=.35,cooldowns=true,starfall=false,aoe=false}
 if change then change(s) end
 if opts then for k,v in pairs(opts) do o[k]=v end end
 local actual=CR.Decide(s,o)
 assert(actual==expected,label..': expected '..tostring(expected)..', got '..tostring(actual));count=count+1
end
test('Lunar direction','wrath')
test('Solar direction','starfire',function(s) s.direction='sun' end)
test('Proc priority','starsurge',function(s) s.proc=true;s.ready.starsurge=true;s.moonfire=0 end)
test('Own Moonfire missing','moonfire',function(s) s.moonfire=0;s.ready.moonfire=true end)
test('Own Sunfire missing','sunfire',function(s) s.sunfire=0;s.ready.sunfire=true end)
test('Alignment applies both','starfire',function(s) s.alignment=true;s.sunfire=0;s.ready.sunfire=true end)
test('Incarnation in Lunar','incarnation',function(s) s.lunar=true;s.ready.incarnation=true end)
test('No Incarnation in Solar','wrath',function(s) s.solar=true;s.ready.incarnation=true end)
test('Alignment outside Eclipse','alignment',function(s) s.ready.alignment=true end)
test('No Alignment inside Eclipse','wrath',function(s) s.lunar=true;s.ready.alignment=true end)
test('Vigil Eclipse','vigil',function(s) s.solar=true;s.ready.vigil=true end)
test('Treants charge','treants',function(s) s.ready.treants=true end)
test('Cooldown disabled','wrath',function(s) s.ready.alignment=true end,{cooldowns=false})
test('Level reserves burst','wrath',function(s) s.ready.alignment=true end,{mode='level'})
test('Level elite burst','alignment',function(s) s.ready.alignment=true;s.elite=true end,{mode='level'})
test('Level healing','heal',function(s) s.health=.1;s.ready.heal=true end,{mode='level'})
test('Renewal before heal','renewal',function(s) s.health=.1;s.ready.heal=true;s.ready.renewal=true end,{mode='level'})
test('Mana recovery','innervate',function(s) s.mana=.1;s.ready.innervate=true end)
test('No target',nil,function(s) s.target=false end)
test('Channel protected',nil,function(s) s.channel=true end)
test('Movement instant','moonfire',function(s) s.moving=true;s.ready.moonfire=true end)
test('Movement waits',nil,function(s) s.moving=true end)
test('Manual AoE','hurricane',function(s) s.enemies=3;s.ready.hurricane=true end,{aoe=true})
test('AoE disabled','wrath',function(s) s.enemies=3;s.ready.hurricane=true end)
test('Starfall opt in','starfall',function(s) s.ready.starfall=true end,{starfall=true})
test('Unlearned unavailable',nil,function(s) s.ready={} end)
test('Cenarius prepares Eclipse','heal',function(s) s.doc=true;s.energy=-80;s.ready.heal=true end)
test('Cenarius buff avoids duplicate heal','wrath',function(s) s.doc=true;s.docBuff=true;s.energy=-80;s.ready.heal=true end)
test('Channel before survival',nil,function(s) s.channel=true;s.health=.1;s.ready.heal=true end,{mode='level'})
print('PASS: '..count..' rotation scenarios; both Lua files compile')
-- Smoke test the live adapter, options, persistence and both API variants.
local handlers={};local objects={}
local function object(name)
 local obj={shown=true}
 setmetatable(obj,{__index=function(t,k)
  if k:find('^coco') then return nil end
  if k=='SetScript' then return function(self,event,fn) self[event]=fn end end
  if k=='CreateTexture' or k=='CreateFontString' then return function() return object() end end
  if k=='GetCenter' then return function() return 500,400 end end
  if k=='IsShown' then return function(self) return self.shown end end
  if k=='SetShown' then return function(self,v) self.shown=v end end
  return function() end
 end})
 objects[#objects+1]=obj;return obj
end
UIParent=object(); SlashCmdList={}
CreateFrame=function(_,name) local obj=object(name);if name then _G[name]=obj end;return obj end
GetTime=function() return 100 end
UnitClass=function() return 'Druid','DRUID' end
GetSpecialization=function() return 1 end
UnitHealth=function() return 100 end;UnitHealthMax=UnitHealth
UnitPower=function(_,p) return p==8 and -50 or 100 end;UnitPowerMax=function() return 100 end
UnitExists=function() return true end;UnitCanAttack=UnitExists
UnitIsDeadOrGhost=function() return false end
UnitAffectingCombat=UnitExists;GetUnitSpeed=function() return 0 end
UnitClassification=function() return 'normal' end
UnitCastingInfo=function() end;UnitChannelInfo=function() end
GetEclipseDirection=function() return 'moon' end
IsPlayerSpell=UnitExists
C_Spell={GetSpellInfo=function(id) return {name='Spell '..id,iconID=id} end,
 GetSpellCooldown=function() return {startTime=0,duration=0,isEnabled=true} end,
 IsSpellUsable=function() return true end,IsSpellInRange=function() return true end,
 GetSpellCharges=function() return nil end}
C_UnitAuras={GetAuraDataByIndex=function() return nil end}
GetBuildInfo=function() return '5.5.3','123','',50503 end
local addonCR={};assert(loadfile('CocoRotation/Engine.lua'))('CocoRotation',addonCR)
assert(loadfile('CocoRotation/CocoRotation.lua'))('CocoRotation',addonCR)
for _,obj in ipairs(objects) do if obj.OnEvent then obj.OnEvent(obj,'ADDON_LOADED','CocoRotation') end end
assert(CocoRotationDB.mode=='pve')
SlashCmdList.COCOROTATION('opciones');SlashCmdList.COCOROTATION('leveo')
assert(CocoRotationDB.mode=='level')
SlashCmdList.COCOROTATION('objetivos 3');assert(CocoRotationDB.enemies==3)
SlashCmdList.COCOROTATION('escala 9');assert(CocoRotationDB.scale==2)
SlashCmdList.COCOROTATION('reset');assert(CocoRotationDB.scale==1)
C_Spell=nil;C_UnitAuras=nil
GetSpellInfo=function(id) return 'Spell '..id,nil,id end
GetSpellCooldown=function() return 0,0,1 end
IsUsableSpell=function() return true end;IsSpellInRange=function() return 1 end
UnitAura=function() return nil end
for _,obj in ipairs(objects) do if obj.OnUpdate then obj.OnUpdate(obj,.2) end end
print('PASS: modern and legacy API adapter smoke tests, options and saved settings')

assert(loadfile('CocoRotation/Extras.lua'))('CocoRotation',addonCR)
assert(addonCR.GearScore({},1)==0)
assert(addonCR.GearScore({ITEM_MOD_INTELLECT_SHORT=100},1)==100)
assert(addonCR.GearScore({ITEM_MOD_AGILITY_SHORT=100},2)==100)
assert(addonCR.GearScore({RESISTANCE0_NAME=100},3)==2.5)
assert(addonCR.GearScore({ITEM_MOD_SPIRIT_SHORT=100},4)==65)
addonCR.damageSession.rows={A={done=0,taken=0},B={done=0,taken=0}}
addonCR.RecordDamage('SPELL_DAMAGE','A','B',100,20)
assert(addonCR.damageSession.rows.A.done==80)
assert(addonCR.damageSession.rows.B.taken==80)
addonCR.RecordDamage('SWING_DAMAGE','A','enemy',50,-1)
assert(addonCR.damageSession.rows.A.done==130)
addonCR.RecordDamage('ENVIRONMENTAL_DAMAGE',nil,'A',40,0)
assert(addonCR.damageSession.rows.A.taken==40)
addonCR.RecordDamage('SPELL_DAMAGE','enemy','A',30,80)
assert(addonCR.damageSession.rows.A.taken==40)
print('PASS: equipment scores for four specs, missing stats, damage accounting and overkill')
-- Exercise real combat-log adapter, ownership, session transitions and UI creation.
local extraEvents=objects[#objects]
UnitGUID=function(u) if u=='player' then return 'A' elseif u=='party1' then return 'B' elseif u=='pet' then return 'PET' end end
UnitName=function(u) return u end
IsInRaid=function() return false end
local inside=true
IsInInstance=function() return inside,'party' end
GetInstanceInfo=function() return 'Dungeon','party',1,nil,nil,nil,nil,123 end
GameTooltip=object();ItemRefTooltip=object()
extraEvents.OnEvent(extraEvents,'PLAYER_LOGIN')
local combatArgs={0,'SPELL_DAMAGE',false,'PET','Pet',0,0,'enemy','Enemy',0,0,123,'Spell',1,200,20}
CombatLogGetCurrentEventInfo=function() return table.unpack(combatArgs) end
extraEvents.OnEvent(extraEvents,'COMBAT_LOG_EVENT_UNFILTERED')
assert(addonCR.damageSession.rows.A.done==180,'pet damage attributed to owner')
combatArgs={0,'SWING_DAMAGE',false,'enemy','Enemy',0,0,'B','party1',0,0,90,-1}
extraEvents.OnEvent(extraEvents,'COMBAT_LOG_EVENT_UNFILTERED')
assert(addonCR.damageSession.rows.B.taken==90,'swing damage received')
extraEvents.OnUpdate(extraEvents,2)
assert(addonCR.damageSession.seconds==2,'combat seconds')
SlashCmdList.COCODAMAGE('')
inside=false;extraEvents.OnEvent(extraEvents,'PLAYER_ENTERING_WORLD')
assert(addonCR.damageSession.rows.A.done==180,'keep dungeon results after leaving')
inside=true;extraEvents.OnEvent(extraEvents,'PLAYER_ENTERING_WORLD')
assert(addonCR.damageSession.rows.A.done==0,'new dungeon session resets')
print('PASS: combat-log parsing, pet attribution, timer, meter UI and instance transitions')
assert(addonCR.GearVerdict(110,100,false)=='MEJORA ESTIMADA')
assert(addonCR.GearVerdict(90,100,false)=='PEOR POR ESTADÍSTICAS')
assert(addonCR.GearVerdict(100,100,false)=='SIMILAR POR ESTADÍSTICAS')
assert(addonCR.GearVerdict(200,100,true):find('REVISAR'))
assert(addonCR.GearVerdict(200,nil,false):find('REVISAR'))
-- Tooltip hooks: incompatible axe and a caster improvement.
local tooltipLines,tipHooks={},{}
GameTooltip.GetItem=function() return 'Test','item:123' end
GameTooltip.HookScript=function(_,event,fn) tipHooks[event]=fn end
GameTooltip.AddLine=function(_,text) tooltipLines[#tooltipLines+1]=text end
local itemClass,itemSub=2,1
GetItemInfo=function() return 'Test','item:123',2,20,1,'Weapon','Axe',1,'INVTYPE_2HWEAPON',nil,nil,itemClass,itemSub end
GetItemStats=function(link) return {ITEM_MOD_INTELLECT_SHORT=link=='item:123' and 100 or 10} end
GetInventoryItemLink=function(_,slot) if slot==16 then return 'item:old' end end
extraEvents.OnEvent(extraEvents,'PLAYER_LOGIN')
tipHooks.OnTooltipSetItem(GameTooltip)
assert(table.concat(tooltipLines,' '):find('NO EQUIPABLE POR DRUIDA'))
GameTooltip.cocoGearLink=nil;tooltipLines={};itemSub=10
tipHooks.OnTooltipSetItem(GameTooltip)
assert(table.concat(tooltipLines,' '):find('Equilibrio %(actual%): MEJORA ESTIMADA'))
local before=#tooltipLines;tipHooks.OnTooltipSetItem(GameTooltip);assert(#tooltipLines==before,'tooltip lines must not duplicate')
print('PASS: upgrade/downgrade/review verdicts, axe restriction, active spec and tooltip stability')



