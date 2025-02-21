// http://www.hashcash.org/docs/hashcash.html
// <input type="hiden" name="hashcash" data-hashcash="{resource: 'site.example', bits: 16}"/>
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
    document.addEventListener("DOMContentLoaded", Hashcash.setup )
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
  extension: null,
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
    options.extension || Hashcash.default.extension,
    options.rand || Math.random().toString(36).substr(2, 10),
  )
  return stamp.work(callback)
}

Hashcash.Stamp = function(version, bits, date, resource, extension, rand, counter = 0) {
  this.version = version
  this.bits = bits
  this.date = date
  this.resource = resource
  this.extension = extension
  this.rand = rand
  this.counter = counter
}

Hashcash.Stamp.parse = function(string) {
  var args = string.split(":")
  return new Hashcash.Stamp(args[0], args[1], args[2], args[3], args[4], args[5], args[6])
}

Hashcash.Stamp.prototype.toString = function() {
  return [this.version, this.bits, this.date, this.resource, this.extension, this.rand, this.counter].join(":")
}

// Trigger the given callback when the problem is solved.
// In order to not freeze the page, setTimeout is called every 100ms to let some CPU to other tasks.
Hashcash.Stamp.prototype.work = function(callback) {
  this.startClock()
  var timer = performance.now()
  while (!this.check())
    if (this.counter++ && performance.now() - timer > 100)
      return setTimeout(this.work.bind(this), 0, callback)
  this.stopClock()
  callback(this)
}

Hashcash.Stamp.prototype.check = function() {
  var array = Hashcash.sha1(this.toString())
  return array[0] >> (160-this.bits) == 0
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

/**
 * Secure Hash Algorithm (SHA1)
 * http://www.webtoolkit.info/
 **/
Hashcash.sha1 = function(msg) {
  var rotate_left = Hashcash.sha1.rotate_left
  var Utf8Encode = Hashcash.sha1.Utf8Encode

  var blockstart;
  var i, j;
  var W = new Array(80);
  var H0 = 0x67452301;
  var H1 = 0xEFCDAB89;
  var H2 = 0x98BADCFE;
  var H3 = 0x10325476;
  var H4 = 0xC3D2E1F0;
  var A, B, C, D, E;
  var temp;
  msg = Utf8Encode(msg);
  var msg_len = msg.length;
  var word_array = new Array();
  for (i = 0; i < msg_len - 3; i += 4) {
    j = msg.charCodeAt(i) << 24 | msg.charCodeAt(i + 1) << 16 |
      msg.charCodeAt(i + 2) << 8 | msg.charCodeAt(i + 3);
    word_array.push(j);
  }
  switch (msg_len % 4) {
    case 0:
      i = 0x080000000;
      break;
    case 1:
      i = msg.charCodeAt(msg_len - 1) << 24 | 0x0800000;
      break;
    case 2:
      i = msg.charCodeAt(msg_len - 2) << 24 | msg.charCodeAt(msg_len - 1) << 16 | 0x08000;
      break;
    case 3:
      i = msg.charCodeAt(msg_len - 3) << 24 | msg.charCodeAt(msg_len - 2) << 16 | msg.charCodeAt(msg_len - 1) << 8 | 0x80;
      break;
  }
  word_array.push(i);
  while ((word_array.length % 16) != 14) word_array.push(0);
  word_array.push(msg_len >>> 29);
  word_array.push((msg_len << 3) & 0x0ffffffff);
  for (blockstart = 0; blockstart < word_array.length; blockstart += 16) {
    for (i = 0; i < 16; i++) W[i] = word_array[blockstart + i];
    for (i = 16; i <= 79; i++) W[i] = rotate_left(W[i - 3] ^ W[i - 8] ^ W[i - 14] ^ W[i - 16], 1);
    A = H0;
    B = H1;
    C = H2;
    D = H3;
    E = H4;
    for (i = 0; i <= 19; i++) {
      temp = (rotate_left(A, 5) + ((B & C) | (~B & D)) + E + W[i] + 0x5A827999) & 0x0ffffffff;
      E = D;
      D = C;
      C = rotate_left(B, 30);
      B = A;
      A = temp;
    }
    for (i = 20; i <= 39; i++) {
      temp = (rotate_left(A, 5) + (B ^ C ^ D) + E + W[i] + 0x6ED9EBA1) & 0x0ffffffff;
      E = D;
      D = C;
      C = rotate_left(B, 30);
      B = A;
      A = temp;
    }
    for (i = 40; i <= 59; i++) {
      temp = (rotate_left(A, 5) + ((B & C) | (B & D) | (C & D)) + E + W[i] + 0x8F1BBCDC) & 0x0ffffffff;
      E = D;
      D = C;
      C = rotate_left(B, 30);
      B = A;
      A = temp;
    }
    for (i = 60; i <= 79; i++) {
      temp = (rotate_left(A, 5) + (B ^ C ^ D) + E + W[i] + 0xCA62C1D6) & 0x0ffffffff;
      E = D;
      D = C;
      C = rotate_left(B, 30);
      B = A;
      A = temp;
    }
    H0 = (H0 + A) & 0x0ffffffff;
    H1 = (H1 + B) & 0x0ffffffff;
    H2 = (H2 + C) & 0x0ffffffff;
    H3 = (H3 + D) & 0x0ffffffff;
    H4 = (H4 + E) & 0x0ffffffff;
  }
  return [H0, H1, H2, H3, H4]
}

Hashcash.hexSha1 = function(msg) {
  var array = Hashcash.sha1(msg)
  var cvt_hex = Hashcash.sha1.cvt_hex
  return cvt_hex(array[0]) + cvt_hex(array[1]) + cvt_hex(array[2]) + cvt_hex(array3) + cvt_hex(array[4])
}

Hashcash.sha1.rotate_left = function(n, s) {
  var t4 = (n << s) | (n >>> (32 - s));
  return t4;
};

Hashcash.sha1.lsb_hex = function(val) {
  var str = '';
  var i;
  var vh;
  var vl;
  for (i = 0; i <= 6; i += 2) {
    vh = (val >>> (i * 4 + 4)) & 0x0f;
    vl = (val >>> (i * 4)) & 0x0f;
    str += vh.toString(16) + vl.toString(16);
  }
  return str;
};

Hashcash.sha1.cvt_hex = function(val) {
  var str = '';
  var i;
  var v;
  for (i = 7; i >= 0; i--) {
    v = (val >>> (i * 4)) & 0x0f;
    str += v.toString(16);
  }
  return str;
};

Hashcash.sha1.Utf8Encode = function(string) {
  string = string.replace(/\r\n/g, '\n');
  var utftext = '';
  for (var n = 0; n < string.length; n++) {
    var c = string.charCodeAt(n);
    if (c < 128) {
      utftext += String.fromCharCode(c);
    } else if ((c > 127) && (c < 2048)) {
      utftext += String.fromCharCode((c >> 6) | 192);
      utftext += String.fromCharCode((c & 63) | 128);
    } else {
      utftext += String.fromCharCode((c >> 12) | 224);
      utftext += String.fromCharCode(((c >> 6) & 63) | 128);
      utftext += String.fromCharCode((c & 63) | 128);
    }
  }
  return utftext;
};

Hashcash.setup()
