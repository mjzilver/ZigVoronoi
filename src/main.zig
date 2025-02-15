const std = @import("std");
const rl = @import("raylib");
const RndGen = std.rand.DefaultPrng;

const Point = struct { x: u16, y: u16, color: rl.Color };
const PointList = std.ArrayList(Point);
const defaultColor = rl.Color{
    .r = 0,
    .g = 0,
    .b = 0,
    .a = 255,
};

pub fn main() anyerror!void {
    const screenWidth = 800;
    const screenHeight = 800;

    rl.initWindow(screenWidth, screenHeight, "Voronoi");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var points = std.ArrayList(Point).init(allocator);
    defer points.deinit();

    var points_buffer = std.ArrayList(Point).init(allocator);
    defer points_buffer.deinit();

    var rnd = std.rand.DefaultPrng.init(@intCast(std.time.timestamp()));
    const random = rnd.random();

    for (0..2) |_| {
        points.append(make_random_point(random)) catch unreachable;
    }

    while (!rl.windowShouldClose()) {
        if (rl.isMouseButtonReleased(rl.MouseButton.left)) {
            const p = Point{ .x = @intCast(rl.getMouseX()), .y = @intCast(rl.getMouseY()), .color = random_color(random) };

            std.debug.print("Clicked!", .{});

            points.append(p) catch |err| {
                std.debug.print("{}", .{err});
            };
        }

        if (rl.isKeyReleased(rl.KeyboardKey.up)) {
            std.debug.print("Up was pressed\n", .{});
            points.append(make_random_point(random)) catch unreachable;
        }

        if (rl.isKeyReleased(rl.KeyboardKey.down)) {
            std.debug.print("Down was pressed\n", .{});
            _ = points.orderedRemove(random.uintLessThan(usize, points.items.len));
        }

        render(&points);
    }
}

pub fn render(points: *PointList) void {
    const start_time = std.time.milliTimestamp();
    rl.beginDrawing();

    for (0..800) |ux| {
        for (0..800) |uy| {
            const x: i32 = @intCast(ux);
            const y: i32 = @intCast(uy);
            const color = get_closest_point(x, y, points).color;
            rl.drawPixel(x, y, color);
        }
    }

    for (points.items) |p| {
        rl.drawCircle(p.x, p.y, 5, defaultColor);
    }

    rl.endDrawing();

    const end_time = std.time.milliTimestamp();
    const elapsed_time = end_time - start_time;
    std.debug.print("Frame time: {} millisecs\n", .{elapsed_time});
}

pub fn get_closest_point(x: i32, y: i32, points: *PointList) Point {
    if (points.items.len < 1) {
        return Point{
            .x = 0,
            .y = 0,
            .color = defaultColor,
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

pub fn make_random_point(random: std.Random) Point {
    return Point{ .x = random.uintLessThan(u16, 800), .y = random.uintLessThan(u16, 800), .color = random_color(random) };
}

pub fn random_color(rand: std.Random) rl.Color {
    return rl.Color{ .r = rand.uintLessThan(u8, 255), .g = rand.uintLessThan(u8, 255), .b = rand.uintLessThan(u8, 255), .a = 255 };
}
