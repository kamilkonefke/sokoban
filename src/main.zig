const std = @import("std");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

var map: [][]u8 = undefined;

pub fn main() !void {
    // enter raw mode
    const tty_backup = try std.posix.tcgetattr(std.posix.STDIN_FILENO);
    defer std.posix.tcsetattr(std.posix.STDIN_FILENO, .FLUSH, tty_backup) catch {}; // restore tty

    _ = try stdout.writeAll("\x1b[?25l"); // hide cursor
    defer _ = std.io.getStdOut().write("\x1b[?25h") catch {};

    var tty_raw = tty_backup;
    tty_raw.lflag.ECHO = false;
    tty_raw.lflag.ICANON = false;
    try std.posix.tcsetattr(std.posix.STDIN_FILENO, .FLUSH, tty_raw);

    var input_buffer: [1]u8 = undefined;
    while (true) {
        // Rendering
        try stdout.writeAll("\x1B[2J\x1B[H");

        // Input
        _ = try stdin.read(&input_buffer);
        switch (input_buffer[0]) {
            'q' => return,
            else => {}
        }

        std.time.sleep(17 * std.time.ns_per_ms);
    }
}
