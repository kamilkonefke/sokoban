const std = @import("std");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

var map: [8][8]u8 = undefined;

const Player = struct {
    stars: i8,
    moves: i8,
    x: i8,
    y: i8
};
var player: Player = .{ .x = 1, .y = 1, .stars = 0, .moves = 50 };

fn load_map() ![]const u8 {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);

    if (args.len != 2) {
        return "";
    }

    return args[1];

    // TODO: FILE FORMAT FOR MAPS
}

fn generate_map() !void {
    for(0..8) |y| {
        for(0..8) |x| {
            map[y][x] = 0;
        }
    }

    // for testing
    map[5][5] = 2;
    map[5][6] = 2;

    map[5][2] = 1;
    map[6][2] = 1;
    map[7][2] = 1;

    map[1][6] = 3;
}

fn restart_game() void {
    try generate_map();
    player = .{ .x = 1, .y = 1, .stars = 0, .moves = 50 };
}

fn render_map() !void {
    for(0..8) |y| {
        for(0..8) |x| {
            var char = switch(map[y][x]) {
                0 => ". ", // Air
                1 => "X ", // Wall
                2 => "# ", // Box
                3 => "* ", // Star
                else => " "
            };

            if (player.x == x and player.y == y) {
                char = "@ ";
            }

            try stdout.print("{s}", .{ char });
        }
        try stdout.print("\n", .{});
    }
}

fn render_statusbar() !void {
    try stdout.print("W|S|A|D - move \nR - restart\n", .{});
    try stdout.print("Moves: {d} - Stars: {d}\n", .{ player.moves, player.stars });
}

fn player_move(dx: i8, dy: i8) void {
    // wtf
    const xi: isize = @intCast(player.x + dx);
    const yi: isize = @intCast(player.y + dy);

    if (xi < 0 or yi < 0 or
        xi >= 8 or yi >= 8) {
        return;
    }

    const xu: usize = @intCast(xi);
    const yu: usize = @intCast(yi);

    // check for cell type
    switch(map[yu][xu]) {
        0 => {
            // move player
            if (player.moves > 0) {
                player.x += dx;
                player.y += dy;
                player.moves -= 1;
            } else {
                restart_game();
            }
        },
        1 => {},
        2 => {
            // move box
            const box_xi: isize = @intCast(xi + dx);
            const box_yi: isize = @intCast(yi + dy);

            if (box_xi < 0 or box_yi < 0 or
                box_xi >= 8 or box_yi >= 8) {
                return;
            }

            const bx: usize = @intCast(box_xi);
            const by: usize = @intCast(box_yi);

            if (map[by][bx] != 0) {
                return;
            }

            map[yu][xu] = 0;
            map[by][bx] = 2;

            player.x += dx;
            player.y += dy;

            player.moves -= 1;
        },
        3 => {
            map[yu][xu] = 0;
            player.stars += 1;

            player.x += dx;
            player.y += dy;
            
            player.moves -= 1;
        },
        else => {}
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
            'w' => player_move(0, -1),
            's' => player_move(0, 1),
            'a' => player_move(-1, 0),
            'd' => player_move(1, 0),
            'r' => restart_game(),
            'q' => return,
            else => {},
        }

        std.time.sleep(33 * std.time.ns_per_ms);
    }
}
