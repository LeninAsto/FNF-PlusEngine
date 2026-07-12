If you don't want to use haxe and want to do it only from lua, which by the way is better to do it in lua since it doesn't alter the mechanics much, look [here](https://github.com/LeninAsto/FNF-PlusEngine/blob/main/docs/scripts/DocLuaModchart.md)

```haxe
function onInitModchart() {
    //From here, I'll explain how to use it. There are several things that might blow your mind...
    //De aquí te explicaré cómo usarlo. Hay varias cosas que pueden confundirte...
    //Let's start with the scripts you can use
    //Empecemos con los scripts que puedes utilizar

    instance.addModifier(mod, field);
    /*
     * Adds or rewrites the percent of `mod` and sets it to `value`
     * Añade o sobrescribe el porcentaje de `mod` y lo establece en `value`
     *
     * mod:String   The modifier name string
     *              El nombre del modificador (cadena)
     * value:Float  The value to be assigned to the modifier.
     *              El valor que se asignará al modificador.
     * field:Int    The playfield number  (-1 by default)
     *              El número de campo de juego (-1 por defecto)
    */
    instance.setPercent(mod, value, field);
    /*
     * Returns the percent of `mod`
     * Devuelve el porcentaje de `mod`
     *
     * mod:String   The modifier name string
     *              El nombre del modificador (cadena)
     * field:Int    The playfield number  (-1 by default)
     *              El número de campo de juego (-1 por defecto)
     *
     * returns: Float
     *          Devuelve: Float
    */
    instance.getPercent(mod, field);
    /*
     * Registers a new modifier in the name of `modN`
     * Registra un nuevo modificador con el nombre `modN`
     *
     * modN:String  The modifier name string
     *              El nombre del nuevo modificador (cadena)
     * mod:Modifier The custom modifier class instance.
     *              La instancia de la clase modificador personalizada.
    */
    instance.registerModifier(modN, mod);

    /* Events Section */
    /* Sección de eventos */
    /*
     * Adds or rewrites the percentage of `mod` and sets it to `value`
     * when the specified beat is reached.
     * Añade o sobrescribe el porcentaje de `mod` y lo establece en `value`
     * cuando se alcanza el beat especificado.
     *
     * mod:String   The modifier name string
     *              El nombre del modificador (cadena)
     * beat:Float   The beat number where the event will be executed.
     *              El número de beat donde se ejecutará el evento.
     * value:Float  The value to be assigned to the modifier.
     *              El valor que se asignará al modificador.
     * player:Int   The player/strumline number (-1 by default)
     *              El número de jugador/strumline (-1 por defecto)
     * field:Int    The playfield number  (-1 by default)
     *              El número de campo de juego (-1 por defecto)
    */
    instance.set(mod, beat, value, player, field);
    /*
     * Tweens the percentage of `mod` from its current value to `value`
     * over the specified duration, using the provided easing function.
     * Interpola el porcentaje de `mod` desde su valor actual hasta `value`
     * durante la duración especificada, usando la función de easing proporcionada.
     *
     * mod:String   The modifier name string
     *              El nombre del modificador (cadena)
     * beat:Float   The beat number where the event will be executed.
     *              El número de beat donde se ejecutará el evento.
     * length:Float The tween duration in beats.
     *              La duración de la interpolación en beats.
     * ease:F->F    The ease function (Float to Float)
     *              La función de easing (Float a Float)
     * value:Float  The value to be assigned to the modifier.
     *              El valor que se asignará al modificador.
     * player:Int   The player/strumline number (-1 by default)
     *              El número de jugador/strumline (-1 por defecto)
     * field:Int    The playfield number  (-1 by default)
     *              El número de campo de juego (-1 por defecto)
    */
    instance.ease(mod, beat, length, value, ease, player, field);
    /*
     * Execute the callback function when the specified beat is reached.
     * Ejecuta la función callback cuando se alcanza el beat especificado.
     *
     * beat:Float   The beat number where the event will be executed.
     *              El número de beat donde se ejecutará el evento.
     * func:V->V    The callback function to execute
     *              La función callback a ejecutar
     * field:Int    The playfield number  (-1 by default)
     *              El número de campo de juego (-1 por defecto)
    */
    instance.callback(beat, func, field);
    /*
     * Repeats the execution of the callback function for the specified duration,
     * starting at the given beat.
     * Repite la ejecución de la función callback durante la duración especificada,
     * comenzando en el beat dado.
     *
     * beat:Float   The beat number where the event will be executed.
     *              El número de beat donde se ejecutará el evento.
     * length:Float The repeater duration in beats.
     *              La duración del repetidor en beats.
     * func:V->V    The callback function to execute
     *              La función callback a ejecutar
     * field:Int    The playfield number  (-1 by default)
     *              El número de campo de juego (-1 por defecto)
    */
    instance.repeater(beat, length, func, field);
    /*
     * Adds a custom event.
     * Añade un evento personalizado.
     *
     * event:Event  The custom event to be added.
     *              El evento personalizado a añadir.
     * field:Int    The playfield number  (-1 by default)
     *              El número de campo de juego (-1 por defecto)
    */
    instance.addEvent(event, field);

    /* Playfield Section */
    /* Sección de campos de juego */
    /*
     * Adds a new playfield.
     * Añade un nuevo campo de juego.
     *
     * WARNING: If you add a playfield after adding modifiers, you will have to add them again to the new playfield.
     * ADVERTENCIA: Si añades un campo de juego después de añadir modificadores, tendrás que añadirlos de nuevo al nuevo campo.
    */
    instance.addPlayfield();
}
```
# Lista de modificadores =D
# List of Modifiers =D

## Estos son los modificadores que puedes usar:
## These are the modifiers you can use:

1. CounterClockWise
    - Mueve las flechas en un patrón circular en sentido contrario a las agujas del reloj.
    - Moves the arrows in a circular pattern counterclockwise.

2. SchmovinArrowShape - ArrowShape
    - Permite que las flechas sigan un camino alrededor de una flecha con el archivo CSV arrowShape.csv "ADVERTENCIA si el archivo noo esta en assets/modchart/arrowShape, crasheara el juego".
    - Allows the arrows to follow a path around an arrow using the CSV file arrowShape.csv. "WARNING: If the file is not in assets/modchart/arrowShape, the game will crash."

3. Spiral 
    - Mueve las flechas en un patrón espiral hasta llegar a un punto central.
    - Moves the arrows in a spiral pattern towards a central point.
    - Hay una variable para este modifier que se llama:
    - There is a variable for this modifier called:
```haxe
spiralDist
```
    - Puedes editarlo para modificar la distancia de la espiral.
    - You can edit it to modify the spiral distance.

4. Wiggle
    - Mueve las flechas de forma ondulatoria en los ejes X e Y, y ajusta la rotación en el eje Z.
    - Moves the arrows in a wavy motion on the X and Y axes, and adjusts the rotation on the Z axis.
    - Hay una variable para este modifier que se llama:
    - There is a variable for this modifier called:
```haxe
rotateZ
```
    - Puedes editarlo para que modifiques la profundidad.
    - You can edit it to modify the depth.

5. Vibrate
    - Mueve las flechas de forma aleatoria en los ejes X e Y, simulando un efecto de vibración.
    - Moves the arrows randomly on the X and Y axes, simulating a vibration effect.

## Faltan mas modificadores pero estos son algunos de ellos, este codigo esta en desarrollo sorry XD