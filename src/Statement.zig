const shared = @import("./shared.zig");
const sqlite = @import("sqlite");
const std = @import("std");

const Database = @import("./Database.zig");
const parseResultCode = shared.parseResultCode;
const ErrorCodes = shared.ErrorCodes;
const OkCodes = shared.OkCodes;

const Statement = @This();

stmt: *sqlite.sqlite3_stmt,
db: *sqlite.sqlite3,

pub fn init(db: *Database, query: [:0]const u8) ErrorCodes!Statement {
    var stmt: ?*sqlite.sqlite3_stmt = undefined;
    const result = sqlite.sqlite3_prepare_v2(db.db.?, query, @intCast(query.len), &stmt, null);

    _ = try parseResultCode(result);

    return .{
        .stmt = stmt.?,
        .db = db.db.?,
    };
}

pub fn step(self: *const Statement) ErrorCodes!OkCodes {
    const result = sqlite.sqlite3_step(self.stmt);
    return parseResultCode(result);
}

pub fn clear(self: *const Statement) ErrorCodes!OkCodes {
    const result = sqlite.sqlite3_clear_bindings(self.stmt);
    return parseResultCode(result);
}

pub fn reset(self: *const Statement) ErrorCodes!OkCodes {
    const result = sqlite.sqlite3_reset(self.stmt);
    return parseResultCode(result);
}

pub fn clearAndReset(self: *const Statement) void {
    self.clear();
    self.reset();
}

pub fn deinit(self: *const Statement) ErrorCodes!OkCodes {
    const result = sqlite.sqlite3_finalize(self.stmt);
    return parseResultCode(result);
}

pub fn bindNull(self: *const Statement, index: u8) ErrorCodes!void {
    const result = sqlite.sqlite3_bind_null(self.stmt, @intCast(index));
    _ = try parseResultCode(result);
}

pub fn bindText(self: *const Statement, index: u8, text: []const u8) ErrorCodes!void {
    // TODO: Check if transient really is the best option for us
    const result = sqlite.sqlite3_bind_text(self.stmt, @intCast(index), text.ptr, @as(c_int, @intCast(text.len)), sqlite.SQLITE_TRANSIENT);
    _ = try parseResultCode(result);
}

pub fn bindBlob(self: *const Statement, index: u8, blob: []const u8) ErrorCodes!void {
    // TODO: Check if transient really is the best option for us
    const result = sqlite.sqlite3_bind_blob(self.stmt, @intCast(index), blob.ptr, @as(c_int, @intCast(blob.len)), null);
    _ = try parseResultCode(result);
}

pub fn bindNumber(self: *const Statement, T: type, index: u8, number: T) ErrorCodes!void {
    return switch (@typeInfo(T)) {
        // TODO: Integers and floats bigger than 64bits should be bound as blob
        .int, .comptime_int => self.bindInt(index, @as(i64, number)),
        .float, .comptime_float => self.bindFloat(index, @as(f64, number)),
        else => @compileError("Invalid type"),
    };
}

pub fn bindInt(self: *const Statement, index: u8, int: i64) ErrorCodes!void {
    const result = sqlite.sqlite3_bind_int64(self.stmt, @intCast(index), int);
    _ = try parseResultCode(result);
}

pub fn bindUInt(self: *const Statement, index: u8, int: u64) ErrorCodes!void {
    const result = sqlite.sqlite3_bind_int64(self.stmt, @intCast(index), @bitCast(int));
    _ = try parseResultCode(result);
}

pub fn bindFloat(self: *const Statement, index: u8, float: f64) ErrorCodes!void {
    const result = sqlite.sqlite3_bind_double(self.stmt, @intCast(index), float);
    _ = try parseResultCode(result);
}

pub fn textColumn(self: *const Statement, allocator: std.mem.Allocator, column: u8) ![]const u8 {
    const text = sqlite.sqlite3_column_text(self.stmt, @as(c_int, column));
    const len: usize = @intCast(sqlite.sqlite3_column_bytes(self.stmt, @as(c_int, column)));

    return try allocator.dupe(u8, text[0..len]);
}

pub fn blobColumn(self: *const Statement, allocator: std.mem.Allocator, column: u8) ![]const u8 {
    const blob = sqlite.sqlite3_column_blob(self.stmt, @as(c_int, column));
    const len: usize = @intCast(sqlite.sqlite3_column_bytes(self.stmt, @as(c_int, column)));

    return try allocator.dupe(u8, blob[0..len]);
}

pub fn intColumn(self: *const Statement, column: u8) i64 {
    return sqlite.sqlite3_column_int64(self.stmt, @as(c_int, column));
}

pub fn uIntColumn(self: *const Statement, column: u8) u64 {
    return @bitCast(sqlite.sqlite3_column_int64(self.stmt, @as(c_int, column)));
}

pub fn floatColumn(self: *const Statement, column: u8) f64 {
    return sqlite.sqlite3_column_double(self.stmt, @as(c_int, column));
}

pub fn columnCount(self: *const Statement) i32 {
    return sqlite.sqlite3_column_count(self.stmt);
}

pub fn dataCount(self: *const Statement) i32 {
    return sqlite.sqlite3_data_count(self.stmt);
}

pub fn changes(self: *const Statement) i64 {
    return sqlite.sqlite3_changes64(self.db);
}
