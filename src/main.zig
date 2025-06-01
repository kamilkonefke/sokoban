const std = @import("std");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

var map: [8][8]u8 = undefined;

const Player = struct {
    x: i8,
    y: i8
};
var player: Player = .{ .x = 1, .y = 1 };

fn load_map() ![]const u8 {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);

    if (args.len != 2) {
        return "";
    }

    return args[1];
}

fn generate_map() !void {
    for(0..8) |y| {
        for(0..8) |x| {
            map[y][x] = 0;
        }
    }

    map[5][5] = 2;
    map[6][2] = 1;
}

fn render_map() !void {
    for(0..8) |y| {
        for(0..8) |x| {
            var char = switch(map[y][x]) {
                0 => ".", // Air
                1 => "X", // Wall
                2 => "#", // Box
                else => "."
            };

            if (player.x == x and player.y == y) {
                char = "@";
            }

            try stdout.print("{s}", .{ char });
        }
        try stdout.print("\n", .{});
    }
}

fn render_statusbar() !void {
    try stdout.print("Sokoban!\n", .{});
}

fn push_box(x: i8, y: i8, dx: i8, dy: i8) void {
    const xx: usize = @intCast(x);
    const yy: usize = @intCast(y);
    const dxx: usize = @intCast(dx);
    const dyy: usize = @intCast(dy);

    if (map[yy][xx] == 2) {
        map[yy][xx] = 0;
        map[yy + dyy][xx + dxx] = 2;
    }
}

fn is_cell_empty(x: i8, y: i8) bool {
    const xx: usize = @intCast(x);
    const yy: usize = @intCast(y);
    if (map[yy][xx] == 1) {
        return false;
    } else {
        return false;
    }
}

fn player_move(dx: i8, dy: i8) {
    if(is_cell_empty(dx, dy)) {

    } else {

    }
}

pub fn main() !void {
    // const map_name = try load_map();

    // enter raw mode
    const tty_backup = try std.posix.tcgetattr(std.posix.STDIN_FILENO);
    defer std.posix.tcsetattr(std.posix.STDIN_FILENO, .FLUSH, tty_backup) catch {}; // restore tty

    _ = try stdout.writeAll("\x1b[?25l"); // hide cursor
    defer _ = std.io.getStdOut().write("\x1b[?25h") catch {};

    var tty_raw = tty_backup;
    tty_raw.lflag.ECHO = false;
    tty_raw.lflag.ICANON = false;
    try std.posix.tcsetattr(std.posix.STDIN_FILENO, .FLUSH, tty_raw);

    try generate_map();

    var input_buffer: [1]u8 = undefined;
    while (true) {
        // Rendering
        try stdout.writeAll("\x1B[2J\x1B[H");
        try render_statusbar();
        try render_map();

        // Input
        _ = try stdin.read(&input_buffer);
        switch (input_buffer[0]) {
            'w' => {
                if (is_cell_empty(player.x, player.y - 1)) {
                    player.y -= 1;
                }
            },
            's' => {
                if (is_cell_empty(player.x, player.y + 1)) {
                    player.y += 1;
                }
            },
            'a' => {
                if (is_cell_empty(player.x - 1, player.y)) {
                    player.x -= 1;
                }
            },
            'd' => {
                if (is_cell_empty(player.x + 1, player.y)) {
                    player.x += 1;
                }
            },
            'q' => return,
            else => {}
        }

        std.time.sleep(17 * std.time.ns_per_ms);
    }
}
