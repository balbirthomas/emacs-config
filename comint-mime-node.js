// comint-mime-node.js -- comint-mime helper for a Node.js REPL
//
// Loaded into a running `node -i' REPL by `comint-mime-setup-js' (see
// lang-js.el) when `enable-comint-mime-js' is turned on. Not meant to
// be require()'d as a module -- it's read and eval()'d as one string
// (rather than passed to the REPL's own `.load' command, which would
// echo every line of it back into the buffer), so it runs in, and
// defines globals in, the REPL's own context.
//
// Defines the same OSC 5151 wire protocol as comint-mime's shell and
// Python helpers (comint-mime.sh, comint-mime.py, alongside
// comint-mime.el in https://github.com/astoff/comint-mime):
//
//     ESC ] 5151 ; {"type":"<mime-type>"} \n <base64-data> ESC \
//
// `mimecat' sends arbitrary data this way; `showCanvas' is a
// convenience wrapper for a node-canvas Canvas object (the `canvas'
// npm package -- Debian's node-canvas), sending its raster (or, for a
// canvas created with `createCanvas(w, h, "svg")', vector) output as
// an inline image in the Emacs buffer instead of the usual
// "Canvas {}" object dump.

global.mimecat = function mimecat(data, type) {
  const payload = Buffer.isBuffer(data) ? data.toString('base64') : data;
  const header = JSON.stringify({type: type});
  process.stdout.write('\x1b]5151;' + header + '\n' + payload + '\x1b\\');
};

global.showCanvas = function showCanvas(canvas, type) {
  type = type || 'image/png';
  mimecat(canvas.toBuffer(type), type);
};

console.log("`comint-mime' enabled: use showCanvas(canvas) or mimecat(buffer, type)");
