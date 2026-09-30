// Focus Window Band — Figma shader (kind: fill, static: isAnimated=false, usesMouse=false)
//
// Renders the Today "focus window" band procedurally: track, warm-up, best focus and
// lighter focus zones, with the uncertainty (±minutes) drawn as a real feathered edge
// instead of stacked translucent rectangles. Dose dot + now marker included.
// Publish with: create_shader(kind: "fill") → update_shader(files: [{ path: "main.ts" }]).
// Positions are % of layer width so the band stays correct when the layer is resized.

import { defineProperties } from "figma:shaders"

export default function FocusWindowBand() {}

export function setup(device: GPUDevice, frame: any) {
  const wgsl = `diagnostic(off,derivative_uniformity);
struct Uniforms {
  a: vec4f,      // start, peakEnd, end, dose   (0..1 of width)
  b: vec4f,      // uncertainty, now, showNow, radiusPx
  c: vec4f,      // width, height, grain, unused
  peakCol: vec4f,
  fadeCol: vec4f,
  warmCol: vec4f,
  trackCol: vec4f,
};
@group(0) @binding(0) var<uniform> u: Uniforms;

struct VOut {
  @builtin(position) pos: vec4f,
  @location(0) uv: vec2f,
};

@vertex
fn vs_main(@location(0) p: vec2f, @location(1) uv: vec2f) -> VOut {
  var o: VOut;
  o.pos = vec4f(p, 0.0, 1.0);
  o.uv = uv;
  return o;
}

fn hash21(q: vec2f) -> f32 {
  let h = dot(q, vec2f(127.1, 311.7));
  return fract(sin(h) * 43758.5453);
}

// 1 inside [lo, hi], feathered by softLo / softHi on each edge.
fn zone(x: f32, lo: f32, hi: f32, softLo: f32, softHi: f32) -> f32 {
  return smoothstep(lo - softLo, lo + softLo, x) * (1.0 - smoothstep(hi - softHi, hi + softHi, x));
}

@fragment
fn fs_main(i: VOut) -> @location(0) vec4f {
  let size = max(u.c.xy, vec2f(1.0, 1.0));
  let px = i.uv * size;
  let x = i.uv.x;
  let startX = u.a.x;
  let peakEnd = u.a.y;
  let endX = u.a.z;
  let doseX = u.a.w;
  let unc = max(u.b.x, 0.0005);
  let nowX = u.b.y;
  let showNow = u.b.z;
  let radius = u.b.w;
  let hair = 1.0 / size.x;

  var col = u.trackCol;
  let warmA = zone(x, doseX, startX, hair, unc);
  let peakA = zone(x, startX, peakEnd, unc, hair * 2.0);
  let fadeA = zone(x, peakEnd, endX, hair * 2.0, unc);
  col = mix(col, u.warmCol, warmA * u.warmCol.a);
  col = mix(col, u.peakCol, peakA * u.peakCol.a);
  col = mix(col, u.fadeCol, fadeA * u.fadeCol.a);

  // Paper grain keeps the Calm theme from feeling flat; 0 disables it.
  let g = (hash21(floor(px)) - 0.5) * u.c.z * 0.06;
  col = vec4f(clamp(col.rgb + vec3f(g, g, g), vec3f(0.0), vec3f(1.0)), col.a);

  let ink = vec4f(0.106, 0.114, 0.110, 1.0);
  let dotR = size.y * 0.2;
  let dd = length(px - vec2f(doseX * size.x, size.y * 0.5));
  col = mix(col, ink, 1.0 - smoothstep(dotR - 0.75, dotR + 0.75, dd));

  let dn = abs(px.x - nowX * size.x);
  col = mix(col, ink, (1.0 - smoothstep(0.5, 1.5, dn)) * showNow);

  // Rounded-rect mask (straight alpha for fills: scale alpha only).
  let halfSize = size * 0.5;
  let r = min(radius, min(halfSize.x, halfSize.y));
  let q = abs(px - halfSize) - (halfSize - vec2f(r, r));
  let sd = length(max(q, vec2f(0.0, 0.0))) + min(max(q.x, q.y), 0.0) - r;
  let edge = 1.0 - smoothstep(-0.5, 0.5, sd);
  return vec4f(col.rgb, col.a * edge);
}
`
  frame.state.shaderModule = device.createShaderModule({ code: wgsl })

  frame.state.quad = device.createBuffer({
    size: 6 * 4 * 4,
    usage: GPUBufferUsage.VERTEX,
    mappedAtCreation: true,
  })
  new Float32Array(frame.state.quad.getMappedRange()).set([
    -1, -1, 0, 1, 1, -1, 1, 1, -1, 1, 0, 0,
    -1, 1, 0, 0, 1, -1, 1, 1, 1, 1, 1, 0,
  ])
  frame.state.quad.unmap()

  // 7 × vec4f = 112 bytes (multiple of 16).
  frame.state.uniforms = device.createBuffer({
    size: 112,
    usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
  })
}

export function render(device: GPUDevice, frame: any) {
  if (frame.state.pipelineFormat !== frame.output.format) {
    frame.state.pipeline = device.createRenderPipeline({
      layout: "auto",
      vertex: {
        module: frame.state.shaderModule,
        entryPoint: "vs_main",
        buffers: [{
          arrayStride: 16,
          attributes: [
            { shaderLocation: 0, format: "float32x2", offset: 0 },
            { shaderLocation: 1, format: "float32x2", offset: 8 },
          ],
        }],
      },
      fragment: {
        module: frame.state.shaderModule,
        entryPoint: "fs_main",
        targets: [{ format: frame.output.format }],
      },
      primitive: { topology: "triangle-list" },
    })
    frame.state.bindGroup = device.createBindGroup({
      layout: frame.state.pipeline.getBindGroupLayout(0),
      entries: [{ binding: 0, resource: { buffer: frame.state.uniforms } }],
    })
    frame.state.pipelineFormat = frame.output.format
  }

  const p = frame.params
  const rgba = (c: any): number[] => Array.isArray(c) ? [c[0], c[1], c[2], c[3] ?? 1] : [c.r, c.g, c.b, c.a ?? 1]
  const pct = (v: number): number => Math.min(1, Math.max(0, v / 100))
  const start = pct(p.windowStart)
  const peakEnd = Math.max(start, pct(p.bestFocusEnd))
  const end = Math.max(peakEnd, pct(p.windowEnd))
  const dose = Math.min(start, pct(p.dose))

  device.queue.writeBuffer(frame.state.uniforms, 0, new Float32Array([
    start, peakEnd, end, dose,
    pct(p.uncertainty), pct(p.now), p.showNow ? 1 : 0, p.cornerRadius,
    frame.output.width, frame.output.height, p.grain, 0,
    ...rgba(p.bestFocusColor),
    ...rgba(p.lighterFocusColor),
    ...rgba(p.warmUpColor),
    ...rgba(p.trackColor),
  ]))

  const encoder = device.createCommandEncoder()
  const pass = encoder.beginRenderPass({
    colorAttachments: [{
      view: frame.output.createView(),
      loadOp: "clear",
      storeOp: "store",
      clearValue: { r: 0, g: 0, b: 0, a: 0 },
    }],
  })
  pass.setPipeline(frame.state.pipeline)
  pass.setBindGroup(0, frame.state.bindGroup)
  pass.setVertexBuffer(0, frame.state.quad)
  pass.draw(6)
  pass.end()
  device.queue.submit([encoder.finish()])
}

// Defaults reproduce the Today card: 6am–11pm track, logged 8:10, focus 9:10–5:10, now 9:41.
defineProperties(FocusWindowBand, {
  dose: { type: "number", defaultValue: 12.7, min: 0, max: 100, step: 0.1, control: "slider", unit: "%" },
  windowStart: { type: "number", defaultValue: 18.6, min: 0, max: 100, step: 0.1, control: "slider", unit: "%" },
  bestFocusEnd: { type: "number", defaultValue: 54.9, min: 0, max: 100, step: 0.1, control: "slider", unit: "%" },
  windowEnd: { type: "number", defaultValue: 65.7, min: 0, max: 100, step: 0.1, control: "slider", unit: "%" },
  uncertainty: { type: "number", defaultValue: 2.5, min: 0, max: 15, step: 0.1, control: "slider", unit: "%" },
  now: { type: "number", defaultValue: 21.6, min: 0, max: 100, step: 0.1, control: "slider", unit: "%" },
  showNow: { type: "boolean", defaultValue: true },
  cornerRadius: { type: "number", defaultValue: 8, min: 0, max: 40, step: 1, control: "slider", unit: "px" },
  grain: { type: "number", defaultValue: 0.15, min: 0, max: 1, step: 0.01, control: "slider" },
  bestFocusColor: { type: "color", defaultValue: { r: 0.169, g: 0.431, b: 0.408, a: 1 } },
  lighterFocusColor: { type: "color", defaultValue: { r: 0.498, g: 0.698, b: 0.675, a: 1 } },
  warmUpColor: { type: "color", defaultValue: { r: 0.835, g: 0.906, b: 0.890, a: 1 } },
  trackColor: { type: "color", defaultValue: { r: 0.925, g: 0.914, b: 0.886, a: 1 } },
})
