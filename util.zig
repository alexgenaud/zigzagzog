// min2 .. min4 return the minimum
// numeric value of their respective inputs
// Assumes all input types match and output
// type specifically matches first input type
const expect = @import("std").testing.expect;

pub fn min2(a: anytype, b: anytype) @TypeOf(a) {
    return if (a < b) a else b;
}

pub fn min3(a: anytype, b: anytype, c: anytype) @TypeOf(a) {
    return min2(min2(a, b), c);
}

pub fn min4(a: anytype, b: anytype, c: anytype, d: anytype) @TypeOf(a) {
    return min2(min2(a, b), min2(c, d));
}

pub fn max2(a: anytype, b: anytype) @TypeOf(a) {
    return if (a > b) a else b;
}

pub fn max3(a: anytype, b: anytype, c: anytype) @TypeOf(a) {
    return max2(max2(a, b), c);
}

pub fn max4(a: anytype, b: anytype, c: anytype, d: anytype) @TypeOf(a) {
    return max2(max2(a, b), max2(c, d));
}

test "min of two" {
    try expect(7 == min2(7, 9));
    try expect(0 == min2(7, 0));
    try expect(3 == min2(3, 3));
    try expect(-5 == min2(-5, 5));
    try expect(-5 == min2(5, -5));
    try expect(2.7 == min2(3.14, 2.7));
}

test "min of three" {
    try expect(4 == min3(4, 7, 9));
    try expect(0 == min3(7, 0, 6));
    try expect(-5 == min3(0, -5, 5));
    try expect(-5 == min3(5, -5, 0));
    try expect(-5 == min3(-5, 5, 0));
}

test "min of four" {
    try expect(-7.123 == min4(-2.546, 4.123, -7.123, 0.123));
    try expect(0 == min4(7.0, 3.14, 0, 6));
    try expect(-5 == min4(0, -5, 5, 999999999999));
    try expect(-69 == min4(740, 3314, 0, -69));
    try expect(0 == min4(0, 0, 0, 0));
}

test "max of two" {
    try expect(9 == max2(7, 9));
    try expect(7 == max2(7, 0));
    try expect(3 == max2(3, 3));
    try expect(5 == max2(-5, 5));
    try expect(3.14 == max2(3.14, 2.7));
}

test "max of three" {
    try expect(9 == max3(4, 7, 9));
    try expect(7 == max3(7, 0, 6));
    try expect(5 == max3(0, -5, 5));
}

test "max of four" {
    try expect(4.123 == max4(-2.546, 4.123, -7.123, 0.123));
    try expect(7.0 == max4(7.0, 3.14, 0, 6));
    try expect(999999999999 == max4(0, -5, 5, 999999999999));
    try expect(3314 == max4(740, 3314, 0, -69));
    try expect(0 == max4(0, 0, 0, 0));
}
