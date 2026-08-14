const ExtensionUtils = imports.misc.extensionUtils;
const Me = ExtensionUtils.getCurrentExtension();

'use strict';

const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;

const pointer_wrapper = {
  get_position: () => {
    let [px, py] = global.get_pointer();
    return [{}, px, py];
  },
  warp: (screen, x, y) => {
    screen.simulated_pointer = [x, y];
  },
};

/**
 * Return a path in /tmp folder with a unique name
 * @param {*} path
 * @returns {string}
 */
var tempPath = (path) => {
  let uuid = GLib.get_user_name(); // Main.overview.d2dl.uuid;
  return `/tmp/${uuid}-${path}`;
};

var getPointer = () => {
  return pointer_wrapper;
};

var warpPointer = (pointer, x, y, extension) => {
  pointer.warp(extension, x, y);
};

var setTimeout = (func, delay, ...args) => {
  const wrappedFunc = () => {
    func.apply(this, args);
  };
  return GLib.timeout_add(GLib.PRIORITY_DEFAULT, delay, wrappedFunc);
};

var setInterval = (func, delay, ...args) => {
  const wrappedFunc = () => {
    return func.apply(this, args) || true;
  };
  return GLib.timeout_add(GLib.PRIORITY_DEFAULT, delay, wrappedFunc);
};

var clearTimeout = (id) => {
  GLib.source_remove(id);
};

var clearInterval = (id) => {
  GLib.source_remove(id);
};

var get_distance_sqr = (pos1, pos2) => {
  let a = pos1[0] - pos2[0];
  let b = pos1[1] - pos2[1];
  return a * a + b * b;
};

var get_distance = (pos1, pos2) => {
  return Math.sqrt(get_distance_sqr(pos1, pos2));
};

var isOverlapRect = (r1, r2) => {
  let [r1x, r1y, r1w, r1h] = r1;
  let [r2x, r2y, r2w, r2h] = r2;
  // are the sides of one rectangle touching the other?
  if (
    r1x + r1w >= r2x && // r1 right edge past r2 left
    r1x <= r2x + r2w && // r1 left edge past r2 right
    r1y + r1h >= r2y && // r1 top edge past r2 bottom
    r1y <= r2y + r2h
  ) {
    // r1 bottom edge past r2 top
    return true;
  }
  return false;
};

var isInRect = (r, p, pad) => {
  let [x1, y1, w, h] = r;
  let x2 = x1 + w;
  let y2 = y1 + h;
  let [px, py] = p;
  return px + pad >= x1 && px - pad < x2 && py + pad >= y1 && py - pad < y2;
};

var trySpawnCommandLine = function (cmd) {
  return new Promise((resolve, reject) => {
    try {
      GLib.spawn_command_line_async(cmd);
      resolve();
    } catch (err) {
      reject(err);
    }
  });
};


