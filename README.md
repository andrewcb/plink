# Plink

Plink is an environment for hosting AudioUnit instruments and effects and allowing them to be played and manipulated in code. It is still under development.

## Quick start

1. Open a new, blank Plink document. If you just started Plink for the first time, this will be done for you; otherwise, press `⌘-N`.
2. In the Mixer pane (the dark pane stretching the full width of the window below the transport controls), click on the white + to create a new channel. A channel strip will appear. The white text box at the bottom gives its name (which, by default, will be `ch1`, though you can change this). The two grey + signs on top are for adding an instrument and one or more effects.
3. Click the top + in the channel strip; it will pop up a menu of instrument plugins, grouped by manufacturer. If you have no additional plugins installed, there will be only one group: Apple. Click on the disclosure triangle to open this, and then double-click on `DLSMusicDevice` to add this instrument; this is the built-in General MIDI synthesiser that ships with macOS.  (If you own any other AudioUnit instruments, you can of course load them here.)
4. The cyan box in the channel strip represents the instrument. Clicking the button to the left of the instrument name will open a window with the AudioUnit's graphical user interface. This is the main way of adjusting the sound of a software synthesiser, and is probably more interesting for units other than `DLSMusicDevice`.
5. Click on the bottom line of the Console window, and type the line: 
```
$ch.ch1.instrument.playNote(MIDINote(60, 100, 12))
```
and press enter. Your computer should play a short middle C, using a piano sound.    
The command above sent a note to the instrument you loaded. `$ch.ch1` refers to the channel named "ch1" and `.instrument` is its instrument. The instrument's `playNote` method accepts a `MIDINote` object and plays it immediately. A `MIDINote` is a note with a MIDI pitch, velocity  and duration; the above command plays middle C (60), at velocity 100 (out of 127), for 12 ticks (or half a beat). (If you change the tempo and rerun the command, the actual duration in seconds of the note will change correspondingly.)

6. The `playNote` function is asynchronous, exiting before the note plays. As such, running it repeatedly will play several notes at once. The following command plays a (C major 7) chord:   
`[60, 64, 67, 71].forEach( (n) => { $ch.ch1.instrument.playNote(MIDINote(n, 100, 12)) } )`  

7. It is possible to synchronously wait for a number of ticks of the metronome, with the `metronome.sleep` function; the following command plays the chord in ascending notes:     
`[60, 64, 67, 71].forEach( (n) => { $ch.ch1.instrument.playNote(MIDINote(n, 100, 12)) ; metronome.sleep(6) } )`

8. It is, as you can imagine, possible to play melodies using these mechanisms; try the following command:   `[76, 75, 76, 75, 76, 71, 74, 72, 69, 52, 57, 60, 64, 69, 71, 52, 56, 64, 68, 71, 72, 52, 57, 64].forEach( (n) => { $ch.ch1.instrument.playNote(MIDINote(n, 100, 12)) ; metronome.sleep(12) } )`  This is a very simple form of sequencing, blocking the interpreter while each note plays, and assuming all notes have the same duration. As an exercise, try writing a version where note durations may be specified in the input.

9. Of course, entering such commands on the command line is less than ideal, which is what the script can be useful for. In the script window (to the left of the console), enter (or copy and paste):   
```
var melody = [76, 75, 76, 75, 76, 71, 74, 72, 69, 52, 57, 60, 64, 69, 71, 52, 56, 64, 68, 71, 72, 52, 57, 64]  
function playMelody(seq, inst) {
    seq.forEach( (n) => { 
      inst.playNote(MIDINote(n, 100, 12)); 
      metronome.sleep(12) 
    })
}
```
Then, to load the script into the JavaScript environment, click the ⟳ button in the top left of the script window. Finally, in the console, enter the command `playMelody(melody, $ch.ch1.instrument)`

This does not cover all the functions of Plink, but hopefully covers enough to get started.

## Overview

### The running environment

A Plink environment consists of several systems in interaction: the *Audio System*, which hosts AudioUnit Instrument and Effect plug-ins, providing a mixer and audio output, the *Code System*, which executes code (currently in JavaScript, using macOS' JavaScriptCore engine), and the time system, which keeps a permanently running clock with an adjustable tempo (the Metronome), and a Score with a position which, when running, is moved forward at the Metronome's rate. 
The Code System has access to the other systems, and code in it can interact with them; i.e., by sending MIDI events to, or adjusting the parameters of, AudioUnits, or scheduling deferred events to take place in a specified amount of musical time. 
The time system's Score can cause code to be executed, either periodically while the score is running (as **cycles**) or at a specific time in the score (as **cues**). Additional capabilities are planned for the future.
The Audio System runs continuously, typically to the system audio output device, though can also render audio offline, either from the Score, or by executing arbitrary sound-producing code. (The Audio System's audio-buffer-rendering mechanism also provides the basis of the Metronome's time.)

Each Plink document window has one environment, with its own instances of audio, code and time systems.

### Plink documents

A Plink environment may be (partially) stored in a Plink document; these end with the `.plink` extension. A Plink document contains:

* a description of the Audio System: the details of channels, and the AudioUnits loaded in each channel, each unit with its current settings
* the script source code in the script pane
* the Score, which currently means the Cue and Cycle lists
* the time settings, which currently mean the current tempo

The state of the JavaScript interpreter's memory is ephemeral, and is not saved to a document. (Indeed, the interpreter's variables are cleared every time the script is reloaded.)

## The Plink user interface

Plink's workspace currently comprises a single window. At the top is a panel containing the tempo, transport controls and master volume meter. Below this is the Mixer, a pane containing an array of channels, each of which is represented by an audio mixer-style channel strip and may hold an AudioUnit Instrument and zero or more audio effects. Each channel also has a volume control and a stereo panning control, and a level meter that displays the current sound level.

Below the mixer are two panes, which may show a number of possible views. The views available are:

* **Script** — the JavaScript source code, whose functions may be executed from the Score. Write your script here. To load the Script into the code environment, click the Reload button in the top left (which is visible when the script has been changed).
* **Console** — Any JavaScript typed into the bottom of this will be executed immediately (and may refer to anything in the Script). If it returns a value, the value will be displayed in the Console. The Console will also display any JavaScript errors, in red, and anything sent to the *log* function.
* **Cue List** — A list of one-off events to be executed at various times in the Score. Each consists of a time and some text, which may be the name of a function to be called, or an arbitrary JavaScript expression.
* **Cycle List** — a list of cycles to be periodically executed. These work like Cues, only they are executed repeatedly, with an amount of musical time between executions. An offset may be specified; for example, a Cycle with a period of 2 beats and offset of 1 beat will be executed at beats 1, 3, 5, and so forth.

## The Mixer

The Plink Mixer consists of zero or more channels, each of which will typically have an *instrument* followed by a (possibly empty) chain of audio *effects*. When a note is played on the instrument, the audio flows through the channel's effects (in descending order, as displayed on the screen) before being mixed into the audio output. Each channel's Instrument and Effects are AudioUnits.

MacOS comes with a few Apple AudioUnits, including a General MIDI synthesiser instrument, *DLSMusicDevice*. You can additionally use free or commercial AudioUnit plug-ins. Note that there is no facility for using VST plugins natively in Plink, though third party VST to AudioUnit adaptors may enable this.

There is an experimental facility for loading [SoundFonts](https://en.wikipedia.org/wiki/SoundFont) as instruments. This uses the Apple DLSMusicDevice synthesiser (which has the ability to play SoundFonts, but no user interface for doing this non-programmatically). Note that this is currently experimental and has problems; for one, it depends on the SoundFont file remaining in the same location on the system to load, and a Plink document will fail to load if it depends on a SoundFont which is absent. It is anticipated that this will be fixed at some point.

## Musical time in Plink

Events in Plink take place in musical time; this is measured in *ticks*, each tick being an arbitrary fraction of a beat (currently 1/24 of a beat; the number of ticks per beat is configured in the code, and may change in future; in JavaScript, `metronome.ticksPerBeat`  returns the current value). Most time as passed in JavaScript code is in ticks. Time specified in the Score is written in "beats:ticks" form.

In Plink, musical events with timing and duration can take place when the transport is stopped and the transport position is not advancing; it is possible to play a note of a duration or schedule an action to take place in a number of beats' time regardless of whether the transport is running. To do this, Plink splits the handling of time into two components: the **Metronome** and the **Transport**. The Metronome keeps track of the current tempo and is a constantly running musical-time clock, which generates an event at each tick (whose duration depends on the current tempo). The current Metronome time is a constantly increasing number whose value is arbitrary, and whose rate of increase depends on the Metronome's tempo. The Transport, however, has a *transport position*, which is a number of ticks from the start of the programme, and a transport state, which is either stopped (at a position) or running. When it is running, it runs at the same rate as the Metronome. This architecture allows time-dependent events (such as notes with a duration) to be played regardless of whether or not the transport is running.

## The Score — triggering events in musical time

The Score is the sequence of events to be triggered at various times, and can be played with the transport controls. It is edited through the Cue and Cycle panes.

## Functions objects available from JavaScript

### Channels
Channels are available in the `$ch` object, either by index (i.e., `$ch[0]`) or by name (i.e., `$ch.melody1`).
Each channel is a Channel object, which has the following fields:

* `instrument` - The channel's instrument (if one is set); this is a `Unit`
* `audioEffects` - a (possibly empty) array of `Unit` objects for any audio insert effects the instrument's output passes through

### Units

a **Unit** provides an interface to an AudioUnit instrument or effect. It has the following methods:

* `playNote(note)` — accepts a `MIDINote` (a note with a duration) and plays it (assuming that the unit is capable of playing notes). This sends a `NoteOn` message immediately, and schedules a `NoteOff` message in the note's duration.
* `sendMIDIEvent(b1, b2, b3)` — The low-level MIDI event sending function, which sends an arbitrary three-byte MIDI event to the unit's MIDI input.
* `getParam(name)` — given the name of a parameter of the unit, retrieve its value; returns a floating-point number.
* `setParam(name, value)` — set the value of a named parameter.

### MIDINote
A `MIDINote` is an object representing a MIDI note with duration; when played, it produces a note-on event and then, the duration's time later at  the current tempo, a note-off event. 

The syntax for constructing a MIDINote is `MIDINote(pitch, velocity, duration)`;  pitch and velocity are MIDI byte values, and duration is the duration in ticks.  The MIDI channel of the note may be specified as an  optional fourth argument; if omitted, it is 0.

### The Metronome

The Metronome object is accessible as `metronome`. It exposes the following functionality:

* `metronome.tempo` — a numeric value giving the current tempo in beats per minute; can be changed.
* `metronome.tickTime` —  the current musical time, in the form of the number of ticks elapsed since some fixed point 
* `metronome.ticksPerBeat` — a numeric value giving the number of ticks per beat.
* `metronome.setTimeout` — execute a block of code in a (possibly fractional) number of beats by the metronome's time. The syntax resembles the client-side web JavaScript `setTimeout` function, with the exception that the time is in beats; i.e., `setTimeout(function(){ melody.playNote(MIDINote(60,100,24) }, 0.25)`
* `metronome.sleep(t)` — suspend execution of JavaScript code for `t` ticks.

### Scheduler

The Scheduler runs on metronome time, independent of the transport state, and allows actions to be scheduled periodically. It exposes the following functionality:

* `scheduler.everyTickMultiple(t, function)` — execute a function every `t` ticks.
* `scheduler.everyBeatFraction(num, denom, function)` — execute a function every `num/denom` beats.

## Acknowledgements

Thanks to everyone who helped test this software and contributed suggestions.

Thanks also to Mouse & De Lotz and Tina We Salute You in London, at whose premises, and over whose coffee, much of Plink was coded.
