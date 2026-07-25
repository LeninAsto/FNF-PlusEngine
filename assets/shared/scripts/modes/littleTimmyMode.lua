function onUpdate(elapsed)
    runHaxeCode([[
        game.notes.forEach(function(daNote:Note) {
            if(!daNote.blockHit && !daNote.ignoreNote && daNote.mustPress && !game.cpuControlled && daNote.canBeHit) {
                if(daNote.isSustainNote) {
                    if(daNote.canBeHit) {
                        game.goodNoteHit(daNote);
                    }
                } else if(daNote.strumTime <= Conductor.songPosition || daNote.isSustainNote) {
                    game.goodNoteHit(daNote);
                }
            }
        });
    ]])
end
function goodNoteHit(i, d)
    setProperty('playerStrums.members['..d..'].resetAnim', stringEndsWith(getProperty('notes.members['..i..'].animation.curAnim.name'), 'hold') and 0.20 or 0.05)
end