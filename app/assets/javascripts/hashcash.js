// http://www.hashcash.org/docs/hashcash.html
// <input type="hidden" name="hashcash" data-hashcash="{resource: 'site.example', bits: 16}"/>
Hashcash = function(input) {
  options = JSON.parse(input.getAttribute("data-hashcash"))
  Hashcash.disableParentForm(input, options)
  input.dispatchEvent(new CustomEvent("hashcash:mint", {bubbles: true}))

  Hashcash.mint(options.resource, options, function(stamp) {
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
    options.rand || Math.random().toString(36).substr(2, 10)
  )
  return stamp.work(callback)
}

Hashcash.Stamp = function(version, bits, date, resource, rand, counter) {
  this.version = version
  this.bits = bits
  this.date = date
  this.resource = resource
  this.rand = rand
  this.counter = counter || 0
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
  var duration = this.endedAt - this.startedAt
  var speed = Math.round(this.counter * 1000 / duration)
  console.debug("Hashcash " + this.toString() + " minted in " + duration + "ms (" + speed + " per seconds)")
}

// Mine a valid stamp using a Web Worker with a pure JS SHA-256 implementation.
// The worker is inlined as a Blob URL so no extra file needs to be served.
// Using a Web Worker keeps the main thread completely unblocked while mining.
// A synchronous SHA-256 in a tight loop is faster than async crypto.subtle
// because it avoids the per-call Promise/microtask overhead entirely.
Hashcash.Stamp.prototype.work = function(callback) {
  this.startClock()
  var self = this

  var workerCode = function() {
    // SHA-256 round constants (FIPS 180-4 §4.2.2)
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

      // Initial hash values (FIPS 180-4 §5.3.3)
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

    self.addEventListener("message", function(e) {
      var d = e.data;
      var prefix = d.prefix + ":";
      var bits = d.bits;
      var counter = 0;

      // Pre-compute how many leading zero bytes and remaining bits to check
      var fullBytes = Math.floor(bits / 8);
      var remBits = bits % 8;
      var mask = remBits > 0 ? (0xFF << (8 - remBits)) & 0xFF : 0;

      // Pre-encode the stamp prefix (everything before the counter) into a
      // reusable byte buffer. Only the counter digits change per iteration.
      var buf = new Uint8Array(prefix.length + 12);
      var prefixLen = strToBytes(prefix, buf, 0);

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
    });
  }

  var blob = new Blob(
    ["(" + workerCode.toString() + ")()"],
    {type: "application/javascript"}
  )
  var workerUrl = URL.createObjectURL(blob)
  var worker = new Worker(workerUrl)

  worker.onmessage = function(e) {
    if (e.data.found) {
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
    bits: parseInt(this.bits, 10)
  })
}

Hashcash.setup()
