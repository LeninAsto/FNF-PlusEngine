--Mmmmm XD

-- Solo para Windows (Animaciones de la ventana)
-- Only Windows (Window animation)

-- Tweens con animaciones
-- Tween animations
winTweenX(tag, targetX, duration, ease)        -- Animar posición X | Animate X position
winTweenY(tag, targetY, duration, ease)        -- Animar posición Y | Animate Y position
winTweenSize(width, height, duration, ease)    -- Animar tamaño | Animate size

-- Cambios instantáneos sin animación
-- Instant changes without animation
setWindowX(x)                    -- Establecer X inmediatamente | Set X immediately
setWindowY(y)                    -- Establecer Y inmediatamente | Set Y immediately
setWindowSize(width, height)     -- Cambiar tamaño inmediatamente | Set size immediately
centerWindow()                   -- Centrar ventana en pantalla | Center window on screen

-- Obtener datos de la ventana
-- Get window data
getWindowX()                     -- Posición X actual | Current X position
getWindowY()                     -- Posición Y actual | Current Y position
getWindowWidth()                 -- Ancho actual | Current width
getWindowHeight()                -- Alto actual | Current height
getWindowTitle()                 -- Título actual | Current title

-- Estados de ventana
-- Window states
setWindowFullscreen(enable)      -- Pantalla completa | Fullscreen
isWindowFullscreen()             -- ¿Está en pantalla completa? | Is fullscreen?

-- Cambiar propiedades
-- Change properties
setWindowTitle(title)            -- Cambiar título | Change title
setWindowIcon(iconPath)          -- Cambiar icono | Change icon
setWindowResizable(enable)       -- Permitir redimensionar | Resizable
setWindowOpacity(opacity)        -- Transparencia (0.0-1.0) | Opacity (0.0-1.0)
hideWindowBorder(enable)            -- Ocultar bordes (legacy) | Hide borders (legacy)
setWinRCenter(width, height, animate) -- Nothing :v | animate: false; no animate: true

-- Efectos visuales
-- Visual effects
shakeWindow(intensity, duration)                                 -- Shake de ventana | Shake window
bounceWindow(bounces, height, duration)                         -- Efecto rebote | Bounce effect
orbitWindow(centerX, centerY, radius, speed, duration)         -- Orbitar punto | Orbit point
pulseWindow(minScale, maxScale, pulseSpeed, duration)          -- Pulsación | Pulse
spinWindow(rotations, duration)                                 -- Girar ventana | Spin window
randomizeWindowPosition(minX, maxX, minY, maxY)                -- Posición aleatoria | Random position

-- Datos del monitor
-- Monitor data
getScreenWidth()                 -- Ancho de pantalla | Screen width
getScreenHeight()                -- Alto de pantalla | Screen height
getScreenResolution()            -- {width: X, height: Y}
getMonitorCount()                -- Número de monitores | Monitor count
moveWindowToMonitor(index)       -- Mover a monitor específico | Move to specific monitor

-- Guardar/cargar configuración
-- Save/load configuration
saveWindowState()                -- Guardar estado como JSON | Save state as JSON
loadWindowState(jsonString)      -- Cargar estado desde JSON | Load state from JSON

