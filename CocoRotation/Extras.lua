local _, CR = ...
-- Relative, deliberately editable heuristics; not simulation or a BiS database.
CR.gearProfiles = {
 {name='Equilibrio', weights={INTELLECT=1,SPELL_POWER=.8,HIT_RATING=.55,SPIRIT=.55,HASTE_RATING=.5,CRIT_RATING=.45,MASTERY_RATING=.35}},
 {name='Feral', weights={AGILITY=1,ATTACK_POWER=.4,HIT_RATING=.4,EXPERTISE_RATING=.4,MASTERY_RATING=.5,CRIT_RATING=.45,HASTE_RATING=.35}},
 {name='Guardián',weights={AGILITY=1,STAMINA=.55,ARMOR=.025,DODGE_RATING=.35,MASTERY_RATING=.35,CRIT_RATING=.5,HIT_RATING=.3,EXPERTISE_RATING=.3,HASTE_RATING=.2}},
 {name='Restauración',weights={INTELLECT=1,SPELL_POWER=.8,SPIRIT=.65,HASTE_RATING=.5,MASTERY_RATING=.45,CRIT_RATING=.35}}
}
function CR.GearScore(stats,spec)
 local score=0
 for stat,weight in pairs(CR.gearProfiles[spec].weights) do
  local value=stats['ITEM_MOD_'..stat..'_SHORT']
  if stat=='ARMOR' then value=stats.RESISTANCE0_NAME or value end
  score=score+(value or 0)*weight
 end
 return score
end
local slots={INVTYPE_HEAD={1},INVTYPE_NECK={2},INVTYPE_SHOULDER={3},INVTYPE_CHEST={5},INVTYPE_ROBE={5},INVTYPE_WAIST={6},INVTYPE_LEGS={7},INVTYPE_FEET={8},INVTYPE_WRIST={9},INVTYPE_HAND={10},INVTYPE_FINGER={11,12},INVTYPE_TRINKET={13,14},INVTYPE_CLOAK={15},INVTYPE_WEAPON={16,17},INVTYPE_2HWEAPON={16},INVTYPE_WEAPONMAINHAND={16},INVTYPE_WEAPONOFFHAND={17},INVTYPE_HOLDABLE={17},INVTYPE_SHIELD={17},INVTYPE_RANGED={16},INVTYPE_RANGEDRIGHT={16},INVTYPE_THROWN={16}}
local getInfo=function(link) if C_Item and C_Item.GetItemInfo then return C_Item.GetItemInfo(link) elseif GetItemInfo then return GetItemInfo(link) end end
local getStats=function(link) if C_Item and C_Item.GetItemStats then return C_Item.GetItemStats(link) elseif GetItemStats then return GetItemStats(link) end end
local allowedWeapons={[4]=true,[5]=true,[6]=true,[10]=true,[13]=true,[15]=true}
function CR.GearVerdict(score,base,uncertain)
 if uncertain then return 'REVISAR: efectos o conjunto no evaluados',1,.8,.25 end
 if base==nil then return 'REVISAR: esperando datos del equipado',1,.8,.25 end
 if score>base+.05 then return 'MEJORA ESTIMADA',.25,1,.35 end
 if score<base-.05 then return 'PEOR POR ESTADÍSTICAS',1,.35,.3 end
 return 'SIMILAR POR ESTADÍSTICAS',.8,.8,.8
end
local function decorateCore(tip)
 if not tip.GetItem then return end
 local _,link=tip:GetItem();if not link or tip.cocoGearLink==link then return end
 local _,_,_,_,_,_,_,_,equip,_,_,classID,subclassID=getInfo(link)
 if not equip or not slots[equip] then return end
 local stat=getStats(link)
 if not stat then return end
 tip.cocoGearLink=link
 tip:AddLine(' ');tip:AddLine('CocoRotation • ¿Me sirve?',.62,.9,.38)
 if (classID==2 and not allowedWeapons[subclassID]) or (classID==4 and subclassID and subclassID>2) then
  tip:AddLine('NO EQUIPABLE POR DRUIDA',1,.3,.3);return
 end
 local current=GetSpecialization and GetSpecialization() or 1
 if not CR.gearProfiles[current] then current=1 end
 local weapon=equip:find('WEAPON')~=nil or equip=='INVTYPE_HOLDABLE'
 for offset=0,3 do
  local spec=offset==0 and current or offset
  if offset>0 and spec>=current then spec=spec+1 end
  local p=CR.gearProfiles[spec]
  local score=CR.GearScore(stat,spec);local base,missing,oldLinks=nil,false,{}
  for _,slot in ipairs(slots[equip]) do
   local old=GetInventoryItemLink('player',slot)
   if old then
    oldLinks[#oldLinks+1]=old
    local oldStats=getStats(old)
    if not oldStats then missing=true else local v=CR.GearScore(oldStats,spec);base=base and math.min(base,v) or v end
   else base=0 end
  end
  if weapon and equip=='INVTYPE_2HWEAPON' then
   local off=GetInventoryItemLink('player',17)
   if off then local st=getStats(off);if st and base then base=base+CR.GearScore(st,spec) else missing=true end end
  end
  if missing then base=nil end
  local uncertain=equip=='INVTYPE_TRINKET' or (weapon and (spec==2 or spec==3))
  -- An offhand/mainhand cannot be rated independently against an equipped two-hander.
  if weapon and equip~='INVTYPE_2HWEAPON' then
   local main=GetInventoryItemLink('player',16)
   if main and select(9,getInfo(main))=='INVTYPE_2HWEAPON' then uncertain=true end
  end
  local verdict,r,g,b=CR.GearVerdict(score,base,uncertain)
  tip:AddLine(p.name..(spec==current and ' (actual)' or '')..': '..verdict,r,g,b)
  local delta=base and score-base
  tip:AddLine(delta and string.format('  %.1f puntos | cambio %+.1f%s',score,delta,base>0 and string.format(' (%+.1f%%)',100*delta/base) or '') or '  Esperando información del objeto equipado.',.8,.85,.95)
 end
 tip:AddLine('Verde = mejor valoración; rojo = inferior; amarillo = revisar.',.8,.8,.8)
 tip:AddLine('Estimación: no calcula caps, procs ni bonos de conjunto.',1,.8,.35)
 if weapon then tip:AddLine('Feral/Guardián: el DPS del arma requiere revisión.',1,.8,.35) end

end

-- Append only while WoW constructs the tooltip. Never Show/Hide it or poll it:
-- doing so can re-enter item comparison and repeatedly rebuild the tooltip.
local function decorate(tip)
 if tip.cocoGearBusy then return end
 tip.cocoGearBusy=true
 local ok,err=pcall(decorateCore,tip)
 tip.cocoGearBusy=nil
 if not ok then geterrorhandler()(err) end
end
-- Effective damage excludes overkill. Pet output belongs to its owner.
CR.damageSession={rows={},seconds=0}
function CR.RecordDamage(event,source,dest,amount,overkill)
 local session=CR.damageSession
 local effective=math.max(0,(tonumber(amount) or 0)-math.max(0,tonumber(overkill) or 0))
 if source and session.rows[source] then session.rows[source].done=session.rows[source].done+effective end
 if dest and session.rows[dest] then session.rows[dest].taken=session.rows[dest].taken+effective end
end
local owners,roster={},{}
local function refreshRoster()
 owners={};roster={}
 local units={'player'}
 if IsInRaid() then for i=1,GetNumGroupMembers() do units[#units+1]='raid'..i end
 else for i=1,4 do units[#units+1]='party'..i end end
 for _,unit in ipairs(units) do
  local guid=UnitGUID(unit)
  if guid then
   roster[guid]=unit
   local name=GetUnitName and GetUnitName(unit,true) or UnitName(unit)
   local row=CR.damageSession.rows[guid]
   if not row then row={done=0,taken=0};CR.damageSession.rows[guid]=row end
   row.name=name or '?'
   local _,class=UnitClass(unit);row.class=class
   local pet=unit=='player' and 'pet' or unit:gsub('(%d+)$','pet%1')
   local pg=UnitGUID(pet);if pg then owners[pg]=guid end
  end
 end
end
local function reset()
 CR.damageSession={rows={},seconds=0};refreshRoster()
end
local panel
local mode='done'
local function compact(n)
 if n>=1000000 then return string.format('%.2fM',n/1000000) end
 if n>=1000 then return string.format('%.1fk',n/1000) end
 return string.format('%.0f',n)
end
local function render()
 if not panel or not panel:IsShown() then return end
 local session=CR.damageSession;local list,total={},0
 for _,r in pairs(session.rows) do list[#list+1]=r;total=total+r[mode] end
 table.sort(list,function(a,b) if a[mode]==b[mode] then return (a.name or '')<(b.name or '') end;return a[mode]>b[mode] end)
 panel.heading:SetText(mode=='done' and 'DAÑO REALIZADO   •   DPS   •   %' or 'DAÑO RECIBIDO   •   POR SEGUNDO   •   %')
 local max=list[1] and list[1][mode] or 0
 for i,bar in ipairs(panel.bars) do
  local r=list[i]
  if r then
   local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[r.class] or {r=.9,g=.5,b=.15}
   bar:SetMinMaxValues(0,math.max(1,max));bar:SetValue(r[mode]);bar:SetStatusBarColor(color.r,color.g,color.b,.85)
   bar.left:SetText(i..'. '..(r.name or '?'))
   bar.right:SetText(string.format('%s  |  %s/s  |  %.1f%%',compact(r[mode]),compact(r[mode]/math.max(1,session.seconds)),total>0 and 100*r[mode]/total or 0))
   bar:Show()
  else bar:Hide() end
 end
 panel.footer:SetText(string.format('Total %s • %s/s • %.0fs en combate',compact(total),compact(total/math.max(1,session.seconds)),session.seconds))
end
local function showPanel()
 if panel then panel:SetShown(not panel:IsShown());render();return end
 panel=CreateFrame('Frame','CocoRotationDamage',UIParent,'BackdropTemplate')
 panel:SetSize(440,410);panel:SetPoint('CENTER',180,0);panel:SetMovable(true);panel:EnableMouse(true);panel:RegisterForDrag('LeftButton');panel:SetClampedToScreen(true)
 panel:SetBackdrop({bgFile='Interface/Buttons/WHITE8X8',edgeFile='Interface/Buttons/WHITE8X8',edgeSize=1,insets={left=1,right=1,top=1,bottom=1}});panel:SetBackdropColor(.035,.035,.045,.92);panel:SetBackdropBorderColor(.2,.2,.25,1)
 panel:SetScript('OnDragStart',panel.StartMoving);panel:SetScript('OnDragStop',panel.StopMovingOrSizing)
 local close=CreateFrame('Button',nil,panel,'UIPanelCloseButton');close:SetPoint('TOPRIGHT')
 local title=panel:CreateFontString(nil,'OVERLAY','GameFontNormal');title:SetPoint('TOPLEFT',10,-12);title:SetText('CocoRotation | Total de la mazmorra')
 panel.heading=panel:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');panel.heading:SetPoint('TOPLEFT',10,-37)
 panel.bars={}
 for i=1,12 do
  local bar=CreateFrame('StatusBar',nil,panel);bar:SetHeight(23);bar:SetPoint('TOPLEFT',10,-57-(i-1)*25);bar:SetPoint('TOPRIGHT',-10,-57-(i-1)*25)
  bar:SetStatusBarTexture('Interface/Buttons/WHITE8X8')
  local bg=bar:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints();bg:SetColorTexture(.13,.13,.16,.8)
  local overlay=CreateFrame('Frame',nil,bar);overlay:SetAllPoints()
  bar.left=overlay:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');bar.left:SetPoint('LEFT',5,0);bar.left:SetWidth(165);bar.left:SetJustifyH('LEFT');bar.left:SetShadowOffset(1,-1)
  bar.right=overlay:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');bar.right:SetPoint('RIGHT',-5,0);bar.right:SetJustifyH('RIGHT');bar.right:SetShadowOffset(1,-1)
  panel.bars[i]=bar
 end
 panel.footer=panel:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');panel.footer:SetPoint('BOTTOMLEFT',10,40)
 local b=CreateFrame('Button',nil,panel,'UIPanelButtonTemplate');b:SetSize(190,23);b:SetPoint('BOTTOMLEFT',10,10);b:SetText('Daño realizado / recibido');b:SetScript('OnClick',function() mode=mode=='done' and 'taken' or 'done';render() end)
 local r=CreateFrame('Button',nil,panel,'UIPanelButtonTemplate');r:SetSize(115,23);r:SetPoint('BOTTOMRIGHT',-10,10);r:SetText('Reiniciar');r:SetScript('OnClick',function() reset();render() end)
 render()
end

local enabled=false;local instanceKey
local events=CreateFrame('Frame')
for _,event in ipairs({'PLAYER_LOGIN','GROUP_ROSTER_UPDATE','UNIT_PET','PLAYER_ENTERING_WORLD','COMBAT_LOG_EVENT_UNFILTERED'}) do events:RegisterEvent(event) end
local function checkInstance()
 local inside,kind=IsInInstance();enabled=inside and (kind=='party' or kind=='raid')
 local _,_,difficulty,_,_,_,_,id=GetInstanceInfo()
 local key=enabled and tostring(id)..':'..tostring(difficulty) or 'outside'
 if instanceKey~=key then
  if enabled then reset() end
  instanceKey=key
 end
end
events:SetScript('OnEvent',function(_,event)
 if event=='PLAYER_LOGIN' then
  refreshRoster();checkInstance()
  local tips={GameTooltip,ItemRefTooltip}
  local modern=TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType
  if modern then
   TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item,function(tip)
    if tip==GameTooltip or tip==ItemRefTooltip then decorate(tip) end
   end)
  end
  for _,tip in ipairs(tips) do
   tip:HookScript('OnTooltipCleared',function(t) t.cocoGearLink=nil end)
   if not modern then tip:HookScript('OnTooltipSetItem',decorate) end
  end
  SLASH_COCODAMAGE1='/cocodmg'
  SlashCmdList.COCODAMAGE=function(input) if input:lower()=='reset' then reset();render() else showPanel() end end
 elseif event=='PLAYER_ENTERING_WORLD' then checkInstance();refreshRoster()
 elseif event=='GROUP_ROSTER_UPDATE' or event=='UNIT_PET' then refreshRoster()
 elseif enabled then
  local a={CombatLogGetCurrentEventInfo()};local eventType=a[2]
  if eventType=='SPELL_SUMMON' and (roster[a[4]] or owners[a[4]]) then owners[a[8]]=owners[a[4]] or a[4] end
  local amount,overkill
  if eventType=='SWING_DAMAGE' then amount,overkill=a[12],a[13]
  elseif eventType=='SPELL_DAMAGE' or eventType=='SPELL_PERIODIC_DAMAGE' or eventType=='RANGE_DAMAGE' or eventType=='DAMAGE_SHIELD' or eventType=='DAMAGE_SPLIT' then amount,overkill=a[15],a[16]
  elseif eventType=='ENVIRONMENTAL_DAMAGE' then amount,overkill=a[13],a[14] end
  if amount then CR.RecordDamage(eventType,owners[a[4]] or a[4],a[8],amount,overkill) end
 end
end)
local elapsed=0
events:SetScript('OnUpdate',function(_,dt)
 if enabled then
  for _,unit in pairs(roster) do if UnitAffectingCombat(unit) then CR.damageSession.seconds=CR.damageSession.seconds+dt;break end end
 end
 elapsed=elapsed+dt;if elapsed>=.5 then elapsed=0;render() end
end)







