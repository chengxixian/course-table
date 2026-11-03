/**
 * Minimal MP4 probe (no ffmpeg available in this environment).
 * Reads mvhd for duration and tkhd for display size + audio track presence.
 *   node scripts/probe.mjs <file.mp4>
 */
import fs from "node:fs";

const file = process.argv[2];
if (!file) {
  console.error("usage: node scripts/probe.mjs <file.mp4>");
  process.exit(1);
}
const buf = fs.readFileSync(file);

const boxes = [];
const walk = (start, end, depth = 0) => {
  let off = start;
  while (off + 8 <= end) {
    let size = buf.readUInt32BE(off);
    const type = buf.toString("ascii", off + 4, off + 8);
    let header = 8;
    if (size === 1) {
      size = Number(buf.readBigUInt64BE(off + 8));
      header = 16;
    }
    if (size < 8) break;
    boxes.push({type, off, size, depth});
    if (["moov", "trak", "mdia", "minf", "stbl"].includes(type)) {
      walk(off + header, off + size, depth + 1);
    }
    off += size;
  }
};
walk(0, buf.length);

const result = {file, bytes: buf.length, tracks: [], durationSec: null, width: null, height: null};

for (const b of boxes) {
  if (b.type === "mvhd") {
    const ver = buf.readUInt8(b.off + 8);
    if (ver === 1) {
      const timescale = buf.readUInt32BE(b.off + 20);
      const duration = Number(buf.readBigUInt64BE(b.off + 24));
      result.durationSec = +(duration / timescale).toFixed(3);
      result.timescale = timescale;
    } else {
      const timescale = buf.readUInt32BE(b.off + 12);
      const duration = buf.readUInt32BE(b.off + 16);
      result.durationSec = +(duration / timescale).toFixed(3);
      result.timescale = timescale;
    }
  }
  if (b.type === "tkhd") {
    const width = buf.readUInt32BE(b.off + b.size - 8) / 65536;
    const height = buf.readUInt32BE(b.off + b.size - 4) / 65536;
    const vol = buf.readUInt16BE(b.off + (buf.readUInt8(b.off + 8) === 1 ? 8 + 4 + 32 + 8 + 8 + 2 : 8 + 4 + 20 + 8 + 8 + 2));
    result.tracks.push({
      w: width || null,
      h: height || null,
      kind: width ? "video" : vol > 0 ? "audio" : "other",
    });
  }
  if (b.type === "hdlr") {
    const handler = buf.toString("ascii", b.off + 16, b.off + 20);
    if (result.tracks.length) result.tracks[result.tracks.length - 1].handler = handler;
  }
}
console.log(JSON.stringify(result, null, 2));
