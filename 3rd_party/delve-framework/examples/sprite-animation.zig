const std = @import("std");
const delve = @import("delve");
const app = delve.app;

const batcher = delve.graphics.batcher;
const debug = delve.debug;
const colors = delve.colors;
const images = delve.images;
const graphics = delve.platform.graphics;
const input = delve.platform.input;
const papp = delve.platform.app;
const math = delve.math;
const modules = delve.modules;
const sprites = delve.graphics.sprites;

const Color = colors.Color;
const Rect = delve.spatial.Rect;

var shader_default: graphics.Shader = undefined;

var sprite_texture: graphics.Texture = undefined;
var sprite_sheet: delve.graphics.sprites.AnimatedSpriteSheet = undefined;
var sprite_animation: delve.graphics.sprites.PlayingAnimation = undefined;

var sprite_batch: batcher.SpriteBatcher = undefined;

var loop_delay_time: f32 = 0.0;

// This example shows how to draw animated sprites out of a sprite sheet

pub fn main() !void {
    try registerModule();
    try app.start(app.AppConfig{ .title = "Delve Framework - Animated Sprite" });
}

pub fn registerModule() !void {
    const animationExample = modules.Module{
        .name = "animated_sprite_example",
        .init_fn = on_init,
        .tick_fn = on_tick,
        .draw_fn = on_draw,
        .cleanup_fn = on_cleanup,
    };

    try modules.registerModule(animationExample);
}

pub fn on_init() void {
    debug.log("Sprite animation example module initializing", .{});

    sprite_batch = batcher.SpriteBatcher.init(.{}) catch {
        debug.showErrorScreen("Fatal error during batch init!");
        return;
    };

    var spritesheet_image = images.loadFile("sprites/cat-anim-sheet.png") catch {
        debug.log("Could not load image", .{});
        return;
    };
    defer spritesheet_image.deinit();

    // make the texture to draw and a default shader
    sprite_texture = graphics.Texture.init(&spritesheet_image);
    shader_default = graphics.Shader.initDefault(.{});

    // create a set of animations from our sprite sheet
    sprite_sheet = delve.graphics.sprites.AnimatedSpriteSheet.initFromGrid(1, 32, "cat_") catch {
        debug.log("Could not create sprite sheet!", .{});
        return;
    };

    // add an extra long delay to a sleeping frame
    var anim = sprite_sheet.entries.getPtr("cat_0").?;
    anim.frames[29].duration = 24.0;

    // get and start the first animation
    sprite_animation = sprite_sheet.playAnimation("cat_0").?;
    sprite_animation.play();
    sprite_animation.setSpeed(16.0);

    graphics.setClearColor(colors.examples_bg_light);
}

pub fn on_tick(deltatime: f32) void {
    // advance the animation
    sprite_animation.tick(deltatime);

    if (input.isKeyJustPressed(.ESCAPE)) {
        std.os.exit(0);
    }
}

pub fn on_draw() void {
    const cur_frame = sprite_animation.getCurrentFrame();

    // clear the batch for this frame
    sprite_batch.reset();

    // make sure we are using the right shader and texture
    sprite_batch.useShader(shader_default);
    sprite_batch.useTexture(sprite_texture);

    // add our sprite rectangle
    const rect = Rect.new(cur_frame.offset, cur_frame.size);
    sprite_batch.addRectangle(rect.centered(), cur_frame.region, colors.white);

    // apply the batch to make it ready to draw!
    sprite_batch.apply();

    // setup our view to draw with
    const projection = graphics.getProjectionPerspective(60, 0.01, 20.0);
    const view = math.Mat4.lookat(.{ .x = 0.0, .y = 0.0, .z = 5.0 }, math.Vec3.zero(), math.Vec3.up());

    // draw the sprite batch
    sprite_batch.draw(projection.mul(view), math.Mat4.identity());
}

pub fn on_cleanup() void {
    debug.log("Sprite animation example module cleaning up", .{});
    sprite_texture.destroy();
    sprite_batch.deinit();
    shader_default.destroy();
}
