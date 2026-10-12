local addon, CR = ...
local defaults = { enabled=true, mode='pve', cooldowns=true, starfall=false, aoe=false,
    enemies=1, locked=false, scale=1, alpha=1, combatOnly=false, health=0.35,
    x=0, y=-160, interval=0.12 }
local db, frame, options, initialized
local function info(id)
    if C_Spell and C_Spell.GetSpellInfo then
        local v=C_Spell.GetSpellInfo(id); if v then return v.name,v.iconID end
    end
    if GetSpellInfo then local n,_,i=GetSpellInfo(id); return n,i end
end
local function cooldown(id)
    if C_Spell and C_Spell.GetSpellCooldown then
        local v=C_Spell.GetSpellCooldown(id)
        if v then return v.startTime or 0,v.duration or 0,v.isEnabled ~= false end
    end
    if GetSpellCooldown then local a,b,c=GetSpellCooldown(id); return a or 0,b or 0,c ~= 0 end
    return 0,0,false
end
local function known(id)
    return (IsPlayerSpell and IsPlayerSpell(id)) or (IsSpellKnown and IsSpellKnown(id)) or false
end
local function aura(unit,id,filter)
    for i=1,40 do
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local a=C_UnitAuras.GetAuraDataByIndex(unit,i,filter)
            if not a then break end
            if a.spellId==id then return a.expirationTime==0 and 999 or math.max(0,(a.expirationTime or 0)-GetTime()) end
        elseif UnitAura then
            local n,_,_,_,_,expires,_,_,_,spell=UnitAura(unit,i,filter)
            if not n then break end
            if spell==id then return expires==0 and 999 or math.max(0,(expires or 0)-GetTime()) end
        end
    end
    return 0
end
local function state()
    local now=GetTime()
    local _,_,_,startMS,endMS,_,_,_,castID=UnitCastingInfo('player')
    local horizon=endMS and math.max(0,endMS/1000-now) or 0
    local gs,gd=cooldown(61304)
    horizon=math.max(horizon,math.max(0,gs+gd-now))
    local s={ready={},health=UnitHealth('player')/math.max(1,UnitHealthMax('player')),
        mana=UnitPower('player',0)/math.max(1,UnitPowerMax('player',0)),
        target=UnitExists('target') and UnitCanAttack('player','target') and not UnitIsDeadOrGhost('target'),
        combat=UnitAffectingCombat('player'),moving=GetUnitSpeed('player')>0,
        channel=UnitChannelInfo('player')~=nil, enemies=db.enemies,
        elite=UnitClassification('target')=='elite' or UnitClassification('target')=='worldboss',
        lunar=aura('player',48518,'HELPFUL')>0,solar=aura('player',48517,'HELPFUL')>0,
        alignment=aura('player',112071,'HELPFUL')>0,proc=aura('player',93400,'HELPFUL')>0,
        moonfire=aura('target',8921,'HARMFUL|PLAYER'),sunfire=aura('target',93402,'HARMFUL|PLAYER'),
        refresh=horizon+1.5, energy=UnitPower('player',8),
        doc=known(108373),docBuff=aura('player',145151,'HELPFUL')>0,
        direction=GetEclipseDirection and GetEclipseDirection() or 'none'}
    if s.direction=='none' then s.direction=s.energy>0 and 'sun' or 'moon' end
    -- Suppress immediate duplication of the cast already underway.
    if castID==8921 then s.moonfire=999 end
    if castID==93402 then s.sunfire=999 end
    for k,id in pairs(CR.spells) do
        local st,dur,enabled=cooldown(id)
        local ready=known(id) and enabled and st+dur<=now+horizon+0.05
        local usable
        if C_Spell and C_Spell.IsSpellUsable then usable=C_Spell.IsSpellUsable(id)
        elseif IsUsableSpell then usable=IsUsableSpell(id) else usable=true end
        ready=ready and usable
        local charges
        if C_Spell and C_Spell.GetSpellCharges then local c=C_Spell.GetSpellCharges(id); charges=c and c.currentCharges
        elseif GetSpellCharges then charges=GetSpellCharges(id) end
        if charges~=nil then ready=known(id) and usable and charges>0 end
        local selfSpell=k=='heal' or k=='renewal' or k=='innervate' or k=='incarnation' or k=='alignment' or k=='vigil' or k=='starfall'
        if not selfSpell and s.target then
            local range
            if C_Spell and C_Spell.IsSpellInRange then range=C_Spell.IsSpellInRange(id,'target')
            elseif IsSpellInRange then range=IsSpellInRange(info(id),'target') end
            if range==false or range==0 then ready=false end
        end
        if s.moving and (k=='wrath' or k=='starfire' or k=='heal' or k=='hurricane' or (k=='starsurge' and not s.proc)) then ready=false end
        if castID==id and k~='wrath' and k~='starfire' then ready=false end
        s.ready[k]=ready
    end
    return s
end
local function apply()
    frame:SetScale(db.scale); frame:SetAlpha(db.alpha)
    frame:ClearAllPoints(); frame:SetPoint('CENTER',UIParent,'CENTER',db.x,db.y)
    frame:EnableMouse(not db.locked)
end
local function update()
    if not initialized then return end
    local _,class=UnitClass('player')
    local spec=GetSpecialization and GetSpecialization()
    if not db.enabled or class~='DRUID' or (spec and spec~=1) or UnitIsDeadOrGhost('player') or (db.combatOnly and not UnitAffectingCombat('player')) then frame:Hide(); return end
    local s=state(); local k=CR.Decide(s,db)
    if not k then frame:Hide(); return end
    local _,icon=info(CR.spells[k])
    if not icon then frame:Hide(); return end
    frame.icon:SetTexture(icon)
    local st,dur=cooldown(CR.spells[k]); frame.cd:SetCooldown(st,dur)
    frame:Show()
end
local function message(t) print('|cff9de660CocoRotation:|r '..t) end
local function toggleOptions()
    if options then options:SetShown(not options:IsShown()); return end
    options=CreateFrame('Frame','CocoRotationOptions',UIParent,'BackdropTemplate')
    options:SetSize(350,390); options:SetPoint('CENTER'); options:SetFrameStrata('DIALOG')
    options:SetBackdrop({bgFile='Interface/Tooltips/UI-Tooltip-Background',edgeFile='Interface/Tooltips/UI-Tooltip-Border',tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
    options:SetBackdropColor(0.04,0.07,0.1,0.96)
    local title=options:CreateFontString(nil,'OVERLAY','GameFontNormalLarge'); title:SetPoint('TOP',0,-18); title:SetText('CocoRotation • Opciones')
    local close=CreateFrame('Button',nil,options,'UIPanelCloseButton'); close:SetPoint('TOPRIGHT')
    local y=-52
    local function button(label,action)
        local b=CreateFrame('Button',nil,options,'UIPanelButtonTemplate'); b:SetSize(294,25); b:SetPoint('TOP',0,y); y=y-29
        b:SetText(label()); b:SetScript('OnClick',function() action(); b:SetText(label()); apply(); update() end)
        b:SetScript('OnShow',function() b:SetText(label()) end)
    end
    button(function() return 'Modo: '..db.mode end,function() db.mode=db.mode=='pve' and 'level' or 'pve' end)
    for _,v in ipairs({{'enabled','Asistente'},{'cooldowns','Cooldowns'},{'starfall','Lluvia de estrellas (área)'},{'aoe','Huracán con 3+ objetivos'},{'locked','Bloquear posición'},{'combatOnly','Mostrar solo en combate'}}) do
        local key,label=v[1],v[2]
        button(function() return label..': '..(db[key] and 'Sí' or 'No') end,function() db[key]=not db[key] end)
    end
    button(function() return 'Objetivos manuales: '..db.enemies end,function() db.enemies=db.enemies%8+1 end)
    button(function() return string.format('Escala: %.1f',db.scale) end,function() db.scale=db.scale>=1.8 and 0.7 or db.scale+0.1 end)
    button(function() return string.format('Opacidad: %.1f',db.alpha) end,function() db.alpha=db.alpha>=0.99 and 0.4 or db.alpha+0.1 end)
    local note=options:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall'); note:SetPoint('BOTTOM',0,10); note:SetText('Arrastra el icono desbloqueado. /coco ayuda')
end
local events=CreateFrame('Frame')
events:RegisterEvent('ADDON_LOADED')
events:SetScript('OnEvent',function(_,event,name)
    if event=='ADDON_LOADED' and name==addon then
        CocoRotationDB=type(CocoRotationDB)=='table' and CocoRotationDB or {}; db=CocoRotationDB
        for k,v in pairs(defaults) do if type(db[k])~=type(v) then db[k]=v end end
        db.scale=math.max(0.5,math.min(2,db.scale));db.alpha=math.max(0.2,math.min(1,db.alpha)); db.enemies=math.max(1,math.min(20,math.floor(db.enemies)))
        if db.mode~='pve' and db.mode~='level' then db.mode='pve' end
        frame=CreateFrame('Frame','CocoRotationDisplay',UIParent)
        frame:SetSize(52,52);frame:SetMovable(true);frame:SetClampedToScreen(true);frame:RegisterForDrag('LeftButton')
        frame.icon=frame:CreateTexture(nil,'ARTWORK');frame.icon:SetAllPoints(frame)
        frame.cd=CreateFrame('Cooldown',nil,frame,'CooldownFrameTemplate');frame.cd:SetAllPoints(frame.icon);frame.cd:SetHideCountdownNumbers(true)
        frame:SetScript('OnDragStart',function(self) if not db.locked then self:StartMoving() end end)
        frame:SetScript('OnDragStop',function(self) self:StopMovingOrSizing();local x,y=self:GetCenter();local ux,uy=UIParent:GetCenter();local ratio=self:GetEffectiveScale()/UIParent:GetEffectiveScale();db.x=x*ratio-ux;db.y=y*ratio-uy end)
        frame:SetScript('OnMouseUp',function(_,b) if b=='RightButton' then toggleOptions() end end)
        local elapsed=0
        events:SetScript('OnUpdate',function(_,dt) elapsed=elapsed+dt;if elapsed>=db.interval then elapsed=0;update() end end)
        initialized=true;apply();update()
        SLASH_COCOROTATION1='/coco';SLASH_COCOROTATION2='/cocorotation'
        SlashCmdList.COCOROTATION=function(input)
            local cmd,arg=input:lower():match('^(%S*)%s*(.-)$')
            if cmd=='' or cmd=='opciones' then toggleOptions()
            elseif cmd=='pve' or cmd=='leveo' then db.mode=cmd=='pve' and 'pve' or 'level'
            elseif cmd=='objetivos' and tonumber(arg) then db.enemies=math.max(1,math.min(20,math.floor(tonumber(arg))))
            elseif cmd=='escala' and tonumber(arg) then db.scale=math.max(0.5,math.min(2,tonumber(arg)));apply()
            elseif cmd=='opacidad' and tonumber(arg) then db.alpha=math.max(0.2,math.min(1,tonumber(arg)));apply()
            elseif cmd=='reset' then for k,v in pairs(defaults) do db[k]=v end;apply()
            elseif cmd=='estado' then local s=state();message('Cliente '..select(4,GetBuildInfo())..' | dirección '..s.direction..' | energía '..s.energy)
            elseif cmd=='ayuda' then message('/coco [pve|leveo|objetivos 1-20|escala 0.5-2|opacidad 0.2-1|reset|estado]. Clic derecho: opciones.')
            else message('Comando desconocido. Usa /coco ayuda.') end
            update()
        end
        message('Cargado. /coco abre opciones; /coco ayuda muestra comandos.')
    end
end)


