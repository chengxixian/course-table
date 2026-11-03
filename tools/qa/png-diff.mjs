/**
 * png-diff.mjs — decode two 8-bit RGB/RGBA PNGs and report pixel statistics.
 *
 * Why not compare file bytes: two independent x264 encodes of identical source
 * frames are not bit-identical, and their decoded pixels differ by a fraction
 * of a level. Byte comparison therefore always "fails" across encodes. This
 * decodes both images and reports the actual per-channel delta, which separates
 * compression noise (mean < 1 level) from a real picture change.
 *
 *   node png-diff.mjs a.png b.png
 */
import fs from "node:fs";
import zlib from "node:zlib";

const decodePng = (file) => {
  const buf = fs.readFileSync(file);
  if (buf.readUInt32BE(0) !== 0x89504e47) throw new Error(`${file}: not a PNG`);
  let pos = 8;
  let w = 0, h = 0, bitDepth = 0, colorType = 0;
  const idat = [];
  while (pos < buf.length) {
    const len = buf.readUInt32BE(pos);
    const type = buf.toString("ascii", pos + 4, pos + 8);
    const data = buf.subarray(pos + 8, pos + 8 + len);
    if (type === "IHDR") {
      w = data.readUInt32BE(0);
      h = data.readUInt32BE(4);
      bitDepth = data[8];
      colorType = data[9];
    } else if (type === "IDAT") {
      idat.push(data);
    } else if (type === "IEND") break;
    pos += 12 + len;
  }
  if (bitDepth !== 8) throw new Error(`unsupported bit depth ${bitDepth}`);
  const channels = colorType === 2 ? 3 : colorType === 6 ? 4 : colorType === 0 ? 1 : 0;
  if (!channels) throw new Error(`unsupported color type ${colorType}`);

  const raw = zlib.inflateSync(Buffer.concat(idat));
  const stride = w * channels;
  const out = Buffer.alloc(w * h * channels);
  let prev = Buffer.alloc(stride);
  let off = 0;
  for (let y = 0; y < h; y++) {
    const filter = raw[off++];
    const line = raw.subarray(off, off + stride);
    off += stride;
    const cur = Buffer.from(line);
    for (let x = 0; x < stride; x++) {
      const a = x >= channels ? cur[x - channels] : 0;
      const b = prev[x];
      const c = x >= channels ? prev[x - channels] : 0;
      let v = cur[x];
      switch (filter) {
        case 0: break;
        case 1: v = (v + a) & 0xff; break;
        case 2: v = (v + b) & 0xff; break;
        case 3: v = (v + ((a + b) >> 1)) & 0xff; break;
        case 4: {
          const p = a + b - c;
          const pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
          const pr = pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
          v = (v + pr) & 0xff;
          break;
        }
        default: throw new Error(`bad filter ${filter}`);
      }
      cur[x] = v;
    }
    cur.copy(out, y * stride);
    prev = cur;
  }
  return {w, h, channels, data: out};
};

const [a, b] = process.argv.slice(2);
const A = decodePng(a);
const B = decodePng(b);
if (A.w !== B.w || A.h !== B.h || A.channels !== B.channels) {
  console.log(JSON.stringify({error: "geometry mismatch", a: [A.w, A.h, A.channels], b: [B.w, B.h, B.channels]}));
  process.exit(1);
}
const n = A.data.length;
let sum = 0, max = 0, over2 = 0, over8 = 0;
for (let i = 0; i < n; i++) {
  const d = Math.abs(A.data[i] - B.data[i]);
  sum += d;
  if (d > max) max = d;
  if (d > 2) over2++;
  if (d > 8) over8++;
}
console.log(
  JSON.stringify(
    {
      size: `${A.w}x${A.h}x${A.channels}`,
      meanAbsDiff: +(sum / n).toFixed(4),
      maxAbsDiff: max,
      pctChannelsOver2Levels: +((100 * over2) / n).toFixed(3),
      pctChannelsOver8Levels: +((100 * over8) / n).toFixed(3),
    },
    null,
    1,
  ),
);
