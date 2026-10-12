local _, CR = ...
CR.spells = { wrath=5176, starfire=2912, moonfire=8921, sunfire=93402,
    starsurge=78674, starfall=48505, alignment=112071, incarnation=102560,
    vigil=124974, treants=33831, communion=127663, hurricane=16914,
    heal=5185, renewal=108238, innervate=29166, typhoon=132469 }
-- Pure priority engine. Availability, range and resources are supplied by the adapter.
function CR.Decide(s, o)
    local function pick(k, why)
        if s.ready[k] then return k, why end
    end
    local k, why
    if s.channel then return nil, 'Canalizando: no interrumpir' end
    if o.mode == 'level' and s.health < o.health then
        k,why=pick('renewal','Supervivencia: salud baja'); if k then return k,why end
        k,why=pick('heal','Recuperar salud'); if k then return k,why end
    end
    if s.mana < 0.2 then
        k,why=pick('innervate','Recuperar maná'); if k then return k,why end
    end
    if not s.target then return nil, 'Selecciona un enemigo vivo' end
    if s.proc then
        k,why=pick('starsurge','Estrellas fugaces: evitar perder el proc'); if k then return k,why end
    end
    if s.moonfire <= s.refresh then
        k,why=pick('moonfire','Mantener Fuego lunar propio'); if k then return k,why end
    end
    -- During Alignment, Moonfire applies both DoTs; allow one update before rechecking.
    if not s.alignment and s.sunfire <= s.refresh then
        k,why=pick('sunfire','Mantener Fuego solar propio'); if k then return k,why end
    end
    if o.cooldowns and s.combat and (o.mode == 'pve' or s.elite) then
        if s.lunar then
            k,why=pick('incarnation','Encarnación al entrar en Eclipse lunar'); if k then return k,why end
        end
        if s.lunar or s.solar or s.alignment then
            k,why=pick('vigil','Vigilia de la Naturaleza durante Eclipse'); if k then return k,why end
        end
        if not s.lunar and not s.solar and not s.alignment then
            k,why=pick('alignment','Alineación celestial fuera de Eclipse'); if k then return k,why end
        end
        k,why=pick('treants','Fuerza de la Naturaleza: usar cargas'); if k then return k,why end
    end
    if o.starfall then
        k,why=pick('starfall','Lluvia de estrellas: comprueba enemigos cercanos'); if k then return k,why end
    end
    if o.aoe and s.enemies >= 3 and not s.moving then
        k,why=pick('hurricane','AoE manual: Huracán'); if k then return k,why end
    end
    k,why=pick('starsurge','Oleada de estrellas disponible'); if k then return k,why end
    if s.moving then
        local dot = (s.solar and 'sunfire') or 'moonfire'
        k,why=pick(dot,'Movimiento: hechizo instantáneo'); if k then return k,why end
        return nil,'En movimiento: espera un instantáneo'
    end
    if s.doc and not s.docBuff and not s.lunar and not s.solar and not s.alignment and math.abs(s.energy or 0)>=70 and not s.moving then
        k,why=pick('heal','Sueño de Cenarius: preparar el siguiente Eclipse'); if k then return k,why end
    end
    local filler = (s.alignment or s.direction == 'sun') and 'starfire' or 'wrath'
    k,why=pick(filler,'Avanzar hacia Eclipse '..(s.direction == 'sun' and 'solar' or 'lunar'))
    if k then return k,why end
    k,why=pick(filler == 'wrath' and 'starfire' or 'wrath','Hechizo aprendido disponible')
    return k, why or 'Sin habilidad disponible / fuera de alcance'
end

