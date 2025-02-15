const std = @import("std");
const rl = @import("raylib");
const RndGen = std.rand.DefaultPrng;

const Point = struct {
    x: u16,
    y: u16,
    color: rl.Color,
};

const PointList = std.ArrayList(Point);

const pointColor = rl.Color.black;
const pointRadius = 5;
const startPointAmount = 5;
const screenWidth = 800;
const screenHeight = 800;

pub fn main() anyerror!void {
    rl.initWindow(screenWidth, screenHeight, "Voronoi");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var points = std.ArrayList(Point).init(allocator);
    defer points.deinit();

    var rnd = std.rand.DefaultPrng.init(@intCast(std.time.timestamp()));
    const random = rnd.random();

    for (0..startPointAmount) |_| {
        points.append(make_random_point(random)) catch unreachable;
    }

    var image = generate_image(&points);
    const texture = rl.loadTextureFromImage(image) catch unreachable;
    rl.unloadImage(image);

    var needs_update = true;

    while (!rl.windowShouldClose()) {
        if (handle_input(&points, &random)) {
            needs_update = true;
        }

        if (needs_update) {
            image = generate_image(&points);
            rl.updateTexture(texture, image.data);
            rl.unloadImage(image);
            needs_update = false;
        }

        rl.beginDrawing();
        rl.drawTexture(texture, 0, 0, rl.Color.white);
        rl.drawFPS(10, 10);
        rl.endDrawing();
    }

    rl.unloadTexture(texture);
}

fn handle_input(points: *PointList, random: *const std.Random) bool {
    if (rl.isMouseButtonReleased(rl.MouseButton.left)) {
        const p = Point{
            .x = @intCast(rl.getMouseX()),
            .y = @intCast(rl.getMouseY()),
            .color = random_color(random.*),
        };

        points.append(p) catch unreachable;
        return true;
    }

    if (rl.isKeyReleased(rl.KeyboardKey.up)) {
        points.append(make_random_point(random.*)) catch unreachable;
        return true;
    }

    if (rl.isKeyReleased(rl.KeyboardKey.down)) {
        if (points.items.len > 0) {
            _ = points.orderedRemove(random.uintLessThan(usize, points.items.len));
            return true;
        }
    }
    return false;
}

fn generate_image(points: *PointList) rl.Image {
    var image = rl.genImageColor(
        screenWidth,
        screenHeight,
        rl.Color{
            .r = 0,
            .g = 0,
            .b = 0,
            .a = 255,
        },
    );

    for (0..screenHeight) |uy| {
        for (0..screenWidth) |ux| {
            const x: i32 = @intCast(ux);
            const y: i32 = @intCast(uy);
            const color = get_closest_point(x, y, points).color;

            rl.imageDrawPixel(&image, x, y, color);
        }
    }

    for (points.items) |p| {
        rl.imageDrawCircle(
            &image,
            p.x,
            p.y,
            pointRadius,
            pointColor,
        );
    }

    return image;
}

fn get_closest_point(x: i32, y: i32, points: *PointList) Point {
    // draw a black screen if there are 0 points
    if (points.items.len == 0) {
        return Point{
            .x = 0,
            .y = 0,
            .color = pointColor,
        };
    }
    var found_closest = points.items[0];
    var shortest_dist = std.math.floatMax(f32);

    for (points.items) |p| {
        const deltaX = p.x - x;
        const deltaY = p.y - y;

        const squared_distance = deltaX * deltaX + deltaY * deltaY;
        const dist = std.math.sqrt(@as(f32, @floatFromInt(squared_distance)));

        if (dist < shortest_dist) {
            found_closest = p;
            shortest_dist = dist;
        }
    }
    return found_closest;
}

fn make_random_point(random: std.Random) Point {
    return Point{
        .x = random.uintLessThan(u16, 800),
        .y = random.uintLessThan(u16, 800),
        .color = random_color(random),
    };
}

fn random_color(rand: std.Random) rl.Color {
    return rl.Color{
        .r = rand.uintLessThan(u8, 255),
        .g = rand.uintLessThan(u8, 255),
        .b = rand.uintLessThan(u8, 255),
        .a = 255,
    };
}
