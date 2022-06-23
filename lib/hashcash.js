// http://www.hashcash.org/docs/hashcash.html
// <input type="hiden" name="hashcash" data-hashcash="{resource: 'site.example', bits: 16}"/>
Hashcash = function(input) {
  options = JSON.parse(input.getAttribute("data-hashcash"))
  Hashcash.disableParentForm(input, options)
  input.dispatchEvent(new CustomEvent("hashcash:mint", {bubbles: true}))
  Hashcash.mint(options.resource, options).then(function(stamp) {
    input.value = stamp.toString()
    Hashcash.enableParentForm(input, options)
    input.dispatchEvent(new CustomEvent("hashcash:minted", {bubbles: true, detail: {stamp: stamp}}))
  })
}

Hashcash.setup = function() {
  if (document.readyState != "loading") {
    var input = document.querySelector("input#hashcash")
    input && new Hashcash(input)
  } else
    document.addEventListener("DOMContentLoaded", Hashcash.setup )
}

Hashcash.disableParentForm = function(input, options) {
  input.form.querySelectorAll("[type=submit]").forEach(function(submit) {
    submit.originalValue = submit.value
    options["waiting_message"] && (submit.value = options["waiting_message"])
    submit.disabled = true
  })
}

Hashcash.enableParentForm = function(input, options) {
  input.form.querySelectorAll("[type=submit]").forEach(function(submit) {
    console.input
    submit.originalValue && (submit.value = submit.originalValue)
    submit.disabled = null
  })
}

Hashcash.default = {
  version: 1,
  bits: 20,
  extension: null,
  algorithm: "SHA-1",
}

Hashcash.mint = async function(resource, options = {}) {
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
  return stamp.work(options.algorithm || Hashcash.default.algorithm)
}

Hashcash.check = async function(string, algorithm = Hashcash.default.algorithm) {
  return await Hashcash.Stamp.parse(string).check(algorithm)
}

Hashcash.digest = async function(algorithm, string) {
  var text = new TextEncoder().encode(string)
  var buffer = await crypto.subtle.digest(algorithm, text)
  return new DataView(buffer)
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

Hashcash.Stamp.prototype.work = async function(algorithm = Hashcash.default.algorithm) {
  while (!await this.check())
    this.counter += 1
  var data = await Hashcash.digest(algorithm, this.toString())
  return this
}

Hashcash.Stamp.prototype.check = async function(algorithm = Hashcash.default.algorithm) {
  var data = await Hashcash.digest(algorithm, this.toString())
  return Math.clz32(data.getUint32(0, false)) >= this.bits // Force big endian
}

Hashcash.setup()
