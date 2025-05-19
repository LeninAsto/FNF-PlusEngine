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
    makeLuaText('timetest', time, 100, 0, 0)--not work in "onUpdate()"
    
    --Display date
    --Mostrar la fecha
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
            --> 100 = Se movera 100 respecto al borde izquierdo en el eje X "0 = pegado al lado izquierdo"
            --> 1.2 = tiempo
            --> "quadInOut" = tipo de interpolación
            ------
            Where:
            --> moveX = name of Tween
            --> 100 = It will move 100 from the left edge on the X axis "0 = stuck to the left side"
            --> 1.2 = time
            --> "quadInOut" = type of interpolation]]

        --Mover la ventana en el eje Y
        --Move the window on the Y axis
        winTweenY("moveY", 200, 1.5, "linear") 
        --[[Donde:
            --> moveY = nombre de Tween
            --> 200 = Se movera 200 respecto al borde superior en el eje Y "0 = pegado al lado superior"
            --> 1.5 = tiempo
            --> "linear" = tipo de interpolación
            ------
            Where:
            --> moveY = name of Tween
            --> 200 = It will move 200 from the top edge on the Y axis "0 = stuck to the top side"
            --> 1.5 = time
            --> "linear" = type of interpolation]]

            -- Video

        -- si usaras para cutcenes de tu nivel
        -- if you use for your level cutscenes
        startVideo("yourvideoname", true, false, false, true)
        -- sin cam
        -- without cam

        -- pero si usaras para introducirlo al camHUD o camGame
        -- if you use for your level introduction to camHUD or camGame
        startVideo("yourvideoname", false, false, false, true, "cam")
        -- no cambies the >false, false, false, true< Solo cam (hud o game)
        -- don't change the >false, false, false, true< Only cam (hud or game)
    end
end