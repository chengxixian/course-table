import { readFile, writeFile } from "node:fs/promises";
import { Midi } from "@tonejs/midi";

function fail(message: string): never {
  console.error(message);
  process.exit(2);
}

const [input, output, flag, value] = process.argv.slice(2);
if (!input || !output || flag !== "--semitones" || value === undefined) {
  fail("Usage: transpose-midi.ts <input.mid> <output.mid> --semitones <integer>");
}

const semitones = Number(value);
if (!Number.isInteger(semitones) || semitones < -48 || semitones > 48) {
  fail("--semitones must be an integer between -48 and 48");
}

try {
  const midi = new Midi(await readFile(input));
  for (const track of midi.tracks) {
    for (const note of track.notes) {
      const next = note.midi + semitones;
      if (next < 0 || next > 127) {
        fail(`Transposition would move MIDI note ${note.midi} outside 0..127`);
      }
      note.midi = next;
    }
  }
  await writeFile(output, Buffer.from(midi.toArray()));
  console.log(JSON.stringify({ input, output, semitones, tracks: midi.tracks.length }, null, 2));
} catch (error) {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`Could not transpose MIDI: ${message}`);
  process.exit(1);
}
