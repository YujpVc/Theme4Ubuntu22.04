const Main = imports.ui.main; 
const { Gio, GLib, Meta, Shell, St } = imports.gi; 

let timeoutId = null; 
let g_focus_window = null; 
let g_wm_title = null; 
let skip_time = 0; 
let max_skip_time = 5; 

const connection = Gio.DBus.session; 

function _hideHello() { 
        if (timeoutId != null) 
        { 
                GLib.Source.remove(timeoutId); 
                timeoutId = null; 
        } 
        g_focus_window = null;        
} 

function _showHello() { 
    _hideHello(); 

    timeoutId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, () => { 
        let focus_window = global.display.get_focus_window(); 
        if (focus_window == null || (focus_window == g_focus_window && focus_window.title == g_wm_title && skip_time < max_skip_time)) 
        { 
            skip_time++; 
            return GLib.SOURCE_CONTINUE; 
        } 
        
        skip_time = 0; 
        
        let apps = Shell.AppSystem.get_default().get_running();  
        for (let app of apps) 
        { 
            let windows = app.get_windows(); 
            for (let window of windows) 
            { 
                if (window != focus_window) continue; 
                
                let pids = app.get_pids(); 
                let outStr = "[" + pids[0]; 
                
                if (pids[0] == -1) 
                { 
                    outStr += "," + window.gtk_application_id; 
                } 
                
                outStr += ']'; 
                
                const notification = new GLib.Variant('(ss)', [outStr, window.title]); 
            const value1 = notification.get_child_value(0); 
            const str = value1.get_string(); 
            connection.call( 
                'org.gnome.TecCustomization', 
                '/org/gnome/TecCustomization', 
                'org.gnome.TecCustomization', 
                'GetFocusWMInfo', 
                notification, 
                null, 
                Gio.DBusCallFlags.NONE, 
                -1, 
                null, 
                (connection, res) => { 
                try { 
                    const reply = connection.call_finish(res); 
                    
                    g_focus_window = focus_window; 
                    g_wm_title = window.title; 
                } catch (e) { 
                    g_focus_window = null; 
                    g_wm_title = null; 
                    if (e instanceof Gio.DBusError) 
                    Gio.DBusError.strip_remote_error(e); 
                    
                    logError(e); 
                } 
                } 
            ); 
            } 
        } 
        
        return GLib.SOURCE_CONTINUE; 
    }); 
} 

function init() { 

} 

function enable() { 
    _showHello(); 
} 

function disable() { 
    _hideHello(); 
} 

