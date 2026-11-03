import { readFile } from "node:fs/promises";
import { Midi } from "@tonejs/midi";

function usage(): never {
  console.error("Usage: inspect-midi.ts <file.mid>");
  process.exit(2);
}

const input = process.argv[2];
if (!input) usage();

try {
  const data = await readFile(input);
  const midi = new Midi(data);
  const notes = midi.tracks.flatMap((track) => track.notes);
  const midiValues = notes.map((note) => note.midi);
  const tempo = midi.header.tempos[0]?.bpm ?? null;
  const result = {
    tracks: midi.tracks.length,
    durationSeconds: midi.duration,
    tempoBpm: tempo,
    noteCount: notes.length,
    noteRange: midiValues.length > 0 ? { min: Math.min(...midiValues), max: Math.max(...midiValues) } : null,
  };
  console.log(JSON.stringify(result, null, 2));
} catch (error) {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`Invalid or unreadable MIDI: ${message}`);
  process.exit(1);
}
