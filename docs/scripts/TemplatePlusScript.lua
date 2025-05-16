--Mmmmm XD

--Ignore this function =p
--Ignorar esta función =p
function onCreate() 
    --Variable "version" has been deleted. This changed:
    --La variable "version" ha sido eliminada. Esto cambió:

    --Display Psych Engine version 
    --Mostrar la versión de Psych Engine
    makeLuaText('testverpsych', PsychVersion, 100, 0, 0) 

    --Display Plus Engine version 
    --Mostrar la versión de Plus Engine
    makeLuaText('testverplus', PlusVersion, 100, 0, 0) 
    --
    
    --Display time
    --Mostrar la hora
    makeLuaText('timetest', time, 100, 0, 0)
    
    --Display date
    -- Mostrar la fecha
    makeLuaText('datetest', date, 100, 0, 0) 
end

--Ignore this function =p
--Ignorar esta función =p
function onStepHit()
    if curStep == 1 then
    --Window functions =p
    --Funciones de la ventana =p

        --Alternar fullscreen
        --Toggle fullscreen
        setFullscreen(true)

        --Cambiar tamaño de la ventana
        --Change window size
        tweenWindowSize(1280, 720, 1.5, "quadInOut")
        --[[Donde:
            --> 1280 = ancho
            --> 720 = alto
            --> 1.5 = tiempo
            --> "quadInOut" = tipo de interpolación
            ------
            Where:
            --> 1280 = width
            --> 720 = height
            --> 1.5 = time
            --> "quadInOut" = type of interpolation]]

        --Mover la ventana en el eje X
        --Move the window on the X axis
        winTweenX("moveX", 100, 1.2, "quadInOut")
        --[[Donde:
            --> moveX = nombre de Tween
            --> 100 = cuanto se movera en el eje X
            --> 1.2 = tiempo
            --> "quadInOut" = tipo de interpolación
            ------
            Where:
            --> moveX = name of Tween
            --> 100 = how much it will move on the X axis
            --> 1.2 = time
            --> "quadInOut" = type of interpolation]]

        --Mover la ventana en el eje Y
        --Move the window on the Y axis
        winTweenY("moveY", 200, 1.5, "linear") 
        --[[Donde:
            --> moveY = nombre de Tween
            --> 200 = cuanto se movera en el eje Y
            --> 1.5 = tiempo
            --> "linear" = tipo de interpolación
            ------
            Where:
            --> moveY = name of Tween
            --> 200 = how much it will move on the Y axis
            --> 1.5 = time
            --> "linear" = type of interpolation]]
    end
end