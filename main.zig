const std = @import("std");
const tree = @import("tree.zig");
const minimax = tree.minimax;
const SoulTable = tree.SoulTable;
const brd = @import("board.zig");
const pos_from_view = brd.pos_from_view;
const soul_from_pos = brd.soul_from_pos;
const pos_status = brd.pos_status;
const draw = brd.pos_draw;
const UNRESOLVED = brd.UNRESOLVED;

pub fn make_good_move(
    board: *[9]i8,
    player: i8,
    souls: *const SoulTable,
) void {
    var extreme_score: i8 = if (player > 0) -99 else 99;
    var extreme_child: usize = undefined;
    var score: i8 = undefined;
    var child: [9]i8 = undefined;
    for (0..9) |p| {
        if (board[p] != 0) continue;
        child = board.*;
        child[p] = player;
        score = souls.get_score_from_pos(&child);
        if ((player > 0 and score > extreme_score) or
            (player < 0 and score < extreme_score))
        {
            extreme_score = score;
            extreme_child = p;
        }
    }
    board[extreme_child] = player;
}

// player +1 = black, -1 = white
pub fn ask_move(bw: anytype, r: anytype, msg_buf: *[64]u8, board: *[9]i8, player: i8) !void {
    while (true) {
        const w = bw.writer();
        try w.print("Select your move: ", .{});
        try bw.flush();
        var msg: ?[]u8 = try r.readUntilDelimiterOrEof(msg_buf, '\n');
        var b = msg orelse continue;
        if (b.len <= 0) continue;
        var c: usize = b[0];
        if (c == '0' or c == 'q' or c == 'Q' or c == 'u' or c == 'U') c = 0;
        if (c == '1' or c == 'w' or c == 'W' or c == 'i' or c == 'I') c = 1;
        if (c == '2' or c == 'e' or c == 'E' or c == 'o' or c == 'O') c = 2;
        if (c == '3' or c == 'a' or c == 'A' or c == 'j' or c == 'J') c = 3;
        if (c == '4' or c == 's' or c == 'S' or c == 'k' or c == 'K') c = 4;
        if (c == '5' or c == 'd' or c == 'D' or c == 'l' or c == 'L') c = 5;
        if (c == '6' or c == 'z' or c == 'Z' or c == 'm' or c == 'M') c = 6;
        if (c == '7' or c == 'x' or c == 'X' or c == ',' or c == '<') c = 7;
        if (c == '8' or c == 'c' or c == 'C' or c == '.' or c == '>') c = 8;
        if (c > 8 or board[c] != 0) continue;
        board[c] = player;
        try w.print("\n", .{});
        try bw.flush();
        break;
    }
}

pub fn ask_player(bw: anytype, r: anytype, msg_buf: *[64]u8) !i8 {
    while (true) {
        const w = bw.writer();
        try w.print("Play first as X?: ", .{});
        try bw.flush();
        var msg = try r.readUntilDelimiterOrEof(msg_buf, '\n');
        if (msg) |m| {
            try w.print("You have selected {s}\n", .{m});
        }
        try bw.flush();
        var b = msg orelse continue;
        if (b.len <= 0) continue;
        var c: usize = b[0];
        if (c == 'y' or c == 'Y' or c == 'j' or c == 'J' or
            c == 'b' or c == 'B' or c == 'x' or c == 'X')
        {
            try w.print("\n", .{});
            try bw.flush();
            return 1;
        }
        if (c == 'n' or c == 'N' or
            c == 'w' or c == 'W' or c == 'o' or c == 'O')
        {
            try w.print("\n", .{});
            try bw.flush();
            return -1;
        }
    }
}

pub fn main() !void {
    const stdout = std.io.getStdOut();
    var bw = std.io.bufferedWriter(stdout.writer());
    const w = bw.writer();
    const stdin = std.io.getStdIn();
    var br = std.io.bufferedReader(stdin.reader());
    var r = br.reader();
    var msg_buf: [64]u8 = undefined;

    const human: i8 = try ask_player(&bw, &r, &msg_buf);
    var souls: SoulTable = SoulTable{};
    var board = pos_from_view(0);
    _ = minimax(&board, false, &souls);

    if (human == 1) draw(&board);

    var player: i8 = 1;
    while (true) {
        if (human == player) {
            try ask_move(&bw, &r, &msg_buf, &board, player);
        } else {
            make_good_move(&board, player, &souls);
        }
        draw(&board);
        var status = pos_status(&board);
        if (status != UNRESOLVED) {
            if (status == 0) {
                try w.print("It's a tie!\n", .{});
            } else if (status > 0) {
                try w.print("Black X won!\n", .{});
            } else if (status < 0) {
                try w.print("White O won!\n", .{});
            }
            try bw.flush();
            break;
        }
        player *= -1;
    }
}
