const std = @import("std");
const main_app = @import("../../../app.zig");
const debug = @import("../../../debug.zig");
// const gfx = @import("graphics.zig");
const input = @import("../../input.zig");
// const modules = @import("../modules.zig");

const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sgapp = sokol.app_gfx_glue;

pub const SokolAppConfig = struct {
    on_init_fn: *const fn () void,
    on_frame_fn: *const fn () void,
    on_cleanup_fn: *const fn () void,
    // maybe an on_event fn?
};

// keep a static version of the app around
var app: App = undefined;

pub const App = struct {
    on_init_fn: *const fn () void,
    on_frame_fn: *const fn () void,
    on_cleanup_fn: *const fn () void,

    pub fn init(cfg: SokolAppConfig) void {
        debug.log("Creating Sokol App backend", .{});

        app = App{
            .on_init_fn = cfg.on_init_fn,
            .on_frame_fn = cfg.on_frame_fn,
            .on_cleanup_fn = cfg.on_cleanup_fn,
        };
    }

    pub fn deinit() void {
        debug.log("Sokol App Backend stopping", .{});
    }

    export fn sokol_init() void {
        debug.log("Sokol app context initializing", .{});

        sg.setup(.{
            .context = sgapp.context(),
            .logger = .{ .func = slog.func },
            .buffer_pool_size = 256, // default is 128
        });

        debug.log("Sokol setup backend: {}\n", .{sg.queryBackend()});

        // call the callback that will tell everything else to start up
        app.on_init_fn();
    }

    export fn sokol_cleanup() void {
        app.on_cleanup_fn();
        sg.shutdown();
    }

    export fn sokol_frame() void {
        app.on_frame_fn();
    }

    export fn sokol_input(event: ?*const sapp.Event) void {
        const ev = event.?;
        if (ev.type == .MOUSE_DOWN) {
            input.onMouseDown(@intFromEnum(ev.mouse_button));
        } else if (ev.type == .MOUSE_UP) {
            input.onMouseUp(@intFromEnum(ev.mouse_button));
        } else if (ev.type == .MOUSE_MOVE) {
            input.onMouseMoved(ev.mouse_x, ev.mouse_y, ev.mouse_dx, ev.mouse_dy);
        } else if (ev.type == .KEY_DOWN) {
            input.onKeyDown(@intFromEnum(ev.key_code));
        } else if (ev.type == .KEY_UP) {
            input.onKeyUp(@intFromEnum(ev.key_code));
        } else if (ev.type == .CHAR) {
            input.onKeyChar(ev.char_code);
        }
    }

    pub fn startMainLoop(config: main_app.AppConfig) void {
        sapp.run(.{
            .init_cb = sokol_init,
            .frame_cb = sokol_frame,
            .cleanup_cb = sokol_cleanup,
            .event_cb = sokol_input,
            .width = config.width,
            .height = config.height,
            .icon = .{
                .sokol_default = true,
            },
            .window_title = config.title,
            .logger = .{
                .func = slog.func,
            },
            .win32_console_attach = true,
        });
    }

    pub fn getWidth() i32 {
        return sapp.width();
    }

    pub fn getHeight() i32 {
        return sapp.height();
    }

    pub fn captureMouse(captured: bool) void {
        sapp.lockMouse(captured);
    }
};
