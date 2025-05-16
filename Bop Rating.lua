local flicker = nil

local playerStrumX = 0  -- Variable para guardar la posición X del strum del jugador
local playerStrumY = 0  -- Variable para guardar la posición Y del strum del jugador

function onCreatePost()
    unShowScore = 0
    comboTextY = 50
    scoreTextY = 90

    setProperty('comboSpr.visible', true)

    playerStrumX = getPropertyFromGroup('strumLineNotes', 4, 'x')
    playerStrumY = getPropertyFromGroup('strumLineNotes', 4, 'y')

    makeLuaText('msText', '', 400, playerStrumX , playerStrumY )  -- Ajusta estos valores según necesites
    setTextSize('msText', 18)
    addLuaText('msText')
    setTextAlignment('msText', 'center')

    -- Crear el texto del combo
    makeLuaText('comboTxt', '', 600, playerStrumX , playerStrumY )  -- Ajusta estos valores según necesites
    setTextSize('comboTxt', 38)
    setTextBorder('comboTxt', 2, '000000')
    setTextAlignment('comboTxt', 'center')
    addLuaText('comboTxt')

    setObjectOrder('comboTxt', 0)
    setObjectOrder('msText', 0)

    local screenWidth = 1280
    local textWidth1 = getProperty('comboTxt.width')
    local textWidth2 = getProperty('msText.width')
    local centerX1 = (screenWidth - textWidth1) / 2
    local centerX2 = (screenWidth - textWidth2) / 2
    setProperty('comboTxt.x', centerX1)
    setProperty('msText.x', centerX2)
end

function onBeatHit()
    bumpText('fcRatingText') -- el texto hace bump cada beat 😎
end

function onUpdate(elapsed)
    -- Actualizar las posiciones de los textos para que sigan al strum del jugador
    playerStrumX = getPropertyFromGroup('strumLineNotes', 4, 'x')
    playerStrumY = getPropertyFromGroup('strumLineNotes', 4, 'y')

    -- Ajustar las posiciones de los textos (puedes modificar estos valores según necesites)

    if downscroll then
        doTweenX('msTextBounceX', 'msText', playerStrumX + 30, 0.2, 'sineOut')
        doTweenY('msTextBounceY', 'msText', playerStrumY - 140, 0.2, 'sineOut')

        doTweenX('comboTxtBounceX', 'comboTxt', playerStrumX - 70, 0.2, 'sineOut')
        doTweenY('comboTxtBounceY', 'comboTxt', playerStrumY - 250, 0.2, 'sineOut')
    else
        doTweenX('msTextBounceX', 'msText', playerStrumX + 30, 0.2, 'sineOut')
        doTweenY('msTextBounceY', 'msText', playerStrumY + 350, 0.2, 'sineOut')

        doTweenX('comboTxtBounceX', 'comboTxt', playerStrumX - 70, 0.2, 'sineOut')
        doTweenY('comboTxtBounceY', 'comboTxt', playerStrumY + 250, 0.2, 'sineOut')
    end
end

function onUpdatePost(elapsed)
    setTextString('fcRatingText', ratingFC.. '\n' ..ratingName)
end

function goodNoteHit(id, direction, noteType, isSustainNote)
    local rawNoteRating = getPropertyFromGroup('notes', id, 'rating')
    local noteRating = rawNoteRating
    local ratingColor = 'FFFFFF' -- Blanco por defecto
    local msOffset = math.abs(getPropertyFromGroup('notes', id, 'strumTime') - getSongPosition()) -- Diferencia de tiempo en ms

    if not isSustainNote then
        -- Nuevo juicio "Yara"
        if rawNoteRating == 'marvelous' then
            noteRating = "Marvelous!!"
            ratingColor = 'FFC800' -- Amarillo oscuro
        elseif rawNoteRating == 'sick' then
            noteRating = "Sick!"
            ratingColor = '7FC9FF' -- Azul claro
        elseif rawNoteRating == 'good' then
            noteRating = "Good"
            ratingColor = '7FFF8E' -- Verde
        elseif rawNoteRating == 'bad' then
            noteRating = "Bad"
            ratingColor = 'A17FFF' -- Morado
        elseif rawNoteRating == 'shit' then
            noteRating = "Shit"
            ratingColor = 'FF7F7F' -- Rojo
        end   

        showScore = score - unShowScore
        flicker = false
        cancelTimer('fade')

        setProperty('comboTxt.alpha', 1)
        setProperty('msText.alpha', 1)
        

        -- Cambiar color del texto según el juicio
        setTextColor('comboTxt', ratingColor)
        setTextColor('msText', ratingColor)

        local combo = getProperty('combo')

        -- Actualizar textos
        setTextString('comboTxt', noteRating .. "\nx" ..combo)

        -- Animación tipo bump
        bumpText('comboTxt')
        bumpText('msText')

        
        msOffset = getPropertyFromGroup('notes', id, 'strumTime') - getSongPosition()
        setTextString('msText', math.floor(msOffset)..'ms')
        
    end    

    runTimer('flicker', 0.5)
end

function bumpText(textObject)
    setProperty(textObject .. '.scale.x', 1.8)
    setProperty(textObject .. '.scale.y', 1.8)
    doTweenX('scaleTweenX_' .. textObject, textObject .. '.scale', 1.1, 0.3, 'expoOut')
    doTweenY('scaleTweenY_' .. textObject, textObject .. '.scale', 1.1, 0.3, 'expoOut')
end

function onStepHit()
    if (curStep % 2 == 0) and flicker then
        setProperty('comboTxt.alpha', 1)
        setProperty('msText.alpha', 1)
    elseif (curStep % 2 > 0) and flicker then
        setProperty('comboTxt.alpha', 0)
        setProperty('msText.alpha', 0)
    end
end

function onTimerCompleted(tag)
    if tag == 'flicker' then
        flicker = true
        runTimer('fade', 1)
    end
    if tag == 'fade' then
        setProperty('comboTxt.alpha', 0)
        setProperty('msText.alpha', 0)
        flicker = false
        unShowScore = score
    end

end
