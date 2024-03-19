const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;

const brd = @import("board.zig");
const pos_score = brd.pos_score;
const pos_from_view = brd.pos_from_view;
const soul_from_pos = brd.soul_from_pos;

const util = @import("util.zig");
const max2 = util.max2;
const min2 = util.min2;
const UNRESOLVED: i8 = brd.UNRESOLVED;

pub const SoulTable = struct {
    souls: [19683]i8 = [_]i8{UNRESOLVED} ** 19683,
    num_entries: u16 = 0,

    pub fn get_score_from_pos(self: *const SoulTable, pos: *const [9]i8) i8 {
        return self.souls[soul_from_pos(pos)];
    }

    pub fn get_score(self: *const SoulTable, key: u16) i8 {
        return self.souls[key];
    }

    pub fn set_score_from_pos(self: *SoulTable, pos: *const [9]i8, val: i8) i8 {
        return self.set_score(soul_from_pos(pos), val);
    }

    pub fn set_score(self: *SoulTable, key: u16, val: i8) i8 {
        var extant: i8 = self.souls[key];
        if (extant == UNRESOLVED) {
            self.num_entries += 1;
            self.souls[key] = val;
            return val;
        }
        if (extant != val) {
            print("CANNOT OVERWRITE key {d} val {d} with new val {d}", .{
                key,
                extant,
                val,
            });
        }
        return extant;
    }

    pub fn get_count(self: *SoulTable) u16 {
        return self.num_entries;
    }
};

pub fn minimax(
    pos: *const [9]i8,
    is_black: bool,
    souls: *SoulTable,
) i8 {
    var score: i8 = pos_score(pos);
    if (score != UNRESOLVED) { // game over
        return souls.set_score_from_pos(pos, score);
    }
    var val: i8 = if (is_black) 99 else -99;
    for (0..9) |p| {
        if (pos[p] != 0) continue;
        var child = pos.*;
        child[p] = if (is_black) -1 else 1;
        val = if (is_black)
            min2(val, minimax(&child, !is_black, souls))
        else
            max2(val, minimax(&child, !is_black, souls));
    }
    return souls.set_score_from_pos(pos, val);
}

test "white always wins, terminal leaf souls, hopeless black parent" {
    const W = -1;
    const WHITE_TO_PLAY = false;
    const BLACK_TO_PLAY = true;

    const white_diagonal_win = [_]i8{
        W, 1, 1,
        1, W, 1,
        0, W, W,
    };
    const white_diagonal_soul = soul_from_pos(&white_diagonal_win);
    const white_diagonal_score = pos_score(&white_diagonal_win);

    // test score
    // negative for W win,
    // with 0 + 1 remaining
    try expect(white_diagonal_score == -2);

    var souls: SoulTable = SoulTable{};

    // minimax returns parent/root score,
    // is that what we expect?
    try expect(-2 == minimax(&white_diagonal_win, WHITE_TO_PLAY, &souls));
    try expect(souls.get_count() == 1);

    // sibling, another way for white to win
    const white_bottom_row_win = [_]i8{
        W, 1, 1,
        1, 0, 1,
        W, W, W,
    };
    const white_bottom_row_soul = soul_from_pos(&white_bottom_row_win);
    const white_bottom_row_score = pos_score(&white_bottom_row_win);

    try expect(white_bottom_row_score == -2);
    try expect(-2 == minimax(&white_bottom_row_win, WHITE_TO_PLAY, &souls));
    try expect(souls.get_count() == 2);

    // let's test integrity of both previous states
    try expect(white_diagonal_score == souls.get_score(white_diagonal_soul));
    try expect(white_bottom_row_score == souls.get_score(white_bottom_row_soul));
    try expect(UNRESOLVED == souls.get_score(123));

    // going up (backwards), let's consider parent
    const black_parent = [_]i8{
        W, 1, 1,
        1, 0, 1,
        0, W, W,
    };
    try expect(pos_score(&black_parent) == UNRESOLVED);
    try expect(-2 == minimax(&black_parent, BLACK_TO_PLAY, &souls));
    try expect(souls.get_count() == 3);
}

test "white always wins, start from hopeless black parent" {
    const W = -1;
    const BLACK_TO_PLAY = true;
    var souls: SoulTable = SoulTable{};
    const white_diagonal_win = [_]i8{
        W, 1, 1,
        1, W, 1,
        0, W, W,
    };
    const white_diagonal_soul = soul_from_pos(&white_diagonal_win);
    const white_diagonal_score = pos_score(&white_diagonal_win);

    // test score
    // negative for W win,
    // with 0 + 1 remaining
    try expect(white_diagonal_score == -2);

    // sibling, another way for white to win
    const white_bottom_row_win = [_]i8{
        W, 1, 1,
        1, 0, 1,
        W, W, W,
    };
    const white_bottom_row_soul = soul_from_pos(&white_bottom_row_win);
    const white_bottom_row_score = pos_score(&white_bottom_row_win);

    try expect(white_bottom_row_score == -2);

    // prove that souls knows nothing
    try expect(UNRESOLVED == souls.get_score(white_diagonal_soul));
    try expect(UNRESOLVED == souls.get_score(white_bottom_row_soul));
    try expect(UNRESOLVED == souls.get_score(123));

    // going up (backwards), let's consider parent
    const black_parent = [_]i8{
        W, 1, 1,
        1, 0, 1,
        0, W, W,
    };
    try expect(pos_score(&black_parent) == UNRESOLVED);
    try expect(-2 == minimax(&black_parent, BLACK_TO_PLAY, &souls));
    try expect(souls.get_count() == 3);
}

test "unbalanced tree, two and three levels from white" {
    const W = -1;
    const WHITE_TO_PLAY = false;
    const BLACK_TO_PLAY = true;
    var souls: SoulTable = SoulTable{};
    const white_diagonal_win = [_]i8{
        W, 0, 1,
        1, W, 1,
        1, W, W,
    };
    const white_diagonal_score = pos_score(&white_diagonal_win);
    try expect(white_diagonal_score == -2);
    try expect(-2 == minimax(&white_diagonal_win, WHITE_TO_PLAY, &souls));

    // black nephew wins by row and diagonal
    const black_nephew_double_win = [_]i8{
        W, W, 1,
        1, 1, 1,
        1, W, W,
    };
    const black_nephew_double_score = pos_score(&black_nephew_double_win);

    // no empty space but still a positive win for black
    try expect(black_nephew_double_score == 1);
    try expect(1 == minimax(&black_nephew_double_win, BLACK_TO_PLAY, &souls));

    // going up (backwards), let's consider parent
    const black_parent = [_]i8{
        W, 1, 1,
        1, 0, 1,
        0, W, W,
    };
    try expect(pos_score(&black_parent) == UNRESOLVED);

    try expect(-2 == minimax(&black_parent, BLACK_TO_PLAY, &souls));
    try expect(souls.get_count() == 5);
}

test "full minimax from empty board" {
    const W: i8 = -1;
    var souls: SoulTable = SoulTable{};
    var empty_board = pos_from_view(0);
    var resMinimax = minimax(&empty_board, false, &souls);
    try expect(resMinimax == 0);
    try expect(souls.get_score(0) == souls.get_score(1)); // top left
    try expect(souls.get_score(3) == souls.get_score(81)); // top == middle
    try expect(souls.get_score_from_pos(&[9]i8{
        W, 1, 0,
        W, 1, 0,
        0, 0, 0,
    }) == 5);
    try expect(souls.get_score_from_pos(&[9]i8{
        W, 1, 0,
        W, 1, 0,
        0, 1, 0,
    }) == 5);
    try expect(souls.get_score_from_pos(&[9]i8{
        W, 1, 0,
        W, 1, 0,
        1, 0, 0,
    }) == 3);
    try expect(souls.get_score_from_pos(&[9]i8{
        W, 1, 0,
        W, 1, 0,
        1, W, 0,
    }) == 3);
    try expect(souls.get_score_from_pos(&[9]i8{
        W, 1, 1,
        W, 1, 0,
        1, W, 0,
    }) == 3);
    try expect(souls.get_score_from_pos(&[9]i8{
        W, 1, 1,
        W, 1, 0,
        1, W, 0,
    }) == 3);
    try expect(souls.get_score_from_pos(&[9]i8{
        W, 1, 1,
        W, 1, W,
        1, W, 0,
    }) == UNRESOLVED);
    try expect(souls.get_score_from_pos(&[9]i8{
        W, 1, 0,
        W, 1, 1,
        1, W, 0,
    }) == 0);
    try expect(souls.get_count() >= 765);
}

test "four levels from the top, white to play" {
    const W = -1;
    const WHITE_TO_PLAY = false;
    var souls: SoulTable = SoulTable{};
    const white_to_play = [_]i8{
        W, 0, 1,
        1, 0, 1,
        0, W, W,
    };
    try expect(pos_score(&white_to_play) == UNRESOLVED);
    try expect(minimax(&white_to_play, WHITE_TO_PLAY, &souls) == 3);
    try expect(souls.get_score(4153) == 3);
    try expect(souls.get_score(4180) == -2);
    try expect(souls.get_score(4234) == 3);
    try expect(souls.get_score(8314) == -2);
    //
    // WHITE                    (4153+3)
    //                         /    |   \
    //                        /     |    \
    // BLACK          (4180-2)  (4234+3)  (8314-2)
    //                /      \            /     \
    //               /        \          /       \
    // WHITE   (4342-2) (10502-2)   (10768+1)   (8476-2)
    //                               /
    //                              /
    // BLACK                  (10849+1)
    //
    try expect(souls.get_score(4342) == -2);
    try expect(souls.get_score(10502) == -2);
    try expect(souls.get_score(10768) == 1);
    try expect(souls.get_score(8476) == -2);
    try expect(souls.get_score(10849) == 1);
    try expect(souls.get_count() >= 9);
}

test "white lead to draw to win early" {
    const W: i8 = -1;
    var souls: SoulTable = SoulTable{};
    var empty_board = pos_from_view(0);
    try expect(0 == minimax(&empty_board, false, &souls));
    try expect(souls.get_score_from_pos(&[9]i8{
        1, 0, 0,
        1, W, 0,
        0, 0, 0,
    }) == 0);
    try expect(souls.get_score_from_pos(&[9]i8{
        1, 0, 0,
        1, W, 0,
        W, 0, 0,
    }) == 0);
    try expect(souls.get_score_from_pos(&[9]i8{
        1, 0, 1,
        1, W, 0,
        W, 0, 0,
    }) == 0);
    try expect(souls.get_score_from_pos(&[9]i8{
        1, W, 1,
        1, W, 0,
        W, 0, 0,
    }) == 0);
    try expect(souls.get_score_from_pos(&[9]i8{
        1, W, 1,
        1, W, 0,
        W, 1, 0,
    }) == 0);
    try expect(souls.get_count() >= 765);
}
