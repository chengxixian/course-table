import fs from "node:fs";
const f = process.argv[2];
const buf = fs.readFileSync(f);
let pos = 12, fmt=null, data=null;
while (pos + 8 <= buf.length) {
  const id = buf.toString("ascii", pos, pos+4); const size = buf.readUInt32LE(pos+4); const body = pos+8;
  if (id === "fmt ") fmt = {ch: buf.readUInt16LE(body+2), sr: buf.readUInt32LE(body+4), bits: buf.readUInt16LE(body+14)};
  else if (id === "data") data = buf.subarray(body, Math.min(body+size, buf.length));
  pos = body + size + (size & 1);
}
const bytes = fmt.bits/8, n = Math.floor(data.length/(bytes*fmt.ch));
const rd = (o) => fmt.bits===24 ? data.readIntLE(o,3)/8388608 : data.readInt16LE(o)/32768;
let sm=0, ss=0, sl=0, sr=0;
for (let i=0;i<n;i++){
  const b=i*bytes*fmt.ch; const l=rd(b), r=rd(b+bytes);
  const m=(l+r)/2, s=(l-r)/2;
  sm+=m*m; ss+=s*s; sl+=l*l; sr+=r*r;
}
const db=(v)=>20*Math.log10(Math.sqrt(v/n)+1e-12);
console.log(JSON.stringify({mid_rms_db:+db(sm).toFixed(2), side_rms_db:+db(ss).toFixed(2), side_minus_mid_db:+(db(ss)-db(sm)).toFixed(2), L: +db(sl).toFixed(2), R: +db(sr).toFixed(2)}, null, 2));

