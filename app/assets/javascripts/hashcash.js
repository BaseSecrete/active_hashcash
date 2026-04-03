// http://www.hashcash.org/docs/hashcash.html
// <input type="hidden" name="hashcash" data-hashcash="{resource: 'site.example', bits: 16}"/>
Hashcash = function(input) {
  options = JSON.parse(input.getAttribute("data-hashcash"))
  Hashcash.disableParentForm(input, options)
  input.dispatchEvent(new CustomEvent("hashcash:mint", {bubbles: true}))

  Hashcash.mint(options.resource, options, function(stamp) {
    // Guard against Turbo navigation: if the input is no longer in the DOM,
    // the user has navigated away and we should silently discard the result.
    if (!input.isConnected) return

    input.value = stamp.toString()
    Hashcash.enableParentForm(input, options)
    input.dispatchEvent(new CustomEvent("hashcash:minted", {bubbles: true, detail: {stamp: stamp}}))
  })

  this.input = input
  input.form.addEventListener("submit", this.preventFromAutoSubmitFromPasswordManagers.bind(this))
}

Hashcash.setup = function() {
  if (document.readyState != "loading") {
    var input = document.querySelector("input#hashcash")
    input && new Hashcash(input)
  } else
    document.addEventListener("DOMContentLoaded", Hashcash.setup)
}

// Terminate the active worker and clean up its Blob URL.
Hashcash.cleanup = function() {
  if (Hashcash._worker) {
    Hashcash._worker.terminate()
    Hashcash._worker = null
  }
  if (Hashcash._workerUrl) {
    URL.revokeObjectURL(Hashcash._workerUrl)
    Hashcash._workerUrl = null
  }
}

// Turbo Drive: terminate the worker when navigating away so it doesn't
// complete after the page has changed, and restore the form state for
// Turbo's page cache so the snapshot doesn't have disabled buttons.
document.addEventListener("turbo:before-visit", Hashcash.cleanup)
document.addEventListener("turbo:before-cache", function() {
  Hashcash.cleanup()
  var input = document.querySelector("input#hashcash")
  if (input && input.form) {
    input.value = ""
    input.form.querySelectorAll("[type=submit]").forEach(function(submit) {
      if (submit.originalValue) {
        Hashcash.setSubmitText(submit, submit.originalValue)
      }
      submit.disabled = null
    })
  }
})

Hashcash.setSubmitText = function(submit, text) {
  if (!text) {
    return
  }
  if (submit.tagName == "BUTTON") {
    !submit.originalValue && (submit.originalValue = submit.innerHTML)
    submit.innerHTML = text
  } else {
    !submit.originalValue && (submit.originalValue = submit.value)
    submit.value = text
  }
}

Hashcash.disableParentForm = function(input, options) {
  input.form.querySelectorAll("[type=submit]").forEach(function(submit) {
    Hashcash.setSubmitText(submit, options["waiting_message"])
    submit.disabled = true
  })
}

Hashcash.enableParentForm = function(input, options) {
  input.form.querySelectorAll("[type=submit]").forEach(function(submit) {
    Hashcash.setSubmitText(submit, submit.originalValue)
    submit.disabled = null
  })
}

Hashcash.prototype.preventFromAutoSubmitFromPasswordManagers = function(event) {
  this.input.value == "" && event.preventDefault()
}

Hashcash.default = {
  version: 1,
  bits: 20,
}

Hashcash.mint = function(resource, options, callback) {
  // Format date to YYMMDD
  var date = new Date
  var year = date.getFullYear().toString()
  year = year.slice(year.length - 2, year.length)
  var month = (date.getMonth() + 1).toString().padStart(2, "0")
  var day = date.getDate().toString().padStart(2, "0")

  var stamp = new Hashcash.Stamp(
    options.version || Hashcash.default.version,
    options.bits || Hashcash.default.bits,
    options.date || year + month + day,
    resource,
    options.rand || Math.random().toString(36).substr(2, 10),
    undefined,
    options.debug
  )
  return stamp.work(callback)
}

Hashcash.Stamp = function(version, bits, date, resource, rand, counter, debug) {
  this.version = version
  this.bits = bits
  this.date = date
  this.resource = resource
  this.rand = rand
  this.counter = counter || 0
  this.debug = !!debug
}

Hashcash.Stamp.parse = function(string) {
  var args = string.split(":")
  return new Hashcash.Stamp(args[0], args[1], args[2], args[3], args[5], args[6])
}

Hashcash.Stamp.prototype.toString = function() {
  return [this.version, this.bits, this.date, this.resource, "sha256", this.rand, this.counter].join(":")
}

Hashcash.Stamp.prototype.startClock = function() {
  this.startedAt || (this.startedAt = performance.now())
}

Hashcash.Stamp.prototype.stopClock = function() {
  this.endedAt || (this.endedAt = performance.now())
  if (this.debug) {
    var duration = Math.round(this.endedAt - this.startedAt)
    var speed = Math.round(this.counter * 1000 / duration)
    console.debug("Hashcash " + this.toString() + " minted in " + duration + "ms (" + speed + " per seconds)")
  }
}

// ======================================================================
// Worker code modules
// ======================================================================
// Mining runs in a Web Worker (inlined as a Blob URL so no extra file needs
// to be served). Each module below is defined as a plain function whose
// *body* is extracted and concatenated to build the worker script. Because
// the bodies are concatenated (not wrapped in IIFEs), all top-level
// declarations share the worker's global scope and can reference each other.
// ======================================================================

Hashcash.WorkerCode = {}

// ------------------------------------------------------------------
// SHA-256 (FIPS 180-4) – pure JavaScript implementation
// Used as fallback when WebGPU is unavailable and for GPU result
// verification.
// ------------------------------------------------------------------
Hashcash.WorkerCode.sha256 = function() {
  // SHA-256 round constants (FIPS 180-4 section 4.2.2)
  var K = new Uint32Array([
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
  ]);

  // Compute SHA-256 over the first `len` bytes of `bytes`. Returns an array
  // of 8 big-endian 32-bit integers (the 256-bit digest).
  function sha256bytes(bytes, len) {
    // Pad to a multiple of 64 bytes: append 0x80, then zeros, then 64-bit
    // big-endian bit length (we only use the low 32 bits since stamp strings
    // are always shorter than 512 MB).
    var padded = new Uint8Array(((len + 9 + 63) & ~63));
    for (var i = 0; i < len; i++) padded[i] = bytes[i];
    padded[len] = 0x80;
    var bitLen = len * 8;
    var pLen = padded.length;
    padded[pLen - 4] = (bitLen >>> 24) & 0xff;
    padded[pLen - 3] = (bitLen >>> 16) & 0xff;
    padded[pLen - 2] = (bitLen >>> 8) & 0xff;
    padded[pLen - 1] = bitLen & 0xff;

    // Initial hash values (FIPS 180-4 section 5.3.3)
    var H0 = 0x6a09e667, H1 = 0xbb67ae85, H2 = 0x3c6ef372, H3 = 0xa54ff53a;
    var H4 = 0x510e527f, H5 = 0x9b05688c, H6 = 0x1f83d9ab, H7 = 0x5be0cd19;
    var W = new Int32Array(64);

    // Process each 512-bit (64-byte) block
    for (var off = 0; off < pLen; off += 64) {
      for (var t = 0; t < 16; t++) {
        W[t] = (padded[off+t*4]<<24)|(padded[off+t*4+1]<<16)|(padded[off+t*4+2]<<8)|padded[off+t*4+3];
      }
      for (var t = 16; t < 64; t++) {
        var w15 = W[t-15], w2 = W[t-2];
        W[t] = (W[t-16] + (((w15>>>7)|(w15<<25))^((w15>>>18)|(w15<<14))^(w15>>>3)) + W[t-7] + (((w2>>>17)|(w2<<15))^((w2>>>19)|(w2<<13))^(w2>>>10))) | 0;
      }
      var a=H0,b=H1,c=H2,d=H3,e=H4,f=H5,g=H6,h=H7;
      for (var t = 0; t < 64; t++) {
        var t1 = (h + (((e>>>6)|(e<<26))^((e>>>11)|(e<<21))^((e>>>25)|(e<<7))) + ((e&f)^(~e&g)) + K[t] + W[t]) | 0;
        var t2 = ((((a>>>2)|(a<<30))^((a>>>13)|(a<<19))^((a>>>22)|(a<<10))) + ((a&b)^(a&c)^(b&c))) | 0;
        h=g; g=f; f=e; e=(d+t1)|0; d=c; c=b; b=a; a=(t1+t2)|0;
      }
      H0=(H0+a)|0; H1=(H1+b)|0; H2=(H2+c)|0; H3=(H3+d)|0;
      H4=(H4+e)|0; H5=(H5+f)|0; H6=(H6+g)|0; H7=(H7+h)|0;
    }
    return [H0, H1, H2, H3, H4, H5, H6, H7];
  }

  // Encode a string as bytes into a pre-allocated buffer at `offset`.
  // Handles ASCII and basic UTF-8 (BMP only).
  function strToBytes(str, out, offset) {
    for (var i = 0; i < str.length; i++) {
      var c = str.charCodeAt(i);
      if (c < 128) out[offset++] = c;
      else if (c < 2048) { out[offset++] = (c>>6)|192; out[offset++] = (c&63)|128; }
      else { out[offset++] = (c>>12)|224; out[offset++] = ((c>>6)&63)|128; out[offset++] = (c&63)|128; }
    }
    return offset;
  }

  // Write the decimal digits of `n` as ASCII bytes into `out` at `offset`.
  // Avoids string allocation in the hot loop.
  function numToBytes(n, out, offset) {
    if (n === 0) { out[offset] = 48; return offset + 1; }
    var digs = [];
    while (n > 0) { digs.push(48 + (n % 10)); n = (n / 10) | 0; }
    for (var i = digs.length - 1; i >= 0; i--) out[offset++] = digs[i];
    return offset;
  }

  // Check if the first `bits` bits of the SHA-256 digest (8 x u32) are zero.
  function checkLeadingZeros(H, bits) {
    var fullBytes = Math.floor(bits / 8);
    var remBits = bits % 8;
    var mask = remBits > 0 ? (0xFF << (8 - remBits)) & 0xFF : 0;
    var byteIdx = 0;
    for (var w = 0; w < 8 && byteIdx <= fullBytes; w++) {
      var word = H[w];
      for (var s = 24; s >= 0; s -= 8) {
        var bv = (word >>> s) & 0xFF;
        if (byteIdx < fullBytes) {
          if (bv !== 0) return false;
        } else if (byteIdx === fullBytes && remBits > 0) {
          return (bv & mask) === 0;
        } else {
          return true;
        }
        byteIdx++;
      }
    }
    return true;
  }

  // Verify a candidate stamp string with pure JS SHA-256.
  function verifyStamp(prefix, counter, bits) {
    var str = prefix + ":" + counter;
    var buf = new Uint8Array(str.length + 4);
    var len = strToBytes(str, buf, 0);
    var H = sha256bytes(buf, len);
    return checkLeadingZeros(H, bits);
  }
}

// ------------------------------------------------------------------
// Pure JS mining – synchronous tight loop in the worker thread
// ------------------------------------------------------------------
Hashcash.WorkerCode.pureJS = function() {
  function minePureJS(prefix, bits) {
    var fullPrefix = prefix + ":";
    var counter = 0;
    var fullBytes = Math.floor(bits / 8);
    var remBits = bits % 8;
    var mask = remBits > 0 ? (0xFF << (8 - remBits)) & 0xFF : 0;

    // Pre-encode the stamp prefix (everything before the counter) into a
    // reusable byte buffer. Only the counter digits change per iteration.
    var buf = new Uint8Array(fullPrefix.length + 12);
    var prefixLen = strToBytes(fullPrefix, buf, 0);

    // Yield every 65536 iterations so the worker stays terminable.
    var YIELD = 65536;

    function mine() {
      var end = counter + YIELD;
      while (counter < end) {
        var len = numToBytes(counter, buf, prefixLen);
        var H = sha256bytes(buf, len);

        // Check leading zero bits by walking the digest words byte-by-byte.
        var ok = true, byteIdx = 0;
        check:
        for (var w = 0; w < 8 && byteIdx <= fullBytes; w++) {
          var word = H[w];
          for (var s = 24; s >= 0; s -= 8) {
            var bv = (word >>> s) & 0xFF;
            if (byteIdx < fullBytes) {
              if (bv !== 0) { ok = false; break check; }
            } else if (byteIdx === fullBytes && remBits > 0) {
              if ((bv & mask) !== 0) ok = false;
              break check;
            } else { break check; }
            byteIdx++;
          }
        }
        if (ok) { self.postMessage({ found: true, counter: counter }); return; }
        counter++;
      }
      setTimeout(mine, 0);
    }
    mine();
  }
}

// ------------------------------------------------------------------
// WebGPU mining – SHA-256 as a WGSL compute shader on the GPU
// ------------------------------------------------------------------
Hashcash.WorkerCode.webGPU = function() {
  var SHADER_CODE = '\
const K: array<u32, 64> = array<u32, 64>(\
  0x428a2f98u, 0x71374491u, 0xb5c0fbcfu, 0xe9b5dba5u, 0x3956c25bu, 0x59f111f1u, 0x923f82a4u, 0xab1c5ed5u,\
  0xd807aa98u, 0x12835b01u, 0x243185beu, 0x550c7dc3u, 0x72be5d74u, 0x80deb1feu, 0x9bdc06a7u, 0xc19bf174u,\
  0xe49b69c1u, 0xefbe4786u, 0x0fc19dc6u, 0x240ca1ccu, 0x2de92c6fu, 0x4a7484aau, 0x5cb0a9dcu, 0x76f988dau,\
  0x983e5152u, 0xa831c66du, 0xb00327c8u, 0xbf597fc7u, 0xc6e00bf3u, 0xd5a79147u, 0x06ca6351u, 0x14292967u,\
  0x27b70a85u, 0x2e1b2138u, 0x4d2c6dfcu, 0x53380d13u, 0x650a7354u, 0x766a0abbu, 0x81c2c92eu, 0x92722c85u,\
  0xa2bfe8a1u, 0xa81a664bu, 0xc24b8b70u, 0xc76c51a3u, 0xd192e819u, 0xd6990624u, 0xf40e3585u, 0x106aa070u,\
  0x19a4c116u, 0x1e376c08u, 0x2748774cu, 0x34b0bcb5u, 0x391c0cb3u, 0x4ed8aa4au, 0x5b9cca4fu, 0x682e6ff3u,\
  0x748f82eeu, 0x78a5636fu, 0x84c87814u, 0x8cc70208u, 0x90befffau, 0xa4506cebu, 0xbef9a3f7u, 0xc67178f2u\
);\
\
const H_INIT: array<u32, 8> = array<u32, 8>(\
  0x6a09e667u, 0xbb67ae85u, 0x3c6ef372u, 0xa54ff53au,\
  0x510e527fu, 0x9b05688cu, 0x1f83d9abu, 0x5be0cd19u\
);\
\
struct Params {\
  base_counter: u32,\
  msg_len: u32,\
  bits: u32,\
  batch_size: u32,\
}\
\
@group(0) @binding(0) var<uniform> params: Params;\
@group(0) @binding(1) var<storage, read> msg_prefix: array<u32>;\
@group(0) @binding(2) var<storage, read_write> results: array<u32>;\
\
fn rotr(x: u32, n: u32) -> u32 {\
  return (x >> n) | (x << (32u - n));\
}\
\
fn sha256_compress(block: array<u32, 16>, h_in: array<u32, 8>) -> array<u32, 8> {\
  var W: array<u32, 64>;\
  for (var t = 0u; t < 16u; t++) { W[t] = block[t]; }\
  for (var t = 16u; t < 64u; t++) {\
    let s0 = rotr(W[t-15u], 7u) ^ rotr(W[t-15u], 18u) ^ (W[t-15u] >> 3u);\
    let s1 = rotr(W[t-2u], 17u) ^ rotr(W[t-2u], 19u) ^ (W[t-2u] >> 10u);\
    W[t] = W[t-16u] + s0 + W[t-7u] + s1;\
  }\
  var h = h_in;\
  for (var t = 0u; t < 64u; t++) {\
    let S1 = rotr(h[4], 6u) ^ rotr(h[4], 11u) ^ rotr(h[4], 25u);\
    let ch = (h[4] & h[5]) ^ (~h[4] & h[6]);\
    let temp1 = h[7] + S1 + ch + K[t] + W[t];\
    let S0 = rotr(h[0], 2u) ^ rotr(h[0], 13u) ^ rotr(h[0], 22u);\
    let maj = (h[0] & h[1]) ^ (h[0] & h[2]) ^ (h[1] & h[2]);\
    let temp2 = S0 + maj;\
    h[7] = h[6]; h[6] = h[5]; h[5] = h[4]; h[4] = h[3] + temp1;\
    h[3] = h[2]; h[2] = h[1]; h[1] = h[0]; h[0] = temp1 + temp2;\
  }\
  for (var i = 0u; i < 8u; i++) { h[i] = h[i] + h_in[i]; }\
  return h;\
}\
\
fn check_leading_zeros(h: array<u32, 8>, bits: u32) -> bool {\
  let full_words = bits / 32u;\
  let rem_bits = bits % 32u;\
  for (var i = 0u; i < full_words; i++) {\
    if (h[i] != 0u) { return false; }\
  }\
  if (rem_bits > 0u) {\
    let mask = 0xFFFFFFFFu << (32u - rem_bits);\
    if ((h[full_words] & mask) != 0u) { return false; }\
  }\
  return true;\
}\
\
fn write_counter(counter: u32, data: ptr<function, array<u32, 32>>, pos: u32) -> u32 {\
  var digits: array<u32, 10>;\
  var num_digits = 0u;\
  var n = counter;\
  if (n == 0u) {\
    digits[0] = 48u;\
    num_digits = 1u;\
  } else {\
    while (n > 0u) {\
      digits[num_digits] = 48u + (n % 10u);\
      num_digits++;\
      n = n / 10u;\
    }\
  }\
  var p = pos;\
  for (var i = 0u; i < num_digits; i++) {\
    let d = digits[num_digits - 1u - i];\
    let word_idx = p / 4u;\
    let byte_idx = p % 4u;\
    let shift = (3u - byte_idx) * 8u;\
    (*data)[word_idx] = (*data)[word_idx] | (d << shift);\
    p++;\
  }\
  return p;\
}\
\
fn set_byte(data: ptr<function, array<u32, 32>>, pos: u32, val: u32) {\
  let word_idx = pos / 4u;\
  let byte_idx = pos % 4u;\
  let shift = (3u - byte_idx) * 8u;\
  (*data)[word_idx] = (*data)[word_idx] | (val << shift);\
}\
\
@compute @workgroup_size(256)\
fn main(@builtin(global_invocation_id) gid: vec3<u32>) {\
  let idx = gid.x;\
  if (idx >= params.batch_size) { return; }\
  if (results[0] != 0u) { return; }\
\
  let counter = params.base_counter + idx;\
  let prefix_len = params.msg_len;\
  let prefix_words = (prefix_len + 3u) / 4u;\
  let last_prefix_word = prefix_len / 4u;\
  let last_prefix_byte = prefix_len % 4u;\
\
  var data: array<u32, 32>;\
  for (var i = 0u; i < 32u; i++) { data[i] = 0u; }\
  for (var i = 0u; i < prefix_words; i++) { data[i] = msg_prefix[i]; }\
  if (last_prefix_byte > 0u) {\
    let keep = 0xFFFFFFFFu << ((4u - last_prefix_byte) * 8u);\
    data[last_prefix_word] = data[last_prefix_word] & keep;\
  }\
\
  let msg_end = write_counter(counter, &data, prefix_len);\
  set_byte(&data, msg_end, 0x80u);\
  let bit_len = msg_end * 8u;\
\
  if (msg_end > 55u) {\
    data[31] = bit_len;\
  } else {\
    data[15] = bit_len;\
  }\
\
  var block: array<u32, 16>;\
  for (var i = 0u; i < 16u; i++) { block[i] = data[i]; }\
  var h = sha256_compress(block, H_INIT);\
\
  if (msg_end > 55u) {\
    for (var i = 0u; i < 16u; i++) { block[i] = data[i + 16u]; }\
    h = sha256_compress(block, h);\
  }\
\
  if (check_leading_zeros(h, params.bits)) {\
    results[0] = 1u;\
    results[1] = counter;\
  }\
}\
';

  var _debug = false;

  function dbg(msg) {
    if (_debug) self.postMessage({ debug: "Hashcash (WebGPU) " + msg });
  }

  async function mineWebGPU(prefix, bits) {
    dbg("Mining with WebGPU (bits=" + bits + ")");

    // The WGSL shader supports up to 2 SHA-256 blocks (119-byte messages).
    // Stamp = prefix + ":" + counter (up to 10 digits). Skip to pure JS
    // for the rare case where the resource name exceeds this.
    if ((prefix + ":").length + 10 > 119) throw new Error("Stamp too long for GPU SHA-256: " + ((prefix + ":").length + 10) + " bytes");

    if (typeof navigator === "undefined" || !navigator.gpu) throw new Error("WebGPU not available");

    var adapter = await navigator.gpu.requestAdapter();
    if (!adapter) throw new Error("No WebGPU adapter");
    var device = await adapter.requestDevice();

    device.lost.then(function(info) {
      dbg("Device lost: " + info.reason + " - " + info.message);
    });

    var shaderModule = device.createShaderModule({ code: SHADER_CODE });

    // Check for shader compilation errors
    if (shaderModule.getCompilationInfo) {
      var compInfo = await shaderModule.getCompilationInfo();
      var hasError = compInfo.messages.some(function(m) { return m.type === "error"; });
      if (hasError) {
        var msgs = compInfo.messages.map(function(m) { return m.type + ": " + m.message; }).join("; ");
        throw new Error("Shader compilation error: " + msgs);
      }
    }

    // Encode prefix + ":" as big-endian packed u32 array
    var fullPrefix = prefix + ":";
    var prefixBytes = [];
    for (var i = 0; i < fullPrefix.length; i++) {
      prefixBytes.push(fullPrefix.charCodeAt(i));
    }
    var prefixLen = prefixBytes.length;
    var prefixWords = Math.ceil(prefixLen / 4);
    var prefixU32 = new Uint32Array(Math.max(prefixWords, 16));
    for (var i = 0; i < prefixLen; i++) {
      var wordIdx = Math.floor(i / 4);
      var byteIdx = i % 4;
      var shift = (3 - byteIdx) * 8;
      prefixU32[wordIdx] |= (prefixBytes[i] << shift);
    }

    var BATCH = 262144; // 256k nonces per GPU dispatch

    var paramsBuffer = device.createBuffer({ size: 16, usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST });
    var prefixBuffer = device.createBuffer({ size: prefixU32.byteLength, usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST });
    var resultsBuffer = device.createBuffer({ size: 8, usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC | GPUBufferUsage.COPY_DST });
    var readBuffer = device.createBuffer({ size: 8, usage: GPUBufferUsage.MAP_READ | GPUBufferUsage.COPY_DST });

    device.queue.writeBuffer(prefixBuffer, 0, prefixU32);

    var pipeline = device.createComputePipeline({
      layout: "auto",
      compute: { module: shaderModule, entryPoint: "main" }
    });

    var bindGroup = device.createBindGroup({
      layout: pipeline.getBindGroupLayout(0),
      entries: [
        { binding: 0, resource: { buffer: paramsBuffer } },
        { binding: 1, resource: { buffer: prefixBuffer } },
        { binding: 2, resource: { buffer: resultsBuffer } }
      ]
    });

    var counter = 0;
    var MAX_DISPATCHES = 200; // Safety limit: 200 * 262144 = ~52M nonces
    var dispatches = 0;
    var dispatchStartTime = performance.now();

    async function dispatch() {
      device.queue.writeBuffer(resultsBuffer, 0, new Uint32Array([0, 0]));
      device.queue.writeBuffer(paramsBuffer, 0, new Uint32Array([counter, prefixLen, bits, BATCH]));

      var commandEncoder = device.createCommandEncoder();
      var passEncoder = commandEncoder.beginComputePass();
      passEncoder.setPipeline(pipeline);
      passEncoder.setBindGroup(0, bindGroup);
      passEncoder.dispatchWorkgroups(Math.ceil(BATCH / 256));
      passEncoder.end();

      commandEncoder.copyBufferToBuffer(resultsBuffer, 0, readBuffer, 0, 8);
      device.queue.submit([commandEncoder.finish()]);

      await readBuffer.mapAsync(GPUMapMode.READ);
      var res = new Uint32Array(readBuffer.getMappedRange().slice(0));
      readBuffer.unmap();

      if (res[0] !== 0) {
        var found = res[1];
        var elapsed = performance.now() - dispatchStartTime;
        var totalNonces = counter + BATCH;
        var speed = Math.round(totalNonces * 1000 / elapsed);
        dbg("GPU found solution! counter=" + found + " after " + dispatches + " dispatches, " + totalNonces + " nonces in " + Math.round(elapsed) + "ms (" + speed + " h/s)");
        device.destroy();
        // Double-check the GPU result with pure JS to guard against GPU quirks
        if (verifyStamp(prefix, found, bits)) {
          self.postMessage({ found: true, counter: found });
        } else {
          dbg("GPU false positive at counter=" + found + ", falling back to pure JS");
          // GPU gave a false positive - fall back to pure JS
          minePureJS(prefix, bits);
        }
        return;
      }

      counter += BATCH;
      dispatches++;
      if (dispatches >= MAX_DISPATCHES) {
        dbg("Reached MAX_DISPATCHES (" + MAX_DISPATCHES + "), falling back to pure JS");
        device.destroy();
        // GPU ran too long without finding a solution - fall back to pure JS
        minePureJS(prefix, bits);
        return;
      }
      setTimeout(dispatch, 0);
    }

    dispatch();
  }
}

// ------------------------------------------------------------------
// Worker entry point – receives a message, tries WebGPU then pure JS
// ------------------------------------------------------------------
Hashcash.WorkerCode.entry = function() {
  self.addEventListener("message", function(e) {
    var d = e.data;
    var prefix = d.prefix;
    var bits = d.bits;
    _debug = !!d.debug;

    mineWebGPU(prefix, bits).catch(function(err) {
      dbg("Falling back to pure JS: " + (err.message || String(err)));
      self.postMessage({ webgpuError: err.message || String(err) });
      minePureJS(prefix, bits);
    });
  });
}

// ======================================================================
// Build the Worker Blob from the code modules above
// ======================================================================
Hashcash._buildWorkerBlob = function() {
  var sections = [
    Hashcash.WorkerCode.sha256,
    Hashcash.WorkerCode.pureJS,
    Hashcash.WorkerCode.webGPU,
    Hashcash.WorkerCode.entry
  ]
  var code = sections.map(function(fn) {
    var s = fn.toString()
    // Extract the function body between the first "{" and last "}".
    // Safe because Function#toString always wraps the body in exactly
    // one pair of braces; inner braces (e.g. in the WGSL shader string)
    // never appear after the final closing brace.
    return s.substring(s.indexOf("{") + 1, s.lastIndexOf("}"))
  }).join("\n")
  return new Blob([code], { type: "application/javascript" })
}

// ======================================================================
// Mine a valid stamp using a Web Worker
// ======================================================================
// Tries WebGPU first for massive GPU parallelism (order of magnitude
// faster). WebGPU is supported in all major browsers (Chrome 113+,
// Edge 113+, Firefox 141+, Safari 26+). Falls back to a synchronous
// pure JS SHA-256 tight loop for older browsers. The worker is inlined
// as a Blob URL so no extra file needs to be served.
Hashcash.Stamp.prototype.work = function(callback) {
  this.startClock()
  var self = this

  // Clean up any previous worker (e.g. Turbo restoring a cached page)
  Hashcash.cleanup()

  var blob = Hashcash._buildWorkerBlob()
  var workerUrl = URL.createObjectURL(blob)
  var worker = new Worker(workerUrl)

  // Track the active worker so Hashcash.cleanup() can terminate it
  Hashcash._worker = worker
  Hashcash._workerUrl = workerUrl

  worker.onmessage = function(e) {
    if (e.data.debug) {
      console.log(e.data.debug)
      return
    }
    if (e.data.webgpuError) {
      if (self.debug) console.warn("Hashcash WebGPU unavailable, using pure JS:", e.data.webgpuError)
      return
    }
    if (e.data.found) {
      Hashcash._worker = null
      Hashcash._workerUrl = null
      self.counter = e.data.counter
      self.stopClock()
      worker.terminate()
      URL.revokeObjectURL(workerUrl)
      callback(self)
    }
  }

  // Build the prefix once and send it to the worker. The worker appends the
  // counter on each iteration, avoiding repeated string building.
  var prefix = [this.version, this.bits, this.date, this.resource, "sha256", this.rand].join(":")

  worker.postMessage({
    prefix: prefix,
    bits: parseInt(this.bits, 10),
    debug: self.debug
  })
}

Hashcash.setup()
