-- Variables globales
local totalNotes = 0
local playedNotes = 0
local currentProgress = "0.00%"
local remainingNotes = 0

local yaraHit = 0 -- Nuevo contador para Yara
local sickHit = 0
local goodHit = 0
local badHit = 0
local shitHit = 0
local miss = 0

local tamanoFijo = 20 -- cambia esto al tamaño que quieras
local fuenteFija = 'vcr.ttf' -- pon aquí el nombre exacto de tu fuente

function onCreate()
    makeLuaText('yaraCounter', 'Yaras: 0', 0, 4, 275)
    setTextSize('yaraCounter', 22)
    setTextBorder('yaraCounter', 2, '000000')
    addLuaText('yaraCounter')
    setTextColor('yaraCounter', 'FFC800')
 
    makeLuaText('sickCounter', 'Sicks!: 0', 0, 4, 300)
    setTextSize('sickCounter', 22)
    setTextBorder('sickCounter', 2, '000000')
    addLuaText('sickCounter')
    setTextColor('sickCounter', '7FC9FF')
 
    makeLuaText('goodCounter', 'Goods: 0', 0, 4, 325)
    setTextSize('goodCounter', 22)
    setTextBorder('goodCounter', 2, '000000')
    addLuaText('goodCounter')
    setTextColor('goodCounter', '7FFF8E')
 
    makeLuaText('badCounter', 'Bads: 0', 0, 4, 350)
    setTextSize('badCounter', 22)
    setTextBorder('badCounter', 2, '000000')
    addLuaText('badCounter')
    setTextColor('badCounter', 'A17FFF')
 
    makeLuaText('shitCounter', 'Shits: 0', 0, 4, 375)
    setTextSize('shitCounter', 22)
    setTextBorder('shitCounter', 2, '000000')
    addLuaText('shitCounter')
    setTextColor('shitCounter', 'FF7F7F')
 
    makeLuaText('missCounter', 'Combo Breaks: 0', 0, 4, 400)
    setTextSize('missCounter', 22)
    setTextBorder('missCounter', 2, '000000')
    addLuaText('missCounter')
    setTextColor('missCounter', 'FF1500')

    setTextSize('scoreTxt', tamanoFijo)
    setTextFont('scoreTxt', fuenteFija)
    setProperty('scoreTxt.alpha', 1) -- opacidad al 100%

    makeLuaText('versionHUD', "Plus Engine v" ..PlusVersion.. "\nPsych Engine v" ..PsychVersion.. "\nFriday Night Funkin' v0.2.8\nYT: @Lenin_Anonimo_Of", 500, 380, 580) -- x = 10 (izquierda), y = 690 (abajo)
    setTextSize('versionHUD', 14)
    doTweenAlpha('versionHUD', 'versionHUD', 0.5, 0.5, 'linear')
    setTextAlignment('versionHUD', 'center')
    setObjectCamera('versionHUD', 'other') -- que esté en la pantalla normal
    setTextFont('versionHUD', 'vcr.ttf') -- opcional: ponle la misma fuente que usas
    addLuaText('versionHUD')

        -- Crear texto para los segundos finales
        makeLuaText('finalCountdown', '', 300, 490, 230)
        setTextSize('finalCountdown', 40) -- Tamaño grande
        setTextFont('finalCountdown', 'vcr.ttf')
        setTextAlignment('finalCountdown', 'center')
        setTextColor('finalCountdown', 'FFFFFF') -- Color blanco
        addLuaText('finalCountdown')
        setObjectCamera('finalCountdown', 'other') -- Asegurarse de que esté en la cámara correcta

        local screenWidth = 1280
        local textWidth = getProperty('finalCountdown.width')
        local centerX = (screenWidth - textWidth) / 2
        setProperty('finalCountdown.x', centerX)
    
        -- Inicialmente invisible
        setProperty('finalCountdown.visible', false)
        
        -- Variable para controlar el último segundo mostrado
        lastSecondShown = -1
end

function onCreatePost()
    -- Contar todas las notas del jugador (mustPress = true)
    for i = 0, getProperty('unspawnNotes.length')-1 do
        if getPropertyFromGroup('unspawnNotes', i, 'mustPress') then
            totalNotes = totalNotes + 1
        end
    end

    remainingNotes = totalNotes
end

-- Esta función se llama cada vez que se toca cualquier nota (acertada o no)
function noteMiss(id, direction, noteType, isSustainNote)
    playedNotes = playedNotes + 1
    remainingNotes = totalNotes - playedNotes
    updateProgress()

    miss = miss + 1
   bumpText('missCounter') -- Efecto bump en Miss
end

function goodNoteHit(id, direction, noteType, isSustainNote)
    playedNotes = playedNotes + 1
    remainingNotes = totalNotes - playedNotes
    updateProgress()

    if not isSustainNote then
        local rating = getPropertyFromGroup('notes', id, 'rating')
        local msOffset = math.abs(getPropertyFromGroup('notes', id, 'strumTime') - getSongPosition()) -- Diferencia en ms
  
        if rating == 'marvelous' then
           yaraHit = yaraHit + 1
           bumpText('yaraCounter') -- Efecto bump en Yara
        elseif rating == 'sick' then
           sickHit = sickHit + 1
           bumpText('sickCounter') -- Efecto bump en Sick
        elseif rating == 'good' then
           goodHit = goodHit + 1
           bumpText('goodCounter') -- Efecto bump en Good
        elseif rating == 'bad' then
           badHit = badHit + 1
           bumpText('badCounter') -- Efecto bump en Bad
        elseif rating == 'shit' then
           shitHit = shitHit + 1
           bumpText('shitCounter') -- Efecto bump en Shit
        end
     end
end

function updateProgress()
    local percent = (playedNotes / totalNotes) * 100
    currentProgress = string.format("%.2f", percent) .. "%"
end

-- Actualizar el texto de la puntuación con progreso y notas restantes
function onUpdatePost()
    local nombre = songName
    local dificultad = difficultyName
    local fecha = os.date("%d/%m/%Y")
    local hora = os.date("%H:%M:%S")

    local folderName = currentModDirectory

    local health = getProperty('health') -- Va de 0.0 a 2.0
    local percent = math.floor(health * 50) -- 1.0 = 50%, 2.0 = 100%

    local score = getProperty('songScore')
    local abbrevScore = abbreviateNumber(score)
    local acc = getProperty('ratingPercent') or 0
    acc = math.floor(acc * 10000) / 100 -- dos decimales
    setTextString('scoreTxt', 'Mod: ' ..folderName.. '\n' ..nombre.. ' (' ..dificultad.. ') | Hora y Fecha: ' ..hora.. ' - ' ..fecha.. '\nPuntuación: ' .. abbrevScore .. ' | Perdidas: ' .. misses.. ' | Calificación: ' ..acc.. '%\nProgreso: ' .. currentProgress .. ' | Notas restantes: ' .. remainingNotes.. ' | BPM: ' ..curBpm.. ' | Salud: ' ..percent.. '\n' ..curBeat.. ' - ' ..curStep)

    setProperty('scoreTxt.visible', true)

        -- Calcular tiempo restante
        local timeRemaining = math.max(0, getProperty('songLength') - getSongPosition())
        local secondsRemaining = math.floor(timeRemaining / 1000)
        
        -- Mostrar solo cuando queden 15 segundos o menos
        if secondsRemaining <= 30 and secondsRemaining >= 0 then
            setProperty('finalCountdown.visible', true)
            
            -- Actualizar texto solo si cambió el segundo
            if secondsRemaining ~= lastSecondShown then
                setTextString('finalCountdown', tostring(secondsRemaining))
                bumpTextV2('finalCountdown') -- Aplicar efecto bump
                lastSecondShown = secondsRemaining
            end
        else
            setProperty('finalCountdown.visible', false)
            lastSecondShown = -1
        end
end

-- Función que acorta los números grandes
function abbreviateNumber(num)
    if num >= 1000000 then
        return string.format("%.2fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fk", num / 1000)
    else
        return tostring(num)
    end
end

local movedScore = false

function onUpdate(elapsed)
    setTextString('yaraCounter', 'MVS:   ' .. yaraHit)
    setTextString('sickCounter', 'SKS:   ' .. sickHit)
    setTextString('goodCounter', 'GDS:   ' .. goodHit)
    setTextString('badCounter',  'BDS:   ' .. badHit)
    setTextString('shitCounter', 'SHS:   ' .. shitHit)
    setTextString('missCounter', 'MIS:   ' .. miss)

    if getProperty('health') > 1.8 and not movedScore then
        movedScore = true
        if downscroll then
            -- Ocultar la barra y los íconos con tween
            doTweenY('barGone', 'healthBar', -200, 0.5, 'quadOut')
            doTweenY('iconP1Gone', 'iconP1', -200, 0.5, 'quadOut')
            doTweenY('iconP2Gone', 'iconP2', -200, 0.5, 'quadOut')

            -- Mover scoreText al lugar de la barra
            doTweenY('scoreY', 'scoreTxt', 30, 0.5, 'quadOut')  -- posición alta para downscroll
            doTweenAlpha('scoreAlpha', 'scoreTxt', 1, 0.5, 'linear')
            setTextSize('scoreTxt', 24)
        else
            -- Ocultar la barra y los íconos con tween
            doTweenY('barGone', 'healthBar', 800, 0.5, 'quadOut')
            doTweenY('iconP1Gone', 'iconP1', 800, 0.5, 'quadOut')
            doTweenY('iconP2Gone', 'iconP2', 800, 0.5, 'quadOut')

            -- Mover scoreText al lugar de la barra
            doTweenY('scoreY', 'scoreTxt', 600, 0.5, 'quadOut') -- posición alta para upscroll
            doTweenAlpha('scoreAlpha', 'scoreTxt', 1, 0.5, 'linear')
            setTextSize('scoreTxt', 24)
        end
    elseif getProperty('health') <= 1.8 and movedScore then
        movedScore = false

        if downscroll then
        -- Volver a mostrar barra e íconos
        doTweenY('barBack', 'healthBar', 80, 0.5, 'quadOut')
        doTweenY('iconP1Back', 'iconP1', 0, 0.5, 'quadOut')
        doTweenY('iconP2Back', 'iconP2', 0, 0.5, 'quadOut')

        -- Regresar el scoreText a su lugar normal
        doTweenX('scoreBackX', 'scoreTxt', 0, 0.5, 'quadOut')
        doTweenY('scoreBackY', 'scoreTxt', 130, 0.5, 'quadOut') -- abajo para downscroll
        doTweenAlpha('scoreAlphaBack', 'scoreTxt', 0.2, 0.5, 'linear')
        setTextSize('scoreTxt', 20)
        else
            doTweenY('barBack', 'healthBar', 640, 0.5, 'quadOut')
            doTweenY('iconP1Back', 'iconP1', 560, 0.5, 'quadOut')
            doTweenY('iconP2Back', 'iconP2', 560, 0.5, 'quadOut')
            -- Regresar el scoreText a su lugar normal
            doTweenX('scoreBackX', 'scoreTxt', 0, 0.5, 'quadOut')
            doTweenY('scoreBackY', 'scoreTxt', 680, 0.5, 'quadOut') -- abajo para upscroll
            doTweenAlpha('scoreAlphaBack', 'scoreTxt', 0.2, 0.5, 'linear')
            setTextSize('scoreTxt', 20)
        end
    end

        -- Forzar el tamaño del texto cada frame
    if getTextSize('scoreTxt') ~= tamanoFijo then
        setTextSize('scoreTxt', tamanoFijo)
    end
        -- Proteger la fuente
        if getTextFont('scoreTxt') ~= fuenteFija then
            setTextFont('scoreTxt', fuenteFija)
        end

 end

 function bumpText(textObject)
    setProperty(textObject .. '.scale.x', 1.3)
    setProperty(textObject .. '.scale.y', 1.3)
    doTweenX('scaleTweenX_' .. textObject, textObject .. '.scale', 1, 0.2, 'expoOut')
    doTweenY('scaleTweenY_' .. textObject, textObject .. '.scale', 1, 0.2, 'expoOut')
 end

 function bumpTextV2(textObject)
    setProperty(textObject .. '.scale.x', 5)
    setProperty(textObject .. '.scale.y', 5)
    doTweenX('scaleTweenX_' .. textObject, textObject .. '.scale', 1.5, 0.3, 'expoOut')
    doTweenY('scaleTweenY_' .. textObject, textObject .. '.scale', 1.5, 0.3, 'expoOut')
end

 function bumpTextV3(textObject)
    setProperty(textObject .. '.scale.x', 1.5)
    setProperty(textObject .. '.scale.y', 1.5)
    doTweenX('scaleTweenX_' .. textObject, textObject .. '.scale', 1, 0.3, 'expoOut')
    doTweenY('scaleTweenY_' .. textObject, textObject .. '.scale', 1, 0.3, 'expoOut')
end

function onBeatHit()
    if curBeat % 1 == 0 then -- Cada beat (1 = cada golpe, 2 = cada 2 beats, etc.)
        bumpTextV3('timeTxt')
    end
end
 --ayudaaaaaaa me canse de esto xddddddd, pero bueno que se puede hacer jeje, fin =p 