'use strict';

const Clutter = imports.gi.Clutter;
const Gio = imports.gi.Gio;
const St = imports.gi.St;
const Main = imports.ui.main;
const Util = imports.misc.util;
const Me = imports.misc.extensionUtils.getCurrentExtension();

let icon = null;

function enable() {
    icon = new St.Icon({
        gicon: Gio.icon_new_for_string(Me.path + '/ubuntu-white.svg'),
        icon_size: 24,
        style_class: 'panel-button',
        reactive: true,
        track_hover: true,
        x_expand: false,
        y_align: Clutter.ActorAlign.CENTER,
    });
    icon.add_style_class_name('panel-status-menu-box');
    icon.connect('button-press-event', () => {
        Util.spawnCommandLine('gnome-control-center');
        return Clutter.EVENT_STOP;
    });
    Main.panel._leftBox.insert_child_at_index(icon, 0);
}

function disable() {
    if (icon) {
        icon.destroy();
        icon = null;
    }
}
