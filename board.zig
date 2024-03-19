const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;
const utils = @import("util.zig");
const min2 = utils.min2;
const min3 = utils.min3;
pub const UNRESOLVED: i8 = -128;

fn str_from_i8(num: i8) []const u8 {
    return switch (num) {
        -1 => "O",
        0 => " ",
        1 => "X",
        else => unreachable,
    };
}

pub fn pos_draw(pos: *const [9]i8) void {
    print("{s} | {s} | {s}\n{s} | {s} | {s}\n{s} | {s} | {s}\n\n", .{
        str_from_i8(pos[0]), str_from_i8(pos[1]), str_from_i8(pos[2]),
        str_from_i8(pos[3]), str_from_i8(pos[4]), str_from_i8(pos[5]),
        str_from_i8(pos[6]), str_from_i8(pos[7]), str_from_i8(pos[8]),
    });
}

// returns the single value
// of sequence of all the same value (1 or -1)
// if 1 1 1 return 1
// else if -1 -1 -1 return -1
// else return -128
fn seq3u(a: i8, b: i8, c: i8) i8 {
    if (a == 0 or b == 0 or c == 0 or a != b or b != c) {
        return UNRESOLVED;
    }
    return a;
}

// tie is 0
// black win +1
// white win -1
pub fn pos_status(pos: *const [9]i8) i8 {
    // diagonal
    var check = seq3u(pos[0], pos[4], pos[8]);
    if (check != UNRESOLVED) return check;
    check = seq3u(pos[2], pos[4], pos[6]);
    if (check != UNRESOLVED) return check;

    // horizontal
    var p: u8 = 0;
    while (p < 9) : (p += 3) {
        check = seq3u(pos[p], pos[1 + p], pos[2 + p]);
        if (check != UNRESOLVED) return check;
    }

    // vertical
    p = 0;
    while (p < 3) : (p += 1) {
        check = seq3u(pos[p], pos[3 + p], pos[6 + p]);
        if (check != UNRESOLVED) return check;
    }

    // filled with no winner, tie)
    for (0..9) |m| {
        if (pos[m] == 0) break;
    } else return 0; // tie

    return UNRESOLVED;
}

pub fn pos_num_empty(pos: *const [9]i8) i8 {
    var cnt: i8 = 0;
    for (0..9) |m| {
        if (pos[m] == 0) cnt += 1;
    }
    return cnt;
}

pub fn pos_score(pos: *const [9]i8) i8 {
    var s = pos_status(pos);
    if (s == UNRESOLVED or s == 0) return s;
    return s * (pos_num_empty(pos) + 1);
}

// pos_reflect
// applies horizontal (left-right) reflection on itself
// 0 1 2       2 1 0
// 3 4 5  -->  5 4 3
// 6 7 8       8 7 6
pub fn pos_reflect(pos: *[9]i8) void {
    var tmp = pos[0];
    pos[0] = pos[2];
    pos[2] = tmp;
    tmp = pos[3];
    pos[3] = pos[5];
    pos[5] = tmp;
    tmp = pos[6];
    pos[6] = pos[8];
    pos[8] = tmp;
}

// reflect_pos
// returns new horizontal (left-right) reflection
// 0 1 2       2 1 0
// 3 4 5  -->  5 4 3
// 6 7 8       8 7 6
pub fn reflect_from_pos(pos: *const [9]i8) [9]i8 {
    return [_]i8{
        pos[2], pos[1], pos[0],
        pos[5], pos[4], pos[3],
        pos[8], pos[7], pos[6],
    };
}

// 0 1 2       6 3 0
// 3 4 5  -->  7 4 1
// 6 7 8       8 5 2
pub fn pos_rotate(pos: *[9]i8) void {
    var tmp = pos[0];
    pos[0] = pos[6];
    pos[6] = pos[8];
    pos[8] = pos[2];
    pos[2] = tmp; // 0
    tmp = pos[1];
    pos[1] = pos[3];
    pos[3] = pos[7];
    pos[7] = pos[5];
    pos[5] = tmp; // 1
}

pub fn pos_invert(pos: *[9]i8) void {
    for (0..9) |p| pos[p] *= -1;
}

pub fn invert_from_pos(pos: *const [9]i8) [9]i8 {
    return [_]i8{
        pos[0] * -1, pos[1] * -1, pos[2] * -1,
        pos[3] * -1, pos[4] * -1, pos[5] * -1,
        pos[6] * -1, pos[7] * -1, pos[8] * -1,
    };
}

// pub fn transform(self: *Board, transType: u3) void {
//     for (0..(transType & 0b11)) |_| self.rotate();
//     if ((transType >> 2) & 1) self.reflect();
//     //if ((transType >> 3) & 1) self.invert();
// }

// A view is compressed representation of a board
// from a specific perspective. Reflection and
// rotation may produce different board views
// with the same soul.
pub fn view_from_pos(pos: *const [9]i8) u16 {
    var h: u16 = 0;
    var m: u16 = 1;
    for (0..9) |p| {
        if (pos[p] == 1) h += m;
        if (pos[p] == -1) h += m * 2;
        m *= 3;
    }
    return h;
}

// Soul is the essense of a board, despite
// its many views. For example, a board with
// a single piece in the corner has four views
// but only one soul. The soul numeric value
// is the view with the lowest numeric value,
// after all possible rotations and reflections.
pub fn soul_from_pos(pos: *const [9]i8) u16 {
    var bo: [9]i8 = pos.*; // bo : original board
    var br: [9]i8 = reflect_from_pos(&bo);

    var min = min2(view_from_pos(&bo), view_from_pos(&br));
    for (0..3) |_| { // rotate both three times
        pos_rotate(&bo);
        pos_rotate(&br);
        min = min3(min, view_from_pos(&bo), view_from_pos(&br));
    }
    return min;
}

// blind returns the lowest essense of a board
// irrespective of translation and blind to color.
// A black or white stone in any corner has the
// same blind numeric value.
pub fn blind_from_pos(pos: *const [9]i8) u16 {
    return min2(
        soul_from_pos(&invert_from_pos(pos)),
        soul_from_pos(pos),
    );
}

pub fn pos_from_view(key: u16) [9]i8 {
    var pos: [9]i8 = undefined;
    var rem = key;
    for (0..9) |p| {
        pos[p] = switch (rem % 3) {
            0 => 0,
            1 => 1,
            2 => -1,
            else => unreachable,
        };
        rem /= 3;
    }
    return pos;
}

pub fn soul_from_view(key: u16) u16 {
    // pos from view
    var bo: [9]i8 = undefined;
    var rem = key;
    for (0..9) |p| {
        bo[p] = switch (rem % 3) {
            0 => 0,
            1 => 1,
            2 => -1,
            else => unreachable,
        };
        rem /= 3;
    }

    // soul from pos
    var br = reflect_from_pos(&bo);
    var min = min2(view_from_pos(&bo), view_from_pos(&br));
    for (0..3) |_| { // rotate both three times
        pos_rotate(&bo);
        pos_rotate(&br);
        min = min3(min, view_from_pos(&bo), view_from_pos(&br));
    }
    return min;
}

test "sequences" {
    try expect(1 == seq3u(1, 1, 1));
    try expect(-1 == seq3u(-1, -1, -1));
    try expect(-128 == seq3u(-1, 1, 0));
    try expect(-128 == seq3u(0, 0, 0));
}

test "soul from view" {
    var pos: [9]i8 = [_]i8{
        -1, 1, 0,
        -1, 0, 1,
        -1, 0, 0,
    };
    const orig_view = view_from_pos(&pos);
    const orig_soul = soul_from_view(orig_view);
    var inv = invert_from_pos(&pos);
    for (0..3) |_| {
        pos_rotate(&pos);
        var v = view_from_pos(&pos);
        try expect(v != orig_view);
        try expect(orig_soul == soul_from_view(v));
        try expect(orig_soul == soul_from_pos(&pos));

        pos_rotate(&inv);
        v = view_from_pos(&inv);
        try expect(v != orig_view);
        try expect(orig_soul != soul_from_view(v));
        try expect(orig_soul != soul_from_pos(&inv));
    }
}

test "test all boards patterns" {
    var pos: [9]i8 = undefined;
    var view: u16 = 0;
    var souls: u16 = 0;
    var blinds: u16 = 0;
    var hi_soul: u16 = 0;
    var hi_blind: u16 = 0;
    while (view < 19683) : (view += 1) {
        pos = pos_from_view(view);
        try expect(view_from_pos(&pos) == view);

        const soul = soul_from_pos(&pos);
        if (view_from_pos(&pos) == soul) souls += 1;
        if (soul > hi_soul) hi_soul = soul;

        const blind = blind_from_pos(&pos);
        if (view_from_pos(&pos) == blind) blinds += 1;
        if (blind > hi_blind) hi_blind = blind;

        try expect(view >= soul);
        try expect(hi_soul >= hi_blind);
        try expect(soul >= blind);
        try expect(souls >= blinds);

        // gold-plating
        if (view < 9) {
            try expect(view + 1 == souls);
            try expect(view + 1 >= blinds);
        } else if (view < 12) {
            try expect(view == souls);
            try expect(view - 4 >= blinds);
            try expect(view * 2 >= blinds * 3);
        } else {
            try expect(view > souls);
            try expect(view - 5 >= blinds);
            try expect(view * 2 >= blinds * 3);
        }

        try expect(view < 2 or view >= blinds);
        try expect(view < 7 or (view + 1) * 2 >= blinds * 3);
    }
    // print("view={d}, souls={d}, hi_soul={d}, blinds={d}, hi_blind={d}\n", .{
    //     view,
    //     souls,
    //     hi_soul,
    //     blinds,
    //     hi_blind,
    // });
}

test "two reflections to the same board" {
    var pos = pos_from_view(32123);
    const orig_view = view_from_pos(&pos);
    const orig_soul = soul_from_pos(&pos);
    const orig_blind = blind_from_pos(&pos);

    try expect(view_from_pos(&pos) == orig_view);

    pos_reflect(&pos);
    try expect(view_from_pos(&pos) != orig_view);
    try expect(soul_from_pos(&pos) == orig_soul);
    try expect(blind_from_pos(&pos) == orig_blind);

    pos_invert(&pos);
    try expect(view_from_pos(&pos) != orig_view);
    try expect(soul_from_pos(&pos) != orig_soul);
    try expect(blind_from_pos(&pos) == orig_blind);

    pos_invert(&pos);
    try expect(blind_from_pos(&pos) == orig_blind);
    try expect(soul_from_pos(&pos) == orig_soul);

    pos_reflect(&pos);
    try expect(view_from_pos(&pos) == orig_view);
    try expect(soul_from_pos(&pos) == orig_soul);
    try expect(blind_from_pos(&pos) == orig_blind);
}

test "four rotations to the same board" {
    var pos = pos_from_view(52123);
    const orig_view = view_from_pos(&pos);
    const orig_soul = soul_from_pos(&pos);
    const orig_blind = blind_from_pos(&pos);

    try expect(view_from_pos(&pos) == orig_view);

    pos_rotate(&pos);
    try expect(view_from_pos(&pos) != orig_view);
    try expect(soul_from_pos(&pos) == orig_soul);
    try expect(blind_from_pos(&pos) == orig_blind);

    pos_invert(&pos);
    pos_rotate(&pos);
    try expect(view_from_pos(&pos) != orig_view);
    try expect(soul_from_pos(&pos) != orig_soul);
    try expect(blind_from_pos(&pos) == orig_blind);

    pos_invert(&pos);
    pos_rotate(&pos);
    try expect(view_from_pos(&pos) != orig_view);
    try expect(soul_from_pos(&pos) == orig_soul);
    try expect(blind_from_pos(&pos) == orig_blind);

    pos_rotate(&pos);
    try expect(view_from_pos(&pos) == orig_view);
    try expect(soul_from_pos(&pos) == orig_soul);
    try expect(blind_from_pos(&pos) == orig_blind);
}

test "test status" {
    const W = -1;

    const boardEmpty = [_]i8{ 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    try expect(pos_status(&boardEmpty) == UNRESOLVED);

    const boardBlackHorizontalWin = [_]i8{ 1, 1, 1, 0, 0, 0, 0, 0, 0 };
    try expect(pos_status(&boardBlackHorizontalWin) == 1);

    const boardWhiteHorizontalWin = [_]i8{ 0, 0, 0, W, W, W, 0, 0, 0 };
    try expect(pos_status(&boardWhiteHorizontalWin) == -1);

    const boardBlackDiagonalWin = [_]i8{ 1, 0, 0, 0, 1, 0, 0, 0, 1 };
    try expect(pos_status(&boardBlackDiagonalWin) == 1);

    const blackMultiWin = [_]i8{ 1, W, 1, W, 1, W, 1, W, 1 };
    try expect(pos_status(&blackMultiWin) == 1);

    const boardUnsettled = [_]i8{ W, W, 1, 1, 1, W, W, W, 1 };
    try expect(pos_status(&boardUnsettled) == 0);
}

test "test weighted score" {
    const W = -1;

    const boardEmpty = [_]i8{ 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    try expect(pos_score(&boardEmpty) == UNRESOLVED);

    const boardBlackHorizontalWin = [_]i8{ 1, 1, 1, 0, 0, 0, 0, 0, 0 };
    try expect(pos_score(&boardBlackHorizontalWin) == 7);

    const boardWhiteHorizontalWin = [_]i8{ 0, 0, 0, W, W, W, 0, 0, 0 };
    try expect(pos_score(&boardWhiteHorizontalWin) == -7);

    const boardBlackDiagonalWin = [_]i8{ W, W, 1, 0, 1, 0, 1, W, 1 };
    try expect(pos_score(&boardBlackDiagonalWin) == 3);

    const blackMultiWin = [_]i8{ 1, W, 1, W, 1, W, 1, W, 1 };
    try expect(pos_score(&blackMultiWin) == 1);

    const boardUnsettled = [_]i8{ W, W, 1, 1, 1, W, W, W, 1 };
    try expect(pos_score(&boardUnsettled) == 0);
}
