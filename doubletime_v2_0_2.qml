import QtQuick 2.0
import MuseScore 3.0

MuseScore {
      version:  "3.0"
      description: "This plugin doubles the duration of all notes in the selection"
      menuPath: "Plugins.Doubletime"

      // Copy all chords/notes/rests from the selection or entire score
      // this section leveraged from colornotes.qml
      function copyFromSelection(chordArray) {
            var cursor = curScore.newCursor();
            cursor.rewind(1); // beginning of selection
            var startStaff;
            var endStaff;
            var endTick;
            var fullScore = false;
            if (!cursor.segment) { // no selection
                  fullScore = true;
                  startStaff = 0; // start with 1st staff
                  endStaff = curScore.nstaves - 1; // and end with last
            } else {
                  startStaff = cursor.staffIdx;
                  cursor.rewind(2); // end of selection
                  if (cursor.tick == 0) { // selection includes last measure of score
                        endTick = curScore.lastSegment.tick + 1;
                  } else {
                        endTick = cursor.tick;
                  }
                  endStaff = cursor.staffIdx;
            }
            console.log(startStaff + " - " + endStaff + " - " + endTick)
            for (var staff = startStaff; staff <= endStaff; staff++) { // each staff
                  for (var voice = 0; voice < 4; voice++) { // each voice
                        cursor.rewind(1); // start over 
                        cursor.voice = voice; // select voice
                        cursor.staffIdx = staff; // select staff
                        if (fullScore) cursor.rewind(0); // unclear why this is needed

                        while (cursor.segment && (fullScore || cursor.tick < endTick)) { // each cursor position in selection
                              if (cursor.element){ // only copy chords/notes/rests...
                                    if (cursor.element.type == Element.CHORD) chordArray.push(cursor.element);
                                    if (cursor.element.type == Element.REST) chordArray.push(cursor.element);
                                    }
                              cursor.next();
                        }
                  }
            }
      }

      // Paste all chords/notes/rests with 1/2 duration to a new score
      function modifyAndPaste(chordArray) {
            // this section leveraged from createscore.qml
            var score = newScore("DoubleTime", "piano", 32); // 32 measure limit
            score.addText("title", "DoubleTime");
            var cursor = score.newCursor();
            var firstchord = 0;
            cursor.track = 0;
            cursor.rewind(0);
            var ts = newElement(Element.TIMESIG);
            ts.timesig = fraction(8,4);
            cursor.add(ts);
            cursor.rewind(0);

            for (var i = 0; i<chordArray.length; i++){ // each chord/note/rest
                  var chord = chordArray[i];

                  if (chord.track > cursor.track){ // track change detection
                        firstchord = i;
                        cursor.track = chord.track;
                        cursor.rewind(0);
                  }

                  cursor.setDuration(chord.duration.numerator * 2, chord.duration.denominator);
                  if (chord.type == Element.CHORD){
                        cursor.addNote(65); // add temporary note to retrieve the correct duration to be assigned to the chord
                        // Place the cursor at the just entered temporary chord
                        cursor.rewind(0);
                        for (var j = firstchord; j < i; j++)  cursor.next();
                        // Retrieve correct 2x duration
                        var notes = chord.notes;
                        for (var j = 0; j < notes.length; j++) {
                              var note = notes[j];
                              cursor.addNote(note.pitch, true);
                              }
                        }
                  else {
                        // At the moment of writing cursor.addRest (or similar) does not exist; the following is a workaround
                        cursor.addNote(60); // add temporary note to retrieve the correct duration to be assigned to the rest
                        var newchord = newElement(Element.REST);
                        newchord.durationType = chord.duration.numerator * division * 4 / chord.duration.denominator * 2;
                        // Place the cursor at the just entered temporary chord
                        cursor.rewind(0);
                        for (var j = firstchord; j < i; j++)  cursor.next();
                        cursor.add(newchord);
                        }
                  // HACK 2 - this is the only way to move forward by an exact amount
                  cursor.rewind(0);
                  for (var j = firstchord; j <= i; j++)  cursor.next();                  
            }
      }

      onRun: {
            if (typeof curScore !== 'undefined') {
                var chordArray = [];
                copyFromSelection(chordArray);
                modifyAndPaste(chordArray);
            }
         }
}
